import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout/Layout';
import Home from './pages/Home';
import Installation from './pages/GettingStarted/Installation';
import Configuration from './pages/GettingStarted/Configuration';
import QuickStart from './pages/GettingStarted/QuickStart';
import PostgreSQL from './pages/Databases/PostgreSQL';
import MySQL from './pages/Databases/MySQL';
import SQLite from './pages/Databases/SQLite';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/install" element={<Installation />} />
        <Route path="/configuration" element={<Configuration />} />
        <Route path="/quick-start" element={<QuickStart />} />
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
      <h1>404 - Page Not Found</h1>
      <p className="lead">The page you&apos;re looking for doesn&apos;t exist.</p>
      <a href="#/" className="btn btn-primary">
        Go Home
      </a>
    </div>
  );
}

export default App;
