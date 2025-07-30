// lib/screens/sdr_screen.dart - Software Defined Radio Interface
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sdr_manager.dart';

class SDRScreen extends StatefulWidget {
  @override
  _SDRScreenState createState() => _SDRScreenState();
}

class _SDRScreenState extends State<SDRScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize frequency controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sdrManager = Provider.of<SDRManager>(context, listen: false);
      _frequencyController.text = sdrManager.currentFrequency;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _frequencyController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📡 SDR Interface'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(icon: Icon(Icons.radio), text: 'Cihazlar'),
            Tab(icon: Icon(Icons.graphic_eq), text: 'Spektrum'),
            Tab(icon: Icon(Icons.message), text: 'Mesajlar'),
            Tab(icon: Icon(Icons.emergency), text: 'Acil Durum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDevicesTab(),
          _buildSpectrumTab(),
          _buildMessagesTab(),
          _buildEmergencyTab(),
        ],
      ),
    );
  }
  
  /// Devices tab - SDR device management
  Widget _buildDevicesTab() {
    return Consumer<SDRManager>(
      builder: (context, sdrManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Card(
                color: sdrManager.isConnected ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        sdrManager.isConnected ? Icons.radio : Icons.radio_button_off,
                        color: sdrManager.isConnected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sdrManager.isConnected ? 'SDR Bağlı' : 'SDR Bağlı Değil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sdrManager.isConnected ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                            if (sdrManager.isConnected)
                              Text(
                                'Frekans: ${sdrManager.currentFrequency} MHz',
                                style: TextStyle(color: Colors.green[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Frequency control
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎛️ Frekans Kontrolü',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _frequencyController,
                              decoration: InputDecoration(
                                labelText: 'Frekans (MHz)',
                                border: OutlineInputBorder(),
                                suffixText: 'MHz',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              final freq = double.tryParse(_frequencyController.text);
                              if (freq != null) {
                                sdrManager.setFrequency(freq);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Ayarla'),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Quick frequency buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFrequencyChip('433.92', 'ISM'),
                          _buildFrequencyChip('446.00', 'PMR446'),
                          _buildFrequencyChip('145.50', '2m Emergency'),
                          _buildFrequencyChip('146.52', '2m Calling'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Connected devices list
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📻 SDR Cihazları',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      if (sdrManager.connectedDevices.isEmpty)
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Henüz SDR cihazı bulunamadı. Demo modunda çalışıyor.',
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...sdrManager.connectedDevices.map((device) => _buildDeviceCard(device, sdrManager)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Scanning controls
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Frekans Tarama',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: sdrManager.isScanning ? null : () {
                                sdrManager.startFrequencyScanning(430.0, 450.0, 0.025);
                              },
                              icon: Icon(Icons.search),
                              label: Text('Taramayı Başlat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !sdrManager.isScanning ? null : () {
                                sdrManager.stopFrequencyScanning();
                              },
                              icon: Icon(Icons.stop),
                              label: Text('Taramayı Durdur'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sdrManager.isScanning)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Frekans taraması devam ediyor...'),
                            ],
                          ),
                        ),
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
  
  /// Spectrum tab - Frequency spectrum display
  Widget _buildSpectrumTab() {
    return Consumer<SDRManager>(
      builder: (context, sdrManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Frekans Spektrumu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 300,
                        child: _buildSpectrumChart(sdrManager.spectrumData),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Spectrum info
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📈 Spektrum Bilgileri',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      if (sdrManager.spectrumData.isNotEmpty) ...[
                        _buildSpectrumInfo('Merkez Frekans', '${sdrManager.currentFrequency} MHz'),
                        _buildSpectrumInfo('Örnekleme Hızı', '${(sdrManager.currentSampleRate / 1000000).toStringAsFixed(1)} MHz'),
                        _buildSpectrumInfo('Spektrum Noktaları', '${sdrManager.spectrumData.length}'),
                        _buildSpectrumInfo('Son Güncelleme', DateTime.now().toString().substring(11, 19)),
                      ] else
                        Text('Spektrum verisi bekleniyor...'),
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
  
  /// Messages tab - SDR communications
  Widget _buildMessagesTab() {
    return Consumer<SDRManager>(
      builder: (context, sdrManager, child) {
        return Column(
          children: [
            // Message input
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📤 Mesaj Gönder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'SDR mesajı yazın...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: sdrManager.isConnected && !sdrManager.isTransmitting ? () {
                                if (_messageController.text.isNotEmpty) {
                                  sdrManager.transmitMessage(_messageController.text);
                                  _messageController.clear();
                                }
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: sdrManager.isTransmitting 
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Gönder'),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${sdrManager.currentFrequency} MHz',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Messages list
            Expanded(
              child: sdrManager.receivedMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radio, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz SDR mesajı yok',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Frekans tarama başlatın veya bir mesaj gönderin',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sdrManager.receivedMessages.length,
                    itemBuilder: (context, index) {
                      final message = sdrManager.receivedMessages[index];
                      return _buildMessageCard(message);
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
  
  /// Emergency tab - Emergency frequency monitoring
  Widget _buildEmergencyTab() {
    return Consumer<SDRManager>(
      builder: (context, sdrManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency monitoring status
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 Acil Durum Takibi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                Text(
                                  'Acil durum frekansları sürekli izleniyor',
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          sdrManager.startEmergencyMonitoring();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🚨 Acil durum frekans takibi başlatıldı'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        icon: Icon(Icons.monitor_heart),
                        label: Text('Acil Durum Takibini Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Emergency frequencies
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📻 Acil Durum Frekansları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...sdrManager.emergencyFrequencies.map((freq) => _buildEmergencyFrequencyCard(freq, sdrManager)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Emergency messages
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 Acil Durum Mesajları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      ...sdrManager.receivedMessages
                          .where((msg) => msg.isEmergency)
                          .take(5)
                          .map((msg) => _buildEmergencyMessageCard(msg)),
                      if (sdrManager.receivedMessages.where((msg) => msg.isEmergency).isEmpty)
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Text(
                                'Acil durum mesajı yok',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ],
                          ),
                        ),
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
  
  /// Build frequency quick-select chip
  Widget _buildFrequencyChip(String frequency, String label) {
    return Consumer<SDRManager>(
      builder: (context, sdrManager, child) {
        final isSelected = sdrManager.currentFrequency == frequency;
        return FilterChip(
          label: Text('$label\n$frequency MHz'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              final freq = double.parse(frequency);
              sdrManager.setFrequency(freq);
              _frequencyController.text = frequency;
            }
          },
          selectedColor: Colors.deepPurple[100],
          checkmarkColor: Colors.deepPurple,
        );
      },
    );
  }
  
  /// Build device card
  Widget _buildDeviceCard(SDRDevice device, SDRManager sdrManager) {
    final deviceInfo = device.deviceInfo;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          deviceInfo?.icon ?? '📻',
          style: TextStyle(fontSize: 24),
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${deviceInfo?.description ?? device.type}'),
            Text('${device.frequency.toStringAsFixed(3)} MHz • ${device.signalQuality}'),
          ],
        ),
        trailing: Switch(
          value: device.isConnected,
          onChanged: (connected) {
            if (connected) {
              sdrManager.connectToDevice(device.id);
            } else {
              sdrManager.disconnectFromDevice(device.id);
            }
          },
          activeColor: Colors.green,
        ),
      ),
    );
  }
  
  /// Build spectrum chart (simplified)
  Widget _buildSpectrumChart(List<FrequencySpectrum> spectrumData) {
    if (spectrumData.isEmpty) {
      return Center(
        child: Text(
          'Spektrum verisi bekleniyor...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return CustomPaint(
      size: Size.infinite,
      painter: SpectrumPainter(spectrumData),
    );
  }
  
  /// Build spectrum info row
  Widget _buildSpectrumInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  /// Build message card
  Widget _buildMessageCard(SDRMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: message.isEmergency ? Colors.red[50] : null,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  message.directionIcon,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Text(
                  message.timeString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isEmergency ? Colors.red[700] : null,
                  ),
                ),
                Spacer(),
                Text(
                  '${message.frequency.toStringAsFixed(3)} MHz',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                fontWeight: message.isEmergency ? FontWeight.bold : null,
                color: message.isEmergency ? Colors.red[800] : null,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 16,
                  color: message.signalStrength > -50 ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  '${message.signalStrength.toStringAsFixed(1)} dBm',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 12),
                Text(
                  message.modulation,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build emergency frequency card
  Widget _buildEmergencyFrequencyCard(String frequency, SDRManager sdrManager) {
    final isActive = sdrManager.currentFrequency == frequency;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isActive ? Colors.red[100] : null,
      child: ListTile(
        leading: Icon(
          Icons.emergency,
          color: isActive ? Colors.red : Colors.grey,
        ),
        title: Text('$frequency MHz'),
        subtitle: Text(_getFrequencyDescription(frequency)),
        trailing: isActive 
          ? Icon(Icons.radio_button_checked, color: Colors.red)
          : IconButton(
              icon: Icon(Icons.radio_button_unchecked),
              onPressed: () {
                final freq = double.parse(frequency);
                sdrManager.setFrequency(freq);
                _frequencyController.text = frequency;
              },
            ),
      ),
    );
  }
  
  /// Build emergency message card
  Widget _buildEmergencyMessageCard(SDRMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.red[100],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  '${message.timeString} • ${message.frequency.toStringAsFixed(3)} MHz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get frequency description
  String _getFrequencyDescription(String frequency) {
    switch (frequency) {
      case '446.00625':
        return 'PMR446 Channel 1';
      case '446.01875':
        return 'PMR446 Channel 2';
      case '146.520':
        return '2m Amateur Calling Frequency';
      case '145.500':
        return '2m Emergency Frequency';
      case '433.500':
        return '70cm Emergency Frequency';
      default:
        return 'Emergency Frequency';
    }
  }
}

/// Custom painter for spectrum display
class SpectrumPainter extends CustomPainter {
  final List<FrequencySpectrum> spectrumData;
  
  SpectrumPainter(this.spectrumData);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (spectrumData.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Find min/max values for scaling
    final minPower = spectrumData.map((s) => s.power).reduce((a, b) => a < b ? a : b);
    final maxPower = spectrumData.map((s) => s.power).reduce((a, b) => a > b ? a : b);
    
    // Draw spectrum line
    for (int i = 0; i < spectrumData.length; i++) {
      final x = (i / (spectrumData.length - 1)) * size.width;
      final y = size.height - ((spectrumData[i].power - minPower) / (maxPower - minPower)) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Vertical grid lines
    for (int i = 0; i <= 8; i++) {
      final x = (i / 8) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
