import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout/Layout';
import Home from './pages/Home';
import Installation from './pages/GettingStarted/Installation';
import Configuration from './pages/GettingStarted/Configuration';
import QuickStart from './pages/GettingStarted/QuickStart';
import Examples from './pages/Examples';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/install" element={<Installation />} />
        <Route path="/configuration" element={<Configuration />} />
        <Route path="/quick-start" element={<QuickStart />} />
        <Route path="/examples" element={<Examples />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Layout>
  );
}

function NotFound() {
  return (
    <div className="container text-center py-5">
      <h1>404 - Page Not Found</h1>
      <p className="lead">The page you're looking for doesn't exist.</p>
      <a href="#/" className="btn btn-primary">
        Go Home
      </a>
    </div>
  );
}

export default App;
