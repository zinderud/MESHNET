import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatChipsModule } from '@angular/material/chips';
import { MatBadgeModule } from '@angular/material/badge';
import { MatMenuModule } from '@angular/material/menu';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';
import { MatTooltipModule } from '@angular/material/tooltip';

import { MessagingService, Message, MessageTemplate } from '../../core/services/messaging.service';
import { EmergencyProtocolService } from '../../core/services/emergency-protocol.service';

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
    MatSelectModule,
    MatChipsModule,
    MatBadgeModule,
    MatMenuModule,
    MatDialogModule,
    FormsModule,
    MatTooltipModule
  ],
  template: `
    <div class="messages-container">
      <div class="messages-header">
        <h1>Mesajlar</h1>
        <div class="header-actions">
          <button mat-icon-button [matBadge]="unreadCount().length" matBadgeColor="warn" 
                  [matBadgeHidden]="unreadCount().length === 0">
            <mat-icon>notifications</mat-icon>
          </button>
          <button mat-icon-button [matMenuTriggerFor]="templateMenu">
            <mat-icon>template_add</mat-icon>
          </button>
        </div>
      </div>

      <!-- Emergency Alert Banner with Angular 20 Control Flow -->
      @if (emergencyProtocolService.isEmergencyActive()) {
        <mat-card class="emergency-banner">
          <mat-card-content>
            <div class="emergency-alert">
              <mat-icon class="emergency-icon">warning</mat-icon>
              <div class="emergency-info">
                <h3>ACİL DURUM AKTİF</h3>
                <p>{{ getEmergencyStatusText() }}</p>
              </div>
              <button mat-raised-button color="warn" (click)="sendEmergencyUpdate()">
                Güncelleme Gönder
              </button>
            </div>
          </mat-card-content>
        </mat-card>
      }

      <!-- Message Statistics -->
      <div class="message-stats">
        @for (stat of messageStatsArray(); track stat.label) {
          <mat-card class="stat-card">
            <mat-card-content>
              <div class="stat-item">
                <mat-icon>{{ stat.icon }}</mat-icon>
                <div class="stat-info">
                  <span class="stat-value">{{ stat.value }}</span>
                  <span class="stat-label">{{ stat.label }}</span>
                </div>
              </div>
            </mat-card-content>
          </mat-card>
        }
      </div>
      
      <!-- Message Filters -->
      <div class="message-filters">
        <mat-chip-listbox [(ngModel)]="selectedFilter" (ngModelChange)="filterMessages()">
          <mat-chip-option value="all">Tümü</mat-chip-option>
          <mat-chip-option value="emergency">Acil Durum</mat-chip-option>
          <mat-chip-option value="unread">Okunmamış</mat-chip-option>
          <mat-chip-option value="sent">Gönderilen</mat-chip-option>
          <mat-chip-option value="received">Alınan</mat-chip-option>
        </mat-chip-listbox>
      </div>

      <!-- Messages List with Angular 20 Control Flow -->
      <div class="messages-list">
        @for (message of filteredMessages(); track message.id) {
          <mat-card class="message-card"
                    [ngClass]="{
                      'sent': isSentMessage(message),
                      'received': !isSentMessage(message),
                      'emergency': message.type === 'emergency' || message.priority === 'emergency',
                      'unread': message.status !== 'read' && !isSentMessage(message)
                    }">
            <mat-card-content>
              <div class="message-header">
                <div class="sender-info">
                  <mat-icon class="message-type-icon" [ngClass]="getMessageTypeClass(message)">
                    {{ getMessageTypeIcon(message) }}
                  </mat-icon>
                  <div class="sender-details">
                    <span class="sender-name">{{ getSenderName(message) }}</span>
                    <span class="message-time">{{ message.timestamp | date:'short':'tr' }}</span>
                  </div>
                </div>
                
                <div class="message-actions">
                  <mat-chip class="priority-chip" [ngClass]="message.priority">
                    {{ getPriorityText(message.priority) }}
                  </mat-chip>
                  <button mat-icon-button [matMenuTriggerFor]="messageMenu" 
                          [matMenuTriggerData]="{message: message}">
                    <mat-icon>more_vert</mat-icon>
                  </button>
                </div>
              </div>
              
              <div class="message-content">
                <p>{{ message.content }}</p>
                
                <!-- Location Info -->
                @if (message.location) {
                  <div class="location-info">
                    <mat-icon>location_on</mat-icon>
                    <span>Konum: {{ formatLocation(message.location) }}</span>
                    <button mat-button size="small" (click)="showLocationOnMap(message.location)">
                      Haritada Göster
                    </button>
                  </div>
                }

                <!-- Emergency Data -->
                @if (message.emergencyData) {
                  <div class="emergency-data">
                    <div class="emergency-details">
                      <mat-icon>warning</mat-icon>
                      <div class="emergency-info">
                        <span class="emergency-type">{{ getEmergencyTypeText(message.emergencyData.emergencyType) }}</span>
                        <span class="emergency-severity">Önem: {{ getSeverityText(message.emergencyData.severity) }}</span>
                      </div>
                    </div>
                    @if (message.emergencyData.assistanceNeeded.length) {
                      <div class="assistance-needed">
                        <span>Yardım türü: {{ message.emergencyData.assistanceNeeded.join(', ') }}</span>
                      </div>
                    }
                  </div>
                }
              </div>
              
              <div class="message-status">
                <div class="status-info">
                  <mat-icon [ngClass]="getStatusClass(message.status)">
                    {{ getStatusIcon(message.status) }}
                  </mat-icon>
                  <span>{{ getStatusText(message.status) }}</span>
                  @if (message.encrypted) {
                    <span class="encryption-indicator">
                      <mat-icon>lock</mat-icon>
                    </span>
                  }
                </div>
                
                <div class="message-meta">
                  @if (message.retryCount > 0) {
                    <span class="retry-count">
                      {{ message.retryCount }} yeniden deneme
                    </span>
                  }
                </div>
              </div>
            </mat-card-content>
          </mat-card>
        } @empty {
          <div class="empty-state">
            <mat-icon>message</mat-icon>
            <h3>Mesaj bulunamadı</h3>
            <p>{{ getEmptyStateText() }}</p>
          </div>
        }
      </div>

      <!-- Message Compose -->
      <mat-card class="compose-card">
        <mat-card-content>
          <div class="compose-header">
            <h3>Yeni Mesaj</h3>
            <div class="compose-actions">
              <button mat-icon-button (click)="toggleEmergencyMode()" 
                      [color]="isEmergencyCompose() ? 'warn' : 'primary'"
                      matTooltip="Acil durum modu">
                @if (isEmergencyCompose()) {
                  <mat-icon>warning</mat-icon>
                } @else {
                  <mat-icon>warning_amber</mat-icon>
                }
              </button>
            </div>
          </div>

          <mat-form-field appearance="outline" class="message-input">
            <mat-label>{{ isEmergencyCompose() ? 'Acil durum mesajı' : 'Mesaj yazın...' }}</mat-label>
            <textarea matInput 
                      [(ngModel)]="newMessage"
                      rows="3"
                      [placeholder]="isEmergencyCompose() ? 'Acil durum detaylarını yazın...' : 'Mesajınızı buraya yazın...'"
                      maxlength="500"></textarea>
            <mat-hint align="end">{{ newMessage().length }}/500</mat-hint>
          </mat-form-field>

          <!-- Emergency Options with Angular 20 Control Flow -->
          @if (isEmergencyCompose()) {
            <div class="emergency-options">
              <mat-form-field appearance="outline">
                <mat-label>Acil Durum Türü</mat-label>
                <mat-select [(ngModel)]="emergencyType">
                  <mat-option value="medical">Tıbbi</mat-option>
                  <mat-option value="fire">Yangın</mat-option>
                  <mat-option value="police">Polis</mat-option>
                  <mat-option value="natural_disaster">Doğal Afet</mat-option>
                  <mat-option value="accident">Kaza</mat-option>
                  <mat-option value="other">Diğer</mat-option>
                </mat-select>
              </mat-form-field>

              <mat-form-field appearance="outline">
                <mat-label>Önem Derecesi</mat-label>
                <mat-select [(ngModel)]="emergencySeverity">
                  <mat-option value="low">Düşük</mat-option>
                  <mat-option value="medium">Orta</mat-option>
                  <mat-option value="high">Yüksek</mat-option>
                  <mat-option value="critical">Kritik</mat-option>
                </mat-select>
              </mat-form-field>
            </div>
          }
          
          <div class="compose-buttons">
            <button mat-raised-button 
                    [color]="isEmergencyCompose() ? 'warn' : 'primary'"
                    (click)="sendMessage()"
                    [disabled]="!newMessage().trim()">
              @if (isEmergencyCompose()) {
                <ng-container>
                  <mat-icon>warning</mat-icon>
                  ACİL MESAJ GÖNDER
                </ng-container>
              } @else {
                <ng-container>
                  <mat-icon>send</mat-icon>
                  Gönder
                </ng-container>
              }
            </button>
            
            <button mat-button (click)="clearMessage()">
              <mat-icon>clear</mat-icon>
              Temizle
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>

    <!-- Template Menu -->
    <mat-menu #templateMenu="matMenu">
      @for (template of messageTemplates; track template.id) {
        <button mat-menu-item (click)="useTemplate(template)">
          <mat-icon>{{ getTemplateIcon(template) }}</mat-icon>
          <span>{{ template.name }}</span>
        </button>
      }
    </mat-menu>

    <!-- Message Menu -->
    <mat-menu #messageMenu="matMenu">
      <ng-template matMenuContent let-message="message">
        @if (message.status !== 'read' && !isSentMessage(message)) {
          <button mat-menu-item (click)="markAsRead(message)">
            <mat-icon>mark_email_read</mat-icon>
            <span>Okundu İşaretle</span>
          </button>
        }
        <button mat-menu-item (click)="replyToMessage(message)">
          <mat-icon>reply</mat-icon>
          <span>Yanıtla</span>
        </button>
        <button mat-menu-item (click)="forwardMessage(message)">
          <mat-icon>forward</mat-icon>
          <span>İlet</span>
        </button>
        <button mat-menu-item (click)="deleteMessage(message)" color="warn">
          <mat-icon>delete</mat-icon>
          <span>Sil</span>
        </button>
      </ng-template>
    </mat-menu>
  `,
  styles: [`
    .messages-container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 16px;
    }

    .messages-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .messages-header h1 {
      margin: 0;
      color: #333;
    }

    .header-actions {
      display: flex;
      gap: 8px;
    }

    .emergency-banner {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #ff5722, #f44336);
      color: white;
    }

    .emergency-alert {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .emergency-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0% { transform: scale(1); }
      50% { transform: scale(1.1); }
      100% { transform: scale(1); }
    }

    .emergency-info h3 {
      margin: 0 0 4px 0;
      font-size: 18px;
    }

    .emergency-info p {
      margin: 0;
      opacity: 0.9;
    }

    .message-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      background: linear-gradient(135deg, #2196f3, #21cbf3);
      color: white;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .stat-item mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .stat-info {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 20px;
      font-weight: bold;
    }

    .stat-label {
      font-size: 12px;
      opacity: 0.8;
    }

    .message-filters {
      margin-bottom: 24px;
    }

    .messages-list {
      max-height: 60vh;
      overflow-y: auto;
      margin-bottom: 24px;
    }

    .message-card {
      margin-bottom: 12px;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .message-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
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

    .message-card.unread {
      border-left: 4px solid #2196f3;
      background-color: #f8f9ff;
    }

    .message-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .sender-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .message-type-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .message-type-icon.emergency {
      color: #f44336;
    }

    .message-type-icon.status {
      color: #ff9800;
    }

    .message-type-icon.text {
      color: #2196f3;
    }

    .sender-details {
      display: flex;
      flex-direction: column;
    }

    .sender-name {
      font-weight: bold;
      color: #333;
    }

    .message-time {
      font-size: 12px;
      color: #666;
    }

    .message-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .priority-chip {
      font-size: 10px;
      height: 20px;
      min-height: 20px;
    }

    .priority-chip.emergency {
      background-color: #f44336;
      color: white;
    }

    .priority-chip.high {
      background-color: #ff9800;
      color: white;
    }

    .priority-chip.normal {
      background-color: #4caf50;
      color: white;
    }

    .priority-chip.low {
      background-color: #9e9e9e;
      color: white;
    }

    .message-content {
      margin-bottom: 12px;
      line-height: 1.5;
    }

    .location-info {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
      padding: 8px;
      background-color: rgba(76, 175, 80, 0.1);
      border-radius: 4px;
      font-size: 14px;
    }

    .location-info mat-icon {
      color: #4caf50;
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .emergency-data {
      margin-top: 8px;
      padding: 8px;
      background-color: rgba(244, 67, 54, 0.1);
      border-radius: 4px;
    }

    .emergency-details {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 4px;
    }

    .emergency-details mat-icon {
      color: #f44336;
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .emergency-info {
      display: flex;
      flex-direction: column;
      font-size: 14px;
    }

    .emergency-type {
      font-weight: bold;
      color: #f44336;
    }

    .emergency-severity {
      font-size: 12px;
      color: #666;
    }

    .assistance-needed {
      font-size: 12px;
      color: #666;
      font-style: italic;
    }

    .message-status {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      color: #666;
    }

    .status-info {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .status-info mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    .status-info .sending {
      color: #ff9800;
    }

    .status-info .sent {
      color: #2196f3;
    }

    .status-info .delivered {
      color: #4caf50;
    }

    .status-info .failed {
      color: #f44336;
    }

    .encryption-indicator {
      color: #4caf50;
    }

    .encryption-indicator mat-icon {
      font-size: 12px;
      width: 12px;
      height: 12px;
    }

    .retry-count {
      color: #ff9800;
    }

    .empty-state {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .compose-card {
      position: sticky;
      bottom: 0;
      background: white;
      box-shadow: 0 -2px 8px rgba(0,0,0,0.1);
    }

    .compose-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .compose-header h3 {
      margin: 0;
      color: #333;
    }

    .message-input {
      width: 100%;
      margin-bottom: 16px;
    }

    .emergency-options {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }

    .compose-buttons {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }

    .compose-buttons button mat-icon {
      margin-right: 8px;
    }

    @media (max-width: 768px) {
      .messages-container {
        padding: 8px;
      }
      
      .message-stats {
        grid-template-columns: repeat(2, 1fr);
      }
      
      .message-card.sent {
        margin-left: 10%;
      }
      
      .message-card.received {
        margin-right: 10%;
      }
      
      .compose-buttons {
        flex-direction: column;
      }
      
      .compose-buttons button {
        width: 100%;
      }

      .emergency-options {
        grid-template-columns: 1fr;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      .pulse {
        animation: none;
      }
      
      .message-card {
        transition: none;
      }
    }
  `]
})
export class MessagesComponent implements OnInit, OnDestroy {
  private messagingService = inject(MessagingService);
  protected emergencyProtocolService = inject(EmergencyProtocolService);
  private dialog = inject(MatDialog);

