// lib/screens/wifi_direct_screen.dart - WiFi Direct Clustering UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wifi_direct_manager.dart';
import '../services/bluetooth_mesh_manager.dart';

class WiFiDirectScreen extends StatefulWidget {
  @override
  _WiFiDirectScreenState createState() => _WiFiDirectScreenState();
}

class _WiFiDirectScreenState extends State<WiFiDirectScreen> {
  WiFiDirectManager? _wifiManager;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeWiFiDirect();
  }

  void _initializeWiFiDirect() async {
    // Initialization will be handled by Provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📶 WiFi Direct Cluster'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          Consumer<WiFiDirectManager>(
            builder: (context, wifiManager, _) {
              return IconButton(
                icon: Icon(
                  wifiManager.isDiscovering ? Icons.wifi_find : Icons.wifi,
                ),
                onPressed: wifiManager.isDiscovering 
                    ? () => wifiManager.stopDiscovery()
                    : () => wifiManager.startDiscovery(),
                tooltip: wifiManager.isDiscovering ? 'Aramayı durdur' : 'Cihaz ara',
              );
            },
          ),
        ],
      ),
      body: Consumer<WiFiDirectManager>(
        builder: (context, wifiManager, child) {
          _wifiManager = wifiManager;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionStatus(wifiManager),
                SizedBox(height: 20),
                _buildNetworkStats(wifiManager),
                SizedBox(height: 20),
                _buildCurrentGroup(wifiManager),
                SizedBox(height: 20),
                _buildGroupActions(wifiManager),
                SizedBox(height: 20),
                _buildDiscoveredDevices(wifiManager),
                SizedBox(height: 20),
                _buildAvailableGroups(wifiManager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(WiFiDirectManager wifiManager) {
    final isConnected = wifiManager.isConnected;
    final deviceCount = wifiManager.deviceCount;
    
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
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'WiFi Direct Durumu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  'Bağlantı',
                  isConnected ? 'Aktif' : 'Pasif',
                  isConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                _buildStatusChip(
                  'Cihaz',
                  '$deviceCount/8',
                  deviceCount > 0 ? Colors.blue : Colors.grey,
                ),
                SizedBox(width: 8),
                _buildStatusChip(
                  'Rol',
                  wifiManager.isGroupOwner ? 'Lider' : 'Üye',
                  wifiManager.isGroupOwner ? Colors.purple : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Chip(
      label: Text(
        '$label: $value',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildNetworkStats(WiFiDirectManager wifiManager) {
    final stats = wifiManager.getNetworkStats();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ağ İstatistikleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Toplam Veri',
                    '${stats['totalThroughput'] ?? 0} KB',
                    Icons.data_usage,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sinyal Gücü',
                    '${(stats['averageSignalStrength'] ?? 0).toStringAsFixed(1)} dBm',
                    Icons.signal_wifi_4_bar,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGroup(WiFiDirectManager wifiManager) {
    final currentGroup = wifiManager.currentGroup;
    
    if (currentGroup == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Herhangi bir gruba bağlı değilsiniz',
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
            Row(
              children: [
                Icon(Icons.group, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Mevcut Grup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (wifiManager.isGroupOwner)
                  Chip(
                    label: Text('LİDER', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.purple,
                  ),
              ],
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.wifi_tethering, color: Colors.purple),
              title: Text(currentGroup.groupName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ağ: ${currentGroup.networkName}'),
                  Text('${currentGroup.channelInfo} • ${currentGroup.memberCount}/${currentGroup.maxMembers} üye'),
                  if (currentGroup.isPasswordProtected)
                    Text('🔒 Şifreli', style: TextStyle(color: Colors.green)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.exit_to_app, color: Colors.red),
                onPressed: () => _disconnectFromGroup(wifiManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActions(WiFiDirectManager wifiManager) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grup İşlemleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateGroupDialog(wifiManager),
                    icon: Icon(Icons.add_circle),
                    label: Text('Grup Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: wifiManager.isDiscovering 
                        ? null 
                        : () => wifiManager.startDiscovery(),
                    icon: Icon(Icons.search),
                    label: Text('Grup Ara'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDevices(WiFiDirectManager wifiManager) {
    final devices = wifiManager.discoveredDevices;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Bulunan Cihazlar (${devices.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (wifiManager.isDiscovering)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (devices.isEmpty) ...[
              Text(
                wifiManager.isDiscovering 
                    ? 'Cihazlar aranıyor...' 
                    : 'Hiç cihaz bulunamadı',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ] else ...[
              ...devices.take(10).map((device) => ListTile(
                leading: Text(
                  device.deviceIcon,
                  style: TextStyle(fontSize: 24),
                ),
                title: Text(device.deviceName),
                subtitle: Text(
                  '${device.signalQuality} (${device.signalStrength} dBm)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (device.isGroupOwner)
                      Chip(
                        label: Text('GRUP', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange,
                      ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.connect_without_contact, color: Colors.green),
                      onPressed: () => _connectToDevice(wifiManager, device),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableGroups(WiFiDirectManager wifiManager) {
    // Mevcut grupları burada gösterebiliriz
    // Şimdilik basit bir placeholder
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_work, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Mevcut Gruplar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Yakınınızdaki WiFi Direct grupları burada görünecek',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(WiFiDirectManager wifiManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Grup Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Grup Adı',
                hintText: 'MESHNET_Emergency_Alpha',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passphraseController,
              decoration: InputDecoration(
                labelText: 'Şifre (İsteğe Bağlı)',
                hintText: 'Güvenli şifre girin',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _createGroup(wifiManager),
            child: Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _createGroup(WiFiDirectManager wifiManager) async {
    final groupName = _groupNameController.text.trim();
    final passphrase = _passphraseController.text.trim();
    
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grup adı gerekli')),
      );
      return;
    }
    
    Navigator.of(context).pop();
    
    try {
      final success = await wifiManager.createGroup(
        groupName: groupName,
        passphrase: passphrase.isEmpty ? null : passphrase,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📶 WiFi Direct grubu oluşturuldu: $groupName'),
            backgroundColor: Colors.green,
          ),
        );
        _groupNameController.clear();
        _passphraseController.clear();
      } else {
        throw Exception('Grup oluşturulamadı');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _connectToDevice(WiFiDirectManager wifiManager, WiFiDirectDevice device) async {
    try {
      final success = await wifiManager.connectToDevice(device);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${device.deviceName} cihazına bağlandı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Bağlantı kurulamadı');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnectFromGroup(WiFiDirectManager wifiManager) async {
    try {
      await wifiManager.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📶 Gruptan ayrıldınız'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ayrılma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }
}
