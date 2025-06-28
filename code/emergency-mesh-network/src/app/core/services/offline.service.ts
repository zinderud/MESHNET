import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, fromEvent, merge } from 'rxjs';
import { map, distinctUntilChanged, debounceTime } from 'rxjs/operators';

export interface OfflineData {
  key: string;
  data: any;
  timestamp: number;
  expiresAt?: number;
  priority: 'low' | 'normal' | 'high' | 'critical';
  syncStatus: 'pending' | 'synced' | 'failed';
}

export interface SyncQueue {
  id: string;
  type: 'message' | 'location' | 'emergency' | 'status';
  data: any;
  timestamp: number;
  retryCount: number;
  maxRetries: number;
  priority: 'low' | 'normal' | 'high' | 'critical';
}

@Injectable({
  providedIn: 'root'
})
export class OfflineService {
  // Signals for reactive state management
  private _isOnline = signal<boolean>(navigator.onLine);
  private _storageUsage = signal<number>(0);
  private _syncQueue = signal<SyncQueue[]>([]);
  private _lastSyncTime = signal<number>(0);

  // Computed signals
  isOnline = this._isOnline.asReadonly();
  isOffline = computed(() => !this._isOnline());
  storageUsage = this._storageUsage.asReadonly();
  syncQueue = this._syncQueue.asReadonly();
  pendingSyncItems = computed(() => this._syncQueue().filter(item => item.retryCount < item.maxRetries));
  lastSyncTime = this._lastSyncTime.asReadonly();

  // Subjects for events
  private onlineStatus$ = new BehaviorSubject<boolean>(navigator.onLine);
  private syncCompleted$ = new BehaviorSubject<{ success: number; failed: number }>({ success: 0, failed: 0 });

  // Storage configuration
  private readonly DB_NAME = 'EmergencyMeshDB';
  private readonly DB_VERSION = 1;
  private readonly STORES = {
    messages: 'messages',
    locations: 'locations',
    emergencies: 'emergencies',
    settings: 'settings',
    cache: 'cache'
  };

  private db?: IDBDatabase;

  constructor() {
    this.initializeOfflineService();
    this.setupNetworkMonitoring();
    this.setupStorageMonitoring();
  }

  private async initializeOfflineService(): Promise<void> {
    try {
      await this.initializeIndexedDB();
      await this.loadSyncQueue();
      this.startSyncProcessor();
      console.log('Offline service initialized successfully');
    } catch (error) {
      console.error('Failed to initialize offline service:', error);
    }
  }

  private setupNetworkMonitoring(): void {
    // Monitor online/offline status
    const online$ = fromEvent(window, 'online').pipe(map(() => true));
    const offline$ = fromEvent(window, 'offline').pipe(map(() => false));
    
    merge(online$, offline$).pipe(
      distinctUntilChanged(),
      debounceTime(1000)
    ).subscribe(isOnline => {
      this._isOnline.set(isOnline);
      this.onlineStatus$.next(isOnline);
      
      if (isOnline) {
        this.processSyncQueue();
      }
    });
  }

  private setupStorageMonitoring(): void {
    // Monitor storage usage
    setInterval(() => {
      this.updateStorageUsage();
    }, 30000);
  }

  // Public API Methods

  async storeData<T>(key: string, data: T, options?: {
    expiresIn?: number;
    priority?: 'low' | 'normal' | 'high' | 'critical';
    store?: string;
  }): Promise<boolean> {
    try {
      const store = options?.store || this.STORES.cache;
      const offlineData: OfflineData = {
        key,
        data,
        timestamp: Date.now(),
        expiresAt: options?.expiresIn ? Date.now() + options.expiresIn : undefined,
        priority: options?.priority || 'normal',
        syncStatus: 'pending'
      };

      await this.saveToIndexedDB(store, key, offlineData);
      this.updateStorageUsage();
      
      return true;
    } catch (error) {
      console.error('Failed to store data:', error);
      return false;
    }
  }

  async getData<T>(key: string, store?: string): Promise<T | null> {
    try {
      const storeName = store || this.STORES.cache;
      const offlineData = await this.getFromIndexedDB(storeName, key) as OfflineData;
      
      if (!offlineData) {
        return null;
      }

      // Check expiration
      if (offlineData.expiresAt && Date.now() > offlineData.expiresAt) {
        await this.removeData(key, storeName);
        return null;
      }

      return offlineData.data as T;
    } catch (error) {
      console.error('Failed to get data:', error);
      return null;
    }
  }