  // Angular 20 Signals for reactive state
  private _newMessage = signal('');
  private _selectedFilter = signal('all');
  private _filteredMessages = signal<Message[]>([]);
  private _isEmergencyCompose = signal(false);
  private _emergencyType = signal<any>('other');
  private _emergencySeverity = signal<any>('high');

  // Readonly signals
  newMessage = this._newMessage.asReadonly();
  selectedFilter = this._selectedFilter.asReadonly();
  filteredMessages = this._filteredMessages.asReadonly();
  isEmergencyCompose = this._isEmergencyCompose.asReadonly();

  // Reactive signals from services
  messages = this.messagingService.messages;
  messageStats = this.messagingService.messageStats;
  unreadCount = this.messagingService.unreadMessages;
  messageTemplates = this.messagingService.getMessageTemplates();

  // Computed properties
  messageStatsArray = computed(() => [
    {
      icon: 'send',
      value: this.messageStats().totalSent,
      label: 'Gönderilen'
    },
    {
      icon: 'inbox',
      value: this.messageStats().totalReceived,
      label: 'Alınan'
    },
    {
      icon: 'warning',
      value: this.messageStats().emergencyMessages,
      label: 'Acil Durum'
    },
    {
      icon: 'check_circle',
      value: `${this.messageStats().deliveryRate.toFixed(1)}%`,
      label: 'Teslimat'
    }
  ]);

