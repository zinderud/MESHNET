import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { retry, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';

export const ErrorInterceptor: HttpInterceptorFn = (req, next) => {
  const snackBar = inject(MatSnackBar);
  return next(req).pipe(
    retry(2),
    catchError((error: HttpErrorResponse) => {
      let errorMessage = 'Bilinmeyen bir hata oluştu';
      if (error.error instanceof ErrorEvent) {
        errorMessage = `İstemci hatası: ${error.error.message}`;
      } else {
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
      snackBar.open(errorMessage, 'Kapat', { duration: 5000 });
      return throwError(() => error);
    })
  );
};