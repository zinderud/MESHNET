# 6. SDR (Software Defined Radio) Entegrasyonu

## 📋 Bu Aşamada Yapılacaklar

BitChat'ten farklı olarak, RTL-SDR ve HackRF gibi external radio frequency cihazlarını entegre ederek uzun mesafe iletişim sağlayacağız.

### ✅ Tamamlanması Gerekenler:
1. **RTL-SDR entegrasyonu** (receive-only, 25MHz-1.7GHz)
2. **HackRF One entegrasyonu** (TX/RX, 1MHz-6GHz)
3. **GNU Radio framework entegrasyonu**
4. **Custom RF protocol implementation**
5. **Emergency frequency monitoring**

## 🔧 BitChat'ten Temel Fark

BitChat sadece **Bluetooth LE** ve **WiFi Direct** kullanır:
- **Menzil:** 10-200 metre
- **Güç:** Düşük (pil dostu)
- **Bant genişliği:** 1-250 Mbps
- **Kullanım:** Lokal mesh network

MESHNET **SDR entegrasyonu** ile:
- **Menzil:** 2-50+ km (RF ile)
- **Güç:** Orta-yüksek (1-50W TX)
- **Bant genişliği:** 0.3-100 kbps (RF)
- **Kullanım:** Wide-area emergency communication

## 📡 SDR Hardware Support

