import { Link, useLocation } from 'react-router-dom';

const GETTING_STARTED_PATHS = ['/install', '/quick-start', '/configuration', '/troubleshooting'];
const DATABASE_PATHS = ['/databases/postgresql', '/databases/mysql', '/databases/sqlite'];

function Header() {
  const location = useLocation();

  const isActive = (path) => location.pathname === path;
  const isActiveSection = (paths) => paths.includes(location.pathname);
  const navLinkProps = (path) => ({
    className: `nav-link ${isActive(path) ? 'active' : ''}`,
    'aria-current': isActive(path) ? 'page' : undefined,
    to: path,
  });
  const dropdownItemProps = (path) => ({
    className: `dropdown-item ${isActive(path) ? 'active' : ''}`,
    'aria-current': isActive(path) ? 'page' : undefined,
    to: path,
  });

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary" aria-label="Main navigation">
      <div className="container">
        <Link className="navbar-brand fw-bold" to="/">
          <i className="bi bi-database-fill me-2" aria-hidden="true" />
          BetterStructureSql
        </Link>

        <button
          className="navbar-toggler"
          type="button"
          data-bs-toggle="collapse"
          data-bs-target="#navbarNav"
          aria-controls="navbarNav"
          aria-expanded="false"
          aria-label="Toggle navigation"
        >
          <span className="navbar-toggler-icon" />
        </button>

        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav ms-auto">
            <li className="nav-item">
              <Link {...navLinkProps('/')}>Home</Link>
            </li>
            <li className="nav-item dropdown">
              <button
                type="button"
                className={`nav-link dropdown-toggle btn btn-link ${isActiveSection(GETTING_STARTED_PATHS) ? 'active' : ''}`}
                data-bs-toggle="dropdown"
                aria-expanded="false"
              >
                Getting Started
              </button>
              <ul className="dropdown-menu dropdown-menu-dark">
                <li>
                  <Link {...dropdownItemProps('/install')}>Installation</Link>
                </li>
                <li>
                  <Link {...dropdownItemProps('/quick-start')}>Quick Start</Link>
                </li>
                <li>
                  <Link {...dropdownItemProps('/configuration')}>Configuration</Link>
                </li>
                <li>
                  <hr className="dropdown-divider" />
                </li>
                <li>
                  <Link {...dropdownItemProps('/troubleshooting')}>
                    <i className="bi bi-tools me-2" aria-hidden="true" />
                    Troubleshooting
                  </Link>
                </li>
              </ul>
            </li>
            <li className="nav-item">
              <Link {...navLinkProps('/features')}>Features</Link>
            </li>
            <li className="nav-item dropdown">
              <button
                type="button"
                className={`nav-link dropdown-toggle btn btn-link ${isActiveSection(DATABASE_PATHS) ? 'active' : ''}`}
                data-bs-toggle="dropdown"
                aria-expanded="false"
              >
                Database Guides
              </button>
              <ul className="dropdown-menu dropdown-menu-dark">
                <li>
                  <Link {...dropdownItemProps('/databases/postgresql')}>
                    <i className="bi bi-database-fill me-2" aria-hidden="true" />
                    PostgreSQL
                  </Link>
                </li>
                <li>
                  <Link {...dropdownItemProps('/databases/mysql')}>
                    <i className="bi bi-database me-2" aria-hidden="true" />
                    MySQL
                  </Link>
                </li>
                <li>
                  <Link {...dropdownItemProps('/databases/sqlite')}>
                    <i className="bi bi-database-dash me-2" aria-hidden="true" />
                    SQLite
                  </Link>
                </li>
              </ul>
            </li>
            <li className="nav-item">
              <a
                className="nav-link"
                href="https://github.com/sebyx07/better_structure_sql"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="bi bi-github" aria-hidden="true" /> GitHub
                <span className="visually-hidden"> (opens in a new tab)</span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
}

export default Header;
