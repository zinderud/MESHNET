import { Injectable, inject } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { CryptoService } from '../services/crypto.service';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  private cryptoService = inject(CryptoService);
  private router = inject(Router);

  canActivate(): Observable<boolean> | Promise<boolean> | boolean {
    // Check if cryptographic keys are initialized
    return this.cryptoService.isInitialized().pipe(
      map(isInitialized => {
        if (!isInitialized) {
          this.router.navigate(['/setup']);
          return false;
        }
        return true;
      })
    );
  }
}