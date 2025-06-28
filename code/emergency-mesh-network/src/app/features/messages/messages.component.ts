import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { FormsModule } from '@angular/forms';

interface Message {
  id: string;
  sender: string;
  content: string;
  timestamp: Date;
  type: 'sent' | 'received' | 'emergency';
  status: 'sending' | 'sent' | 'delivered' | 'failed';
}

@Component({
  selector: 'app-messages',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    FormsModule
  ],
  template: `
    <div class="messages-container">
      <h1>Mesajlar</h1>
      
      <!-- Mesaj Listesi -->
      <div class="messages-list">
        <mat-card *ngFor="let message of messages" 
                  class="message-card"
                  [ngClass]="message.type">
          <mat-card-content>
            <div class="message-header">
              <span class="sender">{{ message.sender }}</span>
              <span class="timestamp">{{ message.timestamp | date:'short':'tr' }}</span>
            </div>
            <div class="message-content">
              {{ message.content }}
            </div>
            <div class="message-status">
              <mat-icon [ngClass]="message.status">
                {{ getStatusIcon(message.status) }}
              </mat-icon>
              <span>{{ getStatusText(message.status) }}</span>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Mesaj Gönderme -->
      <mat-card class="compose-card">
        <mat-card-content>
          <mat-form-field appearance="outline" class="message-input">
            <mat-label>Mesaj yazın...</mat-label>
            <textarea matInput 
                      [(ngModel)]="newMessage"
                      rows="3"
                      placeholder="Mesajınızı buraya yazın..."></textarea>
          </mat-form-field>
          
          <div class="compose-actions">
            <button mat-raised-button color="primary" 
                    (click)="sendMessage()"
                    [disabled]="!newMessage.trim()">
              <mat-icon>send</mat-icon>
              Gönder
            </button>
            
            <button mat-raised-button color="warn" 
                    (click)="sendEmergencyMessage()">
              <mat-icon>warning</mat-icon>
              Acil Mesaj
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .messages-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .messages-list {
      max-height: 60vh;
      overflow-y: auto;
      margin-bottom: 24px;
    }

    .message-card {
      margin-bottom: 12px;
      transition: transform 0.2s ease;
    }

    .message-card:hover {
      transform: translateY(-2px);
    }

    .message-card.sent {
      margin-left: 20%;
      background-color: #e3f2fd;
    }

    .message-card.received {
      margin-right: 20%;
      background-color: #f3e5f5;
    }

    .message-card.emergency {
      background: linear-gradient(135deg, #ffebee, #ffcdd2);
      border-left: 4px solid #f44336;
    }

    .message-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }

    .sender {
      font-weight: bold;
      color: #333;
    }

    .timestamp {
      font-size: 12px;
      color: #666;
    }

    .message-content {
      margin-bottom: 8px;
      line-height: 1.4;
    }

    .message-status {
      display: flex;
      align-items: center;
      font-size: 12px;
      color: #666;
    }

    .message-status mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
      margin-right: 4px;
    }

    .message-status .sending {
      color: #ff9800;
    }

    .message-status .sent {
      color: #2196f3;
    }

    .message-status .delivered {
      color: #4caf50;
    }

    .message-status .failed {
      color: #f44336;
    }

    .compose-card {
      position: sticky;
      bottom: 0;
      background: white;
      box-shadow: 0 -2px 8px rgba(0,0,0,0.1);
    }

    .message-input {
      width: 100%;
      margin-bottom: 16px;
    }

    .compose-actions {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }

    .compose-actions button {
      min-width: 120px;
    }

    .compose-actions button mat-icon {
      margin-right: 8px;
    }

    @media (max-width: 768px) {
      .messages-container {
        padding: 8px;
      }
      
      .message-card.sent {
        margin-left: 10%;
      }
      
      .message-card.received {
        margin-right: 10%;
      }
      
      .compose-actions {
        flex-direction: column;
      }
      
      .compose-actions button {
        width: 100%;
      }
    }
  `]
})
export class MessagesComponent {
  newMessage = '';
  
  messages: Message[] = [
    {
      id: '1',
      sender: 'Ahmet K.',
      content: 'Merhaba, burada güvendeyim. Sizin durumunuz nasıl?',
      timestamp: new Date(Date.now() - 300000),
      type: 'received',
      status: 'delivered'
    },
    {
      id: '2',
      sender: 'Ben',
      content: 'İyiyim, teşekkürler. Elektrik kesildi ama mesh ağ çalışıyor.',
      timestamp: new Date(Date.now() - 240000),
      type: 'sent',
      status: 'delivered'
    },
    {
      id: '3',
      sender: 'Fatma S.',
      content: '🚨 ACİL DURUM: Binada yangın var, yardım gerekiyor!',
      timestamp: new Date(Date.now() - 120000),
      type: 'emergency',
      status: 'delivered'
    }
  ];

  sendMessage() {
    if (!this.newMessage.trim()) return;

    const message: Message = {
      id: Date.now().toString(),
      sender: 'Ben',
      content: this.newMessage,
      timestamp: new Date(),
      type: 'sent',
      status: 'sending'
    };

    this.messages.push(message);
    this.newMessage = '';

    // Simüle et: mesaj gönderme
    setTimeout(() => {
      message.status = 'sent';
    }, 1000);

    setTimeout(() => {
      message.status = 'delivered';
    }, 3000);
  }

  sendEmergencyMessage() {
    const emergencyMessage: Message = {
      id: Date.now().toString(),
      sender: 'Ben',
      content: '🚨 ACİL DURUM: Yardıma ihtiyacım var! Konum: [GPS koordinatları]',
      timestamp: new Date(),
      type: 'emergency',
      status: 'sending'
    };

    this.messages.push(emergencyMessage);

    // Simüle et: acil mesaj gönderme
    setTimeout(() => {
      emergencyMessage.status = 'sent';
    }, 500);

    setTimeout(() => {
      emergencyMessage.status = 'delivered';
    }, 1500);
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'sending': return 'schedule';
      case 'sent': return 'check';
      case 'delivered': return 'done_all';
      case 'failed': return 'error';
      default: return 'help';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'sending': return 'Gönderiliyor...';
      case 'sent': return 'Gönderildi';
      case 'delivered': return 'Teslim edildi';
      case 'failed': return 'Başarısız';
      default: return 'Bilinmiyor';
    }
  }
}