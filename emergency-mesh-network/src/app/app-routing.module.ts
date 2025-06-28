import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { 
    path: 'dashboard', 
    loadChildren: () => import('./features/dashboard/dashboard.module').then(m => m.DashboardModule)
  },
  { 
    path: 'messages', 
    loadChildren: () => import('./features/messages/messages.module').then(m => m.MessagesModule)
  },
  { 
    path: 'network', 
    loadChildren: () => import('./features/network/network.module').then(m => m.NetworkModule)
  },
  { 
    path: 'emergency', 
    loadChildren: () => import('./features/emergency/emergency.module').then(m => m.EmergencyModule)
  },
  { path: '**', redirectTo: '/dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes, {
    enableTracing: false,
    preloadingStrategy: undefined
  })],
  exports: [RouterModule]
})
export class AppRoutingModule { }