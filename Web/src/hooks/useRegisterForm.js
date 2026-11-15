// src/hooks/useRegisterForm.js
import { useCallback, useMemo, useRef, useState } from 'react';
import { validateRegister } from '@/utils/auth/validators';
import { registerUser as registerUserService } from '@/services/authService';

function generateUsername(firstName = '', lastName = '') {
    const randomNum = Math.floor(100 + Math.random() * 900);

    const base = `${firstName}${lastName}`
        .toLowerCase()
        .replace(/\s+/g, '')
        .replace(/[^a-z0-9]/g, '');

    return `${base.slice(0, 17)}${randomNum}`;
}

export default function useRegisterForm(opts = {}) {
    const { onRegister, onError, onSuccess } = opts;

    const [values, setValues] = useState({
        first_name: '',
        last_name: '',
        email: '',
        password: '',
        confirmPassword: '',
    });

    const [errors, setErrors] = useState({});
    const [isSubmitting, setIsSubmitting] = useState(false);
    const firstErrorRef = useRef(null);

    const handleChange = useCallback((e) => {
        const { name, value } = e.target;

        setErrors((prev) => ({ ...prev, [name]: undefined }));
        setValues((prev) => ({ ...prev, [name]: value }));
    }, []);

    const payload = useMemo(() => ({
        first_name: values.first_name.trim(),
        last_name: values.last_name.trim(),
        email: values.email.trim(),
        password: values.password,
        username: generateUsername(values.first_name, values.last_name),

        // IMPORTANTE: tu backend actual usa role, no user_type
        role: 'user',

        location: {
            coordinates: [-66.15886727752816, -17.392543506885183],
        },
    }), [values]);

    const handleSubmit = useCallback(async (e) => {
        e?.preventDefault?.();

        if (isSubmitting) return;

        const vErrors = validateRegister(values);

        if (Object.keys(vErrors).length > 0) {
            setErrors(vErrors);
            firstErrorRef.current?.focus?.();
            onError?.(Object.values(vErrors)[0]);
            return;
        }

        setIsSubmitting(true);

        try {
            const runner = onRegister || registerUserService;
            const result = await runner(payload);

            if (!result?.success) {
                const msg = result?.message || 'No se pudo registrar';
                onError?.(msg);
                return;
            }

            onSuccess?.(result.data || result.user);
        } catch (err) {
            console.error('[useRegisterForm] submit:', err);
            onError?.(err?.message || 'Error de conexión');
        } finally {
            setIsSubmitting(false);
        }
    }, [isSubmitting, onRegister, onError, onSuccess, payload, values]);

    return {
        values,
        errors,
        isSubmitting,
        firstErrorRef,
        handleChange,
        handleSubmit,
        generateUsername,
    };
}