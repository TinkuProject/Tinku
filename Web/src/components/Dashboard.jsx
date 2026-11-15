// src/components/Dashboard.jsx
'use client';

import { useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useUser } from '../context/UserContext';

import {
  FaUsers,
  FaStore,
  FaCalendarAlt,
  FaMapMarkerAlt,
  FaExclamationCircle,
  FaUserShield,
  FaListAlt,
  FaBolt,
  FaBus,
  FaCreditCard,
  FaMoneyBillWave,
  FaCheckCircle,
  FaTimesCircle,
  FaHourglassHalf,
  FaCoins,
  FaChartLine,
  FaCrown,
  FaBoxOpen,
} from 'react-icons/fa';

import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Legend,
} from 'recharts';

import useBusiness from '@/hooks/useBusiness';
import useEvents from '@/hooks/useEvents';
import useUsers from '@/hooks/useUsers';
import useSubscriptionPlans from '@/hooks/useSubscriptionPlans';
import useTransportLines from '@/hooks/useTransportLines';
import useTouristPlace from '@/hooks/useTouristPlace';
import useCategories from '@/hooks/useCategories';
import useChargingPoints from '@/hooks/useChargingPoints';
import usePaymentRequests from '@/hooks/usePaymentRequests';
import useCoinPackages from '@/hooks/useCoinPackages';

