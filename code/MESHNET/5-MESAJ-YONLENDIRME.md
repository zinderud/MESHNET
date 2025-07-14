# 5. MESAJ YÖNLENDIRME VE MESH PROTOKOLLERI (Reticulum Enhanced)

## Genel Bakış

Bu aşamada, **Reticulum Network Stack**'inin self-configuring routing algoritmasını temel alarak, BitChat'in mesh protokolleri ile hibrit bir yönlendirme sistemi implementasyonu ele alınacaktır.

## 5.1 Reticulum-Based Routing Architecture

### 5.1.1 Self-Configuring Mesh Router (Reticulum Pattern)

```dart
// lib/core/routing/reticulum_router.dart
class ReticulumMeshRouter {
  // Reticulum routing constants
  static const int ANNOUNCE_TIMEOUT = 60; // seconds
  static const int MAX_HOPS = 30;
  static const int RECALL_SIZE = 8192; // packet recall buffer
  
  final Map<Uint8List, DestinationEntry> _destinationTable = {};
  final Map<Uint8List, PathEntry> _pathTable = {};
  final Map<String, InterfaceState> _interfaces = {};
  final Queue<PacketRecall> _recallBuffer = Queue();
  
  class DestinationEntry {
    final Uint8List destinationHash; // 80-bit truncated hash
    final Uint8List publicKey;
    final List<PathEntry> availablePaths;
    final DateTime lastAnnounce;
    int hopCount;
    double pathQuality;
    
    DestinationEntry({
      required this.destinationHash,
      required this.publicKey,
      required this.availablePaths,
      required this.lastAnnounce,
      required this.hopCount,
      required this.pathQuality,
    });
  }
  
  class PathEntry {
    final String interfaceId;
    final ProtocolType protocolType;
    final Uint8List nextHop;
    final int hopCount;
    final double rssi;
    final double snr;
    final DateTime established;
    final DateTime lastSeen;
    
    PathEntry({
      required this.interfaceId,
      required this.protocolType,
      required this.nextHop,
      required this.hopCount,
      required this.rssi,
      required this.snr,
      required this.established,
      required this.lastSeen,
    });
  }
  
  // Reticulum hash-based routing
  Future<PathEntry?> findBestPath(Uint8List destinationHash) async {
    final destination = _destinationTable[destinationHash];
    if (destination == null) {
      // No known destination, trigger announce
      await _requestPath(destinationHash);
      return null;
    }
    
    // Select best path based on Reticulum metrics
    return _selectOptimalPath(destination.availablePaths);
  }
  
  PathEntry? _selectOptimalPath(List<PathEntry> paths) {
    if (paths.isEmpty) return null;
    
    // Reticulum path selection algorithm
    return paths.reduce((best, current) {
      final bestScore = _calculatePathScore(best);
      final currentScore = _calculatePathScore(current);
      return currentScore > bestScore ? current : best;
    });
  }
  
  double _calculatePathScore(PathEntry path) {
    // Reticulum path scoring: hop count, signal quality, protocol capability
    double hopPenalty = 1.0 / (path.hopCount + 1);
    double signalQuality = (path.rssi + 100) / 100; // Normalize RSSI
    double protocolBonus = _getProtocolBonus(path.protocolType);
    double agePenalty = _getAgePenalty(path.lastSeen);
    
    return hopPenalty * signalQuality * protocolBonus * agePenalty;
  }
  
  double _getProtocolBonus(ProtocolType protocol) {
    switch (protocol) {
      case ProtocolType.sdr:
        return 1.5; // Long range capability
      case ProtocolType.hamRadio:
        return 1.4; // Emergency reliability
      case ProtocolType.wifiDirect:
        return 1.2; // High bandwidth
      case ProtocolType.bluetooth:
        return 1.0; // Baseline
      default:
        return 0.8;
    }
  }
  
  Future<void> _requestPath(Uint8List destinationHash) async {
    // Send path request packet (Reticulum announce mechanism)
    final pathRequest = PathRequestPacket(
      destinationHash: destinationHash,
      sourceHash: _localIdentity.getHash(),
      maxHops: MAX_HOPS,
      timestamp: DateTime.now(),
    );
    
    // Broadcast on all active interfaces
    for (final interface in _interfaces.values) {
      if (interface.isActive) {
        await interface.broadcastPacket(pathRequest);
      }
    }
  }
}
```

