'use client';

export default function AuthToggle({ isActive, onToggle, disabled = false }) {
    return (
        <p className="text-center text-sm text-[#0077B6] mt-4">
            {isActive ? 'Ya tengo una Cuenta' : 'No tengo una Cuenta'}{' '}
            <button
                type="button"
                onClick={onToggle}
                disabled={disabled}
                className="text-[#0077B6] font-medium underline hover:text-[#005F92] disabled:opacity-60 disabled:pointer-events-none"
                aria-label={isActive ? 'Ir a Iniciar Sesión' : 'Ir a Registrarse'}
            >
                {isActive ? 'Iniciar Sesión' : 'Registrarse'}
            </button>
        </p>
    );
}
