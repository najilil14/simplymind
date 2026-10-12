import type { NodePositions } from '../types';
import { SAMPLE_DBML } from '../sample';

const KEY = 'dbdiagram-simple-v2';

export type PersistedState = {
  dbml: string;
  positions: NodePositions;
};

export function loadState(): PersistedState {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return { dbml: SAMPLE_DBML, positions: {} };
    const parsed = JSON.parse(raw) as PersistedState;
    if (typeof parsed.dbml !== 'string') return { dbml: SAMPLE_DBML, positions: {} };
    return {
      dbml: parsed.dbml,
      positions: parsed.positions && typeof parsed.positions === 'object' ? parsed.positions : {},
    };
  } catch {
    return { dbml: SAMPLE_DBML, positions: {} };
  }
}

export function saveState(state: PersistedState): void {
  localStorage.setItem(KEY, JSON.stringify(state));
}

export function clearState(): void {
  localStorage.removeItem(KEY);
}
