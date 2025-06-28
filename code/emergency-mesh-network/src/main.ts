import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

// Angular 20 Bootstrap with enhanced error handling
bootstrapApplication(AppComponent, appConfig)
  .then(() => {
    console.log('🚀 Angular 20 Emergency Mesh Network başlatıldı!');
    
    // Performance monitoring
    if ('performance' in window && 'measure' in performance) {
      performance.mark('app-bootstrap-end');
      performance.measure('app-bootstrap', 'app-bootstrap-start', 'app-bootstrap-end');
    }
  })
  .catch((err) => {
    console.error('❌ Uygulama başlatma hatası:', err);
    
    // Show user-friendly error message
    document.body.innerHTML = `
      <div style="
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        height: 100vh;
        font-family: 'Roboto', sans-serif;
        text-align: center;
        padding: 20px;
        background: linear-gradient(135deg, #ff5722, #f44336);
        color: white;
      ">
        <h1 style="font-size: 2.5rem; margin-bottom: 1rem;">🚨 Acil Durum Mesh Network</h1>
        <p style="font-size: 1.2rem; margin-bottom: 2rem;">Uygulama başlatılamadı</p>
        <p style="margin-bottom: 2rem;">Lütfen sayfayı yenileyin veya tarayıcınızı güncelleyin</p>
        <button onclick="window.location.reload()" style="
          background: white;
          color: #f44336;
          border: none;
          padding: 12px 24px;
          border-radius: 8px;
          font-size: 1rem;
          font-weight: bold;
          cursor: pointer;
          transition: transform 0.2s ease;
        " onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
          Sayfayı Yenile
        </button>
        <p style="margin-top: 2rem; font-size: 0.9rem; opacity: 0.8;">
          Acil durum için: <strong>112</strong>
        </p>
      </div>
    `;
  });

// Performance mark for bootstrap start
if ('performance' in window && 'mark' in performance) {
  performance.mark('app-bootstrap-start');
}