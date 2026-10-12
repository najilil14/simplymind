import { useCallback, useEffect, useMemo } from 'react';
import {
  Background,
  Controls,
  MarkerType,
  MiniMap,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type Connection,
  type Edge,
  type Node,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import type { Diagram, NodePositions } from '../types';
import { parseColumnHandle } from '../lib/appendRef';
import { TableNode, type TableRfNode } from './TableNode';

const nodeTypes = { table: TableNode };

const COL_GAP = 340;
const COLS = 3;

function defaultPosition(index: number): { x: number; y: number } {
  return {
    x: (index % COLS) * COL_GAP + 40,
    y: Math.floor(index / COLS) * 320 + 40,
  };
}

function toFlow(diagram: Diagram, positions: NodePositions): { nodes: Node[]; edges: Edge[] } {
  const nodes: TableRfNode[] = diagram.tables.map((table, index) => ({
    id: table.id,
    type: 'table',
    position: positions[table.id] ?? defaultPosition(index),
    data: { name: table.name, columns: table.columns },
    style: { width: 260 },
  }));

  const edges: Edge[] = diagram.relations.map((rel) => ({
    id: rel.id,
    source: rel.sourceTable,
    target: rel.targetTable,
    sourceHandle: `${rel.sourceColumn}::right`,
    targetHandle: `${rel.targetColumn}::left`,
    markerEnd: { type: MarkerType.ArrowClosed, width: 16, height: 16, color: '#64748b' },
    style: { stroke: '#64748b', strokeWidth: 1.5 },
    label: rel.marker,
    labelStyle: { fontSize: 11, fill: '#64748b' },
  }));

  return { nodes, edges };
}

type Props = {
  diagram: Diagram;
  positions: NodePositions;
  onPositionsChange: (positions: NodePositions) => void;
  onConnectColumns: (sourceTable: string, sourceColumn: string, targetTable: string, targetColumn: string) => void;
};

export function DiagramCanvas({ diagram, positions, onPositionsChange, onConnectColumns }: Props) {
  const initial = useMemo(() => toFlow(diagram, positions), [diagram, positions]);
  const [nodes, setNodes, onNodesChange] = useNodesState(initial.nodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initial.edges);

  useEffect(() => {
    const next = toFlow(diagram, positions);
    setNodes(next.nodes);
    setEdges(next.edges);
  }, [diagram, positions, setEdges, setNodes]);

  const handleConnect = useCallback(
    (connection: Connection) => {
      if (!connection.source || !connection.target) return;
      const from = parseColumnHandle(connection.sourceHandle);
      const to = parseColumnHandle(connection.targetHandle);
      if (!from || !to) return;
      onConnectColumns(connection.source, from.column, connection.target, to.column);
    },
    [onConnectColumns],
  );

  const handleNodeDragStop = useCallback(
    (_event: unknown, _node: Node, allNodes: Node[]) => {
      const next: NodePositions = { ...positions };
      for (const node of allNodes) {
        next[node.id] = { x: node.position.x, y: node.position.y };
      }
      onPositionsChange(next);
    },
    [onPositionsChange, positions],
  );

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={handleConnect}
      onNodeDragStop={handleNodeDragStop}
      nodeTypes={nodeTypes}
      fitView
      fitViewOptions={{ padding: 0.2 }}
      deleteKeyCode={null}
    >
      <Background gap={20} color="#e2e8f0" />
      <Controls showInteractive={false} />
      <MiniMap pannable zoomable />
    </ReactFlow>
  );
}
