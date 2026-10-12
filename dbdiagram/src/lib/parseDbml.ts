import {
  CompilerError,
  Parser,
  getRelationshipOp,
  isEndpointManySide,
} from '@dbml/core';
import type { Diagram, DiagramRelation, ParseResult, RelationMarker } from '../types';

function tableId(schemaName: string | null | undefined, tableName: string): string {
  if (!schemaName || schemaName === 'public') return tableName;
  return `${schemaName}.${tableName}`;
}

function fieldTypeName(type: unknown): string {
  if (type && typeof type === 'object' && 'type_name' in type) {
    const named = type as { type_name?: string; args?: string | null };
    if (named.args) return `${named.type_name}(${named.args})`;
    return named.type_name ?? 'any';
  }
  if (typeof type === 'string') return type;
  return 'any';
}

function asMarker(op: string): RelationMarker {
  if (op.includes('<>')) return '<>';
  if (op.includes('>')) return '>';
  if (op.includes('<')) return '<';
  return '-';
}

function formatError(err: unknown): string {
  if (err instanceof CompilerError && err.diags.length > 0) {
    const diag = err.diags[0];
    const line = diag.location.start.line;
    return `Line ${line}: ${diag.message}`;
  }
  if (err && typeof err === 'object' && 'diags' in err) {
    const diags = (err as CompilerError).diags;
    if (Array.isArray(diags) && diags[0]) {
      const diag = diags[0];
      return `Line ${diag.location.start.line}: ${diag.message}`;
    }
  }
  if (err instanceof Error) return err.message;
  return 'Invalid DBML';
}

export function parseDbml(source: string): ParseResult {
  if (!source.trim()) {
    return { diagram: { tables: [], relations: [] }, error: null };
  }

  try {
    const database = Parser.parse(source, 'dbml');
    const tables: Diagram['tables'] = [];
    const relations: DiagramRelation[] = [];
    const seenRefs = new Set<string>();

    for (const schema of database.schemas) {
      for (const table of schema.tables) {
        const id = tableId(schema.name, table.name);
        tables.push({
          id,
          name: table.name,
          columns: table.fields.map((field) => ({
            name: field.name,
            type: fieldTypeName(field.type),
            pk: Boolean(field.pk),
            unique: Boolean(field.unique),
            notNull: Boolean(field.not_null),
            fk: (field.endpoints ?? []).some((endpoint) => isEndpointManySide(endpoint.relation)),
          })),
        });
      }

      for (const ref of schema.refs) {
        const [left, right] = ref.endpoints;
        if (!left || !right) continue;
        const leftId = tableId(left.schemaName, left.tableName);
        const rightId = tableId(right.schemaName, right.tableName);
        const leftCol = left.fieldNames?.[0];
        const rightCol = right.fieldNames?.[0];
        if (!leftCol || !rightCol) continue;

        const manyIsLeft = isEndpointManySide(left.relation);
        const manyIsRight = isEndpointManySide(right.relation);
        const sourceIsLeft = manyIsLeft && !manyIsRight ? true : manyIsRight && !manyIsLeft ? false : true;

        const sourceTable = sourceIsLeft ? leftId : rightId;
        const sourceColumn = sourceIsLeft ? leftCol : rightCol;
        const targetTable = sourceIsLeft ? rightId : leftId;
        const targetColumn = sourceIsLeft ? rightCol : leftCol;
        const marker = asMarker(getRelationshipOp(left.relation, right.relation));
        const id = `${sourceTable}.${sourceColumn}->${targetTable}.${targetColumn}`;
        if (seenRefs.has(id)) continue;
        seenRefs.add(id);
        relations.push({
          id,
          sourceTable,
          sourceColumn,
          targetTable,
          targetColumn,
          marker,
        });
      }
    }

    return { diagram: { tables, relations }, error: null };
  } catch (err) {
    return { diagram: null, error: formatError(err) };
  }
}