### 5.1.2 Reticulum Announce System

```dart
// lib/core/routing/announce_system.dart
class ReticulumAnnounceSystem {
  final ReticulumMeshRouter _router;
  final Timer _announceTimer;
  
  static const Duration ANNOUNCE_INTERVAL = Duration(minutes: 2);
  static const Duration ANNOUNCE_TIMEOUT = Duration(minutes: 30);
  
  ReticulumAnnounceSystem(this._router) : 
    _announceTimer = Timer.periodic(ANNOUNCE_INTERVAL, _periodicAnnounce);
  
  // Reticulum destination announce
  Future<void> announceDestination(ReticulumDestination destination) async {
    final announcePacket = AnnouncePacket(
      destinationHash: destination.destinationHash,
      identityHash: destination.identity.getHash(),
      publicKeys: await destination.identity.getPublicKeys(),
      appName: destination.appName,
      aspects: [destination.aspectOne, destination.aspectTwo],
      timestamp: DateTime.now(),
      hopCount: 0,
    );
    
    // Sign announce with destination identity
    final signature = await destination.identity.sign(
      Uint8List.fromList(announcePacket.toBytes())
    );
    announcePacket.signature = signature;
    
    // Broadcast announce on all interfaces
    await _broadcastAnnounce(announcePacket);
    
    debugPrint('Announced destination: ${_hashToHex(destination.destinationHash)}');
  }
  
  Future<void> _broadcastAnnounce(AnnouncePacket packet) async {
    for (final interface in _router._interfaces.values) {
      if (interface.isActive && interface.canBroadcast) {
        await interface.sendPacket(packet);
      }
    }
  }
  
  // Handle received announce
  Future<void> handleReceivedAnnounce(AnnouncePacket packet, String fromInterface) async {
    // Verify announce signature
    final isValid = await _verifyAnnounceSignature(packet);
    if (!isValid) {
      debugPrint('Invalid announce signature rejected');
      return;
    }
    
    // Check for loop prevention
    if (_isLoopback(packet)) {
      return;
    }
    
    // Update destination table
    await _updateDestinationTable(packet, fromInterface);
    
    // Rebroadcast if hop count allows
    if (packet.hopCount < ReticulumMeshRouter.MAX_HOPS) {
      await _rebroadcastAnnounce(packet, fromInterface);
    }
  }
  
  Future<void> _updateDestinationTable(AnnouncePacket packet, String fromInterface) async {
    final destinationEntry = DestinationEntry(
      destinationHash: packet.destinationHash,
      publicKey: packet.publicKeys['encryption']!,
      availablePaths: [
        PathEntry(
          interfaceId: fromInterface,
          protocolType: _getInterfaceProtocol(fromInterface),
          nextHop: packet.sourceHash,
          hopCount: packet.hopCount + 1,
          rssi: packet.rssi ?? -80,
          snr: packet.snr ?? 0,
          established: DateTime.now(),
          lastSeen: DateTime.now(),
        )
      ],
      lastAnnounce: packet.timestamp,
      hopCount: packet.hopCount + 1,
      pathQuality: _calculateInitialQuality(packet),
    );
    
    _router._destinationTable[packet.destinationHash] = destinationEntry;
  }
  
  void _periodicAnnounce(Timer timer) {
    // Periodic announcement of local destinations
    for (final destination in _localDestinations) {
      announceDestination(destination);
    }
  }
}
  final Map<String, RouteMetrics> _routeMetrics = {};
  final Duration _routeTimeout = const Duration(minutes: 5);
  
  class RouteMetrics {
    double latency;
    double throughput;
    double reliability;
    double powerConsumption;
    int packetLoss;
    
    RouteMetrics({
      required this.latency,
      required this.throughput,
      required this.reliability,
      required this.powerConsumption,
      required this.packetLoss,
    });
    
    double getScore(MessagePriority priority) {
      switch (priority) {
        case MessagePriority.emergency:
          return reliability * 0.6 + (1 - latency) * 0.4;
        case MessagePriority.high:
          return reliability * 0.4 + throughput * 0.3 + (1 - latency) * 0.3;
        case MessagePriority.normal:
          return throughput * 0.4 + reliability * 0.3 + (1 - powerConsumption) * 0.3;
        default:
          return (1 - powerConsumption) * 0.5 + throughput * 0.3 + reliability * 0.2;
      }
    }
  }
  
  Future<void> updateRouteMetrics(String routeId, RouteMetrics metrics) async {
    _routeMetrics[routeId] = metrics;
    await _optimizeRoutes();
  }
  
  Future<void> _optimizeRoutes() async {
    // Düşük performanslı rotaları temizle
    var now = DateTime.now();
    _multiPathRoutes.removeWhere((destination, routes) {
      routes.removeWhere((route) => 
          now.difference(route.lastUpdated) > _routeTimeout);
      return routes.isEmpty;
    });
    
    // Yedek rotalar oluştur
    for (var destination in _multiPathRoutes.keys) {
      await _establishBackupRoutes(destination);
    }
  }
  
  Future<void> _establishBackupRoutes(String destination) async {
    var routes = _multiPathRoutes[destination] ?? [];
    if (routes.length < 2) {
      // En az 2 alternatif rota olmalı
      await _discoverAlternativeRoutes(destination);
    }
  }
}
```

