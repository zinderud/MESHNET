// lib/screens/emergency_screen.dart - Emergency Management Interface
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emergency_manager.dart';

class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🚨 Emergency Control'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(icon: Icon(Icons.emergency), text: 'Kontrol'),
            Tab(icon: Icon(Icons.history), text: 'Olaylar'),
            Tab(icon: Icon(Icons.contacts), text: 'Kişiler'),
            Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildControlTab(),
          _buildEventsTab(),
          _buildContactsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }
  
  /// Control tab - Emergency activation and monitoring
  Widget _buildControlTab() {
    return Consumer<EmergencyManager>(
      builder: (context, emergencyManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency status
              Card(
                color: emergencyManager.isEmergencyMode ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            emergencyManager.isEmergencyMode ? Icons.warning : Icons.check_circle,
                            color: emergencyManager.isEmergencyMode ? Colors.red : Colors.green,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emergencyManager.isEmergencyMode ? '🚨 Acil Durum Aktif' : '✅ Normal Durum',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: emergencyManager.isEmergencyMode ? Colors.red[700] : Colors.green[700],
                                  ),
                                ),
                                if (emergencyManager.isEmergencyMode) ...[
                                  Text(
                                    '${EmergencyManager.EMERGENCY_TYPES[emergencyManager.currentType]?.icon} '
                                    '${EmergencyManager.EMERGENCY_TYPES[emergencyManager.currentType]?.name}',
                                    style: TextStyle(color: Colors.red[600]),
                                  ),
                                  Text(
                                    '${EmergencyManager.EMERGENCY_LEVELS[emergencyManager.currentLevel]?.icon} '
                                    '${EmergencyManager.EMERGENCY_LEVELS[emergencyManager.currentLevel]?.name}',
                                    style: TextStyle(color: Colors.red[600]),
                                  ),
                                ] else
                                  Text(
                                    'Sistem normal çalışıyor',
                                    style: TextStyle(color: Colors.green[600]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (emergencyManager.isEmergencyMode) ...[
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showDeactivateDialog(emergencyManager);
                          },
                          icon: Icon(Icons.stop),
                          label: Text('Acil Durumu Sonlandır'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Emergency activation
              if (!emergencyManager.isEmergencyMode) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 Acil Durum Aktivasyonu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text('Acil Durum Türü:'),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: EmergencyType.values.map((type) {
                            final info = EmergencyManager.EMERGENCY_TYPES[type]!;
                            return ElevatedButton(
                              onPressed: () {
                                _showEmergencyActivationDialog(type, emergencyManager);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                                foregroundColor: Colors.red[800],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(info.icon, style: TextStyle(fontSize: 20)),
                                  Text(info.name, style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
              
              // Active beacons
              if (emergencyManager.activeBeacons.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radio_button_checked, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              '📡 Aktif Beaconlar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${emergencyManager.activeBeacons.length}',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ...emergencyManager.activeBeacons.values.take(3).map((beacon) => _buildBeaconCard(beacon)),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
              
              // Auto mode toggle
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            '🤖 Otomatik Mod',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Switch(
                            value: emergencyManager.isAutoMode,
                            onChanged: (value) {
                              emergencyManager.setAutoMode(value);
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        emergencyManager.isAutoMode 
                          ? 'Sistem otomatik acil durum tespiti yapıyor'
                          : 'Manuel acil durum aktivasyonu',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Quick action buttons
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Hızlı Eylemler',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _testEmergencySystem(emergencyManager);
                              },
                              icon: Icon(Icons.play_arrow),
                              label: Text('Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _sendTestBeacon(emergencyManager);
                              },
                              icon: Icon(Icons.radio),
                              label: Text('Test Beacon'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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
            ],
          ),
        );
      },
    );
  }
  
  /// Events tab - Emergency event history
  Widget _buildEventsTab() {
    return Consumer<EmergencyManager>(
      builder: (context, emergencyManager, child) {
        return Column(
          children: [
            // Stats header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '📊 Toplam Olay',
                      '${emergencyManager.emergencyEvents.length}',
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '🚨 Aktif Acil Durum',
                      emergencyManager.isEmergencyMode ? '1' : '0',
                      Colors.red,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '📡 Aktif Beacon',
                      '${emergencyManager.activeBeacons.length}',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            // Events list
            Expanded(
              child: emergencyManager.emergencyEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz acil durum olayı yok',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: emergencyManager.emergencyEvents.length,
                    itemBuilder: (context, index) {
                      final event = emergencyManager.emergencyEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
  
  /// Contacts tab - Emergency contacts management
  Widget _buildContactsTab() {
    return Consumer<EmergencyManager>(
      builder: (context, emergencyManager, child) {
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: emergencyManager.emergencyContacts.length,
          itemBuilder: (context, index) {
            final contact = emergencyManager.emergencyContacts[index];
            return _buildContactCard(contact);
          },
        );
      },
    );
  }
  
  /// Settings tab - Emergency system configuration
  Widget _buildSettingsTab() {
    return Consumer<EmergencyManager>(
      builder: (context, emergencyManager, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beacon settings
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📡 Beacon Ayarları',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Beacon Aralığı:'),
                          Spacer(),
                          Text('${emergencyManager.beaconInterval.inMinutes} dakika'),
                        ],
                      ),
                      Slider(
                        value: emergencyManager.beaconInterval.inMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        onChanged: (value) {
                          emergencyManager.setBeaconInterval(Duration(minutes: value.round()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Auto escalation settings
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            '📈 Otomatik Yükseltme',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Switch(
                            value: emergencyManager.enableAutoEscalation,
                            onChanged: (value) {
                              emergencyManager.setAutoEscalation(value);
                            },
                            activeColor: Colors.orange,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Acil durum seviyesini otomatik olarak yükseltir',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Multi-protocol settings
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hub, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            '🌐 Çoklu Protokol',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          Switch(
                            value: emergencyManager.enableMultiProtocol,
                            onChanged: (value) {
                              emergencyManager.setMultiProtocol(value);
                            },
                            activeColor: Colors.purple,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tüm protokoller üzerinden eşzamanlı yayın',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Protocol status
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Protokol Durumu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      _buildProtocolStatus('Bluetooth', true, Colors.blue),
                      _buildProtocolStatus('WiFi Direct', true, Colors.green),
                      _buildProtocolStatus('SDR', true, Colors.purple),
                      _buildProtocolStatus('Ham Radio', true, Colors.brown),
                      _buildProtocolStatus('GPS', true, Colors.orange),
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
  
  /// Build beacon card
  Widget _buildBeaconCard(EmergencyBeacon beacon) {
    final typeInfo = EmergencyManager.EMERGENCY_TYPES[beacon.type]!;
    final levelInfo = EmergencyManager.EMERGENCY_LEVELS[beacon.level]!;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(typeInfo.icon, style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${typeInfo.name} - ${levelInfo.name}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${DateTime.now().difference(beacon.timestamp).inMinutes}m ago',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              beacon.message,
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: beacon.protocols.map((protocol) => Chip(
                label: Text(protocol, style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.blue[100],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build event card
  Widget _buildEventCard(EmergencyEvent event) {
    final typeInfo = EmergencyManager.EMERGENCY_TYPES[event.type]!;
    final levelInfo = EmergencyManager.EMERGENCY_LEVELS[event.level]!;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(typeInfo.icon, style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeInfo.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        levelInfo.name,
                        style: TextStyle(
                          color: Color(levelInfo.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (event.isAutoTriggered)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AUTO',
                          style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(event.description),
            if (event.location != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build contact card
  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContactTypeColor(contact.type),
          child: Text(
            _getContactTypeIcon(contact.type),
            style: TextStyle(fontSize: 20),
          ),
        ),
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${contact.callSign}${contact.frequency != null ? ' • ${contact.frequency} MHz' : ''}'),
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: contact.protocols.map((protocol) => Chip(
                label: Text(protocol, style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.grey[200],
              )).toList(),
            ),
          ],
        ),
        trailing: contact.isActive 
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.error, color: Colors.grey),
      ),
    );
  }
  
  /// Build stat card
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Build protocol status
  Widget _buildProtocolStatus(String name, bool isActive, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(name),
          Spacer(),
          Text(
            isActive ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show emergency activation dialog
  void _showEmergencyActivationDialog(EmergencyType type, EmergencyManager manager) {
    final typeInfo = EmergencyManager.EMERGENCY_TYPES[type]!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚨 Acil Durum Aktivasyonu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${typeInfo.icon} ${typeInfo.name}'),
            SizedBox(height: 8),
            Text(typeInfo.description),
            SizedBox(height: 16),
            Text('Acil durumu aktive etmek istediğinizden emin misiniz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              manager.activateEmergencyMode(type, EmergencyLevel.alert);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚨 ${typeInfo.name} acil durumu aktive edildi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Aktive Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Show deactivate dialog
  void _showDeactivateDialog(EmergencyManager manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ Acil Durumu Sonlandır'),
        content: Text('Acil durumu sonlandırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              manager.deactivateEmergencyMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Acil durum sonlandırıldı'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Sonlandır', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  /// Test emergency system
  void _testEmergencySystem(EmergencyManager manager) {
    // Run system test
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧪 Sistem testi başlatıldı'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  /// Send test beacon
  void _sendTestBeacon(EmergencyManager manager) {
    manager.activateEmergencyMode(EmergencyType.medical, EmergencyLevel.info);
    
    // Auto-deactivate after 30 seconds for test
    Timer(Duration(seconds: 30), () {
      manager.deactivateEmergencyMode();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📡 Test beacon gönderildi (30 saniye)'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  /// Get contact type color
  Color _getContactTypeColor(ContactType type) {
    switch (type) {
      case ContactType.official:
        return Colors.blue;
      case ContactType.medical:
        return Colors.red;
      case ContactType.fire:
        return Colors.orange;
      case ContactType.rescue:
        return Colors.green;
      case ContactType.police:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
  
  /// Get contact type icon
  String _getContactTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.official:
        return '🏛️';
      case ContactType.medical:
        return '🏥';
      case ContactType.fire:
        return '🚒';
      case ContactType.rescue:
        return '🚁';
      case ContactType.police:
        return '🚔';
      default:
        return '👤';
    }
  }
}
