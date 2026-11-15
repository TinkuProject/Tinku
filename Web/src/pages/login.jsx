'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { useUser } from '../context/UserContext';
import Spinner from '../components/Spinner';

import LoginPageLayout from '../components/auth/LoginPageLayout';
import AuthToggle from '../components/auth/AuthToggle';
import LoginForm from '../components/auth/LoginForm';
import FormRegister from '../components/auth/FormRegister';

import { registerUser, loginUser } from '../services/authService';

export default function LoginPage() {
  const [isActive, setIsActive] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const router = useRouter();
  const { login } = useUser();

  /**
   * Detectar ?register=true
   */
  useEffect(() => {
    if (router.query.register === 'true') {
      setIsActive(true);
    }
  }, [router.query.register]);

  /**
   * =========================
   * REGISTER
   * =========================
   */
  const onRegister = async (data) => {
    setError('');
    setIsLoading(true);

    const result = await registerUser(data);

    setIsLoading(false);

    if (result.success) {
      console.log('Usuario registrado:', result.data);

      setIsActive(false);
      router.push('/login');
    } else {
      setError(result.message);
    }
  };

  /**
   * =========================
   * LOGIN
   * =========================
   */
  const onLogin = async (data) => {
    setError('');
    setIsLoading(true);

    const result = await loginUser(data);

    if (result.success) {
      await login({
        token: result.token,
        refreshToken: result.refreshToken,
        user: result.user,
        profile: result.profile,
      });

      const redirect = router.query.redirect;
      router.push(redirect || '/inicio');
    } else {
      setError(result.message);
    }

    setIsLoading(false);
  };

  /**
   * =========================
   * RENDER
   * =========================
   */
  return (
    <LoginPageLayout>
      {isLoading ? (
        <Spinner text="Cargando..." />
      ) : isActive ? (
        <FormRegister onRegister={onRegister} error={error} />
      ) : (
        <LoginForm onLogin={onLogin} error={error} />
      )}

      {!isLoading && (
        <AuthToggle
          isActive={isActive}
          onToggle={() => setIsActive(!isActive)}
        />
      )}
    </LoginPageLayout>
  );
}