## 5.2 Mesh Protokol Implementasyonu

### 5.2.1 AODV (Ad-hoc On-Demand Distance Vector) Adaptasyonu

```dart
// lib/protocols/mesh/aodv_protocol.dart
class AODVProtocol extends MeshProtocol {
  final Map<String, AODVRouteEntry> _routeTable = {};
  final Map<String, PendingRequest> _pendingRequests = {};
  final int _maxHopCount = 10;
  
  class AODVRouteEntry {
    final String destination;
    final String nextHop;
    final int hopCount;
    final int sequenceNumber;
    final DateTime expiration;
    final ProtocolType protocolType;
    
    AODVRouteEntry({
      required this.destination,
      required this.nextHop,
      required this.hopCount,
      required this.sequenceNumber,
      required this.expiration,
      required this.protocolType,
    });
  }
  
  @override
  Future<bool> sendMessage(String destination, MessagePacket message) async {
    var route = _routeTable[destination];
    
    if (route == null || route.expiration.isBefore(DateTime.now())) {
      // Rota bulunamadı, keşif başlat
      await _initiateRouteDiscovery(destination);
      return false;
    }
    
    // Mevcut rota ile mesaj gönder
    return await _forwardMessage(route, message);
  }
  
  Future<void> _initiateRouteDiscovery(String destination) async {
    var rreq = RouteRequest(
      destination: destination,
      source: deviceId,
      requestId: _generateRequestId(),
      hopCount: 0,
      sequenceNumber: _getNextSequenceNumber(),
    );
    
    _pendingRequests[rreq.requestId] = PendingRequest(
      destination: destination,
      timestamp: DateTime.now(),
    );
    
    // Tüm protokoller üzerinden broadcast
    await _broadcastRouteRequest(rreq);
  }
  
  Future<void> _broadcastRouteRequest(RouteRequest rreq) async {
    for (var protocol in _protocols.values) {
      if (protocol.isAvailable) {
        await protocol.broadcast(rreq.toJson());
      }
    }
  }
  
  Future<void> _handleRouteRequest(RouteRequest rreq, String sender) async {
    // Döngü kontrolü
    if (rreq.hopCount >= _maxHopCount) return;
    
    // Hedef mi?
    if (rreq.destination == deviceId) {
      await _sendRouteReply(rreq, sender);
      return;
    }
    
    // Ara rota var mı?
    var route = _routeTable[rreq.destination];
    if (route != null && route.expiration.isAfter(DateTime.now())) {
      await _sendRouteReply(rreq, sender, intermediateRoute: route);
      return;
    }
    
    // Forward route request
    rreq.hopCount++;
    await _broadcastRouteRequest(rreq);
  }
  
  Future<void> _sendRouteReply(
    RouteRequest rreq, 
    String sender, 
    {AODVRouteEntry? intermediateRoute}
  ) async {
    var rrep = RouteReply(
      destination: rreq.destination,
      source: rreq.source,
      hopCount: intermediateRoute?.hopCount ?? 0,
      sequenceNumber: intermediateRoute?.sequenceNumber ?? _getNextSequenceNumber(),
    );
    
    // Reverse route kurulumu
    _routeTable[rreq.source] = AODVRouteEntry(
      destination: rreq.source,
      nextHop: sender,
      hopCount: rreq.hopCount,
      sequenceNumber: rreq.sequenceNumber,
      expiration: DateTime.now().add(const Duration(minutes: 5)),
      protocolType: _getProtocolType(sender),
    );
    
    await _sendMessage(sender, rrep.toJson());
  }
}
```

