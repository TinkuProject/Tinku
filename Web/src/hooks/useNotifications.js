// src/hooks/useNotifications.js
'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { NotificationsService } from '@/services/notificationsService';
import toast from 'react-hot-toast';

/**
 * Hook para manejar notificaciones de un usuario.
 *
 * @param {Object} options
 * @param {string} options.userId       - ID del usuario (obligatorio para cargar)
 * @param {boolean} options.autoLoad    - si true, carga al montar (default true)
 * @param {number} options.autoRefreshMs- polling en ms (0 = sin polling, default 0)
 * @param {number} options.limit        - cantidad máxima a traer (default 50)
 */
export default function useNotifications({
    userId,
    autoLoad = true,
    autoRefreshMs = 0,
    limit = 50,
} = {}) {
    const [notifications, setNotifications] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [updatingId, setUpdatingId] = useState(null); // para marcar lectura

    // Para evitar setState después del unmount
    const mountedRef = useRef(true);
    useEffect(() => {
        mountedRef.current = true;
        return () => {
            mountedRef.current = false;
        };
    }, []);

    // 🔄 Cargar notificaciones del usuario
    const fetchNotifications = useCallback(
        async ({ notify = false } = {}) => {
            if (!userId) {
                setNotifications([]);
                setError('');
                return;
            }

            setLoading(true);
            setError('');
            try {
                const data = await NotificationsService.getByUser(userId, limit);
                if (!mountedRef.current) return;

                // Orden: más nuevas primero
                const sorted = Array.isArray(data)
                    ? [...data].sort(
                        (a, b) =>
                            new Date(b.created_at).getTime() -
                            new Date(a.created_at).getTime()
                    )
                    : [];

                setNotifications(sorted);
                if (notify) {
                    toast.success('Notificaciones actualizadas');
                }
            } catch (e) {
                if (!mountedRef.current) return;
                const msg = e?.message || 'Error al cargar notificaciones';
                setError(msg);
                toast.error(msg);
            } finally {
                if (mountedRef.current) setLoading(false);
            }
        },
        [userId, limit]
    );

    // 📥 Carga inicial
    useEffect(() => {
        if (autoLoad && userId) {
            fetchNotifications();
        } else if (!userId) {
            setNotifications([]);
            setError('');
        }
    }, [autoLoad, userId, fetchNotifications]);

    // ⏱ Polling opcional
    useEffect(() => {
        if (!autoRefreshMs || autoRefreshMs <= 0 || !userId) return;

        const id = setInterval(() => {
            fetchNotifications();
        }, autoRefreshMs);

        return () => clearInterval(id);
    }, [autoRefreshMs, userId, fetchNotifications]);

    // 📌 No leídas
    const unreadCount = useMemo(
        () => (notifications || []).filter((n) => !n.read).length,
        [notifications]
    );

    // ✅ Marcar una como leída (optimista)
    const markAsRead = useCallback(
        async (id) => {
            if (!id) return;

            // si ya está leída, no hacemos nada
            const current = notifications.find((n) => n.id === id);
            if (!current || current.read) return;

            setUpdatingId(id);
            // update optimista
            setNotifications((prev) =>
                prev.map((n) => (n.id === id ? { ...n, read: true } : n))
            );

            try {
                await NotificationsService.markAsRead(id);
            } catch (e) {
                // revert si falla
                setNotifications((prev) =>
                    prev.map((n) =>
                        n.id === id ? { ...n, read: current.read } : n
                    )
                );
                const msg = e?.message || 'No se pudo marcar como leída';
                toast.error(msg);
            } finally {
                setUpdatingId(null);
            }
        },
        [notifications]
    );

    // ✅ Marcar todas como leídas (best effort)
    const markAllAsRead = useCallback(async () => {
        const idsToUpdate = (notifications || [])
            .filter((n) => !n.read)
            .map((n) => n.id);

        if (!idsToUpdate.length) return;

        // optimista: marcar todo como leído
        setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));

        try {
            await Promise.all(
                idsToUpdate.map((id) =>
                    NotificationsService.markAsRead(id).catch(() => null)
                )
            );
            toast.success('Todas las notificaciones marcadas como leídas');
        } catch {
            // si algo revienta fuerte, recargamos desde servidor
            fetchNotifications();
        }
    }, [notifications, fetchNotifications]);

    // ✉️ Crear notificación (por si la necesitas desde front)
    const createNotification = useCallback(
        async (payload) => {
            try {
                const created = await NotificationsService.create(payload);

                // si la notificación creada es para este userId, la metemos
                if (created?.user_id && created.user_id === userId) {
                    setNotifications((prev) => [created, ...(prev || [])]);
                }
                return created;
            } catch (e) {
                const msg = e?.message || 'No se pudo crear la notificación';
                toast.error(msg);
                throw e;
            }
        },
        [userId]
    );

    // 📢 Broadcast a admins (para panel admin si lo usas en este hook)
    const broadcastToAdmins = useCallback(async ({ message, sender_id }) => {
        try {
            const res = await NotificationsService.broadcast({ message, sender_id });
            toast.success('Notificación enviada a administradores');
            return res;
        } catch (e) {
            const msg = e?.message || 'No se pudo enviar el broadcast';
            toast.error(msg);
            throw e;
        }
    }, []);

    return {
        // estado
        notifications,
        unreadCount,
        loading,
        error,
        updatingId,

        // acciones
        fetchNotifications,
        markAsRead,
        markAllAsRead,
        createNotification,
        broadcastToAdmins,
    };
}
