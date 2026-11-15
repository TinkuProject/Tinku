// utils/auth/username.js

/**
 * Genera un username único a partir de nombre + apellido + número aleatorio
 */
export const generateUsername = (firstName, lastName) => {
  const randomNum = Math.floor(100 + Math.random() * 900);
  return `${firstName.toLowerCase()}${lastName.toLowerCase()}${randomNum}`;
};
