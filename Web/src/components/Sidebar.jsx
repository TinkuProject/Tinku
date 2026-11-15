// File: src/components/Sidebar.jsx

'use client';

import { useEffect, useMemo, useState } from 'react';
import Image from 'next/image';
import { useUser } from '../context/UserContext';
import {
  FaStore,
  FaSignOutAlt,
  FaUser,
  FaThList,
  FaUserFriends,
  FaMobileAlt,
  FaBus,
  FaBuilding,
  FaMapMarkedAlt,
  FaClipboardCheck,
  FaWallet,
  FaCalendarAlt,
  FaHistory,
  FaChevronRight,
  FaShieldAlt,
  FaCog,
} from 'react-icons/fa';

const MENU_ITEMS = [
  {
    roles: ['admin', 'partner', 'master'],
    label: 'Dashboard',
    icon: FaStore,
    component: 'Dashboard',
  },
  {
    roles: ['user'],
    label: 'Inicio',
    icon: FaMobileAlt,
    component: 'UserPanel',
  },
  {
    roles: ['master'],
    label: 'Usuarios',
    icon: FaUserFriends,
    component: 'User',
  },
  {
    roles: ['admin', 'master', 'partner'],
    label: 'Negocios',
    icon: FaBuilding,
    component: 'BusinessManager',
  },
  {
    roles: ['admin', 'master'],
    label: 'Eventos',
    icon: FaCalendarAlt,
    component: 'EventManager',
  },
  {
    roles: ['admin', 'master'],
    label: 'Lugares turísticos',
    icon: FaMapMarkedAlt,
    component: 'TouristPlaceManager',
  },
  {
    roles: ['master'],
    label: 'Categorías',
    icon: FaThList,
    component: 'Category',
  },
  {
    roles: ['admin', 'master'],
    label: 'Líneas de transporte',
    icon: FaBus,
    component: 'TransportationLines',
  },
  {
    roles: ['admin', 'master'],
    label: 'Panel de revisión',
    icon: FaClipboardCheck,
    component: 'ReviewPanel',
  },
  {
    roles: ['admin', 'master'],
    label: 'Actualizaciones',
    icon: FaHistory,
    component: 'UpdateReview',
  },
  {
    roles: ['master'],
    label: 'Gestión Tinku',
    icon: FaWallet,
    component: 'TinkuManager',
  },
  {
    roles: ['admin', 'master'],
    label: 'Configuraciones del sistema',
    icon: FaCog,
    component: 'SystemConfigManager',
  },
];

function getDefaultComponent(role) {
  if (role === 'user') {
    return 'UserPanel';
  }

  return 'Dashboard';
}

