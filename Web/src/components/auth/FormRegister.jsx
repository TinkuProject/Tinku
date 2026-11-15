'use client';
import { motion } from 'framer-motion';
import { FaUser, FaLock, FaEnvelope } from 'react-icons/fa';
import useRegisterForm from '@/hooks/useRegisterForm';

const FormRegister = ({ onRegister, error }) => {
  const {
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
  } = useRegisterForm({ onRegister });

  // ayudas por-campo para accesibilidad y autocompletado
  const fieldMeta = {
    first_name: { autoComplete: 'given-name', icon: FaUser, type: 'text', placeholder: 'Nombre' },
    last_name:  { autoComplete: 'family-name', icon: FaUser, type: 'text', placeholder: 'Apellidos' },
    email:      { autoComplete: 'email', inputMode: 'email', icon: FaEnvelope, type: 'email', placeholder: 'Correo Electrónico',
                  // patrón simple: lo fuerte lo hace tu hook, esto sólo ayuda al navegador
                  pattern: '\\S+@\\S+\\.\\S+' },
    password:   { autoComplete: 'new-password', icon: FaLock, type: 'password', placeholder: 'Contraseña', minLength: 8 },
    confirmPassword: { autoComplete: 'new-password', icon: FaLock, type: 'password', placeholder: 'Confirmar Contraseña', minLength: 8 },
  };

  return (
    <motion.form
      onSubmit={handleSubmit}
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-5"
    >
      <h2 className="text-xl font-semibold text-center text-[#0077B6] tracking-wide mb-2">
        Crear una Cuenta
      </h2>

      {Object.entries(fieldMeta).map(([name, meta]) => {
        const Icon = meta.icon;
        return (
          <div className="relative" key={name}>
            <Icon className="absolute left-3 top-1/2 -translate-y-1/2 text-[#0077B6]" />
            <input
              name={name}
              type={meta.type}
              placeholder={meta.placeholder}
              value={values[name]}
              onChange={handleChange}
              required
              autoComplete={meta.autoComplete}
              inputMode={meta.inputMode}
              minLength={meta.minLength}
              pattern={meta.pattern}
              aria-invalid={errors[name] ? 'true' : 'false'}
              className={`w-full pl-10 py-2 border rounded-lg bg-white text-slate-700 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-[#0077B6] focus:border-[#0077B6] transition ${
                errors[name] ? 'border-red-500' : 'border-slate-300'
              }`}
            />
            {errors[name] && (
              <p className="text-xs text-red-600 mt-1">{errors[name]}</p>
            )}
          </div>
        );
      })}

      {/* Botón de registro */}
      <motion.button
        type="submit"
        disabled={isSubmitting}
        whileTap={{ scale: 0.97 }}
        className="w-full bg-gradient-to-r from-[#0077B6] to-[#00B4D8] hover:from-[#005F92] hover:to-[#0096C7] text-white py-2 rounded-lg font-semibold tracking-wide shadow-md disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {isSubmitting ? 'Creando cuenta...' : 'Registrarse'}
      </motion.button>

      {/* Error global (prop del padre) */}
      {error && <p className="text-center text-red-600 text-sm">{error}</p>}
    </motion.form>
  );
};

export default FormRegister;
