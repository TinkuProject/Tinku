// src/hooks/useLoginForm.js
import { useCallback, useState } from 'react';
import { loginUser as loginUserService } from '@/services/authService';
import { isValidEmail, isRequired } from '@/utils/auth/validators';

export default function useLoginForm(opts = {}) {
    const { onLogin, onError, onSuccess } = opts;

    const [values, setValues] = useState({ email: '', password: '' });
    const [errors, setErrors] = useState({});
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [showPwd, setShowPwd] = useState(false);

    const handleChange = useCallback((e) => {
        const { name, value } = e.target;
        setErrors((prev) => ({ ...prev, [name]: undefined }));
        setValues((prev) => ({ ...prev, [name]: value }));
    }, []);

    const validate = useCallback(() => {
        const e = {};
        if (!isValidEmail(values.email)) e.email = 'Correo inválido';
        if (!isRequired(values.password)) e.password = 'La contraseña es obligatoria';
        return e;
    }, [values]);

    const handleSubmit = useCallback(async (e) => {
        e?.preventDefault?.();
        if (isSubmitting) return;

        const vErrors = validate();
        if (Object.keys(vErrors).length) {
            setErrors(vErrors);
            onError?.(Object.values(vErrors)[0]);
            return;
        }

        setIsSubmitting(true);

        try {
            const runner = onLogin || loginUserService;

            const result = await runner({
                email: values.email.trim(),
                password: values.password,
            });

            if (!result?.success) {
                onError?.(result?.message || 'No se pudo iniciar sesión');
                return;
            }

            onSuccess?.({
                user: result.user,
                profile: result.profile,
                token: result.token,
                refreshToken: result.refreshToken,
            });
        } catch (err) {
            console.error('[useLoginForm] submit:', err);
            onError?.(err?.message || 'Error de conexión');
        } finally {
            setIsSubmitting(false);
        }
    }, [isSubmitting, onLogin, onError, onSuccess, validate, values.email, values.password]);

    return {
        values,
        errors,
        isSubmitting,
        showPwd,
        setShowPwd,
        handleChange,
        handleSubmit,
    };
}