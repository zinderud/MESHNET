import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-network',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatIconModule],
  template: `
    <div class="network-container">
      <mat-card>
        <mat-card-header>
          <mat-card-title>
            <mat-icon>network_check</mat-icon>
            Ağ Durumu
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>Ağ haritası ve detayları yakında eklenecek...</p>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .network-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }
  `]
})
export class NetworkComponent { }