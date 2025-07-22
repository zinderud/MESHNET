// lib/screens/emergency_location_screen.dart - Acil Durum GPS Konum Paylaşımı
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/bluetooth_mesh_manager.dart';
import '../services/location_manager.dart';

class EmergencyLocationScreen extends StatefulWidget {
  @override
  _EmergencyLocationScreenState createState() => _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  BluetoothMeshManager? _meshManager;
  LocationManager? _locationManager;
  
  final TextEditingController _messageController = TextEditingController();
  String _selectedEmergencyType = 'general';
  bool _isSharing = false;

  final Map<String, String> _emergencyTypes = {
    'general': '🚨 Genel Acil Durum',
    'medical': '🚑 Tıbbi Acil Durum',
    'fire': '🚒 Yangın',
    'police': '🚓 Güvenlik',
    'natural_disaster': '🌪️ Doğal Afet',
    'accident': '🚗 Kaza',
    'missing_person': '🔍 Kayıp Kişi',
  };

  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }

  void _initializeManagers() {
    // Bu implementasyon Context'e bağlıdır, gerçek uygulamada Provider veya DI kullanılmalı
    // Şimdilik demo amaçlı basit implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🚨 Acil Durum Konum'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Mevcut konumu al',
          ),
        ],
      ),
      body: Consumer2<BluetoothMeshManager, LocationManager>(
        builder: (context, meshManager, locationManager, child) {
          _meshManager = meshManager;
          _locationManager = locationManager;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLocationStatus(),
                SizedBox(height: 20),
                _buildEmergencyTypeSelector(),
                SizedBox(height: 20),
                _buildMessageInput(),
                SizedBox(height: 20),
                _buildShareButton(),
                SizedBox(height: 30),
                _buildEmergencyHistory(),
                SizedBox(height: 20),
                _buildNearbyEmergencies(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationStatus() {
    final locationManager = _locationManager;
    final position = locationManager?.currentPosition;
    final address = locationManager?.currentAddress;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  locationManager?.locationEnabled == true ? Icons.location_on : Icons.location_off,
                  color: locationManager?.locationEnabled == true ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'Konum Durumu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (position != null) ...[
              Text(
                'Enlem: ${position.latitude.toStringAsFixed(6)}',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              Text(
                'Boylam: ${position.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              Text(
                'Doğruluk: ±${position.accuracy.toStringAsFixed(1)}m',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (address != null) ...[
                SizedBox(height: 8),
                Text(
                  'Adres: $address',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ] else ...[
              Text(
                'Konum bilgisi mevcut değil',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.refresh),
                label: Text('Konumu Yenile'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acil Durum Türü',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedEmergencyType,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _emergencyTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEmergencyType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ek Mesaj (İsteğe Bağlı)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Acil durum hakkında ek bilgi ekleyin...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    final isLocationAvailable = _locationManager?.currentPosition != null;
    final isConnected = _meshManager?.connectedDevices.isNotEmpty == true;
    
    return ElevatedButton.icon(
      onPressed: (isLocationAvailable && isConnected && !_isSharing) 
          ? _shareEmergencyLocation 
          : null,
      icon: _isSharing 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.emergency_share),
      label: Text(
        _isSharing 
            ? 'Konum Paylaşılıyor...' 
            : '🚨 ACİL DURUM KONUM PAYLAŞ',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmergencyHistory() {
    final emergencyShares = _locationManager?.emergencyShares ?? {};
    
    if (emergencyShares.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Henüz acil durum konumu paylaşılmamış',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paylaşılan Acil Durum Konumları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...emergencyShares.values.take(5).map((emergency) {
              return ListTile(
                leading: Text(
                  emergency.emergencyIcon,
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(emergency.emergencyType),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emergency.message),
                    Text(
                      emergency.timeAgo,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Icon(Icons.location_on, color: Colors.red),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyEmergencies() {
    final nearbyEmergencies = _locationManager?.getNearbyEmergencies(5000) ?? []; // 5km radius
    
    if (nearbyEmergencies.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Yakınlarda acil durum konumu yok',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yakındaki Acil Durumlar (5km)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...nearbyEmergencies.map((emergency) {
              return ListTile(
                leading: Text(
                  emergency.emergencyIcon,
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(emergency.emergencyType),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emergency.message),
                    Text(
                      emergency.getDistanceText(_locationManager?.currentPosition),
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.directions, color: Colors.blue),
                  onPressed: () => _openDirections(emergency),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    if (_locationManager == null) return;
    
    setState(() {
      // UI refresh için
    });
    
    try {
      // Location manager zaten mevcut konumu almaya çalışacak
      await Future.delayed(Duration(seconds: 1)); // Demo delay
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareEmergencyLocation() async {
    if (_meshManager == null || _isSharing) return;
    
    setState(() {
      _isSharing = true;
    });
    
    try {
      final message = _messageController.text.trim();
      
      await _meshManager!.sendEmergencyLocation(
        emergencyType: _selectedEmergencyType,
        message: message.isEmpty ? null : message,
        additionalData: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'source': 'mobile_app',
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 Acil durum konumu mesh ağa paylaşıldı!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _messageController.clear();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  void _openDirections(EmergencyLocationShare emergency) {
    // Bu metod harita uygulamasını açacak
    // Şimdilik basit bir dialog gösterelim
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${emergency.emergencyIcon} Acil Durum Konumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tür: ${emergency.emergencyType}'),
            Text('Mesaj: ${emergency.message}'),
            SizedBox(height: 8),
            Text('Koordinatlar:'),
            Text(
              '${emergency.position.latitude.toStringAsFixed(6)}, ${emergency.position.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            if (emergency.address != null) ...[
              SizedBox(height: 8),
              Text('Adres:'),
              Text(emergency.address!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
