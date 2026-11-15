// File: src/components/Tinku/TinkuManager.jsx
'use client';

import dynamic from 'next/dynamic';
import { useState } from 'react';

// Lazy imports
const SubscriptionPlans = dynamic(
  () => import('./SubscriptionPlans/index'),
  { ssr: false }
);

const CoinPackages = dynamic(
  () => import('./CoinPackages/index'),
  { ssr: false }
);



export default function TinkuManager() {
  const [tab, setTab] = useState('subsPlans');

  const tabBtn = (value, label) => (
    <button
      key={value}
      onClick={() => setTab(value)}
      className={`px-4 py-2 rounded-md font-semibold border transition ${tab === value
          ? 'bg-[#0077B6] text-white border-[#0077B6]'
          : 'bg-white text-[#0077B6] border-[#0077B6] hover:bg-[#E0F4FF]'
        }`}
    >
      {label}
    </button>
  );

  return (
    <div className="p-8 bg-[#F8F9FA] shadow-md rounded-lg">
      <h1 className="text-3xl font-bold mb-4 text-[#0077B6]">
        Tinku Manager
      </h1>

      {/* Tabs */}
      <div className="flex flex-wrap gap-2 mb-6">
        {tabBtn('subsPlans', 'Suscripciones')}

        {tabBtn('coins', 'Paquetes de Monedas')}

     
      </div>

      {/* Contenido dinámico */}
      <div className="space-y-6">
        {tab === 'subsPlans' && <SubscriptionPlans />}

        {tab === 'coins' && <CoinPackages />}

   
      </div>
    </div>
  );
}