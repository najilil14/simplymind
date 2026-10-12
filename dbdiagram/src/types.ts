export type RelationMarker = '>' | '<' | '-' | '<>';

export type DiagramColumn = {
  name: string;
  type: string;
  pk: boolean;
  unique: boolean;
  notNull: boolean;
  fk: boolean;
};

export type DiagramTable = {
  id: string;
  name: string;
  columns: DiagramColumn[];
};

export type DiagramRelation = {
  id: string;
  sourceTable: string;
  sourceColumn: string;
  targetTable: string;
  targetColumn: string;
  marker: RelationMarker;
};

export type Diagram = {
  tables: DiagramTable[];
  relations: DiagramRelation[];
};

export type NodePositions = Record<string, { x: number; y: number }>;

export type ParseResult = {
  diagram: Diagram | null;
  error: string | null;
};
