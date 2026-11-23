import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect } from 'vitest';
import Home from '../../src/pages/Home';
import GEM_VERSION from '../../src/version';

describe('Home Page', () => {
  it('lists partitioned tables and table inheritance as supported', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(
      screen.getByText(/partitioned tables and table\s+inheritance\./i)
    ).toBeInTheDocument();
    expect(screen.queryByText(/not supported yet/i)).not.toBeInTheDocument();
  });

  it('renders hero section with tagline', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByText(/Use SQL Databases to the Fullest/i)).toBeInTheDocument();
  });

  it('renders feature cards', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByText(/Clean Git Diffs/i)).toBeInTheDocument();
    expect(screen.getByText(/Multi-Database Support/i)).toBeInTheDocument();
    expect(screen.getAllByText(/Schema Versioning/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Multi-File Output/i).length).toBeGreaterThan(0);
  });

  it('renders database badges', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByRole('link', { name: /^PostgreSQL$/ })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /^MySQL \/ MariaDB$/ })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /^SQLite$/ })).toBeInTheDocument();
    expect(screen.queryByText(/experimental/i)).not.toBeInTheDocument();
  });

  it('renders AI benefits section', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByText(/AI-Friendly Schema Organization/i)).toBeInTheDocument();
    expect(screen.getAllByText(/500-line chunks/i).length).toBeGreaterThan(0);
  });

  it('renders project status with the gem version', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByText(`Version ${GEM_VERSION}`)).toBeInTheDocument();
    expect(
      screen.getAllByText(/round-trip tested in CI/i).length
    ).toBeGreaterThan(0);
    expect(screen.queryByText(/beta/i)).not.toBeInTheDocument();
  });

  it('renders call-to-action buttons', () => {
    render(
      <MemoryRouter>
        <Home />
      </MemoryRouter>
    );

    expect(screen.getByRole('link', { name: /Get Started/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /View on GitHub/i })).toBeInTheDocument();
  });
});
