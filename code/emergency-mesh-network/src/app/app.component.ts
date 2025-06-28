import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    RouterModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatSidenavModule,
    MatListModule
  ],
  template: `
    <mat-sidenav-container class="sidenav-container">
      <mat-sidenav #drawer class="sidenav" fixedInViewport
                   [attr.role]="'navigation'"
                   [mode]="'over'"
                   [opened]="false">
        <mat-toolbar>Menü</mat-toolbar>
        <mat-nav-list>
          <a mat-list-item routerLink="/dashboard" (click)="drawer.close()">
            <mat-icon>dashboard</mat-icon>
            <span>Ana Sayfa</span>
          </a>
          <a mat-list-item routerLink="/emergency" (click)="drawer.close()">
            <mat-icon>warning</mat-icon>
            <span>Acil Durum</span>
          </a>
          <a mat-list-item routerLink="/messages" (click)="drawer.close()">
            <mat-icon>message</mat-icon>
            <span>Mesajlar</span>
          </a>
          <a mat-list-item routerLink="/network" (click)="drawer.close()">
            <mat-icon>network_check</mat-icon>
            <span>Ağ Durumu</span>
          </a>
          <a mat-list-item routerLink="/settings" (click)="drawer.close()">
            <mat-icon>settings</mat-icon>
            <span>Ayarlar</span>
          </a>
        </mat-nav-list>
      </mat-sidenav>
      
      <mat-sidenav-content>
        <mat-toolbar color="primary">
          <button
            type="button"
            aria-label="Toggle sidenav"
            mat-icon-button
            (click)="drawer.toggle()">
            <mat-icon aria-label="Side nav toggle icon">menu</mat-icon>
          </button>
          <span>Acil Durum Mesh Network</span>
          <span class="spacer"></span>
          <button mat-icon-button>
            <mat-icon>signal_wifi_4_bar</mat-icon>
          </button>
        </mat-toolbar>
        
        <main class="main-content">
          <router-outlet></router-outlet>
        </main>
      </mat-sidenav-content>
    </mat-sidenav-container>
  `,
  styles: [`
    .sidenav-container {
      height: 100vh;
    }

    .sidenav {
      width: 250px;
    }

    .sidenav .mat-toolbar {
      background: inherit;
    }

    .mat-toolbar.mat-primary {
      position: sticky;
      top: 0;
      z-index: 1;
    }

    .spacer {
      flex: 1 1 auto;
    }

    .main-content {
      padding: 16px;
      min-height: calc(100vh - 64px);
    }

    @media (max-width: 768px) {
      .main-content {
        padding: 8px;
      }
    }
  `]
})
export class AppComponent {
  title = 'Acil Durum Mesh Network';
}