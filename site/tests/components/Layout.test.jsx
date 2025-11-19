import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect } from 'vitest';
import Header from '../../src/components/Layout/Header';
import Footer from '../../src/components/Layout/Footer';
import Layout from '../../src/components/Layout/Layout';

const routerFutureFlags = {
  v7_startTransition: true,
  v7_relativeSplatPath: true,
};

describe('Header', () => {
  it('renders brand logo', () => {
    render(
      <MemoryRouter future={routerFutureFlags}>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByText('BetterStructureSql')).toBeInTheDocument();
  });

  it('renders navigation links', () => {
    render(
      <MemoryRouter future={routerFutureFlags}>
        <Header />
      </MemoryRouter>
    );
    expect(screen.getByText('Home')).toBeInTheDocument();
    expect(screen.getByText('Examples')).toBeInTheDocument();
  });
});

describe('Footer', () => {
  it('displays version', () => {
    render(<Footer />);
    expect(screen.getByText(/Version 0\.1\.0/i)).toBeInTheDocument();
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
  it('renders children content', () => {
    render(
      <MemoryRouter future={routerFutureFlags}>
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
      <MemoryRouter future={routerFutureFlags}>
        <Layout>
          <div>Content</div>
        </Layout>
      </MemoryRouter>
    );
    expect(screen.getAllByText('BetterStructureSql').length).toBeGreaterThan(0);
    expect(screen.getAllByText(/MIT License/i).length).toBeGreaterThan(0);
  });
});
