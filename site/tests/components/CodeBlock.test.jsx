import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, afterEach } from 'vitest';
import CodeBlock from '../../src/components/CodeBlock/CodeBlock';

const stubClipboard = (writeText) => vi.stubGlobal('navigator', { clipboard: { writeText } });

describe('CodeBlock', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('renders code passed as children or as the code prop', () => {
    const { container, rerender } = render(<CodeBlock language="bash">bundle install</CodeBlock>);
    expect(container).toHaveTextContent('bundle install');

    rerender(<CodeBlock language="text" code="plain output" />);
    expect(container).toHaveTextContent('plain output');
  });

  it('shows the filename when given', () => {
    render(
      <CodeBlock language="ruby" filename="Gemfile">
        {"gem 'better_structure_sql'"}
      </CodeBlock>
    );
    expect(screen.getByText('Gemfile')).toBeInTheDocument();
  });

  it('copies the code and confirms it', async () => {
    const writeText = vi.fn().mockResolvedValue();
    stubClipboard(writeText);
    render(<CodeBlock language="bash">bundle install</CodeBlock>);

    fireEvent.click(screen.getByRole('button', { name: 'Copy code to clipboard' }));

    expect(writeText).toHaveBeenCalledWith('bundle install');
    expect(
      await screen.findByRole('button', { name: 'Copied! code to clipboard' })
    ).toBeInTheDocument();
  });

  it('reports a failed copy', async () => {
    stubClipboard(vi.fn().mockRejectedValue(new Error('denied')));
    render(<CodeBlock language="bash">bundle install</CodeBlock>);

    fireEvent.click(screen.getByRole('button', { name: 'Copy code to clipboard' }));

    expect(
      await screen.findByRole('button', { name: 'Copy failed code to clipboard' })
    ).toBeInTheDocument();
  });
});