  async removeData(key: string, store?: string): Promise<boolean> {
    try {
      const storeName = store || this.STORES.cache;
      await this.deleteFromIndexedDB(storeName, key);
      this.updateStorageUsage();
      return true;
    } catch (error) {
      console.error('Failed to remove data:', error);
      return false;
    }
  }

  async getAllData<T>(store?: string): Promise<T[]> {
    try {
      const storeName = store || this.STORES.cache;
      const allData = await this.getAllFromIndexedDB(storeName);
      
      return allData
        .filter((item: OfflineData) => {
          // Filter out expired items
          return !item.expiresAt || Date.now() <= item.expiresAt;
        })
        .map((item: OfflineData) => item.data as T);
    } catch (error) {
      console.error('Failed to get all data:', error);
      return [];
    }
  }

  async clearStore(store?: string): Promise<boolean> {
    try {
      const storeName = store || this.STORES.cache;
      await this.clearIndexedDBStore(storeName);
      this.updateStorageUsage();
      return true;
    } catch (error) {
      console.error('Failed to clear store:', error);
      return false;
    }
  }

  async addToSyncQueue(item: Omit<SyncQueue, 'id' | 'retryCount'>): Promise<string> {
    const syncItem: SyncQueue = {
      id: this.generateSyncId(),
      retryCount: 0,
      ...item
    };

    const queue = this._syncQueue();
    this._syncQueue.set([...queue, syncItem]);
    
    await this.saveSyncQueue();

    // Try to sync immediately if online
    if (this._isOnline()) {
      this.processSyncQueue();
    }

    return syncItem.id;
  }

  async removeFromSyncQueue(id: string): Promise<void> {
    const queue = this._syncQueue().filter(item => item.id !== id);
    this._syncQueue.set(queue);
    await this.saveSyncQueue();
  }

  async processSyncQueue(): Promise<void> {
    if (!this._isOnline()) {
      console.log('Cannot sync while offline');
      return;
    }

    const queue = this.pendingSyncItems();
    let successCount = 0;
    let failedCount = 0;

    for (const item of queue) {
      try {
        const success = await this.syncItem(item);
        if (success) {
          await this.removeFromSyncQueue(item.id);
          successCount++;
        } else {
          await this.incrementRetryCount(item.id);
          failedCount++;
        }
      } catch (error) {
        console.error('Sync failed for item:', item.id, error);
        await this.incrementRetryCount(item.id);
        failedCount++;
      }
    }

    this._lastSyncTime.set(Date.now());
    this.syncCompleted$.next({ success: successCount, failed: failedCount });
  }

  async cacheResource(url: string, data: any, maxAge?: number): Promise<boolean> {
    const cacheKey = `cache_${this.hashString(url)}`;
    return this.storeData(cacheKey, {
      url,
      data,
      cachedAt: Date.now()
    }, {
      expiresIn: maxAge || 3600000, // 1 hour default
      priority: 'low',
      store: this.STORES.cache
    });
  }

  async getCachedResource<T>(url: string): Promise<T | null> {
    const cacheKey = `cache_${this.hashString(url)}`;
    const cached = await this.getData<{ url: string; data: T; cachedAt: number }>(cacheKey, this.STORES.cache);
    return cached ? cached.data : null;
  }

  async getStorageInfo(): Promise<{
    used: number;
    available: number;
    quota: number;
    percentage: number;
  }> {
    try {
      if ('storage' in navigator && 'estimate' in navigator.storage) {
        const estimate = await navigator.storage.estimate();
        const used = estimate.usage || 0;
        const quota = estimate.quota || 0;
        const available = quota - used;
        const percentage = quota > 0 ? (used / quota) * 100 : 0;

        return { used, available, quota, percentage };
      }
    } catch (error) {
      console.error('Failed to get storage info:', error);
    }

    return { used: 0, available: 0, quota: 0, percentage: 0 };
  }

