'use client';

import { useState } from 'react';

export default function SocioRequest() {
  const [formData, setFormData] = useState({
    message: '',
    comprobante: null,
  });

  const handleChange = (e) => {
    const { name, value, files } = e.target;
    if (files) {
      setFormData((prev) => ({ ...prev, [name]: files[0] }));
    } else {
      setFormData((prev) => ({ ...prev, [name]: value }));
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    alert('📩 Solicitud lista para enviarse (frontend).');
    console.log('Datos del formulario:', formData);
  };

  return (
    <div className="max-w-lg mx-auto p-4">
      <div className="bg-white shadow-md rounded-lg p-6">
        <h1 className="text-2xl font-bold text-center text-gray-800 mb-6">
          Solicitud para ser Socio
        </h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* QR */}
          <div className="text-center">
            <p className="font-semibold text-gray-800 mb-2">
              Pago de membresía (15 Bs)
            </p>
            <img
              src="/images/qr.png"
              alt="QR de pago"
              className="w-48 h-48 object-cover mx-auto mb-4"
            />
          </div>

          {/* Comprobante */}
          <div>
            <label className="block text-gray-800 font-medium mb-1">
              Subir comprobante
            </label>
            <input
              type="file"
              name="comprobante"
              accept="image/*,.pdf"
              onChange={handleChange}
              className="w-full border p-2 rounded text-gray-800"
              required
            />
          </div>

          {/* Mensaje */}
          <div>
            <label className="block text-gray-800 font-medium mb-1">
              Mensaje para el administrador
            </label>
            <textarea
              name="message"
              placeholder="Escribe tu mensaje aquí..."
              value={formData.message}
              onChange={handleChange}
              className="w-full border p-2 rounded text-gray-800"
              rows="4"
            />
          </div>

          {/* Botón */}
          <button
            type="submit"
            className="w-full bg-[#0077B6] text-white py-2 rounded hover:bg-[#005f91] transition"
          >
            Enviar Solicitud
          </button>
        </form>
      </div>
    </div>
  );
}