  emergencyType = this._emergencyType.asReadonly();
  emergencySeverity = this._emergencySeverity.asReadonly();

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.filterMessages();
    this.setupSubscriptions();
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupSubscriptions(): void {
    // Listen for new messages
    this.subscriptions.add(
      this.messagingService.onMessageReceived$.subscribe(message => {
        this.filterMessages();
        
        // Auto-mark emergency messages as read after a delay
        if (message.type === 'emergency') {
          setTimeout(() => {
            this.markAsRead(message);
          }, 5000);
        }
      })
    );

    // Listen for emergency alerts
    this.subscriptions.add(
      this.emergencyProtocolService.onEmergencyTriggered$.subscribe(session => {
        this._isEmergencyCompose.set(true);
        this._emergencyType.set(session.type);
        this._emergencySeverity.set(session.severity);
      })
    );
  }

  async sendMessage(): Promise<void> {
    const messageText = this._newMessage();
    if (!messageText.trim()) return;

    try {
      if (this._isEmergencyCompose()) {
        await this.messagingService.sendEmergencyMessage(
          this._emergencyType(),
          messageText,
          this._emergencySeverity()
        );
      } else {
        await this.messagingService.sendMessage(
          messageText,
          'text',
          'normal'
        );
      }

      this.clearMessage();
    } catch (error) {
      console.error('Failed to send message:', error);
      // Show error notification
    }
  }

