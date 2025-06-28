import { Injectable, inject } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { MatSnackBar } from '@angular/material/snack-bar';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  private snackBar = inject(MatSnackBar);

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      retry(2), // Retry failed requests twice
      catchError((error: HttpErrorResponse) => {
        let errorMessage = 'Bilinmeyen bir hata oluştu';

        if (error.error instanceof ErrorEvent) {
          // Client-side error
          errorMessage = `İstemci hatası: ${error.error.message}`;
        } else {
          // Server-side error
          switch (error.status) {
            case 0:
              errorMessage = 'Ağ bağlantısı yok';
              break;
            case 401:
              errorMessage = 'Yetkisiz erişim';
              break;
            case 403:
              errorMessage = 'Erişim reddedildi';
              break;
            case 404:
              errorMessage = 'Kaynak bulunamadı';
              break;
            case 500:
              errorMessage = 'Sunucu hatası';
              break;
            default:
              errorMessage = `Hata kodu: ${error.status}`;
          }
        }

        // Show user-friendly error message
        this.snackBar.open(errorMessage, 'Kapat', {
          duration: 5000,
          panelClass: ['error-snackbar']
        });

        // Log error for debugging
        console.error('HTTP Error:', {
          message: errorMessage,
          status: error.status,
          url: req.url,
          timestamp: new Date().toISOString()
        });

        return throwError(() => error);
      })
    );
  }
}