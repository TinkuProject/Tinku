import { ALLOWED_CATEGORY_TYPE_VALUES } from '../constants/categoryTypes';

// Valida que el type sea permitido por la API
export function isValidCategoryType(type) {
    return ALLOWED_CATEGORY_TYPE_VALUES.has(type);
}

// Campos requeridos mínimos
export function validateCategoryRequired({ name, type }) {
    if (!name?.trim()) return 'El nombre es obligatorio';
    if (!type?.trim()) return 'El tipo es obligatorio';
    if (!isValidCategoryType(type)) return 'El tipo seleccionado no es válido';
    return null; // ok
}
