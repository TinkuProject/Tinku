'use client';

import { useState } from 'react';
import {
    FaStore,
    FaCalendarAlt,
    FaUserCheck,
    FaBuilding,
    FaWarehouse,
} from 'react-icons/fa';

import BusinessReview from './BusinessReview';
import EventReview from './EventReview';
import TransactionReview from './TransactionReview';
import BusinessClaimReview from './BusinessClaimReview';
import WarehouseReview from './WarehouseReview';

const UI = {
    primary: '#0077B6',
    soft: '#E9F3FF',
    border: '#E2E8F0',
};

export default function ReviewPanel() {
    const [view, setView] = useState('business');
    // business | claims | events | users

    const TabBtn = ({ id, icon: Icon, children }) => {
        const active = view === id;

        return (
            <button
                onClick={() => setView(id)}
                aria-pressed={active}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold border transition
                ${active
                        ? 'bg-white text-slate-900'
                        : 'bg-white text-slate-700 hover:bg-slate-50'
                    }`}
                style={{
                    borderColor: active
                        ? UI.primary
                        : UI.border,
                }}
            >
                <Icon
                    className={
                        active
                            ? 'text-[#0077B6]'
                            : 'text-slate-500'
                    }
                />
                {children}
            </button>
        );
    };

    return (
        <div className="p-0">
            <div
                className="bg-[#F8F9FA] shadow-md rounded-lg p-6 border"
                style={{
                    borderColor: UI.border,
                }}
            >
                {/* HEADER */}
                <div className="flex items-center justify-between gap-3">
                    <h1
                        className="text-3xl font-bold"
                        style={{
                            color: UI.primary,
                        }}
                    >
                        Centro de Revisiones
                    </h1>

                    <div className="flex flex-wrap items-center gap-2">
                        <TabBtn
                            id="business"
                            icon={FaStore}
                        >
                            Negocios
                        </TabBtn>

                        <TabBtn
                            id="claims"
                            icon={FaBuilding}
                        >
                            Reclamaciones
                        </TabBtn>

                        <TabBtn
                            id="events"
                            icon={FaCalendarAlt}
                        >
                            Eventos
                        </TabBtn>

                        <TabBtn
                            id="warehouses"
                            icon={FaWarehouse}
                        >
                            Almacenes
                        </TabBtn>

                        <TabBtn
                            id="users"
                            icon={FaUserCheck}
                        >
                            Usuarios / Pagos
                        </TabBtn>
                    </div>
                </div>

                {/* VIEWS */}
                <div className="mt-6">
                    {view === 'business' && (
                        <BusinessReview />
                    )}

                    {view === 'claims' && (
                        <BusinessClaimReview />
                    )}

                    {view === 'events' && (
                        <EventReview />
                    )}

                    {view === 'warehouses' && (
                        <WarehouseReview />
                    )}

                    {view === 'users' && (
                        <TransactionReview />
                    )}
                </div>
            </div>
        </div>
    );
}
