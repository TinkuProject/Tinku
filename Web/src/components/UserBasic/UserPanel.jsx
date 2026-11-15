// File: src/components/User/UserPanel.jsx

'use client';

import Image from 'next/image';
import {
    FaAndroid,
    FaArrowRight,
    FaBell,
    FaCalendarAlt,
    FaCheckCircle,
    FaClock,
    FaHeart,
    FaMapMarkedAlt,
    FaMobileAlt,
    FaStore,
    FaUser,
} from 'react-icons/fa';

const upcomingFeatures = [
    {
        icon: FaUser,
        title: 'Perfil de usuario',
        description:
            'Administra tu información personal y configura las preferencias de tu cuenta.',
    },
    {
        icon: FaHeart,
        title: 'Mis favoritos',
        description:
            'Guarda negocios, eventos y lugares turísticos para encontrarlos fácilmente.',
    },
    {
        icon: FaCalendarAlt,
        title: 'Eventos guardados',
        description:
            'Consulta los eventos que te interesan y recibe información actualizada.',
    },
    {
        icon: FaBell,
        title: 'Notificaciones',
        description:
            'Recibe novedades, promociones y recomendaciones personalizadas.',
    },
];

const mobileFeatures = [
    {
        icon: FaStore,
        title: 'Negocios y servicios',
        description:
            'Descubre comercios, emprendimientos y servicios disponibles en Cochabamba.',
    },
    {
        icon: FaCalendarAlt,
        title: 'Eventos',
        description:
            'Encuentra actividades culturales, promociones y experiencias disponibles.',
    },
    {
        icon: FaMapMarkedAlt,
        title: 'Lugares turísticos',
        description:
            'Explora atractivos turísticos y consulta sus ubicaciones desde el mapa.',
    },
    {
        icon: FaHeart,
        title: 'Experiencia personalizada',
        description:
            'Accede a toda la experiencia de Tinku directamente desde tu dispositivo móvil.',
    },
];