### 5.2.2 Hibrit Mesh Protokolü

```dart
// lib/protocols/mesh/hybrid_mesh_protocol.dart
class HybridMeshProtocol extends MeshProtocol {
  final AODVProtocol _aodvProtocol;
  final FloodingProtocol _floodingProtocol;
  final GeographicRoutingProtocol _geoRouting;
  
  HybridMeshProtocol({
    required AODVProtocol aodvProtocol,
    required FloodingProtocol floodingProtocol,
    required GeographicRoutingProtocol geoRouting,
  }) : _aodvProtocol = aodvProtocol,
       _floodingProtocol = floodingProtocol,
       _geoRouting = geoRouting;
  
  @override
  Future<bool> sendMessage(String destination, MessagePacket message) async {
    var strategy = _selectRoutingStrategy(message);
    
    switch (strategy) {
      case RoutingStrategy.aodv:
        return await _aodvProtocol.sendMessage(destination, message);
      case RoutingStrategy.flooding:
        return await _floodingProtocol.sendMessage(destination, message);
      case RoutingStrategy.geographic:
        return await _geoRouting.sendMessage(destination, message);
      case RoutingStrategy.hybrid:
        return await _hybridSend(destination, message);
    }
  }
  
  RoutingStrategy _selectRoutingStrategy(MessagePacket message) {
    // Mesaj özelliklerine göre strateji seçimi
    if (message.priority == MessagePriority.emergency) {
      return RoutingStrategy.flooding; // Güvenilirlik öncelikli
    }
    
    if (message.hasGeographicConstraints) {
      return RoutingStrategy.geographic;
    }
    
    if (message.size > 1024 * 1024) { // Büyük mesajlar
      return RoutingStrategy.aodv; // Verimlilik öncelikli
    }
    
    return RoutingStrategy.hybrid;
  }
  
  Future<bool> _hybridSend(String destination, MessagePacket message) async {
    // Paralel gönderim stratejisi
    var futures = <Future<bool>>[];
    
    // Öncelikli protokol
    futures.add(_aodvProtocol.sendMessage(destination, message));
    
    // Yedek protokol (gecikmeli)
    Future.delayed(const Duration(seconds: 2), () {
      _floodingProtocol.sendMessage(destination, message);
    });
    
    // İlk başarılı gönderim
    var results = await Future.wait(futures);
    return results.any((result) => result);
  }
}
```

## 5.3 Mesaj Önceliklendirme ve QoS

### 5.3.1 Mesaj Kuyruğu Yönetimi

```dart
// lib/core/messaging/priority_queue_manager.dart
class PriorityQueueManager {
  final Map<MessagePriority, Queue<MessagePacket>> _queues = {};
  final Map<String, RateLimiter> _rateLimiters = {};
  
  PriorityQueueManager() {
    for (var priority in MessagePriority.values) {
      _queues[priority] = Queue<MessagePacket>();
    }
  }
  
  void enqueueMessage(MessagePacket message) {
    var queue = _queues[message.priority]!;
    
    // Acil durum mesajları için yer açma
    if (message.priority == MessagePriority.emergency) {
      _makeRoomForEmergency();
    }
    
    queue.add(message);
    _scheduleProcessing();
  }
  
  void _makeRoomForEmergency() {
    // Düşük öncelikli mesajları temizle
    var normalQueue = _queues[MessagePriority.normal]!;
    var lowQueue = _queues[MessagePriority.low]!;
    
    while (normalQueue.length > 10) {
      normalQueue.removeFirst();
    }
    
    while (lowQueue.length > 5) {
      lowQueue.removeFirst();
    }
  }
  
  Future<void> _scheduleProcessing() async {
    // Öncelik sırasına göre işleme
    for (var priority in MessagePriority.values) {
      var queue = _queues[priority]!;
      
      while (queue.isNotEmpty) {
        var message = queue.removeFirst();
        
        if (await _checkRateLimit(message)) {
          await _processMessage(message);
        } else {
          // Rate limit aşımı, tekrar kuyruğa ekle
          queue.addFirst(message);
          break;
        }
      }
    }
  }
  
  Future<bool> _checkRateLimit(MessagePacket message) async {
    var key = '${message.sender}_${message.priority}';
    var rateLimiter = _rateLimiters[key] ??= RateLimiter(
      maxRequests: _getMaxRequests(message.priority),
      duration: const Duration(minutes: 1),
    );
    
    return rateLimiter.tryConsume();
  }
  
  int _getMaxRequests(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.emergency:
        return 100; // Acil durum için yüksek limit
      case MessagePriority.high:
        return 50;
      case MessagePriority.normal:
        return 20;
      case MessagePriority.low:
        return 10;
    }
  }
}
```

