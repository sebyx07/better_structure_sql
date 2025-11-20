import { useState } from 'react';
import PropTypes from 'prop-types';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from 'react-syntax-highlighter/dist/esm/styles/prism';

function CodeBlock({ children, code, language, showLineNumbers, highlightLines, filename }) {
  const [copied, setCopied] = useState(false);

  // Support both 'code' prop and 'children' for backwards compatibility
  const codeContent = code || children;

  const handleCopy = () => {
    navigator.clipboard.writeText(codeContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="code-block mb-4">
      {filename && (
        <div className="code-block-header bg-dark text-light px-3 py-2 d-flex justify-content-between align-items-center">
          <span className="font-monospace small">{filename}</span>
          <button
            type="button"
            className="btn btn-sm btn-outline-light"
            onClick={handleCopy}
            aria-label="Copy code to clipboard"
          >
            <i className={`bi ${copied ? 'bi-check2' : 'bi-clipboard'} me-1`} />
            {copied ? 'Copied!' : 'Copy'}
          </button>
        </div>
      )}
      <div className="position-relative">
        {!filename && (
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary position-absolute top-0 end-0 m-2"
            onClick={handleCopy}
            style={{ zIndex: 10 }}
            aria-label="Copy code to clipboard"
          >
            <i className={`bi ${copied ? 'bi-check2' : 'bi-clipboard'}`} />
          </button>
        )}
        <SyntaxHighlighter
          language={language}
          style={oneDark}
          showLineNumbers={showLineNumbers}
          wrapLines={highlightLines && highlightLines.length > 0}
          lineProps={(lineNumber) => {
            const style = { display: 'block' };
            if (highlightLines && highlightLines.includes(lineNumber)) {
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

CodeBlock.defaultProps = {
  children: null,
  code: null,
  language: 'javascript',
  showLineNumbers: false,
  highlightLines: [],
  filename: null,
};

export default CodeBlock;
