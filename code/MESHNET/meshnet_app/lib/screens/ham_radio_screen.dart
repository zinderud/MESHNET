// lib/screens/ham_radio_screen.dart - Ham Radio Protocols Interface
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ham_radio_manager.dart';

class HamRadioScreen extends StatefulWidget {
  @override
  _HamRadioScreenState createState() => _HamRadioScreenState();
}

class _HamRadioScreenState extends State<HamRadioScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _callSignController = TextEditingController();
  final TextEditingController _aprsMessageController = TextEditingController();
  final TextEditingController _winlinkToController = TextEditingController();
  final TextEditingController _winlinkSubjectController = TextEditingController();
  final TextEditingController _winlinkBodyController = TextEditingController();
  
  String _selectedAPRSStation = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hamManager = Provider.of<HamRadioManager>(context, listen: false);
      _callSignController.text = hamManager.callSign;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _callSignController.dispose();
    _aprsMessageController.dispose();
    _winlinkToController.dispose();
    _winlinkSubjectController.dispose();
    _winlinkBodyController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📻 Ham Radio'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(icon: Icon(Icons.location_on), text: 'APRS'),
            Tab(icon: Icon(Icons.email), text: 'Winlink'),
            Tab(icon: Icon(Icons.radio), text: 'Digital'),
            Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAPRSTab(),
          _buildWinlinkTab(),
          _buildDigitalTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }
  
  /// APRS tab - Automatic Packet Reporting System
  Widget _buildAPRSTab() {
    return Consumer<HamRadioManager>(
      builder: (context, hamManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // APRS Status
              Card(
                color: hamManager.isAPRSActive ? Colors.green[50] : Colors.grey[100],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: hamManager.isAPRSActive ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hamManager.isAPRSActive ? 'APRS Beacon Aktif' : 'APRS Beacon Kapalı',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: hamManager.isAPRSActive ? Colors.green[700] : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '144.390 MHz • ${hamManager.callSign}',
                                  style: TextStyle(
                                    color: hamManager.isAPRSActive ? Colors.green[600] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !hamManager.isAPRSActive ? () {
                                // Use demo coordinates
                                hamManager.startAPRSBeacon(
                                  latitude: 41.714775,
                                  longitude: -72.727260,
                                  comment: 'MESHNET Emergency Station',
                                );
                              } : null,
                              icon: Icon(Icons.play_arrow),
                              label: Text('Beacon Başlat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: hamManager.isAPRSActive ? () {
                                hamManager.stopAPRSBeacon();
                              } : null,
                              icon: Icon(Icons.stop),
                              label: Text('Beacon Durdur'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // APRS Message sending
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📤 APRS Mesaj Gönder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedAPRSStation.isEmpty ? null : _selectedAPRSStation,
                        decoration: InputDecoration(
                          labelText: 'Hedef İstasyon',
                          border: OutlineInputBorder(),
                        ),
                        items: hamManager.nearbyStations.map((station) {
                          return DropdownMenuItem(
                            value: station.callSign,
                            child: Text('${station.callSign} (${station.distance.toStringAsFixed(1)} km)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAPRSStation = value ?? '';
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _aprsMessageController,
                        decoration: InputDecoration(
                          labelText: 'Mesaj',
                          border: OutlineInputBorder(),
                          hintText: 'APRS mesajınızı yazın...',
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: hamManager.isConnected && !hamManager.isTransmitting && 
                                 _selectedAPRSStation.isNotEmpty && _aprsMessageController.text.isNotEmpty ? () {
                          hamManager.sendAPRSMessage(_selectedAPRSStation, _aprsMessageController.text);
                          _aprsMessageController.clear();
                        } : null,
                        icon: hamManager.isTransmitting 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send),
                        label: Text('Gönder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Nearby APRS Stations
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Yakındaki İstasyonlar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...hamManager.nearbyStations.map((station) => _buildAPRSStationCard(station)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // APRS Messages
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬 APRS Mesajları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...hamManager.aprsMessages.take(5).map((message) => _buildAPRSMessageCard(message)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Winlink tab - Emergency email system
  Widget _buildWinlinkTab() {
    return Consumer<HamRadioManager>(
      builder: (context, hamManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Winlink Status
              Card(
                color: hamManager.isWinlinkActive ? Colors.blue[50] : Colors.grey[100],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: hamManager.isWinlinkActive ? Colors.blue : Colors.grey,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Winlink Global Radio Email',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hamManager.isWinlinkActive ? Colors.blue[700] : Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${hamManager.callSign}@winlink.org',
                              style: TextStyle(
                                color: hamManager.isWinlinkActive ? Colors.blue[600] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Send Winlink Email
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📧 Email Gönder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _winlinkToController,
                        decoration: InputDecoration(
                          labelText: 'Alıcı',
                          border: OutlineInputBorder(),
                          hintText: 'email@example.com',
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _winlinkSubjectController,
                        decoration: InputDecoration(
                          labelText: 'Konu',
                          border: OutlineInputBorder(),
                          hintText: 'Email konusu',
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _winlinkBodyController,
                        decoration: InputDecoration(
                          labelText: 'Mesaj',
                          border: OutlineInputBorder(),
                          hintText: 'Email içeriği...',
                        ),
                        maxLines: 5,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: hamManager.isConnected && !hamManager.isTransmitting &&
                                 _winlinkToController.text.isNotEmpty && 
                                 _winlinkSubjectController.text.isNotEmpty ? () {
                          hamManager.sendWinlinkEmail(
                            _winlinkToController.text,
                            _winlinkSubjectController.text,
                            _winlinkBodyController.text,
                          );
                          _winlinkToController.clear();
                          _winlinkSubjectController.clear();
                          _winlinkBodyController.clear();
                        } : null,
                        icon: hamManager.isTransmitting 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send),
                        label: Text('Email Gönder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Available Gateways
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌐 Winlink Gateway\'leri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...hamManager.availableGateways.map((gateway) => _buildWinlinkGatewayCard(gateway)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Winlink Messages
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📧 Email Mesajları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      if (hamManager.winlinkMessages.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Henüz Winlink mesajı yok',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      else
                        ...hamManager.winlinkMessages.take(5).map((message) => _buildWinlinkMessageCard(message)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Digital modes tab - FT8, JS8, PSK31
  Widget _buildDigitalTab() {
    return Consumer<HamRadioManager>(
      builder: (context, hamManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Protocol selection
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📻 Dijital Modlar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: HamRadioManager.SUPPORTED_PROTOCOLS.entries
                            .where((entry) => ['ft8', 'js8', 'psk31'].contains(entry.key))
                            .map((entry) => _buildProtocolChip(entry.key, entry.value, hamManager))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Heard Stations
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📶 Duyulan İstasyonlar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...hamManager.heardStations.map((station) => _buildDigitalStationCard(station)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Digital Messages
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬 Dijital Mesajlar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...hamManager.digitalMessages.take(10).map((message) => _buildDigitalMessageCard(message)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Settings tab - Ham radio configuration
  Widget _buildSettingsTab() {
    return Consumer<HamRadioManager>(
      builder: (context, hamManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station Configuration
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📻 İstasyon Ayarları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _callSignController,
                        decoration: InputDecoration(
                          labelText: 'Çağrı İşareti',
                          border: OutlineInputBorder(),
                          hintText: 'TA1ABC',
                        ),
                        onChanged: (value) {
                          hamManager.setCallSign(value);
                        },
                      ),
                      SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Maidenhead Grid',
                          border: OutlineInputBorder(),
                          hintText: 'JN00AA',
                        ),
                        onChanged: (value) {
                          hamManager.setMaidenheadGrid(value);
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Güç: ${hamManager.transmitPower.toStringAsFixed(1)}W'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Slider(
                              value: hamManager.transmitPower,
                              min: 1.0,
                              max: 100.0,
                              divisions: 99,
                              onChanged: (value) {
                                hamManager.setTransmitPower(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Anten Bilgisi',
                          border: OutlineInputBorder(),
                          hintText: 'Dipole @ 10m',
                        ),
                        onChanged: (value) {
                          // Update antenna info
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Protocol Information
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Protokol Bilgileri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...HamRadioManager.SUPPORTED_PROTOCOLS.entries.map((entry) {
                        final protocol = entry.value;
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Text(protocol.icon, style: TextStyle(fontSize: 24)),
                            title: Text(protocol.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(protocol.description),
                                Text('${protocol.frequency} MHz • ${protocol.mode} • ${protocol.bandwidth} Hz'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.radio),
                              onPressed: () {
                                hamManager.setActiveProtocol(entry.key);
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build APRS station card
  Widget _buildAPRSStationCard(APRSStation station) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text('📍', style: TextStyle(fontSize: 20)),
        title: Text(station.callSign),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.comment),
            Text('${station.distance.toStringAsFixed(1)} km • ${station.bearing}°'),
          ],
        ),
        trailing: Text(
          '${DateTime.now().difference(station.lastHeard).inMinutes}m',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }
  
  /// Build APRS message card
  Widget _buildAPRSMessageCard(APRSMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.timeString,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Text('${message.fromCall} → ${message.toCall}'),
                Spacer(),
                Icon(
                  message.messageType == APRSMessageType.position 
                    ? Icons.location_on 
                    : Icons.message,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(message.message),
          ],
        ),
      ),
    );
  }
  
  /// Build Winlink gateway card
  Widget _buildWinlinkGatewayCard(WinlinkGateway gateway) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.router,
          color: gateway.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(gateway.callSign),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${gateway.frequency} MHz • ${gateway.mode}'),
            Text('${gateway.region} • ${gateway.distance.toStringAsFixed(0)} km'),
          ],
        ),
        trailing: gateway.isActive 
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.offline_bolt, color: Colors.grey),
      ),
    );
  }
  
  /// Build Winlink message card
  Widget _buildWinlinkMessageCard(WinlinkMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.timeString,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(
                  message.direction == MessageDirection.sent 
                    ? Icons.outgoing_mail 
                    : Icons.email,
                  size: 16,
                ),
                Spacer(),
                Text(
                  message.gateway,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'From: ${message.from}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'To: ${message.to}',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              message.subject,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (message.body.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                message.body.length > 100 
                  ? '${message.body.substring(0, 100)}...'
                  : message.body,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build protocol selection chip
  Widget _buildProtocolChip(String protocolKey, HamProtocolInfo protocol, HamRadioManager hamManager) {
    final isSelected = hamManager.activeProtocol == protocolKey;
    return FilterChip(
      label: Text('${protocol.icon} ${protocol.name}'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          hamManager.setActiveProtocol(protocolKey);
        }
      },
      selectedColor: Colors.brown[100],
      checkmarkColor: Colors.brown,
    );
  }
  
  /// Build digital station card
  Widget _buildDigitalStationCard(DigitalStation station) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text('📶', style: TextStyle(fontSize: 20)),
        title: Text(station.callSign),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${station.mode} • ${station.grid}'),
            Text('${station.frequency} MHz • SNR: ${station.snr > 0 ? '+' : ''}${station.snr} dB'),
          ],
        ),
        trailing: Text(
          '${station.distance.toStringAsFixed(0)} km',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }
  
  /// Build digital message card
  Widget _buildDigitalMessageCard(DigitalMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.timeString,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Text(message.fromCall),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.mode,
                    style: TextStyle(fontSize: 10, color: Colors.brown[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(message.content),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${message.frequency} MHz',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 12),
                Text(
                  'SNR: ${message.snr > 0 ? '+' : ''}${message.snr} dB',
                  style: TextStyle(
                    fontSize: 12,
                    color: message.snr > -10 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
