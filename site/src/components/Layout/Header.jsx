import { Link, useLocation } from 'react-router-dom';

function Header() {
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
      <div className="container">
        <Link className="navbar-brand fw-bold" to="/">
          <i className="bi bi-database-fill me-2" />
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
              <Link
                className={`nav-link ${isActive('/') ? 'active' : ''}`}
                to="/"
              >
                Home
              </Link>
            </li>
            <li className="nav-item dropdown">
              <button
                type="button"
                className="nav-link dropdown-toggle btn btn-link"
                data-bs-toggle="dropdown"
                aria-expanded="false"
              >
                Getting Started
              </button>
              <ul className="dropdown-menu dropdown-menu-dark">
                <li>
                  <Link className="dropdown-item" to="/install">
                    Installation
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/quick-start">
                    Quick Start
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/configuration">
                    Configuration
                  </Link>
                </li>
              </ul>
            </li>
            <li className="nav-item">
              <Link
                className={`nav-link ${isActive('/examples') ? 'active' : ''}`}
                to="/examples"
              >
                Examples
              </Link>
            </li>
            <li className="nav-item">
              <a
                className="nav-link"
                href="https://github.com/sebyx07/better_structure_sql"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="bi bi-github" /> GitHub
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
}

export default Header;
