import { Injectable } from '@angular/core';

export interface GraphNode {
  id: string;
  type: string;
  x?: number;
  y?: number;
  vx?: number;
  vy?: number;
  fixed?: boolean;
  radius?: number;
  mass?: number;
}

export interface GraphLink {
  source: string;
  target: string;
  strength?: number;
  distance?: number;
}

export interface GraphLayoutOptions {
  width: number;
  height: number;
  nodeRadius: number;
  linkDistance: number;
  linkStrength: number;
  gravity: number;
  charge: number;
  friction: number;
  alpha: number;
  alphaDecay: number;
  alphaMin: number;
  centerStrength: number;
  maxIterations: number;
}

@Injectable({
  providedIn: 'root'
})
export class NetworkGraphLayoutService {
  private defaultOptions: GraphLayoutOptions = {
    width: 800,
    height: 600,
    nodeRadius: 15,
    linkDistance: 100,
    linkStrength: 0.7,
    gravity: 0.1,
    charge: -30,
    friction: 0.9,
    alpha: 1,
    alphaDecay: 0.0228,
    alphaMin: 0.001,
    centerStrength: 0.1,
    maxIterations: 300
  };

  constructor() {}

  /**
   * Applies force-directed layout to a graph
   */
  applyForceLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    options: Partial<GraphLayoutOptions> = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    
    // Initialize node positions if not set
    nodes.forEach(node => {
      if (node.x === undefined || node.y === undefined) {
        node.x = Math.random() * layoutOptions.width;
        node.y = Math.random() * layoutOptions.height;
      }
      
      node.vx = 0;
      node.vy = 0;
      node.radius = node.radius || layoutOptions.nodeRadius;
      node.mass = node.mass || 1;
    });
    
    // Create node map for quick lookup
    const nodeMap = new Map<string, GraphNode>();
    nodes.forEach(node => nodeMap.set(node.id, node));
    
    // Process links to use node references
    const processedLinks = links.map(link => {
      const source = nodeMap.get(link.source);
      const target = nodeMap.get(link.target);
      
      if (!source || !target) {
        console.warn(`Link references missing node: ${link.source} -> ${link.target}`);
        return null;
      }
      
      return {
        source,
        target,
        strength: link.strength || layoutOptions.linkStrength,
        distance: link.distance || layoutOptions.linkDistance
      };
    }).filter(link => link !== null) as Array<{
      source: GraphNode;
      target: GraphNode;
      strength: number;
      distance: number;
    }>;
    
    // Run simulation
    let alpha = layoutOptions.alpha;
    let iteration = 0;
    
    while (alpha > layoutOptions.alphaMin && iteration < layoutOptions.maxIterations) {
      this.tick(nodes, processedLinks, nodeMap, layoutOptions, alpha);
      
      alpha *= 1 - layoutOptions.alphaDecay;
      iteration++;
    }
    