### 5.3.2 QoS Yönetimi

```dart
// lib/core/qos/qos_manager.dart
class QoSManager {
  final Map<String, QoSProfile> _profiles = {};
  final Map<String, ConnectionState> _connections = {};
  
  class QoSProfile {
    final double minThroughput;
    final Duration maxLatency;
    final double minReliability;
    final double maxPowerConsumption;
    
    QoSProfile({
      required this.minThroughput,
      required this.maxLatency,
      required this.minReliability,
      required this.maxPowerConsumption,
    });
  }
  
  void initializeProfiles() {
    _profiles[MessagePriority.emergency.name] = QoSProfile(
      minThroughput: 1024, // 1KB/s minimum
      maxLatency: const Duration(seconds: 1),
      minReliability: 0.99,
      maxPowerConsumption: 1.0, // Güç tüketimi önemli değil
    );
    
    _profiles[MessagePriority.high.name] = QoSProfile(
      minThroughput: 512,
      maxLatency: const Duration(seconds: 5),
      minReliability: 0.95,
      maxPowerConsumption: 0.8,
    );
    
    _profiles[MessagePriority.normal.name] = QoSProfile(
      minThroughput: 256,
      maxLatency: const Duration(seconds: 10),
      minReliability: 0.90,
      maxPowerConsumption: 0.6,
    );
    
    _profiles[MessagePriority.low.name] = QoSProfile(
      minThroughput: 128,
      maxLatency: const Duration(seconds: 30),
      minReliability: 0.80,
      maxPowerConsumption: 0.4,
    );
  }
  
  Future<bool> validateQoS(MessagePacket message, String connectionId) async {
    var profile = _profiles[message.priority.name];
    var connection = _connections[connectionId];
    
    if (profile == null || connection == null) return false;
    
    // QoS gereksinimlerini kontrol et
    if (connection.throughput < profile.minThroughput) return false;
    if (connection.latency > profile.maxLatency) return false;
    if (connection.reliability < profile.minReliability) return false;
    if (connection.powerConsumption > profile.maxPowerConsumption) return false;
    
    return true;
  }
  
  Future<void> adaptConnection(String connectionId, QoSProfile targetProfile) async {
    var connection = _connections[connectionId];
    if (connection == null) return;
    
    // Bağlantı parametrelerini ayarla
    if (connection.throughput < targetProfile.minThroughput) {
      await _increaseThroughput(connectionId);
    }
    
    if (connection.latency > targetProfile.maxLatency) {
      await _reduceLatency(connectionId);
    }
    
    if (connection.reliability < targetProfile.minReliability) {
      await _improveReliability(connectionId);
    }
  }
}
```

## 5.4 Hata Toleransı ve Kurtarma

### 5.4.1 Mesaj Depolama ve Yeniden Gönderim

