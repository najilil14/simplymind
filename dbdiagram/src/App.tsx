import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent } from 'react';
import { DbmlEditor } from './components/DbmlEditor';
import { DiagramCanvas } from './components/DiagramCanvas';
import { appendRef } from './lib/appendRef';
import { parseDbml } from './lib/parseDbml';
import { clearState, loadState, saveState } from './lib/storage';
import { SAMPLE_DBML } from './sample';
import type { Diagram, NodePositions } from './types';
import './App.css';

const PARSE_MS = 250;

export default function App() {
  const initial = useMemo(() => loadState(), []);
  const [dbml, setDbml] = useState(initial.dbml);
  const [positions, setPositions] = useState<NodePositions>(initial.positions);
  const [parsed, setParsed] = useState(() => parseDbml(initial.dbml));
  const lastValid = useRef<Diagram>(parsed.diagram ?? { tables: [], relations: [] });
  const [editorWidth, setEditorWidth] = useState(38);
  const dragging = useRef(false);

  useEffect(() => {
    if (parsed.diagram) lastValid.current = parsed.diagram;
  }, [parsed]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setParsed(parseDbml(dbml));
    }, PARSE_MS);
    return () => window.clearTimeout(timer);
  }, [dbml]);

  useEffect(() => {
    saveState({ dbml, positions });
  }, [dbml, positions]);

  const resetSample = () => {
    clearState();
    setDbml(SAMPLE_DBML);
    setPositions({});
    setParsed(parseDbml(SAMPLE_DBML));
  };

  const onConnectColumns = useCallback(
    (sourceTable: string, sourceColumn: string, targetTable: string, targetColumn: string) => {
      setDbml((current) => appendRef(current, sourceTable, sourceColumn, targetTable, targetColumn));
    },
    [],
  );

  const onSplitterPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    dragging.current = true;
    event.currentTarget.setPointerCapture(event.pointerId);
  };

  const onSplitterPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    if (!dragging.current) return;
    const ratio = (event.clientX / window.innerWidth) * 100;
    setEditorWidth(Math.min(60, Math.max(22, ratio)));
  };

  const onSplitterPointerUp = () => {
    dragging.current = false;
  };

  const diagram = parsed.diagram ?? lastValid.current;

  return (
    <div className="app">
      <header className="app__header">
        <div className="app__brand">
          <span className="app__logo" aria-hidden />
          <strong>dbdiagram</strong>
          <span className="app__muted">local canvas</span>
        </div>
        <button type="button" className="app__reset" onClick={resetSample}>
          Reset sample
        </button>
      </header>
      <div className="app__body">
        {/* nokey keeps React Flow shortcuts (space to pan) from swallowing keys typed in the editor */}
        <aside className="app__editor nokey" style={{ width: `${editorWidth}%` }}>
          <DbmlEditor value={dbml} onChange={setDbml} />
          {parsed.error ? <div className="app__error">{parsed.error}</div> : null}
        </aside>
        <div
          className="app__splitter"
          onPointerDown={onSplitterPointerDown}
          onPointerMove={onSplitterPointerMove}
          onPointerUp={onSplitterPointerUp}
          role="separator"
          aria-orientation="vertical"
        />
        <main className="app__canvas">
          <DiagramCanvas
            diagram={diagram}
            positions={positions}
            onPositionsChange={setPositions}
            onConnectColumns={onConnectColumns}
          />
        </main>
      </div>
    </div>
  );
}