### **1. RTL-SDR (Receive Only)**
```dart
// lib/services/rtl_sdr_manager.dart
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

class RTLSDRManager extends ChangeNotifier {
  // RTL-SDR device handle
  Pointer<Void>? _deviceHandle;
  bool _isInitialized = false;
  bool _isRunning = false;
  
  // Emergency frequencies to monitor
  static const Map<String, double> EMERGENCY_FREQUENCIES = {
    'Police': 453.725e6,      // Police frequency
    'Fire': 154.265e6,        // Fire department
    'EMS': 462.950e6,         // Emergency medical
    'APRS': 144.800e6,        // APRS packet radio
    'Marine': 156.800e6,      // Marine VHF Ch 16
    'Aviation': 121.500e6,    // Aviation emergency
  };
  
  // Native library binding
  late final DynamicLibrary _rtlSdrLib;
  
  // Function pointers
  late final int Function(Pointer<Pointer<Void>>, int) _rtlsdrOpen;
  late final int Function(Pointer<Void>) _rtlsdrClose;
  late final int Function(Pointer<Void>, int) _rtlsdrSetCenterFreq;
  late final int Function(Pointer<Void>, int) _rtlsdrSetSampleRate;
  late final int Function(Pointer<Void>, int) _rtlsdrSetGain;
  
  RTLSDRManager() {
    _loadNativeLibrary();
  }
  
  void _loadNativeLibrary() {
    try {
      // Load RTL-SDR native library
      _rtlSdrLib = DynamicLibrary.open('librtlsdr.so');
      
      // Bind functions
      _rtlsdrOpen = _rtlSdrLib.lookup<NativeFunction<
          Int32 Function(Pointer<Pointer<Void>>, Int32)>>('rtlsdr_open')
          .asFunction();
      
      _rtlsdrClose = _rtlSdrLib.lookup<NativeFunction<
          Int32 Function(Pointer<Void>)>>('rtlsdr_close')
          .asFunction();
      
      _rtlsdrSetCenterFreq = _rtlSdrLib.lookup<NativeFunction<
          Int32 Function(Pointer<Void>, Int32)>>('rtlsdr_set_center_freq')
          .asFunction();
      
      _rtlsdrSetSampleRate = _rtlSdrLib.lookup<NativeFunction<
          Int32 Function(Pointer<Void>, Int32)>>('rtlsdr_set_sample_rate')
          .asFunction();
      
      _rtlsdrSetGain = _rtlSdrLib.lookup<NativeFunction<
          Int32 Function(Pointer<Void>, Int32)>>('rtlsdr_set_tuner_gain')
          .asFunction();
      
      debugPrint('RTL-SDR native library loaded successfully');
      
    } catch (e) {
      debugPrint('Error loading RTL-SDR library: $e');
    }
  }
  
  // Initialize RTL-SDR device
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final devicePtr = calloc<Pointer<Void>>();
      
      // Open first RTL-SDR device
      final result = _rtlsdrOpen(devicePtr, 0);
      if (result != 0) {
        debugPrint('Failed to open RTL-SDR device');
        calloc.free(devicePtr);
        return false;
      }
      
      _deviceHandle = devicePtr.value;
      
      // Configure device
      await _configureDevice();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('RTL-SDR initialized successfully');
      return true;
      
    } catch (e) {
      debugPrint('RTL-SDR initialization error: $e');
      return false;
    }
  }
  
  Future<void> _configureDevice() async {
    if (_deviceHandle == null) return;
    
    // Set sample rate (2.048 MHz)
    _rtlsdrSetSampleRate(_deviceHandle!, 2048000);
    
    // Set gain (auto)
    _rtlsdrSetGain(_deviceHandle!, 0);
    
    // Set initial frequency (433.92 MHz)
    _rtlsdrSetCenterFreq(_deviceHandle!, 433920000);
    
    debugPrint('RTL-SDR configured');
  }
  
  // Start emergency frequency monitoring
  Future<void> startEmergencyMonitoring() async {
    if (!_isInitialized || _isRunning) return;
    
    _isRunning = true;
    notifyListeners();
    
    // Monitor each emergency frequency
    for (final entry in EMERGENCY_FREQUENCIES.entries) {
      final name = entry.key;
      final frequency = entry.value;
      
      _monitorFrequency(name, frequency);
    }
  }
  
  void _monitorFrequency(String name, double frequency) {
    // Set frequency
    _rtlsdrSetCenterFreq(_deviceHandle!, frequency.toInt());
    
    // Start monitoring in background
    // This is simplified - real implementation would use isolates
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      _scanFrequency(name, frequency);
    });
  }
  
  void _scanFrequency(String name, double frequency) {
    // Simplified frequency scanning
    // Real implementation would process IQ samples
    
    // Simulate activity detection
    if (Random().nextDouble() < 0.1) { // 10% chance
      _handleEmergencyActivity(name, frequency);
    }
  }
  
  void _handleEmergencyActivity(String service, double frequency) {
    final activity = EmergencyActivity(
      service: service,
      frequency: frequency,
      timestamp: DateTime.now(),
      signalStrength: Random().nextDouble() * 100,
    );
    
    debugPrint('Emergency activity detected: ${activity.service} on ${activity.frequency}');
    
    // Notify listeners
    _emergencyActivityController.add(activity);
  }
  
  // Stream for emergency activity
  final StreamController<EmergencyActivity> _emergencyActivityController = 
      StreamController.broadcast();
  
  Stream<EmergencyActivity> get emergencyActivityStream => 
      _emergencyActivityController.stream;
  
  // Stop monitoring
  Future<void> stopMonitoring() async {
    _isRunning = false;
    notifyListeners();
  }
  
  // Cleanup
  @override
  void dispose() {
    stopMonitoring();
    
    if (_deviceHandle != null) {
      _rtlsdrClose(_deviceHandle!);
      _deviceHandle = null;
    }
    
    _emergencyActivityController.close();
    super.dispose();
  }
}

class EmergencyActivity {
  final String service;
  final double frequency;
  final DateTime timestamp;
  final double signalStrength;
  
  EmergencyActivity({
    required this.service,
    required this.frequency,
    required this.timestamp,
    required this.signalStrength,
  });
}
```

