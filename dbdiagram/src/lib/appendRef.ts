export function columnHandleId(columnName: string, side: 'left' | 'right'): string {
  return `${columnName}::${side}`;
}

export function parseColumnHandle(handleId: string | null | undefined): {
  column: string;
  side: 'left' | 'right';
} | null {
  if (!handleId) return null;
  const sep = handleId.lastIndexOf('::');
  if (sep < 0) return null;
  const column = handleId.slice(0, sep);
  const side = handleId.slice(sep + 2);
  if (side !== 'left' && side !== 'right') return null;
  return { column, side };
}

export function appendRef(
  dbml: string,
  sourceTable: string,
  sourceColumn: string,
  targetTable: string,
  targetColumn: string,
): string {
  if (sourceTable === targetTable && sourceColumn === targetColumn) return dbml;
  const line = `Ref: ${sourceTable}.${sourceColumn} > ${targetTable}.${targetColumn}`;
  const already =
    dbml.includes(`${sourceTable}.${sourceColumn} > ${targetTable}.${targetColumn}`) ||
    dbml.includes(`${targetTable}.${targetColumn} < ${sourceTable}.${sourceColumn}`);
  if (already) return dbml;
  const trimmed = dbml.trimEnd();
  return `${trimmed}\n\n${line}\n`;
}
