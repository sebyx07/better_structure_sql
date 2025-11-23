function Footer() {
  return (
    <footer className="bg-dark text-light py-4 mt-5">
      <div className="container">
        <div className="row">
          <div className="col-md-6 mb-3 mb-md-0">
            <h5 className="fw-bold">BetterStructureSql</h5>
            <p className="text-muted mb-2">
              Clean, maintainable database schema dumps for Rails.
            </p>
            <p className="text-muted small">
              Version 0.2.2 (Beta) • MIT License
            </p>
          </div>

          <div className="col-md-3 mb-3 mb-md-0">
            <h6 className="fw-bold">Documentation</h6>
            <ul className="list-unstyled small">
              <li className="mb-1">
                <a href="#/install" className="text-muted text-decoration-none">
                  Installation
                </a>
              </li>
              <li className="mb-1">
                <a href="#/quick-start" className="text-muted text-decoration-none">
                  Quick Start
                </a>
              </li>
              <li className="mb-1">
                <a href="#/configuration" className="text-muted text-decoration-none">
                  Configuration
                </a>
              </li>
              <li className="mb-1">
                <a href="#/examples" className="text-muted text-decoration-none">
                  Examples
                </a>
              </li>
            </ul>
          </div>

          <div className="col-md-3">
            <h6 className="fw-bold">Links</h6>
            <ul className="list-unstyled small">
              <li className="mb-1">
                <a
                  href="https://github.com/sebyx07/better_structure_sql"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted text-decoration-none"
                >
                  <i className="bi bi-github me-1" />
                  GitHub
                </a>
              </li>
              <li className="mb-1">
                <a
                  href="https://rubygems.org/gems/better_structure_sql"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted text-decoration-none"
                >
                  <i className="bi bi-gem me-1" />
                  RubyGems
                </a>
              </li>
              <li className="mb-1">
                <a
                  href="https://github.com/sebyx07/better_structure_sql/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-muted text-decoration-none"
                >
                  <i className="bi bi-bug me-1" />
                  Issues
                </a>
              </li>
            </ul>
          </div>
        </div>

        <hr className="my-3 border-secondary" />

        <div className="text-center text-muted small">
          <p className="mb-0">
            Built with <i className="bi bi-heart-fill text-danger" /> by the community
          </p>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
