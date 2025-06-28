import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { 
    path: 'dashboard', 
    loadChildren: () => import('./features/dashboard/dashboard.module').then(m => m.DashboardModule)
  },
  { 
    path: 'messages', 
    loadComponent: () => import('./features/messages/messages.component').then(c => c.MessagesComponent)
  },
  { 
    path: 'network', 
    loadComponent: () => import('./features/network/network.component').then(c => c.NetworkComponent)
  },
  { 
    path: 'emergency', 
    loadComponent: () => import('./features/emergency/emergency.component').then(c => c.EmergencyComponent)
  },
  { path: '**', redirectTo: '/dashboard' }
];