    return nodes;
  }

  /**
   * Applies a specialized layout for mesh networks
   */
  applyMeshLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    options: Partial<GraphLayoutOptions> & {
      coordinatorAtCenter?: boolean;
      relaysInInnerCircle?: boolean;
      bridgesInMiddleCircle?: boolean;
      endpointsInOuterCircle?: boolean;
    } = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    
    // Find node types
    const coordinators = nodes.filter(node => node.type === 'coordinator');
    const relays = nodes.filter(node => node.type === 'relay');
    const bridges = nodes.filter(node => node.type === 'bridge');
    const endpoints = nodes.filter(node => node.type === 'endpoint');
    
    const centerX = layoutOptions.width / 2;
    const centerY = layoutOptions.height / 2;
    
    // Position coordinators at center
    if (options.coordinatorAtCenter !== false) {
      coordinators.forEach((node, i) => {
        const angle = (i / coordinators.length) * Math.PI * 2;
        const radius = 30;
        
        node.x = centerX + Math.cos(angle) * radius;
        node.y = centerY + Math.sin(angle) * radius;
        node.fixed = true;
      });
    }
    
    // Position relays in inner circle
    if (options.relaysInInnerCircle !== false) {
      relays.forEach((node, i) => {
        const angle = (i / relays.length) * Math.PI * 2;
        const radius = Math.min(layoutOptions.width, layoutOptions.height) * 0.2;
        
        node.x = centerX + Math.cos(angle) * radius;
        node.y = centerY + Math.sin(angle) * radius;
      });
    }
    
    // Position bridges in middle circle
    if (options.bridgesInMiddleCircle !== false) {
      bridges.forEach((node, i) => {
        const angle = (i / bridges.length) * Math.PI * 2;
        const radius = Math.min(layoutOptions.width, layoutOptions.height) * 0.3;
        
        node.x = centerX + Math.cos(angle) * radius;
        node.y = centerY + Math.sin(angle) * radius;
      });
    }
    
    // Position endpoints in outer circle
    if (options.endpointsInOuterCircle !== false) {
      endpoints.forEach((node, i) => {
        const angle = (i / endpoints.length) * Math.PI * 2;
        const radius = Math.min(layoutOptions.width, layoutOptions.height) * 0.4;
        
        node.x = centerX + Math.cos(angle) * radius;
        node.y = centerY + Math.sin(angle) * radius;
      });
    }
    
    // Apply force layout to refine positions
    return this.applyForceLayout(nodes, links, {
      ...options,
      alpha: 0.3,
      maxIterations: 50
    });
  }

  /**
   * Applies a geographic layout based on node locations
   */
  applyGeographicLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    nodeLocations: Map<string, { latitude: number; longitude: number }>,
    options: Partial<GraphLayoutOptions> & {
      centerLatitude?: number;
      centerLongitude?: number;
      scale?: number;
    } = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    
    // Calculate center if not provided
    let centerLat = options.centerLatitude;
    let centerLng = options.centerLongitude;
    
    if (centerLat === undefined || centerLng === undefined) {
      let sumLat = 0;
      let sumLng = 0;
      let count = 0;
      
      nodeLocations.forEach(location => {
        sumLat += location.latitude;
        sumLng += location.longitude;
        count++;
      });
      
      centerLat = count > 0 ? sumLat / count : 0;
      centerLng = count > 0 ? sumLng / count : 0;
    }
    
    // Calculate scale if not provided
    const scale = options.scale || 100000;
    
    // Position nodes based on geographic coordinates
    nodes.forEach(node => {
      const location = nodeLocations.get(node.id);
      
      if (location) {
        // Convert lat/lng to x/y
        const x = (location.longitude - centerLng!) * scale;
        const y = (centerLat! - location.latitude) * scale;
        
        node.x = layoutOptions.width / 2 + x;
        node.y = layoutOptions.height / 2 + y;
        node.fixed = true;
      } else {
        // Random position for nodes without location
        node.x = Math.random() * layoutOptions.width;
        node.y = Math.random() * layoutOptions.height;
      }
    });
    
    // Apply light force layout to adjust positions
    return this.applyForceLayout(nodes, links, {
      ...options,
      alpha: 0.1,
      maxIterations: 20
    });
  }

  /**
   * Applies a clustered layout based on node types or communities
   */
  applyClusteredLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    clusterKey: string = 'type',
    options: Partial<GraphLayoutOptions> = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    
    // Group nodes by cluster
    const clusters = new Map<string, GraphNode[]>();
    
    nodes.forEach(node => {
      const clusterValue = (node as any)[clusterKey] || 'default';
      
      if (!clusters.has(clusterValue)) {
        clusters.set(clusterValue, []);
      }
      
      clusters.get(clusterValue)!.push(node);
    });
    
    // Position clusters
    const clusterCount = clusters.size;
    const angleStep = (Math.PI * 2) / clusterCount;
    const radius = Math.min(layoutOptions.width, layoutOptions.height) * 0.35;
    const centerX = layoutOptions.width / 2;
    const centerY = layoutOptions.height / 2;
    
    let clusterIndex = 0;
    clusters.forEach((clusterNodes, clusterValue) => {
      const angle = clusterIndex * angleStep;
      const clusterX = centerX + Math.cos(angle) * radius;
      const clusterY = centerY + Math.sin(angle) * radius;
      
      // Position nodes in a circle within the cluster
      const clusterRadius = Math.sqrt(clusterNodes.length) * layoutOptions.nodeRadius * 2;
      
      clusterNodes.forEach((node, i) => {
        const nodeAngle = (i / clusterNodes.length) * Math.PI * 2;
        
        node.x = clusterX + Math.cos(nodeAngle) * clusterRadius;
        node.y = clusterY + Math.sin(nodeAngle) * clusterRadius;
      });
      
      clusterIndex++;
    });
    
    // Apply force layout to refine positions
    return this.applyForceLayout(nodes, links, {
      ...options,
      alpha: 0.3,
      maxIterations: 100
    });
  }

  /**
   * Applies a hierarchical layout (tree-like)
   */
  applyHierarchicalLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    rootNodeId?: string,
    options: Partial<GraphLayoutOptions> & {
      direction?: 'TB' | 'LR' | 'RL' | 'BT';
      levelSeparation?: number;
      nodeSeparation?: number;
    } = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    const direction = options.direction || 'TB';
    const levelSeparation = options.levelSeparation || 100;
    const nodeSeparation = options.nodeSeparation || 50;
    
    // Create node map for quick lookup
    const nodeMap = new Map<string, GraphNode & { level?: number; children?: string[] }>();
    nodes.forEach(node => {
      nodeMap.set(node.id, { ...node, children: [] });
    });
    
    // Build hierarchy
    const hierarchy = this.buildHierarchy(nodes, links, rootNodeId, nodeMap);
    
    // Position nodes based on hierarchy
    const rootNode = hierarchy.root;
    const levels = hierarchy.levels;
    
    // Calculate dimensions
    const isHorizontal = direction === 'LR' || direction === 'RL';
    const isReversed = direction === 'BT' || direction === 'RL';
    
    const maxLevel = Math.max(...Object.keys(levels).map(Number));
    
    // Position nodes by level
    Object.entries(levels).forEach(([levelStr, levelNodes]) => {
      const level = parseInt(levelStr);
      const levelPosition = isReversed ? 
        (maxLevel - level) * levelSeparation : 
        level * levelSeparation;
      
      // Position nodes within level
      levelNodes.forEach((nodeId, index) => {
        const node = nodeMap.get(nodeId);
        if (!node) return;
        
        const nodesInLevel = levelNodes.length;
        const nodePosition = (index + 0.5) * nodeSeparation;
        
        if (isHorizontal) {
          node.x = levelPosition + layoutOptions.nodeRadius * 2;
          node.y = nodePosition;
        } else {
          node.x = nodePosition;
          node.y = levelPosition + layoutOptions.nodeRadius * 2;
        }
      });
    });
    
    // Center the layout
    const boundingBox = this.calculateBoundingBox(nodes);
    const centerX = layoutOptions.width / 2 - (boundingBox.minX + boundingBox.maxX) / 2;
    const centerY = layoutOptions.height / 2 - (boundingBox.minY + boundingBox.maxY) / 2;
    
    nodes.forEach(node => {
      if (node.x !== undefined && node.y !== undefined) {
        node.x += centerX;
        node.y += centerY;
      }
    });
    
    return nodes;
  }

  /**
   * Applies a radial layout with the specified node at the center
   */
  applyRadialLayout(
    nodes: GraphNode[],
    links: GraphLink[],
    centerNodeId?: string,
    options: Partial<GraphLayoutOptions> = {}
  ): GraphNode[] {
    // Merge options with defaults
    const layoutOptions = { ...this.defaultOptions, ...options };
    
    // Find center node
    const centerNode = centerNodeId ? 
      nodes.find(node => node.id === centerNodeId) : 
      nodes.find(node => node.type === 'coordinator') || nodes[0];
    
    if (!centerNode) return nodes;
    
    // Position center node
    centerNode.x = layoutOptions.width / 2;
    centerNode.y = layoutOptions.height / 2;
    centerNode.fixed = true;
    
    // Create node map for quick lookup
    const nodeMap = new Map<string, GraphNode & { level?: number }>();
    nodes.forEach(node => {
      nodeMap.set(node.id, { ...node, level: node.id === centerNode.id ? 0 : undefined });
    });
    
    // Calculate node levels (distance from center)
    this.calculateNodeLevels(centerNode.id, links, nodeMap);
    
    // Get max level
    const maxLevel = Math.max(
      ...Array.from(nodeMap.values())
        .map(node => node.level !== undefined ? node.level : 0)
    );
    
    // Position nodes in concentric circles
    nodeMap.forEach((node, id) => {
      if (id === centerNode.id) return;
      
      const level = node.level || maxLevel;
      const nodesAtLevel = Array.from(nodeMap.values()).filter(n => n.level === level).length;
      const angleStep = (Math.PI * 2) / nodesAtLevel;
      
      // Find index of this node in its level
      const levelNodes = Array.from(nodeMap.values()).filter(n => n.level === level);
      const nodeIndex = levelNodes.findIndex(n => n.id === id);
      
      const angle = nodeIndex * angleStep;
      const radius = level * (layoutOptions.linkDistance * 0.8);
      
      node.x = centerNode.x + Math.cos(angle) * radius;
      node.y = centerNode.y + Math.sin(angle) * radius;
    });
    
    // Apply force layout to refine positions
    return this.applyForceLayout(nodes, links, {
      ...options,
      alpha: 0.2,
      maxIterations: 50
    });
  }

  private tick(
    nodes: GraphNode[],
    links: Array<{
      source: GraphNode;
      target: GraphNode;
      strength: number;
      distance: number;
    }>,
    nodeMap: Map<string, GraphNode>,
    options: GraphLayoutOptions,
    alpha: number
  ): void {
    // Apply forces
    
    // Link force
    links.forEach(link => {
      const source = link.source;
      const target = link.target;
      
      const dx = (target.x || 0) - (source.x || 0);
      const dy = (target.y || 0) - (source.y || 0);
      const distance = Math.sqrt(dx * dx + dy * dy);
      
      if (distance === 0) return;
      
      // Force is proportional to the difference between actual and desired distance
      const force = link.strength * alpha * (link.distance - distance) / distance;
      
      const fx = dx * force;
      const fy = dy * force;
      
      if (!source.fixed) {
        source.vx = (source.vx || 0) - fx / source.mass!;
        source.vy = (source.vy || 0) - fy / source.mass!;
      }
      
      if (!target.fixed) {
        target.vx = (target.vx || 0) + fx / target.mass!;
        target.vy = (target.vy || 0) + fy / target.mass!;
      }
    });
    
    // Charge force (repulsion)
    for (let i = 0; i < nodes.length; i++) {
      const node1 = nodes[i];
      
      for (let j = i + 1; j < nodes.length; j++) {
        const node2 = nodes[j];
        
        const dx = (node2.x || 0) - (node1.x || 0);
        const dy = (node2.y || 0) - (node1.y || 0);
        const distance = Math.sqrt(dx * dx + dy * dy);
        
        if (distance === 0) continue;
        
        // Repulsive force
        const force = options.charge * alpha / (distance * distance);
        
        const fx = dx * force;
        const fy = dy * force;
        
        if (!node1.fixed) {
          node1.vx = (node1.vx || 0) - fx / node1.mass!;
          node1.vy = (node1.vy || 0) - fy / node1.mass!;
        }
        
        if (!node2.fixed) {
          node2.vx = (node2.vx || 0) + fx / node2.mass!;
          node2.vy = (node2.vy || 0) + fy / node2.mass!;
        }
      }
    }
    
    // Center force (gravity)
    const centerX = options.width / 2;
    const centerY = options.height / 2;
    
    nodes.forEach(node => {
      if (node.fixed) return;
      
      const dx = centerX - (node.x || 0);
      const dy = centerY - (node.y || 0);
      
      node.vx = (node.vx || 0) + dx * options.gravity * alpha;
      node.vy = (node.vy || 0) + dy * options.gravity * alpha;
    });
    
    // Boundary force (keep nodes within canvas)
    const padding = options.nodeRadius * 2;
    
    nodes.forEach(node => {
      if (node.fixed) return;
      
      if ((node.x || 0) < padding) {
        node.vx = (node.vx || 0) + (padding - (node.x || 0)) * 0.1;
      } else if ((node.x || 0) > options.width - padding) {
        node.vx = (node.vx || 0) + (options.width - padding - (node.x || 0)) * 0.1;
      }
      
      if ((node.y || 0) < padding) {
        node.vy = (node.vy || 0) + (padding - (node.y || 0)) * 0.1;
      } else if ((node.y || 0) > options.height - padding) {
        node.vy = (node.vy || 0) + (options.height - padding - (node.y || 0)) * 0.1;
      }
    });
    
    // Update positions
    nodes.forEach(node => {
      if (node.fixed) return;
      
      node.vx = (node.vx || 0) * options.friction;
      node.vy = (node.vy || 0) * options.friction;
      
      node.x = (node.x || 0) + node.vx!;
      node.y = (node.y || 0) + node.vy!;
    });
  }

  private buildHierarchy(
    nodes: GraphNode[],
    links: GraphLink[],
    rootNodeId: string | undefined,
    nodeMap: Map<string, GraphNode & { level?: number; children?: string[] }>
  ): { root: string; levels: Record<number, string[]> } {
    // Find root node if not specified
    let rootId = rootNodeId;
    
    if (!rootId) {
      // Try to find a coordinator node
      const coordinator = nodes.find(node => node.type === 'coordinator');
      
      if (coordinator) {
        rootId = coordinator.id;
      } else {
        // Use the node with most connections
        const nodeDegrees = new Map<string, number>();
        
        links.forEach(link => {
          nodeDegrees.set(link.source, (nodeDegrees.get(link.source) || 0) + 1);
          nodeDegrees.set(link.target, (nodeDegrees.get(link.target) || 0) + 1);
        });
        
        let maxDegree = 0;
        
        nodeDegrees.forEach((degree, id) => {
          if (degree > maxDegree) {
            maxDegree = degree;
            rootId = id;
          }
        });
        
        // Fallback to first node
        if (!rootId && nodes.length > 0) {
          rootId = nodes[0].id;
        }
      }
    }
    
    if (!rootId) {
      return { root: '', levels: {} };
    }
    
    // Build adjacency list
    const adjacencyList = new Map<string, string[]>();
    
    nodes.forEach(node => {
      adjacencyList.set(node.id, []);
    });
    
    links.forEach(link => {
      const sourceList = adjacencyList.get(link.source) || [];
      sourceList.push(link.target);
      adjacencyList.set(link.source, sourceList);
      
      const targetList = adjacencyList.get(link.target) || [];
      targetList.push(link.source);
      adjacencyList.set(link.target, targetList);
    });
    
    // BFS to assign levels and build tree
    const visited = new Set<string>([rootId]);
    const queue: Array<{ id: string; level: number; parent: string | null }> = [
      { id: rootId, level: 0, parent: null }
    ];
    
    const levels: Record<number, string[]> = { 0: [rootId] };
    
    while (queue.length > 0) {
      const { id, level, parent } = queue.shift()!;
      
      // Set node level
      const node = nodeMap.get(id);
      if (node) {
        node.level = level;
      }
      
      // Add to parent's children
      if (parent) {
        const parentNode = nodeMap.get(parent);
        if (parentNode && parentNode.children) {
          parentNode.children.push(id);
        }
      }
      
      // Add neighbors to queue
      const neighbors = adjacencyList.get(id) || [];
      
      for (const neighbor of neighbors) {
        if (visited.has(neighbor)) continue;
        
        visited.add(neighbor);
        queue.push({ id: neighbor, level: level + 1, parent: id });
        
        // Add to levels
        if (!levels[level + 1]) {
          levels[level + 1] = [];
        }
        
        levels[level + 1].push(neighbor);
      }
    }
    
    return { root: rootId, levels };
  }

  private calculateNodeLevels(
    rootId: string,
    links: GraphLink[],
    nodeMap: Map<string, GraphNode & { level?: number }>
  ): void {
    // Build adjacency list
    const adjacencyList = new Map<string, string[]>();
    
    nodeMap.forEach((_, id) => {
      adjacencyList.set(id, []);
    });
    
    links.forEach(link => {
      const sourceList = adjacencyList.get(link.source) || [];
      sourceList.push(link.target);
      adjacencyList.set(link.source, sourceList);
      
      const targetList = adjacencyList.get(link.target) || [];
      targetList.push(link.source);
      adjacencyList.set(link.target, targetList);
    });
    
    // BFS to assign levels
    const visited = new Set<string>([rootId]);
    const queue: Array<{ id: string; level: number }> = [
      { id: rootId, level: 0 }
    ];
    
    while (queue.length > 0) {
      const { id, level } = queue.shift()!;
      
      // Set node level
      const node = nodeMap.get(id);
      if (node) {
        node.level = level;
      }
      
      // Add neighbors to queue
      const neighbors = adjacencyList.get(id) || [];
      
      for (const neighbor of neighbors) {
        if (visited.has(neighbor)) continue;
        
        visited.add(neighbor);
        queue.push({ id: neighbor, level: level + 1 });
      }
    }
  }

  private calculateBoundingBox(nodes: GraphNode[]): {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
    width: number;
    height: number;
  } {
    if (nodes.length === 0) {
      return { minX: 0, minY: 0, maxX: 0, maxY: 0, width: 0, height: 0 };
    }
    
    let minX = Infinity;
    let minY = Infinity;
    let maxX = -Infinity;
    let maxY = -Infinity;
    
    nodes.forEach(node => {
      if (node.x !== undefined) {
        minX = Math.min(minX, node.x);
        maxX = Math.max(maxX, node.x);
      }
      
      if (node.y !== undefined) {
        minY = Math.min(minY, node.y);
        maxY = Math.max(maxY, node.y);
      }
    });
    
    return {
      minX,
      minY,
      maxX,
      maxY,
      width: maxX - minX,
      height: maxY - minY
    };
  }
}