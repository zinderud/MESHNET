import { Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { EmergencyGuard } from './core/guards/emergency.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/dashboard',
    pathMatch: 'full'
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'emergency',
    loadComponent: () => import('./features/emergency/emergency.component').then(m => m.EmergencyComponent),
    canActivate: [EmergencyGuard],
    canDeactivate: [EmergencyGuard]
  },
  {
    path: 'messages',
    loadComponent: () => import('./features/messages/messages.component').then(m => m.MessagesComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'network',
    loadComponent: () => import('./features/network/network.component').then(m => m.NetworkComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'settings',
    loadComponent: () => import('./features/settings/settings.component').then(m => m.SettingsComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'setup',
    loadComponent: () => import('./features/setup/setup.component').then(m => m.SetupComponent)
  },
  {
    path: 'security',
    loadComponent: () => import('./features/security/security.component').then(m => m.SecurityComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'analytics',
    loadComponent: () => import('./features/analytics/analytics.component').then(m => m.AnalyticsComponent),
    canActivate: [AuthGuard]
  },
  {
    path: '**',
    redirectTo: '/dashboard'
  }
];