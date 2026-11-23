import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import PropTypes from 'prop-types';
import Header from './Header';
import Footer from './Footer';

// The site uses hash routing, so a plain #main-content link would change the route
function skipToMain(event) {
  event.preventDefault();
  document.getElementById('main-content').focus();
}

function Layout({ children }) {
  const location = useLocation();

  // Scroll to top on route change
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [location.pathname]);

  return (
    <div className="d-flex flex-column min-vh-100">
      <a href="#main-content" className="visually-hidden-focusable skip-link" onClick={skipToMain}>
        Skip to main content
      </a>
      <Header />
      <main id="main-content" className="flex-grow-1" tabIndex={-1}>
        {children}
      </main>
      <Footer />
    </div>
  );
}

Layout.propTypes = {
  children: PropTypes.node.isRequired,
};

export default Layout;