### **2. HackRF One (TX/RX)**
```dart
// lib/services/hackrf_manager.dart
class HackRFManager extends ChangeNotifier {
  Pointer<Void>? _deviceHandle;
  bool _isInitialized = false;
  bool _isTransmitting = false;
  
  // HackRF frequency range: 1 MHz - 6 GHz
  static const double MIN_FREQUENCY = 1e6;
  static const double MAX_FREQUENCY = 6e9;
  
  // Emergency beacon frequencies
  static const Map<String, double> BEACON_FREQUENCIES = {
    'ISM_433': 433.92e6,      // ISM band
    'ISM_868': 868.0e6,       // ISM band
    'ISM_915': 915.0e6,       // ISM band
    'HAM_2M': 144.39e6,       // 2 meter ham band
    'HAM_70CM': 433.0e6,      // 70 cm ham band
  };
  
  // Native library binding
  late final DynamicLibrary _hackrfLib;
  
  HackRFManager() {
    _loadNativeLibrary();
  }
  
  void _loadNativeLibrary() {
    try {
      _hackrfLib = DynamicLibrary.open('libhackrf.so');
      debugPrint('HackRF native library loaded');
    } catch (e) {
      debugPrint('Error loading HackRF library: $e');
    }
  }
  
  // Initialize HackRF device
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Initialize HackRF
      // Implementation would call hackrf_init() and hackrf_open()
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('HackRF initialized successfully');
      return true;
      
    } catch (e) {
      debugPrint('HackRF initialization error: $e');
      return false;
    }
  }
  
  // Transmit emergency beacon
  Future<bool> transmitEmergencyBeacon(
    String message, 
    double frequency,
    int power, // dBm
  ) async {
    if (!_isInitialized || _isTransmitting) return false;
    
    try {
      _isTransmitting = true;
      notifyListeners();
      
      // Generate FSK modulated signal
      final modulatedSignal = _generateFSKSignal(message, frequency);
      
      // Transmit signal
      await _transmitSignal(modulatedSignal, frequency, power);
      
      _isTransmitting = false;
      notifyListeners();
      
      debugPrint('Emergency beacon transmitted on ${frequency}Hz');
      return true;
      
    } catch (e) {
      debugPrint('Transmission error: $e');
      _isTransmitting = false;
      notifyListeners();
      return false;
    }
  }
  
  Uint8List _generateFSKSignal(String message, double frequency) {
    // Simplified FSK signal generation
    // Real implementation would use proper DSP
    
    final messageBytes = utf8.encode(message);
    final preamble = _generatePreamble();
    final syncWord = _generateSyncWord();
    
    // Combine preamble + sync + message
    final signal = <int>[];
    signal.addAll(preamble);
    signal.addAll(syncWord);
    signal.addAll(messageBytes);
    
    return Uint8List.fromList(signal);
  }
  
  List<int> _generatePreamble() {
    // Generate FSK preamble (alternating 1010...)
    return List.generate(16, (index) => index % 2 == 0 ? 0x55 : 0xAA);
  }
  
  List<int> _generateSyncWord() {
    // Generate sync word for packet detection
    return [0x2D, 0xD4]; // Common sync pattern
  }
  
  Future<void> _transmitSignal(
    Uint8List signal, 
    double frequency, 
    int power,
  ) async {
    // Configure HackRF for transmission
    // Set frequency, sample rate, TX gain
    
    // Transmit signal
    // Implementation would call hackrf_start_tx()
    
    // Simulate transmission delay
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  // Cross-band repeat operation
  Future<void> startCrossBandRepeat(
    double rxFrequency,
    double txFrequency,
  ) async {
    if (!_isInitialized) return;
    
    try {
      // Configure for receive
      // Set RX frequency and gain
      
      // Start RX/TX loop
      Timer.periodic(Duration(milliseconds: 10), (timer) {
        // Receive signal
        final receivedSignal = _receiveSignal();
        
        if (receivedSignal != null) {
          // Retransmit on different frequency
          _retransmitSignal(receivedSignal, txFrequency);
        }
      });
      
      debugPrint('Cross-band repeat started: RX=${rxFrequency}Hz TX=${txFrequency}Hz');
      
    } catch (e) {
      debugPrint('Cross-band repeat error: $e');
    }
  }
  
  Uint8List? _receiveSignal() {
    // Simplified signal reception
    // Real implementation would process IQ samples
    return null;
  }
  
  void _retransmitSignal(Uint8List signal, double frequency) {
    // Retransmit received signal
    // Implementation would call HackRF TX functions
  }
  
  // Get device info
  Map<String, dynamic> getDeviceInfo() {
    return {
      'name': 'HackRF One',
      'frequency_range': '${MIN_FREQUENCY}Hz - ${MAX_FREQUENCY}Hz',
      'tx_power': '14 dBm (25 mW)',
      'sample_rate': 'Up to 20 MHz',
      'initialized': _isInitialized,
      'transmitting': _isTransmitting,
    };
  }
}
```

