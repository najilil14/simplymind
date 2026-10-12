import Editor, { type OnMount } from '@monaco-editor/react';
import { dbmlMonarchTokensProvider } from '@dbml/core';

type Props = {
  value: string;
  onChange: (value: string) => void;
};

export function DbmlEditor({ value, onChange }: Props) {
  const handleMount: OnMount = (_editor, monaco) => {
    const languages = monaco.languages.getLanguages();
      if (!languages.some((lang: { id: string }) => lang.id === 'dbml')) {
      monaco.languages.register({ id: 'dbml' });
      monaco.languages.setMonarchTokensProvider('dbml', dbmlMonarchTokensProvider);
    }
  };

  return (
    <Editor
      height="100%"
      language="dbml"
      theme="vs-dark"
      value={value}
      onChange={(next) => onChange(next ?? '')}
      onMount={handleMount}
      options={{
        minimap: { enabled: false },
        fontSize: 13,
        lineNumbers: 'on',
        scrollBeyondLastLine: false,
        wordWrap: 'on',
        tabSize: 2,
        automaticLayout: true,
        padding: { top: 8 },
      }}
    />
  );
}