export default function UserPanel() {
    const handleDownloadApp = () => {
        const downloadLink = document.createElement('a');

        downloadLink.href = '/downloads/tinku-latest.apk';

        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
    };

    return (
        <main className="min-h-screen bg-slate-50 text-slate-900 overflow-hidden">
            {/* HERO */}
            <section className="relative overflow-hidden bg-gradient-to-br from-[#EAF7FF] via-white to-[#DBF1FF]">
                <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-sky-300/20 blur-3xl" />

                <div className="absolute -bottom-40 -right-32 w-[500px] h-[500px] rounded-full bg-blue-400/20 blur-3xl" />

                <div className="relative max-w-7xl mx-auto px-5 md:px-8 py-14 md:py-20">
                    <div className="grid lg:grid-cols-2 gap-14 items-center">
                        <div>
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white border border-sky-100 shadow-sm text-sm text-[#0077B6] font-semibold">
                                <FaCheckCircle />
                                Sesión iniciada correctamente
                            </div>

                            <h1 className="mt-6 text-4xl md:text-5xl xl:text-6xl font-black leading-tight text-slate-900">
                                Bienvenido a
                                <span className="block text-[#0077B6]">Tinku</span>
                            </h1>

                            <p className="mt-6 max-w-2xl text-lg md:text-xl leading-relaxed text-slate-600">
                                Actualmente, la experiencia completa para usuarios está
                                disponible en nuestra aplicación móvil. Descárgala para
                                descubrir negocios, eventos, servicios y lugares turísticos.
                            </p>

                            <div className="mt-8 flex flex-col sm:flex-row gap-3">
                                <button
                                    type="button"
                                    onClick={handleDownloadApp}
                                    className="inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-[#0077B6] hover:bg-[#005f92] text-white font-bold shadow-lg shadow-sky-200 transition hover:-translate-y-0.5"
                                >
                                    <FaAndroid className="text-xl" />
                                    Descargar aplicación
                                    <FaArrowRight />
                                </button>

                                <a
                                    href="#proximamente"
                                    className="inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-white border border-slate-200 hover:border-[#0077B6] text-slate-800 font-bold shadow-sm transition"
                                >
                                    <FaClock className="text-[#0077B6]" />
                                    Ver próximas funciones
                                </a>
                            </div>

                            <div className="mt-8 flex items-start gap-3 p-4 max-w-xl rounded-2xl bg-white/80 border border-white shadow-sm backdrop-blur">
                                <FaMobileAlt className="mt-1 text-xl text-[#0077B6] shrink-0" />

                                <p className="text-sm leading-relaxed text-slate-600">
                                    Para instalar la aplicación en Android, es posible que debas
                                    habilitar temporalmente la instalación desde fuentes
                                    desconocidas.
                                </p>
                            </div>
                        </div>

                        {/* MOCKUP */}
                        <div className="relative flex justify-center lg:justify-end">
                            <div className="absolute top-20 left-8 w-48 h-48 rounded-full bg-sky-400/20 blur-3xl" />

                            <div className="relative">
                                <div className="absolute -left-16 top-24 hidden md:block z-20 w-56 rounded-2xl border border-slate-100 bg-white p-4 shadow-xl">
                                    <div className="flex items-center gap-3">
                                        <div className="w-11 h-11 rounded-xl bg-sky-100 text-[#0077B6] flex items-center justify-center">
                                            <FaMapMarkedAlt />
                                        </div>

                                        <div>
                                            <p className="text-sm font-bold text-slate-900">
                                                Explora Cochabamba
                                            </p>

                                            <p className="mt-1 text-xs text-slate-500">
                                                Descubre nuevas experiencias
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <div className="absolute -right-12 bottom-24 hidden md:block z-20 w-56 rounded-2xl border border-slate-100 bg-white p-4 shadow-xl">
                                    <div className="flex items-center gap-3">
                                        <div className="w-11 h-11 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center">
                                            <FaCheckCircle />
                                        </div>

                                        <div>
                                            <p className="text-sm font-bold text-slate-900">
                                                Aplicación disponible
                                            </p>

                                            <p className="mt-1 text-xs text-slate-500">
                                                Descárgala para Android
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <div className="relative w-[280px] sm:w-[320px] h-[590px] sm:h-[650px] rounded-[48px] bg-slate-950 p-3 shadow-2xl">
                                    <div className="absolute top-4 left-1/2 -translate-x-1/2 z-10 w-28 h-7 rounded-full bg-black" />

                                    <div className="relative w-full h-full rounded-[38px] overflow-hidden bg-white">
                                        <Image
                                            src="/images/Splash.jpg"
                                            alt="Aplicación móvil Tinku"
                                            fill
                                            sizes="320px"
                                            className="object-cover"
                                            priority
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* FUNCIONALIDADES DE LA APP */}
            <section className="py-20 md:py-24 bg-white">
                <div className="max-w-7xl mx-auto px-5 md:px-8">
                    <div className="max-w-3xl mx-auto text-center">
                        <span className="text-[#0077B6] uppercase tracking-widest text-sm font-bold">
                            Aplicación móvil
                        </span>

                        <h2 className="mt-3 text-3xl md:text-4xl font-black text-slate-900">
                            Todo Tinku desde tu teléfono
                        </h2>

                        <p className="mt-4 text-lg leading-relaxed text-slate-600">
                            Descarga la aplicación para acceder a las principales
                            funcionalidades disponibles para usuarios.
                        </p>
                    </div>

                    <div className="mt-14 grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
                        {mobileFeatures.map(
                            ({ icon: Icon, title, description }) => (
                                <article
                                    key={title}
                                    className="group p-6 rounded-2xl border border-slate-200 bg-white hover:border-sky-300 hover:shadow-xl hover:-translate-y-1 transition"
                                >
                                    <div className="w-14 h-14 rounded-2xl bg-sky-100 text-[#0077B6] flex items-center justify-center text-2xl group-hover:bg-[#0077B6] group-hover:text-white transition">
                                        <Icon />
                                    </div>

                                    <h3 className="mt-5 text-lg font-bold text-slate-900">
                                        {title}
                                    </h3>

                                    <p className="mt-3 text-sm leading-relaxed text-slate-600">
                                        {description}
                                    </p>
                                </article>
                            )
                        )}
                    </div>
                </div>
            </section>

            {/* DESCARGA */}
            <section className="relative overflow-hidden py-24 bg-gradient-to-b from-sky-50 via-white to-slate-50">
                {/* Efectos de fondo */}
                <div className="absolute -top-32 -left-32 w-[30rem] h-[30rem] rounded-full bg-sky-200/30 blur-3xl" />

                <div className="absolute -bottom-40 -right-32 w-[36rem] h-[36rem] rounded-full bg-blue-200/30 blur-3xl" />

                <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(14,165,233,0.08),transparent_35%),radial-gradient(circle_at_bottom_left,rgba(59,130,246,0.08),transparent_35%)]" />

                <div className="relative max-w-6xl mx-auto px-5 md:px-8">
                    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#0077B6] via-[#0069A8] to-[#003B64] p-8 md:p-14 shadow-2xl ring-1 ring-white/10">

                        {/* Decoración interna */}
                        <div className="absolute -top-32 -right-28 w-80 h-80 rounded-full border-[60px] border-white/5" />

                        <div className="absolute -bottom-36 -left-32 w-96 h-96 rounded-full border-[70px] border-white/5" />

                        <div className="relative grid lg:grid-cols-[1fr_auto] gap-10 items-center">
                            <div>
                                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 border border-white/20 text-sm text-white font-semibold backdrop-blur-sm">
                                    <FaAndroid />
                                    Disponible para Android
                                </div>

                                <h2 className="mt-6 text-3xl md:text-5xl font-black text-white leading-tight">
                                    Descarga Tinku y comienza a explorar
                                </h2>

                                <p className="mt-5 max-w-2xl text-lg leading-relaxed text-sky-100">
                                    Accede a negocios, servicios, eventos, promociones y
                                    lugares turísticos desde una sola aplicación.
                                </p>
                            </div>

                            <button
                                type="button"
                                onClick={handleDownloadApp}
                                className="inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-white hover:bg-slate-100 text-slate-900 font-bold shadow-xl transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl"
                            >
                                <FaAndroid className="text-2xl text-emerald-600" />

                                <span className="text-left">
                                    <span className="block text-[11px] font-medium text-slate-500">
                                        Descargar DEMO para
                                    </span>

                                    <span className="block text-lg leading-none">
                                        Android
                                    </span>
                                </span>
                            </button>
                        </div>
                    </div>
                </div>
            </section>

            {/* PRÓXIMAMENTE */}
            <section id="proximamente" className="py-20 md:py-24 bg-slate-50">
                <div className="max-w-7xl mx-auto px-5 md:px-8">
                    <div className="max-w-3xl mx-auto text-center">
                        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-100 text-amber-700 text-sm font-semibold">
                            <FaClock />
                            En desarrollo
                        </div>

                        <h2 className="mt-5 text-3xl md:text-4xl font-black text-slate-900">
                            Próximamente en la plataforma web
                        </h2>

                        <p className="mt-4 text-lg leading-relaxed text-slate-600">
                            Estamos trabajando para incorporar nuevas funcionalidades y
                            mejorar tu experiencia desde el navegador.
                        </p>
                    </div>

                    <div className="mt-14 grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
                        {upcomingFeatures.map(
                            ({ icon: Icon, title, description }) => (
                                <article
                                    key={title}
                                    className="relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
                                >
                                    <span className="absolute top-4 right-4 px-2.5 py-1 rounded-full bg-amber-100 text-[10px] uppercase tracking-wide font-bold text-amber-700">
                                        Próximamente
                                    </span>

                                    <div className="w-14 h-14 rounded-2xl bg-slate-100 text-slate-500 flex items-center justify-center text-2xl">
                                        <Icon />
                                    </div>

                                    <h3 className="mt-5 pr-16 text-lg font-bold text-slate-900">
                                        {title}
                                    </h3>

                                    <p className="mt-3 text-sm leading-relaxed text-slate-600">
                                        {description}
                                    </p>

                                    <div className="absolute inset-0 pointer-events-none bg-gradient-to-br from-transparent via-transparent to-slate-100/50" />
                                </article>
                            )
                        )}
                    </div>

                    <div className="mt-12 flex items-start gap-4 max-w-4xl mx-auto rounded-2xl border border-sky-200 bg-sky-50 p-5 md:p-6">
                        <div className="w-12 h-12 rounded-xl bg-white text-[#0077B6] flex items-center justify-center text-xl shadow-sm shrink-0">
                            <FaMobileAlt />
                        </div>

                        <div>
                            <h3 className="font-bold text-slate-900">
                                La experiencia completa está en la aplicación
                            </h3>

                            <p className="mt-2 text-sm md:text-base leading-relaxed text-slate-600">
                                Mientras incorporamos nuevas funcionalidades en la plataforma
                                web, puedes utilizar la aplicación móvil de Tinku para acceder
                                a todos los servicios disponibles.
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            {/* CTA FINAL */}
            <section className="py-20 bg-white">
                <div className="max-w-6xl mx-auto px-5 md:px-8">
                    <div className="relative overflow-hidden rounded-3xl bg-slate-950 px-7 py-12 md:p-14 text-center">
                        <div className="absolute inset-0 bg-gradient-to-r from-[#0077B6]/30 to-transparent" />

                        <div className="relative">
                            <div className="mx-auto w-16 h-16 rounded-2xl bg-white/10 text-sky-300 flex items-center justify-center text-3xl">
                                <FaMobileAlt />
                            </div>

                            <h2 className="mt-6 text-3xl md:text-4xl font-black text-white">
                                Lleva Tinku contigo
                            </h2>

                            <p className="mt-4 max-w-2xl mx-auto text-lg leading-relaxed text-slate-300">
                                Descarga la aplicación móvil y descubre todo lo que Cochabamba
                                tiene para ofrecerte.
                            </p>

                            <button
                                type="button"
                                onClick={handleDownloadApp}
                                className="mt-8 inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-[#0077B6] hover:bg-[#0096D6] text-white font-bold shadow-lg transition"
                            >
                                <FaAndroid />
                                Descargar aplicación
                                <FaArrowRight />
                            </button>
                        </div>
                    </div>
                </div>
            </section>
        </main>
    );
}
