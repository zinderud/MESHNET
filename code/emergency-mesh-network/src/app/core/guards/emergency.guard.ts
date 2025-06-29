import { Injectable, inject } from '@angular/core';
import { CanActivate, CanDeactivate } from '@angular/router';
import { Observable } from 'rxjs';
import { EmergencyProtocolService } from '../services/emergency-protocol.service';

export interface CanComponentDeactivate {
  canDeactivate: () => Observable<boolean> | Promise<boolean> | boolean;
}

@Injectable({
  providedIn: 'root'
})
export class EmergencyGuard implements CanActivate, CanDeactivate<CanComponentDeactivate> {
  private emergencyService = inject(EmergencyProtocolService);

  canActivate(): boolean {
    // Always allow access to emergency features
    return true;
  }

  canDeactivate(component: CanComponentDeactivate): Observable<boolean> | Promise<boolean> | boolean {
    // Prevent leaving emergency mode without confirmation
    if (this.emergencyService.isEmergencyActive()) {
      return confirm('Acil durum modu aktif! Çıkmak istediğinizden emin misiniz?');
    }
    return true;
  }
}