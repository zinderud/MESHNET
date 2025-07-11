import { Injectable, signal, computed, NgZone } from '@angular/core';
import { BehaviorSubject, Observable, fromEvent, merge } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged } from 'rxjs/operators';

export interface TouchGesture {
  type: 'tap' | 'double_tap' | 'long_press' | 'swipe' | 'pinch' | 'pan';
  startX: number;
  startY: number;
  endX: number;
  endY: number;
  deltaX: number;
  deltaY: number;
  distance: number;
  duration: number;
  direction?: 'up' | 'down' | 'left' | 'right';
  scale?: number;
  velocity?: number;
  target: HTMLElement;
  timestamp: number;
}

export interface TouchSettings {
  tapThreshold: number; // max movement for tap
  longPressDelay: number; // ms for long press
  swipeThreshold: number; // min distance for swipe
  swipeVelocityThreshold: number; // min velocity for swipe
  doubleTapDelay: number; // max time between taps
  pinchThreshold: number; // min scale change for pinch
  enableHapticFeedback: boolean;
  emergencyGesturesEnabled: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class TouchService {
  // Signals for reactive touch state
  private _touchSettings = signal<TouchSettings>({
    tapThreshold: 10,
    longPressDelay: 500,
    swipeThreshold: 50,
    swipeVelocityThreshold: 0.3,
    doubleTapDelay: 300,
    pinchThreshold: 0.1,
    enableHapticFeedback: true,
    emergencyGesturesEnabled: true
  });

  private _isTouch = signal<boolean>(false);
  private _activeTouches = signal<number>(0);

  // Computed touch indicators
  touchSettings = this._touchSettings.asReadonly();
  isTouch = this._isTouch.asReadonly();
  activeTouches = this._activeTouches.asReadonly();
  isTouchDevice = computed(() => 'ontouchstart' in window || navigator.maxTouchPoints > 0);

  // Touch event subjects
  private gestureDetected$ = new BehaviorSubject<TouchGesture | null>(null);
  private emergencyGesture$ = new BehaviorSubject<string | null>(null);

  // Touch tracking
  private touchStartTime = 0;
  private touchStartPos = { x: 0, y: 0 };
  private lastTapTime = 0;
  private lastTapPos = { x: 0, y: 0 };
  private longPressTimer?: number;
  private initialPinchDistance = 0;
  private currentScale = 1;

  constructor(private ngZone: NgZone) {
    this.initializeTouchHandling();
    this.setupEmergencyGestures();
  }

  private initializeTouchHandling(): void {
    if (!this.isTouchDevice()) {
      return;
    }

    this.ngZone.runOutsideAngular(() => {
      // Touch start
      document.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: false });
      
      // Touch move
      document.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
      
      // Touch end
      document.addEventListener('touchend', this.handleTouchEnd.bind(this), { passive: false });
      
      // Touch cancel
      document.addEventListener('touchcancel', this.handleTouchCancel.bind(this), { passive: false });
    });

