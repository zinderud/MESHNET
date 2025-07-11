import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface EncryptedData {
  data: string;
  signature: string;
  iv: string;
  timestamp: number;
}

export interface KeyPair {
  publicKey: CryptoKey;
  privateKey: CryptoKey;
}

@Injectable({
  providedIn: 'root'
})
export class CryptoService {
  // Signals for reactive crypto state
  private _isInitialized = signal<boolean>(false);
  private _keyPair = signal<KeyPair | null>(null);
  private _symmetricKey = signal<CryptoKey | null>(null);

  // Computed crypto indicators
  isInitialized = computed(() => this._isInitialized());
  hasKeyPair = computed(() => this._keyPair() !== null);
  hasSymmetricKey = computed(() => this._symmetricKey() !== null);

  // Crypto events
  private initializationComplete$ = new BehaviorSubject<boolean>(false);

  constructor() {
    this.initializeCrypto();
  }

  private async initializeCrypto(): Promise<void> {
    try {
      // Generate RSA key pair for digital signatures
      const keyPair = await this.generateKeyPair();
      this._keyPair.set(keyPair);
      
      // Generate AES key for symmetric encryption
      const symmetricKey = await this.generateSymmetricKey();
      this._symmetricKey.set(symmetricKey);
      
      this._isInitialized.set(true);
      this.initializationComplete$.next(true);
      
      console.log('Cryptographic keys initialized successfully');
    } catch (error) {
      console.error('Failed to initialize cryptographic keys:', error);
      this._isInitialized.set(false);
      this.initializationComplete$.next(false);
    }
  }

  async encryptMessage(message: string): Promise<EncryptedData> {
    const symmetricKey = this._symmetricKey();
    const keyPair = this._keyPair();
    
    if (!symmetricKey || !keyPair) {
      throw new Error('Cryptographic keys not initialized');
    }

    try {
      // Convert message to ArrayBuffer
      const encoder = new TextEncoder();
      const data = encoder.encode(message);

      // Generate random IV
      const iv = crypto.getRandomValues(new Uint8Array(12));

      // Encrypt with AES-GCM
      const encryptedData = await crypto.subtle.encrypt(
        {
          name: 'AES-GCM',
          iv: iv
        },
        symmetricKey,
        data
      );

      // Convert to base64
      const encryptedBase64 = this.arrayBufferToBase64(encryptedData);
      const ivBase64 = this.arrayBufferToBase64(iv);

      // Create signature
      const signature = await this.signData(encryptedBase64);

      return {
        data: encryptedBase64,
        signature,
        iv: ivBase64,
        timestamp: Date.now()
      };
    } catch (error) {
      console.error('Encryption failed:', error);
      throw new Error('Failed to encrypt message');
    }
  }

  async decryptMessage(encryptedData: string, signature: string, iv?: string): Promise<string> {
    const symmetricKey = this._symmetricKey();
    const keyPair = this._keyPair();
    
    if (!symmetricKey || !keyPair) {
      throw new Error('Cryptographic keys not initialized');
    }

    try {
      // Verify signature first
      const isValid = await this.verifySignature(encryptedData, signature);
      if (!isValid) {
        throw new Error('Message signature verification failed');
      }

      // Convert from base64
      const encrypted = this.base64ToArrayBuffer(encryptedData);
      const ivBuffer = iv ? this.base64ToArrayBuffer(iv) : new Uint8Array(12);

      // Decrypt with AES-GCM
      const decryptedData = await crypto.subtle.decrypt(
        {
          name: 'AES-GCM',
          iv: ivBuffer
        },
        symmetricKey,
        encrypted
      );

      // Convert back to string
      const decoder = new TextDecoder();
      return decoder.decode(decryptedData);
    } catch (error) {
      console.error('Decryption failed:', error);
      throw new Error('Failed to decrypt message');
    }
  }

