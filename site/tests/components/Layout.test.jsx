import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect } from 'vitest';
import Header from '../../src/components/Layout/Header';
import Footer from '../../src/components/Layout/Footer';
import Layout from '../../src/components/Layout/Layout';
import GEM_VERSION from '../../src/version';

describe('Header', () => {
  it('renders brand logo', () => {
    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByText('BetterStructureSql')).toBeInTheDocument();
  });

  it('renders navigation links', () => {
    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByText('Home')).toBeInTheDocument();
    expect(screen.getByText('Getting Started')).toBeInTheDocument();
    expect(screen.getByText('Database Guides')).toBeInTheDocument();
  });
});

describe('Header accessibility', () => {
  it('labels the navigation landmark', () => {
    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByRole('navigation', { name: 'Main navigation' })).toBeInTheDocument();
  });
});

describe('Footer', () => {
  it('displays version', () => {
    render(<Footer />);
    expect(screen.getByText(new RegExp(`Version ${GEM_VERSION} `))).toBeInTheDocument();
    expect(screen.queryByText(/beta/i)).not.toBeInTheDocument();
  });

  it('credits developerz.ai and links the repository', () => {
    render(<Footer />);
    expect(screen.getByText(/AI-maintained by/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'developerz.ai' })).toHaveAttribute(
      'href',
      'https://developerz.ai'
    );
    expect(screen.getAllByRole('link', { name: /GitHub/ })[0]).toHaveAttribute(
      'href',
      'https://github.com/sebyx07/better_structure_sql'
    );
  });

  it('displays license', () => {
    render(<Footer />);
    expect(screen.getByText(/MIT License/i)).toBeInTheDocument();
  });

  it('renders documentation links', () => {
    render(<Footer />);
    expect(screen.getAllByText(/Installation/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Configuration/i).length).toBeGreaterThan(0);
  });
});

describe('Layout', () => {
  it('offers a skip link to the main content', () => {
    render(
      <MemoryRouter>
        <Layout>
          <div>Content</div>
        </Layout>
      </MemoryRouter>
    );
    expect(screen.getByRole('link', { name: 'Skip to main content' })).toBeInTheDocument();
    expect(screen.getByRole('main')).toHaveAttribute('id', 'main-content');
  });

  it('renders children content', () => {
    render(
      <MemoryRouter>
        <Layout>
          <div data-testid="test-content">Test Content</div>
        </Layout>
      </MemoryRouter>
    );
    expect(screen.getByTestId('test-content')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('includes header and footer', () => {
    render(
      <MemoryRouter>
        <Layout>
          <div>Content</div>
        </Layout>
      </MemoryRouter>
    );
    expect(screen.getAllByText('BetterStructureSql').length).toBeGreaterThan(0);
    expect(screen.getAllByText(/MIT License/i).length).toBeGreaterThan(0);
  });
});