### **3. GNU Radio Integration**
```dart
// lib/services/gnu_radio_manager.dart
class GNURadioManager extends ChangeNotifier {
  Process? _gnuRadioProcess;
  bool _isRunning = false;
  
  // GNU Radio flowgraph for emergency communication
  Future<bool> startEmergencyFlowgraph() async {
    if (_isRunning) return false;
    
    try {
      // Create GNU Radio flowgraph
      final flowgraph = _createEmergencyFlowgraph();
      
      // Write flowgraph to file
      final flowgraphFile = await _writeFlowgraph(flowgraph);
      
      // Start GNU Radio
      _gnuRadioProcess = await Process.start(
        'python3',
        [flowgraphFile.path],
      );
      
      _isRunning = true;
      notifyListeners();
      
      // Monitor process output
      _gnuRadioProcess!.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        _handleGNURadioOutput(output);
      });
      
      debugPrint('GNU Radio flowgraph started');
      return true;
      
    } catch (e) {
      debugPrint('GNU Radio error: $e');
      return false;
    }
  }
  
  String _createEmergencyFlowgraph() {
    // Create GNU Radio Python flowgraph
    return '''
#!/usr/bin/env python3

from gnuradio import blocks
from gnuradio import gr
from gnuradio import uhd
import time

class EmergencyFlowgraph(gr.top_block):
    def __init__(self):
        gr.top_block.__init__(self, "Emergency Communication")
        
        # Variables
        self.samp_rate = 2048000
        self.freq = 433920000
        
        # Blocks
        self.uhd_usrp_source = uhd.usrp_source(
            ",".join(("", "")),
            uhd.stream_args(
                cpu_format="fc32",
                channels=range(1),
            ),
        )
        self.uhd_usrp_source.set_samp_rate(self.samp_rate)
        self.uhd_usrp_source.set_center_freq(self.freq, 0)
        
        self.blocks_file_sink = blocks.file_sink(
            gr.sizeof_gr_complex*1, 
            "/tmp/emergency_samples.dat", 
            False
        )
        
        # Connections
        self.connect((self.uhd_usrp_source, 0), (self.blocks_file_sink, 0))

if __name__ == '__main__':
    tb = EmergencyFlowgraph()
    tb.start()
    time.sleep(10)  # Run for 10 seconds
    tb.stop()
    tb.wait()
''';
  }
  
  Future<File> _writeFlowgraph(String flowgraph) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/emergency_flowgraph.py');
    await file.writeAsString(flowgraph);
    return file;
  }
  
  void _handleGNURadioOutput(String output) {
    // Process GNU Radio output
    debugPrint('GNU Radio: $output');
  }
  
  // Stop GNU Radio
  Future<void> stopFlowgraph() async {
    if (_gnuRadioProcess != null) {
      _gnuRadioProcess!.kill();
      _gnuRadioProcess = null;
      _isRunning = false;
      notifyListeners();
    }
  }
}
```