const Sidebar = ({ setActiveComponent }) => {
  const { user: currentUser, logout } = useUser();

  const currentRole =
    currentUser?.role ||
    currentUser?.profile?.role ||
    null;

  const [active, setActive] = useState(() =>
    getDefaultComponent(currentRole)
  );

  const allowedItems = useMemo(() => {
    if (!currentRole) {
      return [];
    }

    return MENU_ITEMS.filter((item) =>
      item.roles.includes(currentRole)
    );
  }, [currentRole]);

  /*
   * Al recuperar el usuario desde el contexto o localStorage,
   * establece el componente inicial según su rol.
   */
  useEffect(() => {
    if (!currentRole) {
      return;
    }

    const defaultComponent = getDefaultComponent(currentRole);

    setActive(defaultComponent);
    setActiveComponent(defaultComponent);
  }, [currentRole, setActiveComponent]);

  const handleClick = (component) => {
    setActive(component);
    setActiveComponent(component);
  };

  const fullName = [
    currentUser?.profile?.first_name,
    currentUser?.profile?.last_name,
  ]
    .filter(Boolean)
    .join(' ')
    .trim();

  const displayName =
    currentUser?.profile?.username ||
    fullName ||
    currentUser?.username ||
    currentUser?.name ||
    currentUser?.displayName ||
    currentUser?.email ||
    'Usuario';

  const displayEmail =
    currentUser?.email ||
    currentUser?.profile?.email ||
    '';

  const initials = displayName
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word.charAt(0).toUpperCase())
    .join('');

  const roleLabel = {
    user: 'Usuario',
    partner: 'Socio',
    admin: 'Administrador',
    master: 'Master',
  }[currentRole] || 'Usuario';

  return (
    <aside
      className="
        relative z-40
        flex w-full flex-col
        border-r border-slate-200
        bg-white
        shadow-xl shadow-slate-200/40
        transition-all duration-300
        md:fixed md:inset-y-0 md:left-0
        md:h-screen md:w-72
      "
    >
      {/* HEADER */}
      <div className="relative overflow-hidden border-b border-slate-200 bg-white px-5 py-5">
        <div className="absolute -right-12 -top-12 h-32 w-32 rounded-full bg-sky-100/70 blur-2xl" />

        <div className="relative flex items-center gap-3">
          <div className="relative h-14 w-14 shrink-0 overflow-hidden rounded-2xl border border-sky-100 bg-white shadow-md">
            <Image
              src="/images/LogoTinku.png"
              alt="Logo de Tinku"
              fill
              sizes="56px"
              className="object-contain p-1"
              priority
            />
          </div>

          <div className="min-w-0">
            <p className="text-xl font-black leading-none text-[#0077B6]">
              Tinku
            </p>

            <p className="mt-1 truncate text-xs font-medium text-slate-500">
              Conecta, descubre y crece
            </p>
          </div>
        </div>
      </div>

      {/* INFORMACIÓN DE NAVEGACIÓN */}
      <div className="px-5 pb-2 pt-5">
        <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">
          Navegación
        </p>
      </div>

      {/* MENÚ */}
      <nav className="flex-1 space-y-1.5 overflow-y-auto px-3 pb-5 pt-2">
        {allowedItems.length === 0 ? (
          <div className="mx-2 rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm leading-relaxed text-slate-500">
              No tienes opciones disponibles para este rol.
            </p>
          </div>
        ) : (
          allowedItems.map(({ label, icon: Icon, component }) => {
            const isActive = active === component;

            return (
              <button
                key={component}
                type="button"
                onClick={() => handleClick(component)}
                aria-current={isActive ? 'page' : undefined}
                title={label}
                className={`
                  group relative flex w-full items-center gap-3
                  overflow-hidden rounded-xl px-3.5 py-3
                  text-left text-sm font-semibold
                  transition-all duration-200
                  ${isActive
                    ? 'bg-[#0077B6] text-white shadow-lg shadow-sky-200'
                    : 'text-slate-600 hover:bg-sky-50 hover:text-[#0077B6]'
                  }
                `}
              >
                {isActive && (
                  <span className="absolute inset-y-2 left-0 w-1 rounded-r-full bg-white/90" />
                )}

                <span
                  className={`
                    flex h-9 w-9 shrink-0 items-center justify-center
                    rounded-lg text-base transition-all duration-200
                    ${isActive
                      ? 'bg-white/15 text-white'
                      : 'bg-slate-100 text-[#0077B6] group-hover:bg-white'
                    }
                  `}
                >
                  <Icon />
                </span>

                <span className="min-w-0 flex-1 truncate">
                  {label}
                </span>

                <FaChevronRight
                  className={`
                    shrink-0 text-xs transition-all duration-200
                    ${isActive
                      ? 'translate-x-0 text-white/80'
                      : '-translate-x-1 text-slate-300 opacity-0 group-hover:translate-x-0 group-hover:opacity-100'
                    }
                  `}
                />
              </button>
            );
          })
        )}
      </nav>

      {/* USUARIO */}
      {currentUser && (
        <div className="border-t border-slate-200 bg-slate-50/80 p-3">
          <div className="rounded-2xl border border-slate-200 bg-white p-3 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#0077B6] to-[#003B64] text-sm font-black text-white shadow-md">
                {initials || <FaUser />}
              </div>

              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-slate-900">
                  {displayName}
                </p>

                {displayEmail && (
                  <p className="mt-0.5 truncate text-[11px] text-slate-500">
                    {displayEmail}
                  </p>
                )}

                <div className="mt-1.5 inline-flex items-center gap-1.5 rounded-full bg-sky-50 px-2 py-1 text-[10px] font-bold uppercase tracking-wide text-[#0077B6]">
                  <FaShieldAlt />
                  {roleLabel}
                </div>
              </div>
            </div>

            <button
              type="button"
              onClick={() => handleClick('InfoUser')}
              className="
                mt-3 flex w-full items-center justify-center gap-2
                rounded-xl border border-slate-200
                bg-white px-3 py-2.5
                text-xs font-bold text-slate-700
                transition
                hover:border-sky-200 hover:bg-sky-50 hover:text-[#0077B6]
              "
              title="Ver perfil"
            >
              <FaUser />
              Ver mi perfil
            </button>

            <button
              type="button"
              onClick={logout}
              className="
                mt-2 flex w-full items-center justify-center gap-2
                rounded-xl bg-red-50 px-3 py-2.5
                text-xs font-bold text-red-600
                transition
                hover:bg-red-600 hover:text-white
              "
              title="Cerrar sesión"
            >
              <FaSignOutAlt />
              Cerrar sesión
            </button>
          </div>
        </div>
      )}
    </aside>
  );
};

export default Sidebar;
