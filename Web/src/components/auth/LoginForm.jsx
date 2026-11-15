'use client';
import { motion } from 'framer-motion';
import { FaEnvelope, FaLock, FaEye, FaEyeSlash } from 'react-icons/fa';
import useLoginForm from '@/hooks/useLoginForm';

const LoginForm = ({ onLogin, error }) => {
  const {
    values,
    errors,
    isSubmitting,
    showPwd,
    setShowPwd,
    handleChange,
    handleSubmit,
  } = useLoginForm({ onLogin });

  return (
    <motion.form
      onSubmit={handleSubmit}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-5"
    >
      <h2 className="text-xl font-semibold text-center text-[#0077B6] tracking-wide mb-4">
        Iniciar Sesión
      </h2>

      {/* Email */}
      <div className="relative">
        <FaEnvelope className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
        <input
          type="email"
          name="email"
          placeholder="Correo Electrónico"
          value={values.email}
          onChange={handleChange}
          autoComplete="email"
          required
          className={`w-full pl-10 py-2 border rounded-lg bg-white text-slate-700 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.email ? 'border-red-500' : 'border-slate-300'
            }`}
        />
        {errors.email && <p className="text-xs text-red-600 mt-1">{errors.email}</p>}
      </div>

      {/* Password */}
      <div className="relative">
        <FaLock className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
        <input
          type={showPwd ? 'text' : 'password'}
          name="password"
          placeholder="Contraseña"
          value={values.password}
          onChange={handleChange}
          autoComplete="current-password"
          required
          className={`w-full pl-10 pr-10 py-2 border rounded-lg bg-white text-slate-700 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] ${errors.password ? 'border-red-500' : 'border-slate-300'
            }`}
        />
        <button
          type="button"
          onClick={() => setShowPwd((v) => !v)}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700"
          aria-label={showPwd ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          tabIndex={-1}
        >
          {showPwd ? <FaEyeSlash /> : <FaEye />}
        </button>
        {errors.password && <p className="text-xs text-red-600 mt-1">{errors.password}</p>}
      </div>

      {/* Botón */}
      <motion.button
        type="submit"
        disabled={isSubmitting}
        whileTap={{ scale: 0.97 }}
        className="w-full bg-gradient-to-r from-[#0077B6] to-[#00B4D8] hover:from-[#005F92] hover:to-[#0096C7] text-white py-2 rounded-lg font-semibold tracking-wide shadow-md disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {isSubmitting ? 'Ingresando…' : 'Iniciar'}
      </motion.button>

      {/* Error global (del padre) */}
      {error && <p className="text-center text-red-600 text-sm">{error}</p>}
    </motion.form>
  );
};

export default LoginForm;
