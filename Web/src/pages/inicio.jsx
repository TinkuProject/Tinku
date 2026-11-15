// src/pages/inicio.jsx

'use client';

import { useState } from 'react';

import { useUser } from '@/context/UserContext';

import Sidebar from '@/components/Sidebar';
import Dashboard from '@/components/Dashboard';
import Spinner from '@/components/Spinner';

import InfoUser from '@/components/user/InfoUser';
import User from '@/components/Admin/User';
import UserPanel from '@/components/UserBasic/UserPanel';

import Category from '@/components/Category/Category';

import BusinessManager from '@/components/Business/BusinessManager';
import EventManager from '@/components/Events/EventManager';
import TouristPlace from '@/components/TouristPlace/TouristPlaceManager';

import ReviewPanel from '@/components/Review/ReviewPanel';
import UpdateReview from '@/components/UpdateReview/UpdateReview';

import TransportationLines from '@/components/Transport/TransportationLines';
import TinkuManager from '@/components/Tinku/TinkuManeger';
import SystemConfigManager from '@/components/SystemConfig/SystemConfigManager';

function Inicio() {
  const { loading } = useUser();

  const [activeComponent, setActiveComponent] = useState('Dashboard');

  const renderComponent = () => {
    switch (activeComponent) {
      case 'Dashboard':
        return <Dashboard />;

      case 'User':
        return <User />;

      case 'Category':
        return <Category />;

      case 'BusinessManager':
        return <BusinessManager />;

      case 'EventManager':
        return <EventManager />;

      case 'TouristPlaceManager':
        return <TouristPlace />;

      case 'ReviewPanel':
        return <ReviewPanel />;

      case 'UpdateReview':
        return <UpdateReview />;

      case 'InfoUser':
        return <InfoUser />;

      case 'TransportationLines':
        return <TransportationLines />;

      case 'TinkuManager':
        return <TinkuManager />;
        
      case 'SystemConfigManager':
        return <SystemConfigManager />;

      case 'UserPanel':
        return <UserPanel />;

      default:
        return (
          <h1 className="text-xl font-semibold">
            Componente no encontrado
          </h1>
        );
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Spinner text="Cargando tu panel..." />
      </div>
    );
  }

  return (
    <div className="min-h-screen md:flex">
      <Sidebar setActiveComponent={setActiveComponent} />

      <main className="w-full bg-[#F1F5F9] p-6 transition-all duration-300 md:ml-64">
        {renderComponent()}
      </main>
    </div>
  );
}

Inicio.auth = true;

export default Inicio;