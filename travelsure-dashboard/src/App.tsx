import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Alerts from './pages/Alerts';
import Map from './pages/Map';
import Tourists from './pages/Tourists';
import Geofences from './pages/Geofences';
import Analytics from './pages/Analytics';
import Settings from './pages/Settings';

export default function App() {
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/alerts" element={<Alerts />} />
          <Route path="/map" element={<Map />} />
          <Route path="/tourists" element={<Tourists />} />
          <Route path="/geofences" element={<Geofences />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </Layout>
    </Router>
  );
}
