import { Injectable, ElementRef } from '@angular/core';

export interface NetworkNode {
  id: string;
  x: number;
  y: number;
  type: 'coordinator' | 'relay' | 'endpoint' | 'bridge';
  signalStrength: number;
  batteryLevel: number;
  isOnline: boolean;
  emergencyStatus: 'normal' | 'alert' | 'emergency' | 'critical';
  label?: string;
}

export interface NetworkConnection {
  source: string;
  target: string;
  strength: number;
  isEmergency: boolean;
  hopCount?: number;
  bandwidth?: number;
}

export interface NetworkRenderOptions {
  showLabels: boolean;
  showSignalStrength: boolean;
  showBatteryLevel: boolean;
  showEmergencyStatus: boolean;
  nodeSize: number;
  lineWidth: number;
  theme: 'light' | 'dark';
  animateConnections: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class NetworkTopologyRendererService {
  private canvas: HTMLCanvasElement | null = null;
  private ctx: CanvasRenderingContext2D | null = null;
  private width = 0;
  private height = 0;
  private animationFrame: number | null = null;
  private animationTime = 0;

  private defaultOptions: NetworkRenderOptions = {
    showLabels: true,
    showSignalStrength: true,
    showBatteryLevel: true,
    showEmergencyStatus: true,
    nodeSize: 15,
    lineWidth: 2,
    theme: 'light',
    animateConnections: true
  };

  constructor() {}

  initialize(canvasRef: ElementRef<HTMLCanvasElement>, width: number, height: number): void {
    this.canvas = canvasRef.nativeElement;
    const ctx = this.canvas.getContext('2d');
    
    if (!ctx) {
      console.error('Failed to get canvas context');
      return;
    }
    
    this.ctx = ctx;
    this.width = width;
    this.height = height;
    
    this.canvas.width = width;
    this.canvas.height = height;
  }

  resize(width: number, height: number): void {
    if (!this.canvas) return;
    
    this.width = width;
    this.height = height;
    this.canvas.width = width;
    this.canvas.height = height;
  }

  renderTopology(
    nodes: NetworkNode[],
    connections: NetworkConnection[],
    options: Partial<NetworkRenderOptions> = {}
  ): void {
    if (!this.ctx || !this.canvas) return;
    
    // Merge options with defaults
    const renderOptions = { ...this.defaultOptions, ...options };
    
    // Clear canvas
    this.ctx.clearRect(0, 0, this.width, this.height);
    
    // Set background color
    this.ctx.fillStyle = renderOptions.theme === 'light' ? '#f8f9fa' : '#1e1e1e';
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    // Draw connections
    this.drawConnections(connections, renderOptions);
    
    // Draw nodes
    this.drawNodes(nodes, renderOptions);
    
    // Draw labels if enabled
    if (renderOptions.showLabels) {
      this.drawLabels(nodes, renderOptions);
    }
  }

  renderHeatmap(
    nodes: NetworkNode[],
    options: Partial<NetworkRenderOptions> = {}
  ): void {
    if (!this.ctx || !this.canvas) return;
    
    // Merge options with defaults
    const renderOptions = { ...this.defaultOptions, ...options };
    
    // Clear canvas
    this.ctx.clearRect(0, 0, this.width, this.height);
    
    // Set background color
    this.ctx.fillStyle = renderOptions.theme === 'light' ? '#f8f9fa' : '#1e1e1e';
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    // Draw heatmap
    this.drawHeatmap(nodes, renderOptions);
    
    // Draw nodes
    this.drawNodes(nodes, renderOptions);
    
    // Draw labels if enabled
    if (renderOptions.showLabels) {
      this.drawLabels(nodes, renderOptions);
    }
  }

  renderRoutingPaths(
    nodes: NetworkNode[],
    connections: NetworkConnection[],
    routes: Array<{ source: string; target: string; hops: number; isEmergency: boolean }>,
    options: Partial<NetworkRenderOptions> = {}
  ): void {
    if (!this.ctx || !this.canvas) return;
    
    // Merge options with defaults
    const renderOptions = { ...this.defaultOptions, ...options };
    
    // Clear canvas
    this.ctx.clearRect(0, 0, this.width, this.height);
    
    // Set background color
    this.ctx.fillStyle = renderOptions.theme === 'light' ? '#f8f9fa' : '#1e1e1e';
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    // Draw connections
    this.drawConnections(connections, renderOptions);
    
    // Draw routing paths
    this.drawRoutingPaths(nodes, routes, renderOptions);
    
    // Draw nodes
    this.drawNodes(nodes, renderOptions);
    
    // Draw labels if enabled
    if (renderOptions.showLabels) {
      this.drawLabels(nodes, renderOptions);
    }
  }

  renderEmergencyCoverage(
    nodes: NetworkNode[],
    connections: NetworkConnection[],
    coverageAreas: Array<{ center: { x: number; y: number }; radius: number; type: string }>,
    options: Partial<NetworkRenderOptions> = {}
  ): void {
    if (!this.ctx || !this.canvas) return;
    
    // Merge options with defaults
    const renderOptions = { ...this.defaultOptions, ...options };
    
    // Clear canvas
    this.ctx.clearRect(0, 0, this.width, this.height);
    
    // Set background color
    this.ctx.fillStyle = renderOptions.theme === 'light' ? '#f8f9fa' : '#1e1e1e';
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    // Draw coverage areas
    this.drawCoverageAreas(coverageAreas, renderOptions);
    
    // Draw connections
    this.drawConnections(connections, renderOptions);
    
    // Draw nodes
    this.drawNodes(nodes, renderOptions);
    
    // Draw labels if enabled
    if (renderOptions.showLabels) {
      this.drawLabels(nodes, renderOptions);
    }
  }

  startAnimation(): void {
    if (this.animationFrame !== null) {
      cancelAnimationFrame(this.animationFrame);
    }
    
    this.animationTime = 0;
    this.animate();
  }

  stopAnimation(): void {
    if (this.animationFrame !== null) {
      cancelAnimationFrame(this.animationFrame);
      this.animationFrame = null;
    }
  }

  private animate(): void {
    this.animationTime += 0.01;
    
    // Re-render with animation time
    // This would be called by the component with the current data
    
    this.animationFrame = requestAnimationFrame(() => this.animate());
  }

  private drawNodes(nodes: NetworkNode[], options: NetworkRenderOptions): void {
    if (!this.ctx) return;
    
    const nodeRadius = options.nodeSize;
    
    nodes.forEach(node => {
      // Draw node circle
      this.ctx!.beginPath();
      this.ctx!.arc(node.x, node.y, nodeRadius, 0, Math.PI * 2);
      
      // Set color based on node type
      switch (node.type) {
        case 'coordinator':
          this.ctx!.fillStyle = '#f44336';
          break;
        case 'relay':
          this.ctx!.fillStyle = '#ff9800';
          break;
        case 'bridge':
          this.ctx!.fillStyle = '#2196f3';
          break;
        case 'endpoint':
        default:
          this.ctx!.fillStyle = '#4caf50';
          break;
      }
      
      this.ctx!.fill();
      
      // Draw border
      this.ctx!.strokeStyle = options.theme === 'light' ? '#fff' : '#333';
      this.ctx!.lineWidth = 2;
      this.ctx!.stroke();
      
      // Draw status indicators
      if (options.showEmergencyStatus && node.emergencyStatus !== 'normal') {
        // Draw emergency indicator
        this.ctx!.beginPath();
        this.ctx!.arc(
          node.x + nodeRadius * 0.7, 
          node.y - nodeRadius * 0.7, 
          nodeRadius * 0.3, 
          0, 
          Math.PI * 2
        );
        
        // Set color based on emergency status
        switch (node.emergencyStatus) {
          case 'critical':
            this.ctx!.fillStyle = '#f44336';
            break;
          case 'emergency':
            this.ctx!.fillStyle = '#ff5722';
            break;
          case 'alert':
            this.ctx!.fillStyle = '#ff9800';
            break;
          default:
            this.ctx!.fillStyle = '#4caf50';
        }
        
        this.ctx!.fill();
      }
      
      if (options.showBatteryLevel) {
        // Draw battery indicator
        const batteryWidth = nodeRadius * 1.2;
        const batteryHeight = nodeRadius * 0.4;
        const batteryX = node.x - batteryWidth / 2;
        const batteryY = node.y + nodeRadius + 5;
        
        // Battery outline
        this.ctx!.fillStyle = options.theme === 'light' ? '#ddd' : '#555';
        this.ctx!.fillRect(batteryX, batteryY, batteryWidth, batteryHeight);
        
        // Battery level
        let batteryColor = '#4caf50';
        if (node.batteryLevel < 30) {
          batteryColor = '#f44336';
        } else if (node.batteryLevel < 70) {
          batteryColor = '#ff9800';
        }
        
        this.ctx!.fillStyle = batteryColor;
        this.ctx!.fillRect(
          batteryX + 1, 
          batteryY + 1, 
          (batteryWidth - 2) * (node.batteryLevel / 100), 
          batteryHeight - 2
        );
      }
      
      if (options.showSignalStrength) {
        // Draw signal strength indicator
        const signalX = node.x - nodeRadius * 0.7;
        const signalY = node.y - nodeRadius * 0.7;
        const signalSize = nodeRadius * 0.6;
        
        // Signal bars
        const barWidth = signalSize / 4;
        const barGap = barWidth / 3;
        const maxBarHeight = signalSize;
        
        for (let i = 0; i < 4; i++) {
          const barHeight = maxBarHeight * ((i + 1) / 4);
          const barX = signalX - signalSize / 2 + i * (barWidth + barGap);
          const barY = signalY - barHeight / 2;
          
          this.ctx!.fillStyle = node.signalStrength >= (i + 1) * 25 ? 
            '#4caf50' : 
            options.theme === 'light' ? '#ddd' : '#555';
          
          this.ctx!.fillRect(barX, barY, barWidth, barHeight);
        }
      }
    });
  }

  private drawConnections(connections: NetworkConnection[], options: NetworkRenderOptions): void {
    if (!this.ctx) return;
    
    connections.forEach(conn => {
      // Find source and target nodes
      const sourceNode = this.findNodeById(conn.source);
      const targetNode = this.findNodeById(conn.target);
      
      if (!sourceNode || !targetNode) return;
      
      this.ctx!.beginPath();
      this.ctx!.moveTo(sourceNode.x, sourceNode.y);
      
      if (options.animateConnections) {
        // Draw animated connection
        this.drawAnimatedConnection(
          sourceNode.x, sourceNode.y,
          targetNode.x, targetNode.y,
          conn.strength,
          conn.isEmergency,
          options
        );
      } else {
        // Draw straight connection
        this.ctx!.lineTo(targetNode.x, targetNode.y);
        
        if (conn.isEmergency) {
          // Emergency connection
          this.ctx!.strokeStyle = '#f44336';
          this.ctx!.lineWidth = options.lineWidth + 1;
        } else if (conn.strength >= 70) {
          // Strong connection
          this.ctx!.strokeStyle = options.theme === 'light' ? '#2196f3' : '#64b5f6';
          this.ctx!.lineWidth = options.lineWidth;
        } else {
          // Weak connection
          this.ctx!.strokeStyle = options.theme === 'light' ? '#9e9e9e' : '#bdbdbd';
          this.ctx!.lineWidth = options.lineWidth - 0.5;
          this.ctx!.setLineDash([5, 3]);
        }
        
        this.ctx!.stroke();
        this.ctx!.setLineDash([]);
      }
      
      // Draw connection strength if enabled
      if (options.showSignalStrength && conn.strength) {
        const midX = (sourceNode.x + targetNode.x) / 2;
        const midY = (sourceNode.y + targetNode.y) / 2;
        
        this.ctx!.fillStyle = options.theme === 'light' ? 'rgba(0, 0, 0, 0.7)' : 'rgba(255, 255, 255, 0.7)';
        this.ctx!.fillRect(midX - 15, midY - 10, 30, 20);
        
        this.ctx!.font = '12px Arial';
        this.ctx!.textAlign = 'center';
        this.ctx!.textBaseline = 'middle';
        this.ctx!.fillStyle = options.theme === 'light' ? '#fff' : '#000';
        this.ctx!.fillText(`${conn.strength}%`, midX, midY);
      }
    });
  }

  private drawAnimatedConnection(
    x1: number, y1: number,
    x2: number, y2: number,
    strength: number,
    isEmergency: boolean,
    options: NetworkRenderOptions
  ): void {
    if (!this.ctx) return;
    
    // Draw line
    this.ctx.lineTo(x2, y2);
    
    if (isEmergency) {
      // Emergency connection
      this.ctx.strokeStyle = '#f44336';
      this.ctx.lineWidth = options.lineWidth + 1;
    } else if (strength >= 70) {
      // Strong connection
      this.ctx.strokeStyle = options.theme === 'light' ? '#2196f3' : '#64b5f6';
      this.ctx.lineWidth = options.lineWidth;
    } else {
      // Weak connection
      this.ctx.strokeStyle = options.theme === 'light' ? '#9e9e9e' : '#bdbdbd';
      this.ctx.lineWidth = options.lineWidth - 0.5;
      this.ctx.setLineDash([5, 3]);
    }
    
    this.ctx.stroke();
    this.ctx.setLineDash([]);
    
    // Draw animated particles
    if (isEmergency || strength >= 50) {
      this.drawConnectionParticles(x1, y1, x2, y2, isEmergency, options);
    }
  }

  private drawConnectionParticles(
    x1: number, y1: number,
    x2: number, y2: number,
    isEmergency: boolean,
    options: NetworkRenderOptions
  ): void {
    if (!this.ctx) return;
    
    const particleCount = isEmergency ? 3 : 1;
    const animationSpeed = isEmergency ? 2 : 1;
    
    for (let i = 0; i < particleCount; i++) {
      // Calculate position along the line
      const t = ((this.animationTime * animationSpeed) + i / particleCount) % 1;
      
      const x = x1 + (x2 - x1) * t;
      const y = y1 + (y2 - y1) * t;
      
      // Draw particle
      this.ctx.beginPath();
      this.ctx.arc(x, y, 3, 0, Math.PI * 2);
      
      if (isEmergency) {
        this.ctx.fillStyle = '#f44336';
      } else {
        this.ctx.fillStyle = options.theme === 'light' ? '#2196f3' : '#64b5f6';
      }
      
      this.ctx.fill();
    }
  }

  private drawLabels(nodes: NetworkNode[], options: NetworkRenderOptions): void {
    if (!this.ctx) return;
    
    this.ctx.font = '12px Arial';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    
    nodes.forEach(node => {
      const labelText = node.label || node.id.substring(0, 8) + '...';
      
      // Draw label background
      this.ctx!.fillStyle = options.theme === 'light' ? 'rgba(0, 0, 0, 0.7)' : 'rgba(255, 255, 255, 0.7)';
      const textWidth = this.ctx!.measureText(labelText).width + 10;
      this.ctx!.fillRect(
        node.x - textWidth / 2,
        node.y + options.nodeSize + 5,
        textWidth,
        20
      );
      
      // Draw label text
      this.ctx!.fillStyle = options.theme === 'light' ? '#fff' : '#000';
      this.ctx!.fillText(
        labelText,
        node.x,
        node.y + options.nodeSize + 15
      );
    });
  }

  private drawHeatmap(nodes: NetworkNode[], options: NetworkRenderOptions): void {
    if (!this.ctx) return;
    
    // Create offscreen canvas for heatmap
    const offscreen = document.createElement('canvas');
    offscreen.width = this.width;
    offscreen.height = this.height;
    const offCtx = offscreen.getContext('2d');
    
    if (!offCtx) return;
    
    // Clear offscreen canvas
    offCtx.clearRect(0, 0, this.width, this.height);
    
    // Draw signal strength heatmap
    nodes.forEach(node => {
      const radius = node.signalStrength * 2;
      
      const gradient = offCtx.createRadialGradient(
        node.x, node.y, 0,
        node.x, node.y, radius
      );
      
      gradient.addColorStop(0, `rgba(76, 175, 80, ${node.signalStrength / 100})`);
      gradient.addColorStop(0.7, `rgba(255, 152, 0, ${node.signalStrength / 200})`);
      gradient.addColorStop(1, 'rgba(244, 67, 54, 0)');
      
      offCtx.beginPath();
      offCtx.arc(node.x, node.y, radius, 0, Math.PI * 2);
      offCtx.fillStyle = gradient;
      offCtx.fill();
    });
    
    // Apply heatmap to main canvas
    this.ctx.globalAlpha = 0.7;
    this.ctx.drawImage(offscreen, 0, 0);
    this.ctx.globalAlpha = 1.0;
  }

  private drawRoutingPaths(
    nodes: NetworkNode[],
    routes: Array<{ source: string; target: string; hops: number; isEmergency: boolean }>,
    options: NetworkRenderOptions
  ): void {
    if (!this.ctx) return;
    
    routes.forEach(route => {
      const sourceNode = this.findNodeById(route.source);
      const targetNode = this.findNodeById(route.target);
      
      if (!sourceNode || !targetNode) return;
      
      // Draw route path
      this.ctx!.beginPath();
      this.ctx!.moveTo(sourceNode.x, sourceNode.y);
      
      // Draw curved path
      const midX = (sourceNode.x + targetNode.x) / 2;
      const midY = (sourceNode.y + targetNode.y) / 2;
      const curveFactor = 30;
      
      // Calculate perpendicular offset for curve
      const dx = targetNode.x - sourceNode.x;
      const dy = targetNode.y - sourceNode.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      
      const offsetX = -dy / dist * curveFactor;
      const offsetY = dx / dist * curveFactor;
      
      this.ctx!.quadraticCurveTo(
        midX + offsetX,
        midY + offsetY,
        targetNode.x,
        targetNode.y
      );
      
      if (route.isEmergency) {
        // Emergency route
        this.ctx!.strokeStyle = '#f44336';
        this.ctx!.lineWidth = options.lineWidth + 1;
      } else {
        // Normal route
        this.ctx!.strokeStyle = options.theme === 'light' ? '#2196f3' : '#64b5f6';
        this.ctx!.lineWidth = options.lineWidth;
      }
      
      this.ctx!.stroke();
      
      // Draw hop count
      this.ctx!.font = '12px Arial';
      this.ctx!.textAlign = 'center';
      this.ctx!.textBaseline = 'middle';
      
      this.ctx!.fillStyle = options.theme === 'light' ? 'rgba(0, 0, 0, 0.7)' : 'rgba(255, 255, 255, 0.7)';
      this.ctx!.fillRect(
        midX + offsetX - 15,
        midY + offsetY - 10,
        30,
        20
      );
      
      this.ctx!.fillStyle = options.theme === 'light' ? '#fff' : '#000';
      this.ctx!.fillText(
        route.hops.toString(),
        midX + offsetX,
        midY + offsetY
      );
      
      // Draw arrow
      const arrowSize = 10;
      const angle = Math.atan2(
        targetNode.y - (midY + offsetY),
        targetNode.x - (midX + offsetX)
      );
      
      const arrowX = targetNode.x - options.nodeSize * Math.cos(angle);
      const arrowY = targetNode.y - options.nodeSize * Math.sin(angle);
      
      this.ctx!.beginPath();
      this.ctx!.moveTo(arrowX, arrowY);
      this.ctx!.lineTo(
        arrowX - arrowSize * Math.cos(angle - Math.PI / 6),
        arrowY - arrowSize * Math.sin(angle - Math.PI / 6)
      );
      
      this.ctx!.moveTo(arrowX, arrowY);
      this.ctx!.lineTo(
        arrowX - arrowSize * Math.cos(angle + Math.PI / 6),
        arrowY - arrowSize * Math.sin(angle + Math.PI / 6)
      );
      
      this.ctx!.stroke();
    });
  }

  private drawCoverageAreas(
    areas: Array<{ center: { x: number; y: number }; radius: number; type: string }>,
    options: NetworkRenderOptions
  ): void {
    if (!this.ctx) return;
    
    areas.forEach(area => {
      this.ctx!.beginPath();
      this.ctx!.arc(area.center.x, area.center.y, area.radius, 0, Math.PI * 2);
      
      if (area.type === 'emergency') {
        this.ctx!.fillStyle = 'rgba(244, 67, 54, 0.1)';
        this.ctx!.strokeStyle = 'rgba(244, 67, 54, 0.5)';
      } else {
        this.ctx!.fillStyle = 'rgba(33, 150, 243, 0.1)';
        this.ctx!.strokeStyle = 'rgba(33, 150, 243, 0.5)';
      }
      
      this.ctx!.fill();
      this.ctx!.lineWidth = 2;
      this.ctx!.stroke();
      
      // Draw coverage radius label
      this.ctx!.font = '14px Arial';
      this.ctx!.textAlign = 'center';
      this.ctx!.textBaseline = 'middle';
      this.ctx!.fillStyle = options.theme === 'light' ? '#333' : '#fff';
      
      this.ctx!.fillText(
        `${Math.round(area.radius)}m`,
        area.center.x,
        area.center.y + area.radius + 20
      );
    });
  }

  private findNodeById(id: string): { x: number; y: number } | null {
    // This is a placeholder - in a real implementation, this would look up
    // the node in the provided nodes array
    return { x: Math.random() * this.width, y: Math.random() * this.height };
  }
}