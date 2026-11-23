import { Routes, Route, Link } from 'react-router-dom';
import Seo from './components/Seo/Seo';
import Layout from './components/Layout/Layout';
import Home from './pages/Home';
import Installation from './pages/GettingStarted/Installation';
import Configuration from './pages/GettingStarted/Configuration';
import QuickStart from './pages/GettingStarted/QuickStart';
import PostgreSQL from './pages/Databases/PostgreSQL';
import MySQL from './pages/Databases/MySQL';
import SQLite from './pages/Databases/SQLite';
import Troubleshooting from './pages/Troubleshooting';
import Features from './pages/Features';
import Examples from './pages/Examples';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/install" element={<Installation />} />
        <Route path="/configuration" element={<Configuration />} />
        <Route path="/quick-start" element={<QuickStart />} />
        <Route path="/features" element={<Features />} />
        <Route path="/examples" element={<Examples />} />
        <Route path="/troubleshooting" element={<Troubleshooting />} />
        <Route path="/databases/postgresql" element={<PostgreSQL />} />
        <Route path="/databases/mysql" element={<MySQL />} />
        <Route path="/databases/sqlite" element={<SQLite />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Layout>
  );
}

function NotFound() {
  return (
    <div className="container text-center py-5">
      <Seo title="Page Not Found" />
      <h1>404 - Page Not Found</h1>
      <p className="lead">The page you&apos;re looking for doesn&apos;t exist.</p>
      <Link to="/" className="btn btn-primary">
        Go Home
      </Link>
    </div>
  );
}

export default App;
