import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import { describe, it, expect } from 'vitest';
import Home from '../../src/pages/Home';

describe('Home Page', () => {
  it('renders hero section with tagline', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByText(/Use SQL Databases to the Fullest/i)).toBeInTheDocument();
  });

  it('renders feature cards', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByText(/Clean Git Diffs/i)).toBeInTheDocument();
    expect(screen.getByText(/Multi-Database Support/i)).toBeInTheDocument();
    expect(screen.getAllByText(/Schema Versioning/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Multi-File Output/i).length).toBeGreaterThan(0);
  });

  it('renders database badges', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByText(/PostgreSQL 12\+/i)).toBeInTheDocument();
    expect(screen.getByText(/MySQL 8\.0\+/i)).toBeInTheDocument();
    expect(screen.getByText(/SQLite 3\.35\+/i)).toBeInTheDocument();
  });

  it('renders AI benefits section', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByText(/AI-Friendly Schema Organization/i)).toBeInTheDocument();
    expect(screen.getAllByText(/500-line chunks/i).length).toBeGreaterThan(0);
  });

  it('renders beta notice', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByText(/Beta Version 0\.1\.0/i)).toBeInTheDocument();
  });

  it('renders call-to-action buttons', () => {
    render(
      <HelmetProvider>
        <MemoryRouter>
          <Home />
        </MemoryRouter>
      </HelmetProvider>
    );

    expect(screen.getByRole('link', { name: /Get Started/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /View on GitHub/i })).toBeInTheDocument();
  });
});
