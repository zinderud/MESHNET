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
    path: 'emergency-scenario',
    loadComponent: () => import('./features/emergency-scenario/emergency-scenario.component').then(m => m.EmergencyScenarioComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'network-implementation',
    loadComponent: () => import('./features/network-implementation/network-implementation.component').then(m => m.NetworkImplementationComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'network-visualization',
    loadComponent: () => import('./features/network-visualization/network-visualization.component').then(m => m.NetworkVisualizationComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'network-simulation',
    loadComponent: () => import('./features/network-simulation/network-simulation.component').then(m => m.NetworkSimulationComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'network-testing',
    loadComponent: () => import('./features/network-testing/network-testing.component').then(m => m.NetworkTestingComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'p2p-network',
    loadComponent: () => import('./features/p2p-network/p2p-network-dashboard.component').then(m => m.P2PNetworkDashboardComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'blockchain',
    loadComponent: () => import('./features/blockchain/blockchain-explorer.component').then(m => m.BlockchainExplorerComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'blockchain/transaction',
    loadComponent: () => import('./features/blockchain/transaction-creator.component').then(m => m.TransactionCreatorComponent),
    canActivate: [AuthGuard]
  },
  {
    path: 'deployment',
    loadComponent: () => import('./features/deployment/deployment.component').then(m => m.DeploymentComponent),
    canActivate: [AuthGuard]
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
    path: 'pwa',
    loadComponent: () => import('./features/pwa-install/pwa-install.component').then(m => m.PWAInstallComponent)
  },
  {
    path: '**',
    redirectTo: '/dashboard'
  }
];