  async sendEmergencyUpdate(): Promise<void> {
    const updateMessage = prompt('Acil durum güncellemesi girin:');
    if (updateMessage) {
      try {
        await this.emergencyProtocolService.sendEmergencyUpdate(updateMessage);
      } catch (error) {
        console.error('Failed to send emergency update:', error);
      }
    }
  }

  async useTemplate(template: MessageTemplate): Promise<void> {
    try {
      await this.messagingService.sendTemplateMessage(template.id);
    } catch (error) {
      console.error('Failed to send template message:', error);
    }
  }

  filterMessages(): void {
    const allMessages = this.messages();
    const filter = this._selectedFilter();
    
    let filtered: Message[];
    
    switch (filter) {
      case 'emergency':
        filtered = allMessages.filter(m => 
          m.type === 'emergency' || m.priority === 'emergency'
        );
        break;
      case 'unread':
        filtered = allMessages.filter(m => 
          m.status !== 'read' && !this.isSentMessage(m)
        );
        break;
      case 'sent':
        filtered = allMessages.filter(m => this.isSentMessage(m));
        break;
      case 'received':
        filtered = allMessages.filter(m => !this.isSentMessage(m));
        break;
      default:
        filtered = allMessages;
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp - a.timestamp);
    this._filteredMessages.set(filtered);
  }

