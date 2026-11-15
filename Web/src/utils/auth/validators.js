// src/utils/auth/validators.js

export const isValidEmail = (v) => /\S+@\S+\.\S+/.test(String(v || '').trim());
export const isRequired = (v) => String(v ?? '').trim().length > 0;

export const validateRegister = (values) => {
  const errors = {};

  if (!isRequired(values.first_name)) {
    errors.first_name = 'El nombre es obligatorio';
  }

  if (!isRequired(values.last_name)) {
    errors.last_name = 'El apellido es obligatorio';
  }

  if (!isValidEmail(values.email)) {
    errors.email = 'El correo no es válido';
  }

  if (!isRequired(values.password)) {
    errors.password = 'La contraseña es obligatoria';
  }

  if (values.password !== values.confirmPassword) {
    errors.confirmPassword = 'Las contraseñas no coinciden';
  }

  return errors;
};
