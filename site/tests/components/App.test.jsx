import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect } from 'vitest';
import App from '../../src/App';

const renderAt = (path) =>
  render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>
  );

const ROUTES = [
  ['/install', 'Installation'],
  ['/quick-start', 'Quick Start'],
  ['/configuration', 'Configuration'],
  ['/features', 'Features'],
  ['/examples', 'Examples'],
  ['/troubleshooting', 'Troubleshooting'],
  ['/databases/postgresql', 'PostgreSQL Guide'],
  ['/databases/mysql', 'MySQL Guide'],
  ['/databases/sqlite', 'SQLite Guide'],
];

describe('App routes', () => {
  it.each(ROUTES)('renders %s with its heading and title', (path, heading) => {
    renderAt(path);

    expect(screen.getByRole('heading', { level: 1, name: heading })).toBeInTheDocument();
    expect(document.title).toBe(`${heading} - BetterStructureSql`);
  });

  it('renders a not found page for unknown routes', () => {
    renderAt('/nope');

    expect(screen.getByRole('heading', { level: 1, name: /Page Not Found/i })).toBeInTheDocument();
  });

  it('marks the current page in the navigation', () => {
    renderAt('/features');

    expect(screen.getByRole('link', { name: 'Features' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByRole('link', { name: 'Home' })).not.toHaveAttribute('aria-current');
  });

  it('documents partitioned tables as unsupported on the PostgreSQL guide', () => {
    renderAt('/databases/postgresql');

    expect(screen.getByRole('heading', { name: /Not Yet Supported/i })).toBeInTheDocument();
    expect(screen.queryByText(/Partitioned Tables Tutorial/i)).not.toBeInTheDocument();
  });
});

describe('App', () => {
  it('renders without crashing', () => {
    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>
    );
    expect(screen.getByRole('main')).toBeInTheDocument();
  });

  it('renders header navigation', () => {
    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>
    );
    expect(screen.getAllByText('BetterStructureSql').length).toBeGreaterThan(0);
  });

  it('renders footer', () => {
    render(
      <MemoryRouter>
        <App />
      </MemoryRouter>
    );
    expect(screen.getAllByText(/Version \d+\.\d+\.\d+/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/MIT License/i).length).toBeGreaterThan(0);
  });
});
