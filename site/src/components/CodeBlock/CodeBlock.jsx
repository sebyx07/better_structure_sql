import { useState } from 'react';
import PropTypes from 'prop-types';
import SyntaxHighlighter from 'react-syntax-highlighter/dist/esm/prism-light';
import bash from 'react-syntax-highlighter/dist/esm/languages/prism/bash';
import ruby from 'react-syntax-highlighter/dist/esm/languages/prism/ruby';
import sql from 'react-syntax-highlighter/dist/esm/languages/prism/sql';
import yaml from 'react-syntax-highlighter/dist/esm/languages/prism/yaml';
import { oneDark } from 'react-syntax-highlighter/dist/esm/styles/prism';

// Only the languages the docs use are registered, which keeps the bundle small.
// Any other language (e.g. "text") renders as plain, unhighlighted code.
SyntaxHighlighter.registerLanguage('bash', bash);
SyntaxHighlighter.registerLanguage('ruby', ruby);
SyntaxHighlighter.registerLanguage('sql', sql);
SyntaxHighlighter.registerLanguage('yaml', yaml);

const COPY_FEEDBACK_MS = 2000;
const COPY_LABELS = { idle: 'Copy', copied: 'Copied!', failed: 'Copy failed' };
const COPY_ICONS = { idle: 'bi-clipboard', copied: 'bi-check2', failed: 'bi-x-circle' };

function CodeBlock({
  children = null,
  code = null,
  language = 'text',
  showLineNumbers = false,
  highlightLines = [],
  filename = null,
}) {
  const [copyState, setCopyState] = useState('idle');

  // Support both 'code' prop and 'children' for backwards compatibility
  const codeContent = code || children;

  const showFeedback = (state) => {
    setCopyState(state);
    setTimeout(() => setCopyState('idle'), COPY_FEEDBACK_MS);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(codeContent).then(
      () => showFeedback('copied'),
      () => showFeedback('failed')
    );
  };

  return (
    <div className="code-block mb-4">
      {filename && (
        <div className="code-block-header bg-dark text-light px-3 py-2 d-flex justify-content-between align-items-center">
          <span className="font-monospace small">{filename}</span>
          <button type="button" className="btn btn-sm btn-outline-light" onClick={handleCopy}>
            <i className={`bi ${COPY_ICONS[copyState]} me-1`} aria-hidden="true" />
            {COPY_LABELS[copyState]}
            <span className="visually-hidden"> code to clipboard</span>
          </button>
        </div>
      )}
      <div className="position-relative">
        {!filename && (
          <button
            type="button"
            className="btn btn-sm btn-outline-light position-absolute top-0 end-0 m-2"
            onClick={handleCopy}
            style={{ zIndex: 10 }}
            aria-label={`${COPY_LABELS[copyState]} code to clipboard`}
          >
            <i className={`bi ${COPY_ICONS[copyState]}`} aria-hidden="true" />
          </button>
        )}
        <SyntaxHighlighter
          language={language}
          style={oneDark}
          showLineNumbers={showLineNumbers}
          wrapLines={highlightLines.length > 0}
          lineProps={(lineNumber) => {
            const style = { display: 'block' };
            if (highlightLines.includes(lineNumber)) {
              style.backgroundColor = 'rgba(255, 255, 0, 0.1)';
            }
            return { style };
          }}
          customStyle={{
            margin: 0,
            borderRadius: filename ? '0 0 0.375rem 0.375rem' : '0.375rem',
            fontSize: '0.875rem',
          }}
        >
          {codeContent}
        </SyntaxHighlighter>
      </div>
    </div>
  );
}

CodeBlock.propTypes = {
  children: PropTypes.string,
  code: PropTypes.string,
  language: PropTypes.string,
  showLineNumbers: PropTypes.bool,
  highlightLines: PropTypes.arrayOf(PropTypes.number),
  filename: PropTypes.string,
};

export default CodeBlock;