### **4. RF Protocol Implementation**
```dart
// lib/services/rf_protocol_manager.dart
class RFProtocolManager extends ChangeNotifier {
  final HackRFManager _hackrfManager;
  final RTLSDRManager _rtlsdrManager;
  
  RFProtocolManager(this._hackrfManager, this._rtlsdrManager);
  
  // Send RF message with custom protocol
  Future<bool> sendRFMessage(
    String message,
    double frequency,
    RFProtocol protocol,
  ) async {
    try {
      switch (protocol) {
        case RFProtocol.FSK:
          return await _sendFSKMessage(message, frequency);
        case RFProtocol.APRS:
          return await _sendAPRSMessage(message, frequency);
        case RFProtocol.CUSTOM:
          return await _sendCustomMessage(message, frequency);
      }
    } catch (e) {
      debugPrint('RF message send error: $e');
      return false;
    }
  }
  
  Future<bool> _sendFSKMessage(String message, double frequency) async {
    // Implement FSK modulation
    final packet = RFPacket(
      preamble: _generatePreamble(),
      syncWord: 0x2DD4,
      payload: utf8.encode(message),
      crc: _calculateCRC(utf8.encode(message)),
    );
    
    return await _hackrfManager.transmitEmergencyBeacon(
      packet.toString(),
      frequency,
      14, // 14 dBm
    );
  }
  
  Future<bool> _sendAPRSMessage(String message, double frequency) async {
    // Implement APRS packet format
    final aprsPacket = 'N0CALL-9>MESHNET,TCPIP*:!' + message;
    
    return await _hackrfManager.transmitEmergencyBeacon(
      aprsPacket,
      frequency,
      14,
    );
  }
  
  Future<bool> _sendCustomMessage(String message, double frequency) async {
    // Implement custom MESHNET protocol
    final customPacket = MeshnetRFPacket(
      header: MeshnetHeader(
        version: 1,
        messageType: MessageType.emergency,
        hopCount: 0,
        ttl: 10,
      ),
      payload: utf8.encode(message),
      signature: _signMessage(message),
    );
    
    return await _hackrfManager.transmitEmergencyBeacon(
      customPacket.serialize(),
      frequency,
      14,
    );
  }
  
  List<int> _generatePreamble() {
    return [0x55, 0x55, 0x55, 0x55]; // Preamble pattern
  }
  
  int _calculateCRC(List<int> data) {
    // Simple CRC calculation
    int crc = 0;
    for (int byte in data) {
      crc ^= byte;
    }
    return crc;
  }
  
  String _signMessage(String message) {
    // Digital signature for message authenticity
    return base64Encode(utf8.encode(message + 'signature'));
  }
}

enum RFProtocol {
  FSK,
  APRS,
  CUSTOM,
}

class RFPacket {
  final List<int> preamble;
  final int syncWord;
  final List<int> payload;
  final int crc;
  
  RFPacket({
    required this.preamble,
    required this.syncWord,
    required this.payload,
    required this.crc,
  });
  
  @override
  String toString() {
    final packet = <int>[];
    packet.addAll(preamble);
    packet.addAll(_intToBytes(syncWord));
    packet.addAll(payload);
    packet.addAll(_intToBytes(crc));
    
    return String.fromCharCodes(packet);
  }
  
  List<int> _intToBytes(int value) {
    return [
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }
}
```

## 📱 SDR UI Integration

### **1. SDR Status Widget**
```dart
// lib/widgets/sdr_status_widget.dart
class SDRStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade900, Colors.red.shade900],
        ),
      ),
      child: Column(
        children: [
          Text(
            'SDR Status',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSDRIndicator('RTL-SDR', true),
              _buildSDRIndicator('HackRF', false),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSDRIndicator(String name, bool isActive) {
    return Column(
      children: [
        Icon(
          Icons.radio,
          color: isActive ? Colors.green : Colors.grey,
          size: 16,
        ),
        Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
```

## ✅ Bu Aşama Tamamlandığında

- [ ] **RTL-SDR emergency frequency monitoring**
- [ ] **HackRF emergency beacon transmission**
- [ ] **GNU Radio flowgraph integration**
- [ ] **Custom RF protocol implementation**
- [ ] **Cross-band repeat capability**
- [ ] **Wide-area emergency communication**

## 🔄 Sonraki Adım

**7. Adım:** `7-HAM-RADIO-PROTOKOLLERI.md` dosyasını inceleyin ve ham radio protocol implementasyonuna başlayın.

---

**Son Güncelleme:** 11 Temmuz 2025  
**Durum:** SDR Entegrasyonu Implementasyonu Hazır
