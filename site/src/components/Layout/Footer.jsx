import GEM_VERSION from '../../version';

function Footer() {
  return (
    <footer className="bg-dark text-light py-4 mt-5">
      <div className="container">
        <div className="row">
          <div className="col-md-6 mb-3 mb-md-0">
            <p className="h5 fw-bold">BetterStructureSql</p>
            <p className="footer-muted mb-2">
              Clean, maintainable database schema dumps for Rails.
            </p>
            <p className="footer-muted small">Version {GEM_VERSION} • MIT License</p>
          </div>

          <div className="col-md-3 mb-3 mb-md-0">
            <h2 className="h6 fw-bold">Documentation</h2>
            <ul className="list-unstyled small">
              <li className="mb-1">
                <a href="#/install" className="footer-muted text-decoration-none">
                  Installation
                </a>
              </li>
              <li className="mb-1">
                <a href="#/quick-start" className="footer-muted text-decoration-none">
                  Quick Start
                </a>
              </li>
              <li className="mb-1">
                <a href="#/configuration" className="footer-muted text-decoration-none">
                  Configuration
                </a>
              </li>
              <li className="mb-1">
                <a href="#/examples" className="footer-muted text-decoration-none">
                  Examples
                </a>
              </li>
            </ul>
          </div>

          <div className="col-md-3">
            <h2 className="h6 fw-bold">Links</h2>
            <ul className="list-unstyled small">
              <li className="mb-1">
                <a
                  href="https://github.com/sebyx07/better_structure_sql"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="footer-muted text-decoration-none"
                >
                  <i className="bi bi-github me-1" aria-hidden="true" />
                  GitHub
                </a>
              </li>
              <li className="mb-1">
                <a
                  href="https://rubygems.org/gems/better_structure_sql"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="footer-muted text-decoration-none"
                >
                  <i className="bi bi-gem me-1" aria-hidden="true" />
                  RubyGems
                </a>
              </li>
              <li className="mb-1">
                <a
                  href="https://github.com/sebyx07/better_structure_sql/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="footer-muted text-decoration-none"
                >
                  <i className="bi bi-bug me-1" aria-hidden="true" />
                  Issues
                </a>
              </li>
            </ul>
          </div>
        </div>

        <hr className="my-3 border-secondary" />

        <div className="text-center footer-muted small">
          <p className="mb-0">
            AI-maintained by{' '}
            <a href="https://developerz.ai" target="_blank" rel="noopener noreferrer">
              developerz.ai
            </a>{' '}
            • Source on{' '}
            <a
              href="https://github.com/sebyx07/better_structure_sql"
              target="_blank"
              rel="noopener noreferrer"
            >
              GitHub
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
