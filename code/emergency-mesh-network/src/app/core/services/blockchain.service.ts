import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';
import { CryptoService } from './crypto.service';
import { AnalyticsService } from './analytics.service';
import { WebrtcService } from './webrtc.service';
import { MeshNetworkImplementationService } from './mesh-network-implementation.service';

export interface Block {
  index: number;
  timestamp: number;
  transactions: Transaction[];
  previousHash: string;
  hash: string;
  nonce: number;
  validator: string;
  signature: string;
}

export interface Transaction {
  id: string;
  type: 'message' | 'emergency' | 'location' | 'network' | 'system';
  sender: string;
  recipient?: string;
  data: any;
  timestamp: number;
  signature: string;
  hash: string;
}

export interface BlockchainState {
  chain: Block[];
  pendingTransactions: Transaction[];
  validators: Map<string, number>; // nodeId -> reputation
  lastBlockTime: number;
  difficulty: number;
}

export interface BlockchainStats {
  blockCount: number;
  transactionCount: number;
  validatorCount: number;
  averageBlockTime: number;
  lastBlockTime: number;
  pendingTransactions: number;
}

@Injectable({
  providedIn: 'root'
})
export class BlockchainService {
  private cryptoService = inject(CryptoService);
  private analyticsService = inject(AnalyticsService);
  private webrtcService = inject(WebrtcService);
  private meshService = inject(MeshNetworkImplementationService);

  // Signals for reactive blockchain state
  private _blockchainState = signal<BlockchainState>({
    chain: [],
    pendingTransactions: [],
    validators: new Map(),
    lastBlockTime: 0,
    difficulty: 2
  });

  private _isValidator = signal<boolean>(false);
  private _isValidating = signal<boolean>(false);
  private _validatorReputation = signal<number>(0);
  private _syncStatus = signal<'syncing' | 'synced' | 'error'>('syncing');

  // Computed blockchain indicators
  blockchainState = this._blockchainState.asReadonly();
  isValidator = this._isValidator.asReadonly();
  isValidating = this._isValidating.asReadonly();
  validatorReputation = this._validatorReputation.asReadonly();
  syncStatus = this._syncStatus.asReadonly();

  blockCount = computed(() => this._blockchainState().chain.length);
  pendingTransactionCount = computed(() => this._blockchainState().pendingTransactions.length);
  validatorCount = computed(() => this._blockchainState().validators.size);
  
  blockchainStats = computed(() => {
    const state = this._blockchainState();
    const blockTimes = state.chain.slice(1).map((block, i) => 
      block.timestamp - state.chain[i].timestamp
    );
    
    const avgBlockTime = blockTimes.length > 0 
      ? blockTimes.reduce((sum, time) => sum + time, 0) / blockTimes.length 
      : 0;
    
    const transactionCount = state.chain.reduce(
      (sum, block) => sum + block.transactions.length, 0
    );
    
    return {
      blockCount: state.chain.length,
      transactionCount,
      validatorCount: state.validators.size,
      averageBlockTime: avgBlockTime,
      lastBlockTime: state.lastBlockTime,
      pendingTransactions: state.pendingTransactions.length
    };
  });

  // Blockchain events
  private blockAdded$ = new Subject<Block>();
  private transactionAdded$ = new Subject<Transaction>();
  private blockchainSynced$ = new Subject<number>(); // Number of blocks synced
  private validatorStatusChanged$ = new Subject<boolean>();
  private consensusError$ = new Subject<string>();

  private destroy$ = new Subject<void>();

  constructor() {
    this.initializeBlockchain();
    this.setupNetworkListeners();
    this.startBlockchainMaintenance();
  }

  private initializeBlockchain(): void {
    // Create genesis block if chain is empty
    const state = this._blockchainState();
    if (state.chain.length === 0) {
      const genesisBlock = this.createGenesisBlock();
      this._blockchainState.update(state => ({
        ...state,
        chain: [genesisBlock],
        lastBlockTime: genesisBlock.timestamp
      }));
    }

    // Determine if this node should be a validator
    this.evaluateValidatorEligibility();
    
    console.log('Blockchain service initialized');
  }