```dart
// lib/core/reliability/message_store.dart
class MessageStore {
  final Map<String, StoredMessage> _pendingMessages = {};
  final Map<String, List<String>> _deliveryReceipts = {};
  final Duration _retryInterval = const Duration(seconds: 30);
  final int _maxRetries = 5;
  
  class StoredMessage {
    final MessagePacket message;
    final DateTime timestamp;
    final int retryCount;
    final Set<String> attemptedProtocols;
    
    StoredMessage({
      required this.message,
      required this.timestamp,
      required this.retryCount,
      required this.attemptedProtocols,
    });
  }
  
  Future<void> storeMessage(MessagePacket message) async {
    _pendingMessages[message.id] = StoredMessage(
      message: message,
      timestamp: DateTime.now(),
      retryCount: 0,
      attemptedProtocols: {},
    );
    
    _scheduleRetry(message.id);
  }
  
  Future<void> _scheduleRetry(String messageId) async {
    await Future.delayed(_retryInterval);
    
    var stored = _pendingMessages[messageId];
    if (stored == null) return; // Mesaj başarıyla gönderildi
    
    if (stored.retryCount >= _maxRetries) {
      // Maksimum yeniden deneme aşıldı
      await _handleFailedMessage(stored);
      _pendingMessages.remove(messageId);
      return;
    }
    
    // Farklı protokol ile yeniden deneme
    var availableProtocols = _getAvailableProtocols()
        .where((p) => !stored.attemptedProtocols.contains(p))
        .toList();
    
    if (availableProtocols.isEmpty) {
      // Tüm protokoller denendi, bekle
      await Future.delayed(_retryInterval);
      availableProtocols = _getAvailableProtocols();
    }
    
    var protocol = availableProtocols.first;
    stored.attemptedProtocols.add(protocol);
    
    var success = await _sendWithProtocol(stored.message, protocol);
    
    if (!success) {
      // Başarısız, yeniden deneme planla
      _pendingMessages[messageId] = StoredMessage(
        message: stored.message,
        timestamp: stored.timestamp,
        retryCount: stored.retryCount + 1,
        attemptedProtocols: stored.attemptedProtocols,
      );
      
      _scheduleRetry(messageId);
    } else {
      // Başarılı, mesajı kaldır
      _pendingMessages.remove(messageId);
    }
  }
  
  Future<void> _handleFailedMessage(StoredMessage stored) async {
    // Kalıcı hata - mesajı offline store'a kaydet
    await _offlineStore.storeFailedMessage(stored.message);
    
    // Kullanıcıya bildirim
    await _notificationService.showFailedMessageNotification(stored.message);
  }
}
```

### 5.4.2 Ağ Bölünmesi Kurtarma

```dart
// lib/core/reliability/network_healing.dart
class NetworkHealingManager {
  final Map<String, NetworkPartition> _partitions = {};
  final Duration _healingInterval = const Duration(minutes: 2);
  
  class NetworkPartition {
    final Set<String> nodes;
    final DateTime detectionTime;
    final List<String> bridgeNodes;
    
    NetworkPartition({
      required this.nodes,
      required this.detectionTime,
      required this.bridgeNodes,
    });
  }
  
  Future<void> startHealingProcess() async {
    Timer.periodic(_healingInterval, (timer) async {
      await _detectPartitions();
      await _attemptHealing();
    });
  }
  
  Future<void> _detectPartitions() async {
    var allNodes = await _discoveryService.getAllKnownNodes();
    var reachableNodes = await _discoveryService.getReachableNodes();
    
    var unreachableNodes = allNodes.difference(reachableNodes);
    
    if (unreachableNodes.isNotEmpty) {
      var partition = NetworkPartition(
        nodes: unreachableNodes,
        detectionTime: DateTime.now(),
        bridgeNodes: await _findPotentialBridgeNodes(unreachableNodes),
      );
      
      _partitions[_generatePartitionId()] = partition;
    }
  }
  
  Future<void> _attemptHealing() async {
    for (var partition in _partitions.values) {
      await _tryReconnectPartition(partition);
    }
  }
  
  Future<void> _tryReconnectPartition(NetworkPartition partition) async {
    // Bridge node'lar ile yeniden bağlanma denemeleri
    for (var bridgeNode in partition.bridgeNodes) {
      for (var protocol in _getAvailableProtocols()) {
        try {
          var success = await _attemptConnection(bridgeNode, protocol);
          if (success) {
            await _reconstructRoutes(partition.nodes);
            _partitions.removeWhere((key, value) => value == partition);
            return;
          }
        } catch (e) {
          // Bağlantı başarısız, devam et
          continue;
        }
      }
    }
    
    // Uzun menzilli protokoller ile deneme
    await _tryLongRangeReconnection(partition);
  }
  
  Future<void> _tryLongRangeReconnection(NetworkPartition partition) async {
    // SDR ve HAM radio ile yeniden bağlanma
    for (var protocol in [ProtocolType.sdr, ProtocolType.hamRadio]) {
      if (await _isProtocolAvailable(protocol)) {
        var success = await _broadcastReconnectionRequest(partition, protocol);
        if (success) {
          await _reconstructRoutes(partition.nodes);
          _partitions.removeWhere((key, value) => value == partition);
          return;
        }
      }
    }
  }
}
```

