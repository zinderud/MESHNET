import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-messages',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatIconModule],
  template: `
    <div class="messages-container">
      <mat-card>
        <mat-card-header>
          <mat-card-title>
            <mat-icon>message</mat-icon>
            Mesajlar
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>Mesajlaşma özelliği yakında eklenecek...</p>
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
  `]
})
export class MessagesComponent { }