import React, { useEffect, ReactNode } from 'react';
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
  useLocation,
  useNavigate } from
'react-router-dom';
import { AppProvider, useApp } from './contexts/AppContext';
import { PhoneShell } from './components/PhoneShell';
import { Accueil } from './pages/Accueil';
import { CreerBoutique } from './pages/CreerBoutique';
import { Connexion } from './pages/Connexion';
import { Verrouillage } from './pages/Verrouillage';
import { Home } from './pages/Home';
import { Notifications } from './pages/Notifications';
import { Parametres } from './pages/Parametres';
import { Employes } from './pages/Employes';
import { Appareils } from './pages/Appareils';
import { Journal } from './pages/Journal';
import { Pointages } from './pages/Pointages';
import { Retours } from './pages/Retours';
import { Rapports } from './pages/Rapports';
import { peut, Permission } from './utils/permissions';

const PUBLIQUES = ['/', '/creer', '/connexion'];

function Protege({ permission, children }: {permission: Permission;children: ReactNode;}) {
  const { session } = useApp();
  if (!peut(session, permission)) return <Navigate to="/app" replace />;
  return <>{children}</>;
}

function Routeur() {
  const { session, verrouille } = useApp();
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (!session && !PUBLIQUES.includes(location.pathname)) {
      navigate('/', { replace: true });
    }
  }, [session, location.pathname, navigate]);

  if (session && verrouille) return <Verrouillage />;

  return (
    <Routes>
      <Route path="/" element={session ? <Navigate to="/app" replace /> : <Accueil />} />
      <Route path="/creer" element={<CreerBoutique />} />
      <Route path="/connexion" element={<Connexion />} />
      <Route path="/app" element={session ? <Home /> : <Accueil />} />
      <Route path="/notifications" element={<Notifications />} />
      <Route path="/parametres" element={<Parametres />} />
      <Route
        path="/parametres/employes"
        element={
        <Protege permission="gererComptes">
            <Employes />
          </Protege>
        } />
      
      <Route
        path="/parametres/appareils"
        element={
        <Protege permission="appareils">
            <Appareils />
          </Protege>
        } />
      
      <Route
        path="/journal"
        element={
        <Protege permission="journal">
            <Journal />
          </Protege>
        } />
      
      <Route
        path="/pointages"
        element={
        <Protege permission="pointages">
            <Pointages />
          </Protege>
        } />
      
      <Route
        path="/retours"
        element={
        <Protege permission="traiterRetours">
            <Retours />
          </Protege>
        } />
      
      <Route
        path="/rapports"
        element={
        <Protege permission="exporter">
            <Rapports />
          </Protege>
        } />
      
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>);

}

export function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <PhoneShell>
          <Routeur />
        </PhoneShell>
      </BrowserRouter>
    </AppProvider>);

}