## 5.5 Performans Optimizasyonu

### 5.5.1 Adaptif Protokol Seçimi

```dart
// lib/core/optimization/adaptive_protocol_selector.dart
class AdaptiveProtocolSelector {
  final Map<ProtocolType, ProtocolMetrics> _metrics = {};
  final Map<String, ProtocolUsageHistory> _history = {};
  
  class ProtocolMetrics {
    double throughput;
    double latency;
    double reliability;
    double powerConsumption;
    double signalStrength;
    
    ProtocolMetrics({
      required this.throughput,
      required this.latency,
      required this.reliability,
      required this.powerConsumption,
      required this.signalStrength,
    });
    
    double getScore(MessageContext context) {
      var score = 0.0;
      
      switch (context.priority) {
        case MessagePriority.emergency:
          score = reliability * 0.5 + signalStrength * 0.3 + (1 - latency) * 0.2;
          break;
        case MessagePriority.high:
          score = reliability * 0.3 + throughput * 0.3 + (1 - latency) * 0.4;
          break;
        case MessagePriority.normal:
          score = throughput * 0.4 + (1 - powerConsumption) * 0.3 + reliability * 0.3;
          break;
        case MessagePriority.low:
          score = (1 - powerConsumption) * 0.6 + throughput * 0.4;
          break;
      }
      
      return score;
    }
  }
  
  Future<ProtocolType> selectOptimalProtocol(MessageContext context) async {
    await _updateMetrics();
    
    var bestScore = 0.0;
    var bestProtocol = ProtocolType.bluetooth;
    
    for (var entry in _metrics.entries) {
      var protocol = entry.key;
      var metrics = entry.value;
      
      if (!await _isProtocolAvailable(protocol)) continue;
      
      var score = metrics.getScore(context);
      
      // Geçmiş performans bonus
      var history = _history[protocol.name];
      if (history != null) {
        score *= history.getSuccessRate();
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestProtocol = protocol;
      }
    }
    
    return bestProtocol;
  }
  
  Future<void> _updateMetrics() async {
    for (var protocol in ProtocolType.values) {
      if (await _isProtocolAvailable(protocol)) {
        _metrics[protocol] = await _measureProtocol(protocol);
      }
    }
  }
  
  Future<ProtocolMetrics> _measureProtocol(ProtocolType protocol) async {
    var startTime = DateTime.now();
    
    // Test mesajı gönder
    var testMessage = _createTestMessage();
    var success = await _sendTestMessage(protocol, testMessage);
    
    var endTime = DateTime.now();
    var latency = endTime.difference(startTime).inMilliseconds / 1000.0;
    
    return ProtocolMetrics(
      throughput: await _measureThroughput(protocol),
      latency: latency,
      reliability: success ? 1.0 : 0.0,
      powerConsumption: await _measurePowerConsumption(protocol),
      signalStrength: await _measureSignalStrength(protocol),
    );
  }
}
```

## 5.6 Test Senaryoları

### 5.6.1 Yönlendirme Testi