const COLORS = ['#0ea5e9', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6'];

const toNumber = (v) => {
  const n = Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
};

const lower = (v) => String(v ?? '').trim().toLowerCase();

const isActiveStatus = (raw) =>
  ['1', 'active', 'activo', 'true', 'si', 'yes'].includes(lower(raw));

const isStatus = (item, status) => lower(item?.status) === status;

const getNested = (obj, paths = []) => {
  for (const path of paths) {
    const value = path.split('.').reduce((acc, key) => acc?.[key], obj);
    if (value !== undefined && value !== null && value !== '') return value;
  }

  return undefined;
};

const getPaymentTargetId = (p) =>
  Number(
    getNested(p, [
      'targetId',
      'target_id',
      'package_id',
      'coin_package_id',
      'subscription_plan_id',
      'plan_id',
      'payment.target_id',
    ])
  );

const getPaymentType = (p) =>
  lower(
    getNested(p, [
      'type',
      'request_type',
      'payment_type',
      'payment.type',
    ])
  );

const getPaymentAmount = (p, coinPackages = [], plans = []) => {
  const direct = toNumber(
    getNested(p, [
      'cash_amount',
      'cashAmount',
      'amount',
      'price',
      'total',
      'total_amount',
      'bs_amount',
      'bob_amount',
      'payment.amount',
      'payment.price',
      'payment.total',
      'payment.total_amount',
      'payment.cash_amount',
      'package.price',
      'package.cash_amount',
      'coin_package.cash_amount',
      'coinPackage.cash_amount',
      'subscription.price',
      'subscription_plan.price',
      'plan.price',
    ])
  );

  if (direct > 0) return direct;

  const type = getPaymentType(p);
  const targetId = getPaymentTargetId(p);

  if (type.includes('coin') || type.includes('package')) {
    const pkg = coinPackages.find((x) => Number(x.id) === targetId);
    return toNumber(pkg?.cash_amount ?? pkg?.price ?? pkg?.amount);
  }

  if (type.includes('subscription') || type.includes('partner')) {
    const plan = plans.find((x) => Number(x.id) === targetId);
    return toNumber(plan?.price ?? plan?.amount);
  }

  return 0;
};

const getPaymentTinkus = (p, coinPackages = [], plans = []) => {
  const direct = toNumber(
    getNested(p, [
      'tinkus_amount',
      'tinkusAmount',
      'included_tinku',
      'coins',
      'tinkus',
      'payment.tinkus_amount',
      'payment.included_tinku',
      'package.tinkus_amount',
      'coin_package.tinkus_amount',
      'coinPackage.tinkus_amount',
      'subscription.included_tinku',
      'subscription_plan.included_tinku',
      'plan.included_tinku',
    ])
  );

  if (direct > 0) return direct;

  const type = getPaymentType(p);
  const targetId = getPaymentTargetId(p);

  if (type.includes('coin') || type.includes('package')) {
    const pkg = coinPackages.find((x) => Number(x.id) === targetId);
    return toNumber(pkg?.tinkus_amount);
  }

  if (type.includes('subscription') || type.includes('partner')) {
    const plan = plans.find((x) => Number(x.id) === targetId);
    return toNumber(plan?.included_tinku);
  }

  return 0;
};

export default function Dashboard() {
  const { user, loading } = useUser();
  const router = useRouter();

  const { users = [], loading: loadingUsers } = useUsers?.() || {};
  const { businesses = [], loading: loadingBusinesses } = useBusiness({ autoLoad: true });
  const { filteredRows: events = [], loading: loadingEvents } = useEvents({ autoLoad: true });
  const { plans = [], loadingList: loadingPlans } = useSubscriptionPlans();
  const { coinPackages = [], loadingList: loadingCoinPackages } = useCoinPackages();
  const { rawRows: paymentRequests = [], loading: loadingPayments } = usePaymentRequests();
  const { allRows: transportLines = [], loading: loadingTransport } = useTransportLines();
  const { places = [], loading: loadingPlaces } = useTouristPlace({ autoLoad: true });
  const { categories = [], loadingList: loadingCategories } = useCategories();

  const {
    rows: chargingPoints = [],
    loading: loadingChargingPoints,
  } = useChargingPoints({ autoLoad: true });

  useEffect(() => {
    if (!loading && !user) router.push('/');
  }, [user, loading, router]);

  const stats = useMemo(() => {
    const totalUsers = users.length;

    const partners = users.filter((u) =>
      ['partner', 'socio'].includes(lower(u?.user_type ?? u?.role ?? u?.rol))
    ).length;

    const totalBusinesses = businesses.length;
    const activeBusinesses = businesses.filter((b) => isStatus(b, 'active')).length;
    const pendingBusinesses = businesses.filter((b) => isStatus(b, 'pending')).length;

    const totalEvents = events.length;
    const activeEvents = events.filter((e) => isStatus(e, 'active')).length;
    const pendingEvents = events.filter((e) => isStatus(e, 'pending')).length;

    const activePlans = plans.filter((p) => isActiveStatus(p?.status)).length;
    const activeCoinPackages = coinPackages.filter((p) => isActiveStatus(p?.status)).length;

    const totalTransportLines = transportLines.length;
    const activeTransportLines = transportLines.filter((l) =>
      isActiveStatus(l?.status ?? l?.estado ?? l?.is_active ?? l?.active)
    ).length;

    const totalPlaces = places.length;
    const activePlaces = places.filter((p) =>
      isActiveStatus(p?.status ?? p?.estado ?? p?.is_active ?? p?.active)
    ).length;

    const placesWithoutCoords = places.filter((p) => {
      const hasLatLng =
        (p.lat != null && p.lng != null) ||
        (p.latitude != null && p.longitude != null) ||
        (p.location?.latitude != null && p.location?.longitude != null);

      const hasGeoJSON =
        p.location?.type === 'Point' &&
        Array.isArray(p.location?.coordinates) &&
        p.location.coordinates.length === 2;

      return !hasLatLng && !hasGeoJSON;
    }).length;

    const totalCategories = categories.length;

    const eventCategories = categories.filter(
      (c) => lower(c.type || c.entity_type) === 'event'
    ).length;

    const businessCategories = categories.filter(
      (c) => lower(c.type || c.entity_type) === 'business'
    ).length;

    const totalChargingPoints = chargingPoints.length;

    const activeChargingPoints = chargingPoints.filter((cp) =>
      isActiveStatus(cp?.status ?? cp?.estado ?? cp?.is_active ?? cp?.active)
    ).length;

    const loadingAny =
      loadingUsers ||
      loadingBusinesses ||
      loadingEvents ||
      loadingPlans ||
      loadingCoinPackages ||
      loadingPayments ||
      loadingTransport ||
      loadingPlaces ||
      loadingCategories ||
      loadingChargingPoints;

    return {
      loadingAny,
      totalUsers,
      partners,
      totalBusinesses,
      activeBusinesses,
      pendingBusinesses,
      totalEvents,
      activeEvents,
      pendingEvents,
      activePlans,
      activeCoinPackages,
      totalTransportLines,
      activeTransportLines,
      totalPlaces,
      activePlaces,
      placesWithoutCoords,
      totalCategories,
      eventCategories,
      businessCategories,
      totalChargingPoints,
      activeChargingPoints,
    };
  }, [
    users,
    businesses,
    events,
    plans,
    coinPackages,
    transportLines,
    places,
    categories,
    chargingPoints,
    loadingUsers,
    loadingBusinesses,
    loadingEvents,
    loadingPlans,
    loadingCoinPackages,
    loadingPayments,
    loadingTransport,
    loadingPlaces,
    loadingCategories,
    loadingChargingPoints,
  ]);

  const economy = useMemo(() => {
    const approved = paymentRequests.filter((p) => lower(p?.status) === 'approved');
    const pending = paymentRequests.filter((p) => lower(p?.status) === 'pending');
    const rejected = paymentRequests.filter((p) => lower(p?.status) === 'rejected');

    const totalRevenue = approved.reduce(
      (acc, p) => acc + getPaymentAmount(p, coinPackages, plans),
      0
    );

    const tinkusSold = approved.reduce(
      (acc, p) => acc + getPaymentTinkus(p, coinPackages, plans),
      0
    );

    const activePackages = coinPackages.filter((p) => lower(p?.status) === 'active');
    const activePlans = plans.filter((p) => lower(p?.status) === 'active');

    const offeredTinkusPackages = activePackages.reduce(
      (acc, p) => acc + toNumber(p?.tinkus_amount),
      0
    );

    const offeredTinkusPlans = activePlans.reduce(
      (acc, p) => acc + toNumber(p?.included_tinku),
      0
    );

    const offeredTinkus = offeredTinkusPackages + offeredTinkusPlans;

    const packageValueRows = activePackages.map((p) => {
      const cash = toNumber(p?.cash_amount ?? p?.price ?? p?.amount);
      const tinkus = toNumber(p?.tinkus_amount);
      const ratio = cash > 0 ? tinkus / cash : 0;
      const bobPerTinku = tinkus > 0 ? cash / tinkus : 0;

      return {
        id: p.id,
        name: p.name || `Pack ${p.id}`,
        cash,
        tinkus,
        ratio,
        bobPerTinku,
      };
    });

    const planValueRows = activePlans.map((p) => {
      const cash = toNumber(p?.price ?? p?.amount);
      const tinkus = toNumber(p?.included_tinku);
      const duration = toNumber(p?.duration_months);
      const monthly = duration > 0 ? cash / duration : cash;
      const ratio = cash > 0 ? tinkus / cash : 0;
      const bobPerTinku = tinkus > 0 ? cash / tinkus : 0;

      return {
        id: p.id,
        name: p.name || `Plan ${p.id}`,
        cash,
        tinkus,
        duration,
        monthly,
        ratio,
        bobPerTinku,
      };
    });

    const allValueRows = [...packageValueRows, ...planValueRows];

    const bestPackage = packageValueRows
      .slice()
      .sort((a, b) => b.ratio - a.ratio)[0];

    const bestPlan = planValueRows
      .slice()
      .sort((a, b) => b.ratio - a.ratio)[0];

    const avgTinkuValue =
      allValueRows.length > 0
        ? allValueRows.reduce((acc, p) => acc + p.bobPerTinku, 0) / allValueRows.length
        : 0;

    const paymentStatusData = [
      { name: 'Aprobados', value: approved.length },
      { name: 'Pendientes', value: pending.length },
      { name: 'Rechazados', value: rejected.length },
    ];

    const coinPackageChartData = packageValueRows.map((p) => ({
      name: p.name,
      Tinkus: p.tinkus,
      Bs: p.cash,
    }));

    const subscriptionChartData = planValueRows.map((p) => ({
      name: p.name,
      Tinkus: p.tinkus,
      Bs: p.cash,
      Mensual: Number(p.monthly.toFixed(2)),
    }));

    return {
      approvedPayments: approved.length,
      pendingPayments: pending.length,
      rejectedPayments: rejected.length,
      totalRevenue,
      tinkusSold,
      offeredTinkus,
      offeredTinkusPackages,
      offeredTinkusPlans,
      activePackages: activePackages.length,
      activePlans: activePlans.length,
      bestPackage,
      bestPlan,
      avgTinkuValue,
      paymentStatusData,
      coinPackageChartData,
      subscriptionChartData,
      packageValueRows,
      planValueRows,
    };
  }, [paymentRequests, coinPackages, plans]);

  if (loading || !user) return null;

  return (
    <div className="p-6 md:p-10 space-y-8">
      <header>
        <h1 className="text-3xl font-bold text-sky-700">Dashboard Tinku</h1>

        <p className="mt-2 text-base md:text-lg text-gray-800">
          Bienvenido, <b>{user.username || user.email}</b>
        </p>

        <p className="text-sm text-gray-600">
          Rol:{' '}
          <span className="font-semibold">
            {user.user_type || user.role || 'No definido'}
          </span>
        </p>
      </header>

      <section className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
        <HeaderSection title="Resumen general" loading={stats.loadingAny} />

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard label="Usuarios totales" value={stats.totalUsers} icon={<FaUsers />} color="text-sky-600" />
          <StatCard label="Socios" value={stats.partners} icon={<FaUserShield />} color="text-purple-600" />
          <StatCard label="Negocios activos" value={stats.activeBusinesses} icon={<FaStore />} color="text-emerald-600" />
          <StatCard label="Eventos activos" value={stats.activeEvents} icon={<FaCalendarAlt />} color="text-amber-500" />
        </div>

        <div className="mt-6 grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard label="Líneas activas" value={stats.activeTransportLines} icon={<FaBus />} color="text-lime-600" />
          <StatCard label="Lugares activos" value={stats.activePlaces} icon={<FaMapMarkerAlt />} color="text-rose-600" />
          <StatCard label="Categorías totales" value={stats.totalCategories} icon={<FaListAlt />} color="text-indigo-600" />
          <StatCard label="Puntos de recarga activos" value={stats.activeChargingPoints} icon={<FaBolt />} color="text-yellow-500" />
        </div>
      </section>

      <section className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
        <HeaderSection
          title="Economía Tinku"
          subtitle="Estado financiero, paquetes, suscripciones y movimiento de pagos."
          loading={loadingPayments || loadingCoinPackages || loadingPlans}
        />

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">


          <StatCard
            label="Tinkus vendidos"
            value={economy.tinkusSold}
            icon={<FaCoins />}
            color="text-yellow-500"
          />

          <StatCard
            label="Tinkus ofertados"
            value={economy.offeredTinkus}
            icon={<FaBolt />}
            color="text-sky-600"
          />

          <StatCard
            label="Valor promedio Tinku"
            value={`${economy.avgTinkuValue.toFixed(2)} Bs`}
            icon={<FaChartLine />}
            color="text-purple-600"
          />
        </div>

        <div className="mt-6 grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <SmallStat label="Pagos aprobados" value={economy.approvedPayments} icon={<FaCheckCircle />} />
          <SmallStat label="Pagos pendientes" value={economy.pendingPayments} icon={<FaHourglassHalf />} />
          <SmallStat label="Pagos rechazados" value={economy.rejectedPayments} icon={<FaTimesCircle />} />
          <SmallStat label="Paquetes activos" value={economy.activePackages} icon={<FaBoxOpen />} />
        </div>

        <div className="mt-6 grid lg:grid-cols-2 gap-6">
          <ChartCard title="Estado de pagos">
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={economy.paymentStatusData}
                  dataKey="value"
                  nameKey="name"
                  outerRadius={90}
                  label
                >
                  {economy.paymentStatusData.map((_, index) => (
                    <Cell key={index} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Paquetes de monedas: Bs vs Tinkus">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={economy.coinPackageChartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="Bs" fill="#0ea5e9" />
                <Bar dataKey="Tinkus" fill="#f59e0b" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        <div className="mt-6 grid lg:grid-cols-2 gap-6">
          <ChartCard title="Suscripciones: precio, tinkus y valor mensual">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={economy.subscriptionChartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="Bs" fill="#22c55e" />
                <Bar dataKey="Tinkus" fill="#f59e0b" />
                <Bar dataKey="Mensual" fill="#8b5cf6" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <div className="grid gap-4">
            <HighlightCard
              title="Mejor paquete"
              value={economy.bestPackage?.name || '—'}
              detail={
                economy.bestPackage
                  ? `${economy.bestPackage.ratio.toFixed(2)} tinkus por Bs.`
                  : 'Sin paquetes activos'
              }
              icon={<FaCrown />}
            />

            <HighlightCard
              title="Mejor suscripción"
              value={economy.bestPlan?.name || '—'}
              detail={
                economy.bestPlan
                  ? `${economy.bestPlan.ratio.toFixed(2)} tinkus por Bs.`
                  : 'Sin planes activos'
              }
              icon={<FaCreditCard />}
            />

            <HighlightCard
              title="Oferta disponible"
              value={`${economy.offeredTinkusPackages} + ${economy.offeredTinkusPlans}`}
              detail="Tinkus en paquetes + tinkus en planes"
              icon={<FaBolt />}
            />
          </div>
        </div>
      </section>


    </div>
  );
}

function HeaderSection({ title, subtitle, loading }) {
  return (
    <div className="flex items-center justify-between mb-4 gap-4">
      <div>
        <h2 className="text-lg md:text-xl font-semibold text-gray-800">
          {title}
        </h2>

        {subtitle && (
          <p className="text-sm text-slate-500 mt-1">{subtitle}</p>
        )}
      </div>

      {loading && (
        <span className="text-xs text-gray-500 flex items-center gap-1">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          Actualizando datos…
        </span>
      )}
    </div>
  );
}

function StatCard({ label, value, icon, color }) {
  return (
    <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-100 bg-slate-50">
      <div className={`w-10 h-10 flex items-center justify-center rounded-full bg-white shadow-sm ${color}`}>
        <span className="text-lg">{icon}</span>
      </div>

      <div>
        <p className="text-xs text-gray-500">{label}</p>
        <p className="text-2xl font-bold text-gray-900">{value ?? 0}</p>
      </div>
    </div>
  );
}

function SmallStat({ label, value, icon }) {
  return (
    <div className="flex items-center gap-3 p-3 rounded-lg bg-slate-50 border border-slate-200">
      <div className="w-9 h-9 flex items-center justify-center rounded-full bg-white shadow text-sky-600">
        {icon}
      </div>

      <div>
        <p className="text-xs text-slate-500">{label}</p>
        <p className="text-lg font-semibold text-slate-900">{value ?? 0}</p>
      </div>
    </div>
  );
}

function ChartCard({ title, children }) {
  return (
    <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
      <h3 className="text-sm font-semibold text-slate-700 mb-3">
        {title}
      </h3>

      {children}
    </div>
  );
}

function HighlightCard({ title, value, detail, icon }) {
  return (
    <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 flex items-center gap-3">
      <div className="w-11 h-11 rounded-full bg-white shadow flex items-center justify-center text-yellow-500 text-xl">
        {icon}
      </div>

      <div>
        <p className="text-xs text-slate-500">{title}</p>
        <p className="text-lg font-bold text-slate-900">{value}</p>
        <p className="text-xs text-slate-500">{detail}</p>
      </div>
    </div>
  );
}

function MiniTable({ title, rows = [] }) {
  return (
    <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
      <h3 className="text-sm font-semibold text-slate-700 mb-3">
        {title}
      </h3>

      <div className="overflow-x-auto">
        <table className="min-w-full text-sm">
          <tbody>
            {rows.length ? (
              rows.map((row, i) => (
                <tr key={i} className="border-t border-slate-200">
                  <td className="py-2 font-semibold text-slate-800">
                    {row.name}
                  </td>
                  <td className="py-2 text-slate-600">{row.c1}</td>
                  <td className="py-2 text-slate-600">{row.c2}</td>
                  <td className="py-2 text-slate-600">{row.c3}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td className="py-4 text-center text-slate-500">
                  Sin datos disponibles
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Pill({ label }) {
  return (
    <span className="inline-flex items-center px-3 py-1.5 rounded-full bg-white border border-amber-300 text-amber-900 text-xs font-medium">
      {label}
    </span>
  );
}