  markAsRead(message: Message): void {
    this.messagingService.markAsRead(message.id);
  }

  deleteMessage(message: Message): void {
    if (confirm('Bu mesajı silmek istediğinizden emin misiniz?')) {
      this.messagingService.deleteMessage(message.id);
      this.filterMessages();
    }
  }

  replyToMessage(message: Message): void {
    this._newMessage.set(`@${message.sender.name}: `);
    // Focus on message input
  }

  forwardMessage(message: Message): void {
    this._newMessage.set(`İletilen mesaj: ${message.content}`);
  }

  toggleEmergencyMode(): void {
    this._isEmergencyCompose.update(current => !current);
    if (this._isEmergencyCompose()) {
      this._newMessage.set('');
    }
  }

  clearMessage(): void {
    this._newMessage.set('');
    this._isEmergencyCompose.set(false);
    this._emergencyType.set('other');
    this._emergencySeverity.set('high');
  }

  showLocationOnMap(location: any): void {
    // Open location in maps application
    const url = `https://maps.google.com/?q=${location.latitude},${location.longitude}`;
    window.open(url, '_blank');
  }

  // Helper methods
  trackMessage(index: number, message: Message): string {
    return message.id;
  }

  isSentMessage(message: Message): boolean {
    // This should check against actual user ID
    return message.sender.id === 'current_user_id';
  }