```dart
// test/routing/routing_test.dart
void main() {
  group('Mesh Routing Tests', () {
    late HybridMeshRouter router;
    late MockNetworkProtocol mockProtocol;
    
    setUp(() {
      mockProtocol = MockNetworkProtocol();
      router = HybridMeshRouter();
      router.addProtocol(ProtocolType.bluetooth, mockProtocol);
    });
    
    test('should select emergency protocol for high priority messages', () async {
      var message = MessagePacket(
        id: 'test-emergency',
        priority: MessagePriority.emergency,
        content: 'Emergency message',
        sender: 'node1',
        destination: 'node2',
      );
      
      var protocol = await router.selectBestProtocol(
        message.destination,
        message.priority,
        message.content.length,
      );
      
      expect(protocol, equals(ProtocolType.bluetooth)); // Mevcut tek protokol
    });
    
    test('should create multiple routes for redundancy', () async {
      // Çoklu rota testi
      router.addRoute('node2', 'node1', ProtocolType.bluetooth, 1, 0.9);
      router.addRoute('node2', 'node3', ProtocolType.wifiDirect, 2, 0.8);
      
      var routes = router.getRoutesTo('node2');
      expect(routes.length, greaterThan(1));
    });
    
    test('should handle route failures gracefully', () async {
      // Rota hatası simülasyonu
      mockProtocol.setFailureRate(1.0); // %100 hata oranı
      
      var message = MessagePacket(
        id: 'test-failure',
        priority: MessagePriority.normal,
        content: 'Test message',
        sender: 'node1',
        destination: 'node2',
      );
      
      var success = await router.sendMessage('node2', message);
      expect(success, isFalse);
      
      // Alternatif rota arayışı başlatılmalı
      verify(mockProtocol.broadcast(any)).called(1);
    });
  });
}
```

## 5.7 Monitoring ve Debugging

### 5.7.1 Rota Monitörü

```dart
// lib/core/monitoring/route_monitor.dart
class RouteMonitor {
  final Map<String, RouteStatistics> _routeStats = {};
  final StreamController<RouteEvent> _eventController = StreamController.broadcast();
  
  Stream<RouteEvent> get events => _eventController.stream;
  
  class RouteStatistics {
    int messagesSent;
    int messagesDelivered;
    int messagesFailed;
    double averageLatency;
    double averageThroughput;
    
    RouteStatistics({
      required this.messagesSent,
      required this.messagesDelivered,
      required this.messagesFailed,
      required this.averageLatency,
      required this.averageThroughput,
    });
    
    double getDeliveryRate() {
      if (messagesSent == 0) return 0.0;
      return messagesDelivered / messagesSent;
    }
  }
  
  void recordMessageSent(String routeId) {
    var stats = _routeStats[routeId] ??= RouteStatistics(
      messagesSent: 0,
      messagesDelivered: 0,
      messagesFailed: 0,
      averageLatency: 0.0,
      averageThroughput: 0.0,
    );
    
    stats.messagesSent++;
    _eventController.add(RouteEvent.messageSent(routeId));
  }
  
  void recordMessageDelivered(String routeId, Duration latency) {
    var stats = _routeStats[routeId];
    if (stats == null) return;
    
    stats.messagesDelivered++;
    stats.averageLatency = (stats.averageLatency + latency.inMilliseconds) / 2;
    
    _eventController.add(RouteEvent.messageDelivered(routeId, latency));
  }
  
  void recordMessageFailed(String routeId, String error) {
    var stats = _routeStats[routeId];
    if (stats == null) return;
    
    stats.messagesFailed++;
    _eventController.add(RouteEvent.messageFailed(routeId, error));
  }
  
  Map<String, RouteStatistics> getStatistics() {
    return Map.from(_routeStats);
  }
}
```

Bu dosya, mesh network'te mesaj yönlendirme, protokol seçimi, hata toleransı ve performans optimizasyonu konularını kapsamlı bir şekilde ele almaktadır. BitChat'in temel yönlendirme mantığı üzerine kurulmuş, multi-protocol ortam için genişletilmiş ve acil durum senaryoları için optimize edilmiştir.

## Sonraki Adımlar

1. **7-HAM-RADIO-PROTOKOLLERI.md** - HAM radio protokollerinin implementasyonu
2. **8-ACIL-DURUM-OZELLIKLERI.md** - Acil durum özelliklerinin detaylı implementasyonu
3. **9-KULLANICI-ARAYUZU.md** - Kullanıcı arayüzü tasarımı ve implementasyonu
4. **10-TEST-SIMULASYON.md** - Test stratejileri ve simülasyon ortamı
5. **11-DERLEME-DEPLOY.md** - Derleme ve deployment süreçleri
6. **12-DOKUMANTASYON.md** - Son kullanıcı ve geliştirici dokümantasyonu