  private setupNetworkListeners(): void {
    // Listen for blockchain messages from WebRTC
    this.webrtcService.onDataReceived$.pipe(
      filter(data => data.type === 'mesh_routing')
    ).subscribe(data => {
      this.handleBlockchainMessage(data.payload);
    });

    // Listen for blockchain messages from mesh network
    this.meshService.onMeshMessageRouted$.pipe(
      filter(message => message.type === 'broadcast' && message.payload?.type === 'blockchain')
    ).subscribe(message => {
      this.handleBlockchainMessage(message.payload.data);
    });
  }

  private startBlockchainMaintenance(): void {
    // Periodically check for pending transactions and create new blocks
    interval(10000).pipe(
      takeUntil(this.destroy$),
      filter(() => this._isValidator() && !this._isValidating())
    ).subscribe(() => {
      this.processPendingTransactions();
    });

    // Periodically sync blockchain with other nodes
    interval(60000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.syncBlockchain();
    });

    // Periodically evaluate validator eligibility
    interval(300000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.evaluateValidatorEligibility();
    });
  }

  // Public API Methods
  async addTransaction(
    type: Transaction['type'],
    data: any,
    recipient?: string
  ): Promise<string> {
    try {
      const sender = await this.getNodeId();
      
      // Create transaction object
      const transaction: Omit<Transaction, 'hash' | 'signature'> = {
        id: this.generateTransactionId(),
        type,
        sender,
        recipient,
        data,
        timestamp: Date.now()
      };
      
      // Sign transaction
      const signature = await this.cryptoService.signData(JSON.stringify({
        id: transaction.id,
        type: transaction.type,
        sender: transaction.sender,
        recipient: transaction.recipient,
        data: transaction.data,
        timestamp: transaction.timestamp
      }));
      
      // Calculate hash
      const hash = await this.cryptoService.generateHash(JSON.stringify({
        ...transaction,
        signature
      }));
      
      const fullTransaction: Transaction = {
        ...transaction,
        signature,
        hash
      };
      
      // Add to pending transactions
      this._blockchainState.update(state => ({
        ...state,
        pendingTransactions: [...state.pendingTransactions, fullTransaction]
      }));
      
      // Broadcast transaction to network
      this.broadcastTransaction(fullTransaction);
      
      // Emit event
      this.transactionAdded$.next(fullTransaction);
      
      return fullTransaction.id;
    } catch (error) {
      console.error('Failed to add transaction:', error);
      throw error;
    }
  }

  async becomeValidator(): Promise<boolean> {
    try {
      // Check if node meets requirements
      const eligible = await this.checkValidatorEligibility();
      
      if (!eligible) {
        console.warn('Node is not eligible to become a validator');
        return false;
      }
      
      // Register as validator
      const nodeId = await this.getNodeId();
      
      this._blockchainState.update(state => {
        const validators = new Map(state.validators);
        validators.set(nodeId, 100); // Initial reputation
        
        return {
          ...state,
          validators
        };
      });
      
      this._isValidator.set(true);
      this._validatorReputation.set(100);
      
      // Broadcast validator registration
      this.broadcastValidatorRegistration();
      
      // Emit event
      this.validatorStatusChanged$.next(true);
      
      return true;
    } catch (error) {
      console.error('Failed to become validator:', error);
      return false;
    }
  }

  async stopValidating(): Promise<boolean> {
    try {
      if (!this._isValidator()) {
        return false;
      }
      
      const nodeId = await this.getNodeId();
      
      this._blockchainState.update(state => {
        const validators = new Map(state.validators);
        validators.delete(nodeId);
        
        return {
          ...state,
          validators
        };
      });
      
      this._isValidator.set(false);
      this._isValidating.set(false);
      
      // Broadcast validator deregistration
      this.broadcastValidatorDeregistration();
      
      // Emit event
      this.validatorStatusChanged$.next(false);
      
      return true;
    } catch (error) {
      console.error('Failed to stop validating:', error);
      return false;
    }
  }

  getBlock(index: number): Block | null {
    const chain = this._blockchainState().chain;
    return index >= 0 && index < chain.length ? chain[index] : null;
  }

  getLatestBlock(): Block | null {
    const chain = this._blockchainState().chain;
    return chain.length > 0 ? chain[chain.length - 1] : null;
  }

  getTransaction(transactionId: string): Transaction | null {
    // Check pending transactions
    const pendingTransaction = this._blockchainState().pendingTransactions.find(
      tx => tx.id === transactionId
    );
    
    if (pendingTransaction) {
      return pendingTransaction;
    }
    
    // Check transactions in blocks
    for (const block of this._blockchainState().chain) {
      const transaction = block.transactions.find(tx => tx.id === transactionId);
      if (transaction) {
        return transaction;
      }
    }
    
    return null;
  }

  getTransactionsByType(type: Transaction['type']): Transaction[] {
    const transactions: Transaction[] = [];
    
    // Add transactions from blocks
    for (const block of this._blockchainState().chain) {
      transactions.push(...block.transactions.filter(tx => tx.type === type));
    }
    
    // Add pending transactions
    transactions.push(
      ...this._blockchainState().pendingTransactions.filter(tx => tx.type === type)
    );
    
    return transactions;
  }

  getTransactionsByAddress(address: string): Transaction[] {
    const transactions: Transaction[] = [];
    
    // Add transactions from blocks
    for (const block of this._blockchainState().chain) {
      transactions.push(
        ...block.transactions.filter(
          tx => tx.sender === address || tx.recipient === address
        )
      );
    }
    
    // Add pending transactions
    transactions.push(
      ...this._blockchainState().pendingTransactions.filter(
        tx => tx.sender === address || tx.recipient === address
      )
    );
    
    return transactions;
  }

  verifyBlockchain(): boolean {
    const chain = this._blockchainState().chain;
    
    // Check each block
    for (let i = 1; i < chain.length; i++) {
      const currentBlock = chain[i];
      const previousBlock = chain[i - 1];
      
      // Verify block hash
      if (currentBlock.previousHash !== previousBlock.hash) {
        console.error(`Invalid previous hash in block ${i}`);
        return false;
      }
      
      // Verify block hash
      const calculatedHash = this.calculateBlockHash(
        currentBlock.index,
        currentBlock.timestamp,
        currentBlock.transactions,
        currentBlock.previousHash,
        currentBlock.nonce,
        currentBlock.validator
      );
      
      if (calculatedHash !== currentBlock.hash) {
        console.error(`Invalid hash in block ${i}`);
        return false;
      }
      
      // Verify block signature
      const isSignatureValid = this.verifyBlockSignature(currentBlock);
      if (!isSignatureValid) {
        console.error(`Invalid signature in block ${i}`);
        return false;
      }
    }
    
    return true;
  }

  // Event Observables
  get onBlockAdded$(): Observable<Block> {
    return this.blockAdded$.asObservable();
  }

  get onTransactionAdded$(): Observable<Transaction> {
    return this.transactionAdded$.asObservable();
  }

  get onBlockchainSynced$(): Observable<number> {
    return this.blockchainSynced$.asObservable();
  }

  get onValidatorStatusChanged$(): Observable<boolean> {
    return this.validatorStatusChanged$.asObservable();
  }

  get onConsensusError$(): Observable<string> {
    return this.consensusError$.asObservable();
  }

  // Private Methods
  private createGenesisBlock(): Block {
    const timestamp = Date.now();
    const transactions: Transaction[] = [{
      id: 'genesis_transaction',
      type: 'system',
      sender: 'genesis',
      data: { message: 'Genesis Block for Emergency Mesh Network' },
      timestamp,
      signature: 'genesis_signature',
      hash: 'genesis_hash'
    }];
    
    const hash = this.calculateBlockHash(0, timestamp, transactions, '0', 0, 'genesis');
    
    return {
      index: 0,
      timestamp,
      transactions,
      previousHash: '0',
      hash,
      nonce: 0,
      validator: 'genesis',
      signature: 'genesis_signature'
    };
  }

  private async processPendingTransactions(): Promise<void> {
    const state = this._blockchainState();
    const pendingTransactions = state.pendingTransactions;
    
    // Check if there are enough pending transactions
    if (pendingTransactions.length < 1) {
      return;
    }
    
    try {
      this._isValidating.set(true);
      
      // Get latest block
      const latestBlock = this.getLatestBlock();
      if (!latestBlock) {
        throw new Error('No blocks in chain');
      }
      
      // Create new block
      const newBlock = await this.createNewBlock(latestBlock, pendingTransactions);
      
      // Add block to chain
      this._blockchainState.update(state => ({
        ...state,
        chain: [...state.chain, newBlock],
        pendingTransactions: [],
        lastBlockTime: newBlock.timestamp
      }));
      
      // Broadcast new block
      this.broadcastNewBlock(newBlock);
      
      // Emit event
      this.blockAdded$.next(newBlock);
      
      this.analyticsService.trackEvent('system_event', 'blockchain', 'block_created', undefined, newBlock.transactions.length);
    } catch (error) {
      console.error('Failed to process pending transactions:', error);
      this.consensusError$.next(error.message);
    } finally {
      this._isValidating.set(false);
    }
  }

  private async createNewBlock(previousBlock: Block, transactions: Transaction[]): Promise<Block> {
    const nodeId = await this.getNodeId();
    const index = previousBlock.index + 1;
    const timestamp = Date.now();
    const previousHash = previousBlock.hash;
    
    // Proof of Authority - no mining needed
    const nonce = 0;
    
    // Calculate block hash
    const hash = this.calculateBlockHash(
      index,
      timestamp,
      transactions,
      previousHash,
      nonce,
      nodeId
    );
    
    // Sign the block
    const signature = await this.cryptoService.signData(hash);
    
    return {
      index,
      timestamp,
      transactions,
      previousHash,
      hash,
      nonce,
      validator: nodeId,
      signature
    };
  }

  private calculateBlockHash(
    index: number,
    timestamp: number,
    transactions: Transaction[],
    previousHash: string,
    nonce: number,
    validator: string
  ): string {
    const data = index + timestamp + JSON.stringify(transactions) + previousHash + nonce + validator;
    return this.sha256(data);
  }

  private sha256(data: string): string {
    // Simple hash function for demo purposes
    // In a real implementation, use a proper crypto library
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(16);
  }

  private async verifyBlockSignature(block: Block): Promise<boolean> {
    try {
      // For genesis block, always return true
      if (block.index === 0) {
        return true;
      }
      
      // Get validator's public key
      // In a real implementation, you would retrieve this from a key store
      const publicKey = await this.getPublicKeyForNode(block.validator);
      
      if (!publicKey) {
        console.warn(`Public key not found for validator ${block.validator}`);
        return false;
      }
      
      // Verify signature
      return await this.cryptoService.verifySignature(block.hash, block.signature, publicKey);
    } catch (error) {
      console.error('Failed to verify block signature:', error);
      return false;
    }
  }

  private async getPublicKeyForNode(nodeId: string): Promise<any> {
    // In a real implementation, you would retrieve this from a key store
    // For demo purposes, we'll return a dummy key
    return 'dummy_public_key';
  }

  private async syncBlockchain(): Promise<void> {
    try {
      this._syncStatus.set('syncing');
      
      // Request blockchain from peers
      const peerChains = await this.requestBlockchainFromPeers();
      
      if (peerChains.length === 0) {
        console.log('No peer chains received');
        this._syncStatus.set('synced');
        return;
      }
      
      // Find the longest valid chain
      let longestChain: Block[] | null = null;
      let maxLength = this._blockchainState().chain.length;
      
      for (const chain of peerChains) {
        if (chain.length > maxLength && this.isValidChain(chain)) {
          longestChain = chain;
          maxLength = chain.length;
        }
      }
      
      // Replace our chain if we found a longer valid chain
      if (longestChain) {
        this._blockchainState.update(state => ({
          ...state,
          chain: longestChain!,
          lastBlockTime: longestChain![longestChain!.length - 1].timestamp
        }));
        
        const syncedBlocks = longestChain.length - this._blockchainState().chain.length;
        this.blockchainSynced$.next(syncedBlocks);
        
        this.analyticsService.trackEvent('system_event', 'blockchain', 'synced', undefined, syncedBlocks);
      }
      
      this._syncStatus.set('synced');
    } catch (error) {
      console.error('Failed to sync blockchain:', error);
      this._syncStatus.set('error');
    }
  }

  private async requestBlockchainFromPeers(): Promise<Block[][]> {
    const peerChains: Block[][] = [];
    
    // Request blockchain from WebRTC peers
    const webrtcPeers = this.webrtcService.getConnectedPeers();
    
    for (const peer of webrtcPeers) {
      try {
        const response = await this.webrtcService.sendData(peer.id, {
          type: 'mesh_routing',
          payload: {
            action: 'get_chain'
          },
          priority: 'normal'
        });
        
        // In a real implementation, you would handle the response
        // For demo purposes, we'll just add a dummy chain
        peerChains.push(this._blockchainState().chain);
      } catch (error) {
        console.error(`Failed to request blockchain from peer ${peer.id}:`, error);
      }
    }
    
    return peerChains;
  }

  private isValidChain(chain: Block[]): boolean {
    // Check if chain is valid
    if (chain.length === 0) {
      return false;
    }
    
    // Check genesis block
    if (JSON.stringify(chain[0]) !== JSON.stringify(this.createGenesisBlock())) {
      return false;
    }
    
    // Check each block
    for (let i = 1; i < chain.length; i++) {
      const currentBlock = chain[i];
      const previousBlock = chain[i - 1];
      
      // Verify block hash
      if (currentBlock.previousHash !== previousBlock.hash) {
        return false;
      }
      
      // Verify block hash
      const calculatedHash = this.calculateBlockHash(
        currentBlock.index,
        currentBlock.timestamp,
        currentBlock.transactions,
        currentBlock.previousHash,
        currentBlock.nonce,
        currentBlock.validator
      );
      
      if (calculatedHash !== currentBlock.hash) {
        return false;
      }
    }
    
    return true;
  }

  private async evaluateValidatorEligibility(): Promise<void> {
    const eligible = await this.checkValidatorEligibility();
    
    if (eligible && !this._isValidator()) {
      await this.becomeValidator();
    } else if (!eligible && this._isValidator()) {
      await this.stopValidating();
    }
  }

  private async checkValidatorEligibility(): Promise<boolean> {
    // Check if node meets requirements to be a validator
    // In a real implementation, this would check things like:
    // - Node uptime
    // - Node resources
    // - Node reputation
    // - Stake (if using Proof of Stake)
    
    // For demo purposes, we'll use a simple check
    const nodeId = await this.getNodeId();
    const isCoordinator = this.meshService.localMeshNode()?.type === 'coordinator';
    const isRelay = this.meshService.localMeshNode()?.type === 'relay';
    
    return isCoordinator || isRelay;
  }

  private async broadcastTransaction(transaction: Transaction): Promise<void> {
    try {
      // Broadcast to WebRTC peers
      await this.webrtcService.broadcastData({
        type: 'mesh_routing',
        payload: {
          action: 'new_transaction',
          transaction
        },
        priority: transaction.type === 'emergency' ? 'emergency' : 'normal'
      });
      
      // Broadcast to mesh network
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: transaction.type === 'emergency' ? 'emergency' : 'normal',
        payload: {
          type: 'blockchain',
          data: {
            action: 'new_transaction',
            transaction
          }
        },
        source: await this.getNodeId(),
        ttl: 5
      });
    } catch (error) {
      console.error('Failed to broadcast transaction:', error);
    }
  }

  private async broadcastNewBlock(block: Block): Promise<void> {
    try {
      // Broadcast to WebRTC peers
      await this.webrtcService.broadcastData({
        type: 'mesh_routing',
        payload: {
          action: 'new_block',
          block
        },
        priority: 'high'
      });
      
      // Broadcast to mesh network
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: 'high',
        payload: {
          type: 'blockchain',
          data: {
            action: 'new_block',
            block
          }
        },
        source: await this.getNodeId(),
        ttl: 10
      });
    } catch (error) {
      console.error('Failed to broadcast new block:', error);
    }
  }

  private async broadcastValidatorRegistration(): Promise<void> {
    try {
      const nodeId = await this.getNodeId();
      
      // Broadcast to WebRTC peers
      await this.webrtcService.broadcastData({
        type: 'mesh_routing',
        payload: {
          action: 'validator_registration',
          nodeId
        },
        priority: 'normal'
      });
      
      // Broadcast to mesh network
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: 'normal',
        payload: {
          type: 'blockchain',
          data: {
            action: 'validator_registration',
            nodeId
          }
        },
        source: nodeId,
        ttl: 5
      });
    } catch (error) {
      console.error('Failed to broadcast validator registration:', error);
    }
  }

  private async broadcastValidatorDeregistration(): Promise<void> {
    try {
      const nodeId = await this.getNodeId();
      
      // Broadcast to WebRTC peers
      await this.webrtcService.broadcastData({
        type: 'mesh_routing',
        payload: {
          action: 'validator_deregistration',
          nodeId
        },
        priority: 'normal'
      });
      
      // Broadcast to mesh network
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: 'normal',
        payload: {
          type: 'blockchain',
          data: {
            action: 'validator_deregistration',
            nodeId
          }
        },
        source: nodeId,
        ttl: 5
      });
    } catch (error) {
      console.error('Failed to broadcast validator deregistration:', error);
    }
  }

  private handleBlockchainMessage(payload: any): void {
    if (!payload || !payload.action) {
      console.warn('Invalid blockchain message:', payload);
      return;
    }
    
    switch (payload.action) {
      case 'new_transaction':
        this.handleNewTransaction(payload.transaction);
        break;
      case 'new_block':
        this.handleNewBlock(payload.block);
        break;
      case 'get_chain':
        this.handleGetChain(payload.sender);
        break;
      case 'chain_response':
        this.handleChainResponse(payload.chain, payload.sender);
        break;
      case 'validator_registration':
        this.handleValidatorRegistration(payload.nodeId);
        break;
      case 'validator_deregistration':
        this.handleValidatorDeregistration(payload.nodeId);
        break;
      default:
        console.warn('Unknown blockchain action:', payload.action);
    }
  }

  private handleNewTransaction(transaction: Transaction): void {
    // Verify transaction
    if (!this.verifyTransaction(transaction)) {
      console.warn('Invalid transaction received:', transaction);
      return;
    }
    
    // Check if transaction already exists
    const exists = this.transactionExists(transaction.id);
    if (exists) {
      return;
    }
    
    // Add to pending transactions
    this._blockchainState.update(state => ({
      ...state,
      pendingTransactions: [...state.pendingTransactions, transaction]
    }));
    
    // Emit event
    this.transactionAdded$.next(transaction);
    
    // If validator, process transactions
    if (this._isValidator() && !this._isValidating() && 
        this._blockchainState().pendingTransactions.length >= 5) {
      this.processPendingTransactions();
    }
  }

  private handleNewBlock(block: Block): void {
    // Verify block
    if (!this.verifyBlock(block)) {
      console.warn('Invalid block received:', block);
      return;
    }
    
    // Check if block already exists
    const exists = this._blockchainState().chain.some(b => b.hash === block.hash);
    if (exists) {
      return;
    }
    
    // Check if block index is next in sequence
    const latestBlock = this.getLatestBlock();
    if (!latestBlock || block.index !== latestBlock.index + 1) {
      console.warn('Block index out of sequence:', block.index);
      this.syncBlockchain();
      return;
    }
    
    // Add block to chain
    this._blockchainState.update(state => ({
      ...state,
      chain: [...state.chain, block],
      lastBlockTime: block.timestamp
    }));
    
    // Remove transactions that are now in the block
    this.removeConfirmedTransactions(block.transactions);
    
    // Emit event
    this.blockAdded$.next(block);
    
    // Update validator reputation
    this.updateValidatorReputation(block.validator, 1);
  }

  private handleGetChain(sender: string): void {
    // Send chain to requester
    this.sendChainResponse(sender);
  }

  private handleChainResponse(chain: Block[], sender: string): void {
    // Validate chain
    if (!this.isValidChain(chain)) {
      console.warn('Invalid chain received from:', sender);
      return;
    }
    
    // Check if chain is longer than ours
    if (chain.length <= this._blockchainState().chain.length) {
      return;
    }
    
    // Replace our chain
    this._blockchainState.update(state => ({
      ...state,
      chain,
      lastBlockTime: chain[chain.length - 1].timestamp
    }));
    
    // Emit event
    this.blockchainSynced$.next(chain.length - this._blockchainState().chain.length);
  }

  private handleValidatorRegistration(nodeId: string): void {
    // Add validator to list
    this._blockchainState.update(state => {
      const validators = new Map(state.validators);
      validators.set(nodeId, 100); // Initial reputation
      
      return {
        ...state,
        validators
      };
    });
  }

  private handleValidatorDeregistration(nodeId: string): void {
    // Remove validator from list
    this._blockchainState.update(state => {
      const validators = new Map(state.validators);
      validators.delete(nodeId);
      
      return {
        ...state,
        validators
      };
    });
  }

  private async sendChainResponse(recipient: string): Promise<void> {
    try {
      const chain = this._blockchainState().chain;
      
      // Send via WebRTC
      await this.webrtcService.sendData(recipient, {
        type: 'mesh_routing',
        payload: {
          action: 'chain_response',
          chain,
          sender: await this.getNodeId()
        },
        priority: 'normal'
      });
    } catch (error) {
      console.error('Failed to send chain response:', error);
    }
  }

  private verifyTransaction(transaction: Transaction): boolean {
    // Verify transaction hash
    const calculatedHash = this.calculateTransactionHash(transaction);
    if (calculatedHash !== transaction.hash) {
      console.warn('Invalid transaction hash');
      return false;
    }
    
    // Verify transaction signature
    // In a real implementation, you would verify the signature using the sender's public key
    
    return true;
  }

  private verifyBlock(block: Block): boolean {
    // Verify block hash
    const calculatedHash = this.calculateBlockHash(
      block.index,
      block.timestamp,
      block.transactions,
      block.previousHash,
      block.nonce,
      block.validator
    );
    
    if (calculatedHash !== block.hash) {
      console.warn('Invalid block hash');
      return false;
    }
    
    // Verify block signature
    // In a real implementation, you would verify the signature using the validator's public key
    
    // Verify all transactions in the block
    for (const transaction of block.transactions) {
      if (!this.verifyTransaction(transaction)) {
        console.warn('Invalid transaction in block');
        return false;
      }
    }
    
    return true;
  }

  private calculateTransactionHash(transaction: Transaction): string {
    const data = transaction.id + 
                 transaction.type + 
                 transaction.sender + 
                 (transaction.recipient || '') + 
                 JSON.stringify(transaction.data) + 
                 transaction.timestamp + 
                 transaction.signature;
    
    return this.sha256(data);
  }

  private transactionExists(transactionId: string): boolean {
    // Check pending transactions
    if (this._blockchainState().pendingTransactions.some(tx => tx.id === transactionId)) {
      return true;
    }
    
    // Check transactions in blocks
    for (const block of this._blockchainState().chain) {
      if (block.transactions.some(tx => tx.id === transactionId)) {
        return true;
      }
    }
    
    return false;
  }

  private removeConfirmedTransactions(confirmedTransactions: Transaction[]): void {
    const confirmedIds = new Set(confirmedTransactions.map(tx => tx.id));
    
    this._blockchainState.update(state => ({
      ...state,
      pendingTransactions: state.pendingTransactions.filter(tx => !confirmedIds.has(tx.id))
    }));
  }

  private updateValidatorReputation(validatorId: string, change: number): void {
    this._blockchainState.update(state => {
      const validators = new Map(state.validators);
      const currentReputation = validators.get(validatorId) || 0;
      validators.set(validatorId, Math.max(0, Math.min(100, currentReputation + change)));
      
      return {
        ...state,
        validators
      };
    });
    
    // Update local validator reputation if this is our node
    this.getNodeId().then(nodeId => {
      if (nodeId === validatorId) {
        const reputation = this._blockchainState().validators.get(nodeId) || 0;
        this._validatorReputation.set(reputation);
      }
    });
  }

  private async getNodeId(): Promise<string> {
    // In a real implementation, this would be a unique identifier for the node
    return this.meshService.localMeshNode()?.id || 'unknown';
  }

  private generateTransactionId(): string {
    return `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}