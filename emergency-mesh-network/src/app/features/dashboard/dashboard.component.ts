import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

interface NetworkStatus {
  text: string;
  description: string;
  color: string;
  icon: string;
}

interface ConnectedDevice {
  id: string;
  name: string;
  type: string;
  signalStrength: number;
}

interface Activity {
  title: string;
  description: string;
  timestamp: Date;
  icon: string;
  color: string;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  
  // Network Status
  networkStatus: NetworkStatus = {
    text: 'Bağlı',
    description: '3 cihaz ile mesh ağında',
    color: 'var(--connected-green)',
    icon: 'signal_cellular_4_bar'
  };
  
  // Connected Devices
  connectedDevices: ConnectedDevice[] = [
    { id: '1', name: 'Telefon-A', type: 'mobile', signalStrength: 85 },
    { id: '2', name: 'Telefon-B', type: 'mobile', signalStrength: 72 },
    { id: '3', name: 'Tablet-C', type: 'tablet', signalStrength: 91 }
  ];
  
  // Emergency State
  isEmergencyActive = false;
  emergencyButtonDisabled = false;
  
  // Messages
  unreadMessages = 2;
  
  // Recent Activities
  recentActivities: Activity[] = [
    {
      title: 'Yeni cihaz bağlandı',
      description: 'Telefon-D mesh ağına katıldı',
      timestamp: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
      icon: 'smartphone',
      color: 'var(--safe-green)'
    },
    {
      title: 'Mesaj alındı',
      description: 'Ali: "Durumum iyi, güvendeyim"',
      timestamp: new Date(Date.now() - 15 * 60 * 1000), // 15 minutes ago
      icon: 'message',
      color: 'var(--info-blue)'
    },
    {
      title: 'Konum güncellendi',
      description: 'GPS koordinatları paylaşıldı',
      timestamp: new Date(Date.now() - 30 * 60 * 1000), // 30 minutes ago
      icon: 'location_on',
      color: 'var(--warning-orange)'
    }
  ];

  constructor(private router: Router) { }

  ngOnInit(): void {
    this.initializeNetworkStatus();
    this.startNetworkMonitoring();
  }

  private initializeNetworkStatus(): void {
    // Simulate network initialization
    setTimeout(() => {
      this.updateNetworkStatus();
    }, 1000);
  }

  private startNetworkMonitoring(): void {
    // Simulate periodic network status updates
    setInterval(() => {
      this.updateNetworkStatus();
    }, 10000); // Update every 10 seconds
  }

  private updateNetworkStatus(): void {
    // Simulate network status changes
    const statuses: NetworkStatus[] = [
      {
        text: 'Bağlı',
        description: `${this.connectedDevices.length} cihaz ile mesh ağında`,
        color: 'var(--connected-green)',
        icon: 'signal_cellular_4_bar'
      },
      {
        text: 'Aranıyor',
        description: 'Yakındaki cihazlar aranıyor...',
        color: 'var(--searching-yellow)',
        icon: 'search'
      },
      {
        text: 'Bağlantısız',
        description: 'Mesh ağına bağlı değil',
        color: 'var(--disconnected-red)',
        icon: 'signal_cellular_off'
      }
    ];
    
    // Randomly select status for demo (in real app, this would be based on actual network state)
    const randomIndex = Math.floor(Math.random() * statuses.length);
    this.networkStatus = statuses[0]; // Keep connected for demo
  }

  scanForDevices(): void {
    this.networkStatus = {
      text: 'Aranıyor',
      description: 'Yakındaki cihazlar aranıyor...',
      color: 'var(--searching-yellow)',
      icon: 'search'
    };
    
    // Simulate device discovery
    setTimeout(() => {
      // Add a new device
      const newDevice: ConnectedDevice = {
        id: Date.now().toString(),
        name: `Telefon-${String.fromCharCode(65 + this.connectedDevices.length)}`,
        type: 'mobile',
        signalStrength: Math.floor(Math.random() * 40) + 60 // 60-100
      };
      
      this.connectedDevices.push(newDevice);
      this.updateNetworkStatus();
      
      // Add activity
      this.addActivity({
        title: 'Yeni cihaz bulundu',
        description: `${newDevice.name} mesh ağına katıldı`,
        timestamp: new Date(),
        icon: 'smartphone',
        color: 'var(--safe-green)'
      });
    }, 3000);
  }

  toggleEmergency(): void {
    if (this.emergencyButtonDisabled) return;
    
    this.emergencyButtonDisabled = true;
    this.isEmergencyActive = !this.isEmergencyActive;
    
    if (this.isEmergencyActive) {
      this.activateEmergency();
    } else {
      this.deactivateEmergency();
    }
    
    // Re-enable button after 2 seconds
    setTimeout(() => {
      this.emergencyButtonDisabled = false;
    }, 2000);
  }

  private activateEmergency(): void {
    // Add emergency activation activity
    this.addActivity({
      title: 'ACİL DURUM AKTİVE EDİLDİ',
      description: 'Acil durum sinyali mesh ağına gönderildi',
      timestamp: new Date(),
      icon: 'emergency',
      color: 'var(--emergency-red)'
    });
    
    // Simulate emergency broadcast
    console.log('Emergency activated - broadcasting to mesh network');
    
    // In a real app, this would:
    // 1. Send emergency signal to all connected devices
    // 2. Share current location
    // 3. Start continuous location updates
    // 4. Notify emergency contacts
  }

  private deactivateEmergency(): void {
    this.addActivity({
      title: 'Acil durum devre dışı bırakıldı',
      description: 'Acil durum durumu sonlandırıldı',
      timestamp: new Date(),
      icon: 'check_circle',
      color: 'var(--safe-green)'
    });
    
    console.log('Emergency deactivated');
  }

  private addActivity(activity: Activity): void {
    this.recentActivities.unshift(activity);
    // Keep only last 5 activities
    if (this.recentActivities.length > 5) {
      this.recentActivities = this.recentActivities.slice(0, 5);
    }
  }

  // Navigation methods
  navigateToMessages(): void {
    this.router.navigate(['/messages']);
  }

  shareLocation(): void {
    // TODO: Implement location sharing
    this.addActivity({
      title: 'Konum paylaşıldı',
      description: 'GPS koordinatları mesh ağına gönderildi',
      timestamp: new Date(),
      icon: 'location_on',
      color: 'var(--warning-orange)'
    });
    
    console.log('Location shared');
  }

  viewNetworkMap(): void {
    this.router.navigate(['/network']);
  }

  emergencyContacts(): void {
    // TODO: Implement emergency contacts
    console.log('Emergency contacts');
  }
}