  getSenderName(message: Message): string {
    return this.isSentMessage(message) ? 'Ben' : message.sender.name;
  }

  getMessageTypeIcon(message: Message): string {
    switch (message.type) {
      case 'emergency': return 'warning';
      case 'location': return 'location_on';
      case 'status': return 'info';
      default: return 'message';
    }
  }

  getMessageTypeClass(message: Message): string {
    return message.type;
  }

  getPriorityText(priority: string): string {
    switch (priority) {
      case 'emergency': return 'ACİL';
      case 'high': return 'Yüksek';
      case 'normal': return 'Normal';
      case 'low': return 'Düşük';
      default: return 'Normal';
    }
  }

  getStatusIcon(status: string): string {
    switch (status) {
      case 'sending': return 'schedule';
      case 'sent': return 'check';
      case 'delivered': return 'done_all';
      case 'read': return 'mark_email_read';
      case 'failed': return 'error';
      default: return 'help';
    }
  }

  getStatusClass(status: string): string {
    return status;
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'sending': return 'Gönderiliyor...';
      case 'sent': return 'Gönderildi';
      case 'delivered': return 'Teslim edildi';
      case 'read': return 'Okundu';
      case 'failed': return 'Başarısız';
      default: return 'Bilinmiyor';
    }
  }

  getEmergencyTypeText(type: string): string {
    switch (type) {
      case 'medical': return 'Tıbbi Acil Durum';
      case 'fire': return 'Yangın';
      case 'police': return 'Polis';
      case 'natural_disaster': return 'Doğal Afet';
      case 'accident': return 'Kaza';
      default: return 'Acil Durum';
    }
  }

  getSeverityText(severity: string): string {
    switch (severity) {
      case 'critical': return 'Kritik';
      case 'high': return 'Yüksek';
      case 'medium': return 'Orta';
      case 'low': return 'Düşük';
      default: return 'Orta';
    }
  }

  getTemplateIcon(template: MessageTemplate): string {
    switch (template.type) {
      case 'emergency': return 'warning';
      case 'status': return 'info';
      default: return 'message';
    }
  }

  formatLocation(location: any): string {
    return `${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}`;
  }

  getEmergencyStatusText(): string {
    const session = this.emergencyProtocolService.activeSession();
    if (!session) return '';
    
    const duration = Math.floor((Date.now() - session.startTime) / 1000 / 60);
    return `${this.getEmergencyTypeText(session.type)} - ${duration} dakika`;
  }

  getEmptyStateText(): string {
    switch (this._selectedFilter()) {
      case 'emergency': return 'Acil durum mesajı bulunmuyor.';
      case 'unread': return 'Okunmamış mesaj bulunmuyor.';
      case 'sent': return 'Gönderilen mesaj bulunmuyor.';
      case 'received': return 'Alınan mesaj bulunmuyor.';
      default: return 'Henüz mesaj bulunmuyor.';
    }
  }

  // Update methods for template binding
  updateNewMessage(value: string): void {
    this._newMessage.set(value);
  }

  updateSelectedFilter(value: string): void {
    this._selectedFilter.set(value);
    this.filterMessages();
  }

  updateEmergencyType(value: any): void {
    this._emergencyType.set(value);
  }

  updateEmergencySeverity(value: any): void {
    this._emergencySeverity.set(value);
  }
}