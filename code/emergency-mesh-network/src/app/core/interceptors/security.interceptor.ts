import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { timeout, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';

export const SecurityInterceptor: HttpInterceptorFn = (req, next) => {
  const REQUEST_TIMEOUT = 30000; // 30 seconds
  // Add security headers
  const secureReq = req.clone({
    setHeaders: {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
      'Content-Security-Policy': [
        "default-src 'self'",
        "script-src 'self' 'wasm-unsafe-eval'",
        "style-src 'self' 'unsafe-inline'",
        "connect-src 'self' wss: https:",
        "img-src 'self' data: https:",
        "worker-src 'self'",
        "object-src 'none'",
        "base-uri 'self'",
      ].join('; ')
    }
  });
  return next(secureReq).pipe(
    timeout(REQUEST_TIMEOUT),
    catchError(error => {
      console.error('HTTP Security Error:', error);
      return throwError(() => error);
    })
  );
};