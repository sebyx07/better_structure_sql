import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import { describe, it, expect } from 'vitest';
import App from '../../src/App';

describe('App', () => {
  it('renders without crashing', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    );
    expect(screen.getByRole('main')).toBeInTheDocument();
  });

  it('renders header navigation', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    );
    expect(screen.getAllByText('BetterStructureSql').length).toBeGreaterThan(0);
  });

  it('renders footer', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    );
    expect(screen.getAllByText(/Version 0.1.0/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/MIT License/i).length).toBeGreaterThan(0);
  });
});
