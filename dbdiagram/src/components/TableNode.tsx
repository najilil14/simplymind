import { Handle, Position, type Node, type NodeProps } from '@xyflow/react';
import type { DiagramColumn } from '../types';
import { columnHandleId } from '../lib/appendRef';

export type TableNodeData = {
  name: string;
  columns: DiagramColumn[];
};

export type TableRfNode = Node<TableNodeData, 'table'>;

export function TableNode({ data }: NodeProps<TableRfNode>) {
  return (
    <div className="table-node">
      <div className="table-node__header">{data.name}</div>
      <div className="table-node__body">
        {data.columns.map((column) => (
          <div className="table-node__row" key={column.name}>
            <Handle
              type="target"
              position={Position.Left}
              id={columnHandleId(column.name, 'left')}
              className="table-node__handle"
            />
            <span className="table-node__name">
              {column.pk ? <span className="badge badge--pk">PK</span> : null}
              {column.fk ? <span className="badge badge--fk">FK</span> : null}
              {column.name}
            </span>
            <span className="table-node__type">{column.type}</span>
            <Handle
              type="source"
              position={Position.Right}
              id={columnHandleId(column.name, 'right')}
              className="table-node__handle"
            />
          </div>
        ))}
      </div>
    </div>
  );
}
