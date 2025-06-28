import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { importProvidersFrom } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterModule } from '@angular/router';
import { ServiceWorkerModule } from '@angular/service-worker';
import { environment } from './environments/environment';

// Angular Material Modules
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatTabsModule } from '@angular/material/tabs';
import { MatCardModule } from '@angular/material/card';
import { MatGridListModule } from '@angular/material/grid-list';
import { MatChipsModule } from '@angular/material/chips';

import { routes } from './app/app-routing.module';

bootstrapApplication(AppComponent, {
  providers: [
    importProvidersFrom(
      BrowserAnimationsModule,
      RouterModule.forRoot(routes, {
        enableTracing: false,
        preloadingStrategy: undefined
      }),
      
      // Angular Material
      MatToolbarModule,
      MatIconModule,
      MatButtonModule,
      MatMenuModule,
      MatTabsModule,
      MatCardModule,
      MatGridListModule,
      MatChipsModule,
      
      // Service Worker
      ServiceWorkerModule.register('ngsw-worker.js', {
        enabled: environment.production,
        registrationStrategy: 'registerWhenStable:30000'
      })
    )
  ]
}).catch(err => console.error(err));