  async signData(data: string): Promise<string> {
    const keyPair = this._keyPair();
    if (!keyPair) {
      throw new Error('Key pair not initialized');
    }

    try {
      const encoder = new TextEncoder();
      const dataBuffer = encoder.encode(data);

      const signature = await crypto.subtle.sign(
        'RSASSA-PKCS1-v1_5',
        keyPair.privateKey,
        dataBuffer
      );

      return this.arrayBufferToBase64(signature);
    } catch (error) {
      console.error('Signing failed:', error);
      throw new Error('Failed to sign data');
    }
  }

  async verifySignature(data: string, signature: string, publicKey?: CryptoKey): Promise<boolean> {
    const keyPair = this._keyPair();
    const keyToUse = publicKey || keyPair?.publicKey;
    if (!keyToUse) {
      throw new Error('Public key not available');
    }

    try {
      const encoder = new TextEncoder();
      const dataBuffer = encoder.encode(data);
      const signatureBuffer = this.base64ToArrayBuffer(signature);

      return await crypto.subtle.verify(
        'RSASSA-PKCS1-v1_5',
        keyToUse,
        signatureBuffer,
        dataBuffer
      );
    } catch (error) {
      console.error('Signature verification failed:', error);
      return false;
    }
  }

  async generateSharedSecret(peerPublicKey: CryptoKey): Promise<CryptoKey> {
    const keyPair = this._keyPair();
    if (!keyPair) {
      throw new Error('Key pair not initialized');
    }

    try {
      // Generate ECDH shared secret
      const sharedSecret = await crypto.subtle.deriveBits(
        {
          name: 'ECDH',
          public: peerPublicKey
        },
        keyPair.privateKey,
        256
      );

      // Derive AES key from shared secret
      return await crypto.subtle.importKey(
        'raw',
        sharedSecret,
        { name: 'AES-GCM' },
        false,
        ['encrypt', 'decrypt']
      );
    } catch (error) {
      console.error('Shared secret generation failed:', error);
      throw new Error('Failed to generate shared secret');
    }
  }

  async exportPublicKey(): Promise<string> {
    const keyPair = this._keyPair();
    if (!keyPair) {
      throw new Error('Key pair not initialized');
    }

    try {
      const exported = await crypto.subtle.exportKey('spki', keyPair.publicKey);
      return this.arrayBufferToBase64(exported);
    } catch (error) {
      console.error('Public key export failed:', error);
      throw new Error('Failed to export public key');
    }
  }

  async importPublicKey(publicKeyData: string): Promise<CryptoKey> {
    try {
      const keyBuffer = this.base64ToArrayBuffer(publicKeyData);
      
      return await crypto.subtle.importKey(
        'spki',
        keyBuffer,
        {
          name: 'RSASSA-PKCS1-v1_5',
          hash: 'SHA-256'
        },
        true,
        ['verify']
      );
    } catch (error) {
      console.error('Public key import failed:', error);
      throw new Error('Failed to import public key');
    }
  }

  generateHash(data: string): Promise<string> {
    return new Promise(async (resolve, reject) => {
      try {
        const encoder = new TextEncoder();
        const dataBuffer = encoder.encode(data);
        
        const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
        const hashBase64 = this.arrayBufferToBase64(hashBuffer);
        
        resolve(hashBase64);
      } catch (error) {
        reject(error);
      }
    });
  }

  generateRandomId(length: number = 16): string {
    const array = new Uint8Array(length);
    crypto.getRandomValues(array);
    return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
  }

  // Observable for initialization status
  get onInitializationComplete$(): Observable<boolean> {
    return this.initializationComplete$.asObservable();
  }

  // Private helper methods
  private async generateKeyPair(): Promise<KeyPair> {
    const keyPair = await crypto.subtle.generateKey(
      {
        name: 'RSASSA-PKCS1-v1_5',
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: 'SHA-256'
      },
      true,
      ['sign', 'verify']
    );

    return {
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey
    };
  }

  private async generateSymmetricKey(): Promise<CryptoKey> {
    return await crypto.subtle.generateKey(
      {
        name: 'AES-GCM',
        length: 256
      },
      true,
      ['encrypt', 'decrypt']
    );
  }

  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  private base64ToArrayBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }
}