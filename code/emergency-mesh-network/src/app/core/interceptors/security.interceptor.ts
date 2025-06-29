import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, timeout } from 'rxjs/operators';

@Injectable()
export class SecurityInterceptor implements HttpInterceptor {
  private readonly REQUEST_TIMEOUT = 30000; // 30 seconds

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Add security headers
    const secureReq = req.clone({
      setHeaders: {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
        'Content-Security-Policy': this.getCSP()
      }
    });

    return next.handle(secureReq).pipe(
      timeout(this.REQUEST_TIMEOUT),
      catchError(error => {
        console.error('HTTP Security Error:', error);
        throw error;
      })
    );
  }

  private getCSP(): string {
    return [
      "default-src 'self'",
      "script-src 'self' 'wasm-unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "connect-src 'self' wss: https:",
      "img-src 'self' data: https:",
      "worker-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join('; ');
  }
}