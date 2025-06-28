import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-emergency',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatIconModule],
  template: `
    <div class="emergency-container">
      <mat-card>
        <mat-card-header>
          <mat-card-title>
            <mat-icon>emergency</mat-icon>
            Acil Durum
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>Acil durum özellikleri yakında eklenecek...</p>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .emergency-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }
  `]
})
export class EmergencyComponent { }