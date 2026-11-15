// src/hooks/useAuth.js
'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useUser } from '@/context/UserContext';
import { loginUser, registerUser } from '@/services/authService';

export default function useAuth() {
    const [isActive, setIsActive] = useState(false);
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const router = useRouter();
    const searchParams = useSearchParams();
    const { login } = useUser();

    useEffect(() => {
        if (searchParams.get('register') === 'true') {
            setIsActive(true);
        }
    }, [searchParams]);

    const onRegister = async (data) => {
        setError('');
        setIsLoading(true);

        const result = await registerUser(data);

        setIsLoading(false);

        if (result.success) {
            setIsActive(false);
            router.push('/login');
        } else {
            setError(result.message);
        }
    };

    const onLogin = async (data) => {
        setError('');
        setIsLoading(true);

        const result = await loginUser(data);

        setIsLoading(false);

        if (result.success) {
            await login({
                token: result.token,
                refreshToken: result.refreshToken,
                user: result.user,
                profile: result.profile,
            });

            const redirect = searchParams.get('redirect');
            router.push(redirect || '/inicio');
        } else {
            setError(result.message);
        }
    };

    return {
        isActive,
        setIsActive,
        error,
        isLoading,
        onRegister,
        onLogin,
    };
}