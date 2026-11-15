'use client';
import { FaTimes } from 'react-icons/fa';

export default function Toast({ open, onClose, children }) {
    if (!open) return null;
    return (
        <div className="fixed top-5 left-1/2 -translate-x-1/2 bg-emerald-500 text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50">
            <span>{children}</span>
            <button onClick={onClose} title="Cerrar">
                <FaTimes className="text-white/90 hover:text-white" />
            </button>
        </div>
    );
}