  async cleanupExpiredData(): Promise<number> {
    let cleanedCount = 0;

    for (const storeName of Object.values(this.STORES)) {
      try {
        const allData = await this.getAllFromIndexedDB(storeName);
        
        for (const item of allData) {
          if (item.expiresAt && Date.now() > item.expiresAt) {
            await this.deleteFromIndexedDB(storeName, item.key);
            cleanedCount++;
          }
        }
      } catch (error) {
        console.error(`Failed to cleanup store ${storeName}:`, error);
      }
    }

    this.updateStorageUsage();
    return cleanedCount;
  }

  // Event Observables
  get onOnline$(): Observable<boolean> {
    return this.onlineStatus$.pipe(filter(status => status === true));
  }

  get onOffline$(): Observable<boolean> {
    return this.onlineStatus$.pipe(filter(status => status === false));
  }

  get onSyncCompleted$(): Observable<{ success: number; failed: number }> {
    return this.syncCompleted$.asObservable();
  }

  // Private Methods

  private async initializeIndexedDB(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.DB_NAME, this.DB_VERSION);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Create object stores
        Object.values(this.STORES).forEach(storeName => {
          if (!db.objectStoreNames.contains(storeName)) {
            const store = db.createObjectStore(storeName, { keyPath: 'key' });
            store.createIndex('timestamp', 'timestamp', { unique: false });
            store.createIndex('priority', 'priority', { unique: false });
          }
        });
      };
    });
  }

  private async saveToIndexedDB(storeName: string, key: string, data: any): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.put({ key, ...data });

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  private async getFromIndexedDB(storeName: string, key: string): Promise<any> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.get(key);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  private async deleteFromIndexedDB(storeName: string, key: string): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.delete(key);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  private async getAllFromIndexedDB(storeName: string): Promise<any[]> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readonly');
      const store = transaction.objectStore(storeName);
      const request = store.getAll();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
    });
  }

  private async clearIndexedDBStore(storeName: string): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([storeName], 'readwrite');
      const store = transaction.objectStore(storeName);
      const request = store.clear();

      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve();
    });
  }

  private async loadSyncQueue(): Promise<void> {
    try {
      const queueData = await this.getData<SyncQueue[]>('sync_queue', this.STORES.settings);
      if (queueData) {
        this._syncQueue.set(queueData);
      }
    } catch (error) {
      console.error('Failed to load sync queue:', error);
    }
  }

  private async saveSyncQueue(): Promise<void> {
    try {
      await this.storeData('sync_queue', this._syncQueue(), {
        store: this.STORES.settings,
        priority: 'high'
      });
    } catch (error) {
      console.error('Failed to save sync queue:', error);
    }
  }

  private async syncItem(item: SyncQueue): Promise<boolean> {
    // This would implement actual sync logic based on item type
    // For now, we'll simulate sync success/failure
    
    console.log('Syncing item:', item.type, item.id);
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000));
    
    // Simulate success rate based on priority
    const successRate = {
      critical: 0.95,
      high: 0.9,
      normal: 0.85,
      low: 0.8
    }[item.priority];

    return Math.random() < successRate;
  }

  private async incrementRetryCount(id: string): Promise<void> {
    const queue = this._syncQueue();
    const itemIndex = queue.findIndex(item => item.id === id);
    
    if (itemIndex !== -1) {
      const updatedQueue = [...queue];
      updatedQueue[itemIndex] = {
        ...updatedQueue[itemIndex],
        retryCount: updatedQueue[itemIndex].retryCount + 1
      };
      this._syncQueue.set(updatedQueue);
      await this.saveSyncQueue();
    }
  }

  private startSyncProcessor(): void {
    // Process sync queue every 30 seconds when online
    setInterval(() => {
      if (this._isOnline() && this.pendingSyncItems().length > 0) {
        this.processSyncQueue();
      }
    }, 30000);

    // Cleanup expired data every hour
    setInterval(() => {
      this.cleanupExpiredData();
    }, 3600000);
  }

  private async updateStorageUsage(): Promise<void> {
    try {
      const storageInfo = await this.getStorageInfo();
      this._storageUsage.set(storageInfo.percentage);
    } catch (error) {
      console.error('Failed to update storage usage:', error);
    }
  }

  private generateSyncId(): string {
    return `sync_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private hashString(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash).toString(36);
  }
}