    console.log('Touch service initialized for touch device');
  }

  private setupEmergencyGestures(): void {
    // Listen for emergency gestures
    this.gestureDetected$.pipe(
      filter(gesture => gesture !== null && this._touchSettings().emergencyGesturesEnabled),
      debounceTime(100)
    ).subscribe(gesture => {
      if (gesture) {
        this.checkEmergencyGesture(gesture);
      }
    });
  }

  private handleTouchStart(event: TouchEvent): void {
    const touch = event.touches[0];
    if (!touch) return;

    this._isTouch.set(true);
    this._activeTouches.set(event.touches.length);

    this.touchStartTime = Date.now();
    this.touchStartPos = { x: touch.clientX, y: touch.clientY };

    // Handle multi-touch (pinch)
    if (event.touches.length === 2) {
      this.initialPinchDistance = this.getDistance(event.touches[0], event.touches[1]);
      this.currentScale = 1;
    }

    // Start long press timer
    this.startLongPressTimer(touch.target as HTMLElement);

    // Prevent default for emergency areas
    if (this.isEmergencyElement(touch.target as HTMLElement)) {
      event.preventDefault();
    }
  }

  private handleTouchMove(event: TouchEvent): void {
    const touch = event.touches[0];
    if (!touch) return;

    const deltaX = touch.clientX - this.touchStartPos.x;
    const deltaY = touch.clientY - this.touchStartPos.y;
    const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

    // Cancel long press if moved too much
    if (distance > this._touchSettings().tapThreshold) {
      this.cancelLongPress();
    }

    // Handle pinch gesture
    if (event.touches.length === 2) {
      const currentDistance = this.getDistance(event.touches[0], event.touches[1]);
      const scale = currentDistance / this.initialPinchDistance;
      
      if (Math.abs(scale - this.currentScale) > this._touchSettings().pinchThreshold) {
        this.currentScale = scale;
        this.emitGesture({
          type: 'pinch',
          startX: this.touchStartPos.x,
          startY: this.touchStartPos.y,
          endX: touch.clientX,
          endY: touch.clientY,
          deltaX,
          deltaY,
          distance,
          duration: Date.now() - this.touchStartTime,
          scale,
          target: touch.target as HTMLElement,
          timestamp: Date.now()
        });
      }
    }

    // Prevent scrolling on emergency elements
    if (this.isEmergencyElement(touch.target as HTMLElement)) {
      event.preventDefault();
    }
  }

  private handleTouchEnd(event: TouchEvent): void {
    const touch = event.changedTouches[0];
    if (!touch) return;

    this._activeTouches.set(event.touches.length);

    const endTime = Date.now();
    const duration = endTime - this.touchStartTime;
    const deltaX = touch.clientX - this.touchStartPos.x;
    const deltaY = touch.clientY - this.touchStartPos.y;
    const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

    this.cancelLongPress();

    // Determine gesture type
    if (distance <= this._touchSettings().tapThreshold) {
      this.handleTap(touch, duration);
    } else if (distance >= this._touchSettings().swipeThreshold) {
      this.handleSwipe(touch, deltaX, deltaY, distance, duration);
    }

    // Reset touch state after a delay
    setTimeout(() => {
      if (this._activeTouches() === 0) {
        this._isTouch.set(false);
      }
    }, 100);
  }

  private handleTouchCancel(event: TouchEvent): void {
    this._activeTouches.set(event.touches.length);
    this.cancelLongPress();
    
    setTimeout(() => {
      if (this._activeTouches() === 0) {
        this._isTouch.set(false);
      }
    }, 100);
  }

  private handleTap(touch: Touch, duration: number): void {
    const now = Date.now();
    const timeSinceLastTap = now - this.lastTapTime;
    const distanceFromLastTap = Math.sqrt(
      Math.pow(touch.clientX - this.lastTapPos.x, 2) + 
      Math.pow(touch.clientY - this.lastTapPos.y, 2)
    );

    // Check for double tap
    if (timeSinceLastTap < this._touchSettings().doubleTapDelay && 
        distanceFromLastTap < this._touchSettings().tapThreshold) {
      
      this.emitGesture({
        type: 'double_tap',
        startX: this.touchStartPos.x,
        startY: this.touchStartPos.y,
        endX: touch.clientX,
        endY: touch.clientY,
        deltaX: 0,
        deltaY: 0,
        distance: 0,
        duration,
        target: touch.target as HTMLElement,
        timestamp: now
      });

      // Reset last tap to prevent triple tap
      this.lastTapTime = 0;
    } else {
      // Single tap
      this.emitGesture({
        type: 'tap',
        startX: this.touchStartPos.x,
        startY: this.touchStartPos.y,
        endX: touch.clientX,
        endY: touch.clientY,
        deltaX: 0,
        deltaY: 0,
        distance: 0,
        duration,
        target: touch.target as HTMLElement,
        timestamp: now
      });

      this.lastTapTime = now;
      this.lastTapPos = { x: touch.clientX, y: touch.clientY };
    }

    // Haptic feedback for taps
    if (this._touchSettings().enableHapticFeedback) {
      this.triggerHapticFeedback('light');
    }
  }

  private handleSwipe(touch: Touch, deltaX: number, deltaY: number, distance: number, duration: number): void {
    const velocity = distance / duration;
    
    if (velocity < this._touchSettings().swipeVelocityThreshold) {
      return; // Too slow to be a swipe
    }

    // Determine swipe direction
    let direction: 'up' | 'down' | 'left' | 'right';
    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      direction = deltaX > 0 ? 'right' : 'left';
    } else {
      direction = deltaY > 0 ? 'down' : 'up';
    }

    this.emitGesture({
      type: 'swipe',
      startX: this.touchStartPos.x,
      startY: this.touchStartPos.y,
      endX: touch.clientX,
      endY: touch.clientY,
      deltaX,
      deltaY,
      distance,
      duration,
      direction,
      velocity,
      target: touch.target as HTMLElement,
      timestamp: Date.now()
    });

    // Haptic feedback for swipes
    if (this._touchSettings().enableHapticFeedback) {
      this.triggerHapticFeedback('medium');
    }
  }

  private startLongPressTimer(target: HTMLElement): void {
    this.longPressTimer = window.setTimeout(() => {
      this.emitGesture({
        type: 'long_press',
        startX: this.touchStartPos.x,
        startY: this.touchStartPos.y,
        endX: this.touchStartPos.x,
        endY: this.touchStartPos.y,
        deltaX: 0,
        deltaY: 0,
        distance: 0,
        duration: this._touchSettings().longPressDelay,
        target,
        timestamp: Date.now()
      });

      // Strong haptic feedback for long press
      if (this._touchSettings().enableHapticFeedback) {
        this.triggerHapticFeedback('heavy');
      }
    }, this._touchSettings().longPressDelay);
  }

  private cancelLongPress(): void {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = undefined;
    }
  }

  private emitGesture(gesture: TouchGesture): void {
    this.ngZone.run(() => {
      this.gestureDetected$.next(gesture);
    });
  }

  private checkEmergencyGesture(gesture: TouchGesture): void {
    // Emergency gesture patterns
    if (gesture.type === 'long_press' && this.isEmergencyElement(gesture.target)) {
      this.emergencyGesture$.next('emergency_long_press');
    }

    // Triple tap anywhere for emergency
    if (gesture.type === 'tap') {
      // This would need more sophisticated tracking for triple tap
    }

    // Swipe patterns for emergency
    if (gesture.type === 'swipe' && gesture.direction === 'up' && (gesture.velocity ?? 0) > 1.0) {
      this.emergencyGesture$.next('emergency_swipe_up');
    }
  }

  private isEmergencyElement(element: HTMLElement): boolean {
    return element.closest('.emergency-button, .emergency-card, [data-emergency]') !== null;
  }

  private getDistance(touch1: Touch, touch2: Touch): number {
    const deltaX = touch1.clientX - touch2.clientX;
    const deltaY = touch1.clientY - touch2.clientY;
    return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  // Haptic feedback
  private async triggerHapticFeedback(intensity: 'light' | 'medium' | 'heavy'): Promise<void> {
    try {
      if ('vibrate' in navigator) {
        const patterns = {
          light: [10],
          medium: [20],
          heavy: [50]
        };
        navigator.vibrate(patterns[intensity]);
      }
    } catch (error) {
      console.error('Haptic feedback failed:', error);
    }
  }

  // Public API methods
  enableEmergencyGestures(): void {
    this._touchSettings.update(settings => ({
      ...settings,
      emergencyGesturesEnabled: true
    }));
  }

  disableEmergencyGestures(): void {
    this._touchSettings.update(settings => ({
      ...settings,
      emergencyGesturesEnabled: false
    }));
  }

  updateSettings(newSettings: Partial<TouchSettings>): void {
    this._touchSettings.update(settings => ({
      ...settings,
      ...newSettings
    }));
  }

  // Touch-friendly UI helpers
  addTouchFriendlyClass(element: HTMLElement): void {
    element.classList.add('touch-friendly');
    element.style.minHeight = '44px';
    element.style.minWidth = '44px';
    element.style.touchAction = 'manipulation';
  }

  optimizeForTouch(element: HTMLElement): void {
    // Add touch-friendly styling
    this.addTouchFriendlyClass(element);
    
    // Add touch event listeners
    element.addEventListener('touchstart', (e) => {
      element.classList.add('touch-active');
    }, { passive: true });

    element.addEventListener('touchend', (e) => {
      element.classList.remove('touch-active');
    }, { passive: true });

    element.addEventListener('touchcancel', (e) => {
      element.classList.remove('touch-active');
    }, { passive: true });
  }

  // Pull-to-refresh implementation
  setupPullToRefresh(container: HTMLElement, onRefresh: () => Promise<void>): void {
    let startY = 0;
    let currentY = 0;
    let isPulling = false;
    let refreshThreshold = 80;

    container.addEventListener('touchstart', (e) => {
      if (container.scrollTop === 0) {
        startY = e.touches[0].clientY;
        isPulling = true;
      }
    }, { passive: true });

    container.addEventListener('touchmove', (e) => {
      if (!isPulling) return;

      currentY = e.touches[0].clientY;
      const pullDistance = currentY - startY;

      if (pullDistance > 0 && container.scrollTop === 0) {
        e.preventDefault();
        
        // Visual feedback
        const opacity = Math.min(pullDistance / refreshThreshold, 1);
        container.style.transform = `translateY(${Math.min(pullDistance * 0.5, 40)}px)`;
        container.style.opacity = (1 - opacity * 0.3).toString();
      }
    });

    container.addEventListener('touchend', async (e) => {
      if (!isPulling) return;

      const pullDistance = currentY - startY;
      isPulling = false;

      // Reset visual state
      container.style.transform = '';
      container.style.opacity = '';

      if (pullDistance > refreshThreshold) {
        // Trigger refresh
        try {
          await onRefresh();
        } catch (error) {
          console.error('Pull to refresh failed:', error);
        }
      }
    }, { passive: true });
  }

  // Event observables
  get onGestureDetected$(): Observable<TouchGesture> {
    return this.gestureDetected$.pipe(
      filter(gesture => gesture !== null),
      map(gesture => gesture!)
    );
  }

  get onEmergencyGesture$(): Observable<string> {
    return this.emergencyGesture$.pipe(
      filter(gesture => gesture !== null),
      map(gesture => gesture!)
    );
  }

  get onTap$(): Observable<TouchGesture> {
    return this.onGestureDetected$.pipe(
      filter(gesture => gesture.type === 'tap')
    );
  }

  get onDoubleTap$(): Observable<TouchGesture> {
    return this.onGestureDetected$.pipe(
      filter(gesture => gesture.type === 'double_tap')
    );
  }

  get onLongPress$(): Observable<TouchGesture> {
    return this.onGestureDetected$.pipe(
      filter(gesture => gesture.type === 'long_press')
    );
  }

  get onSwipe$(): Observable<TouchGesture> {
    return this.onGestureDetected$.pipe(
      filter(gesture => gesture.type === 'swipe')
    );
  }

  // Cleanup
  destroy(): void {
    this.cancelLongPress();
    // Remove event listeners would be handled by Angular's lifecycle
  }
}