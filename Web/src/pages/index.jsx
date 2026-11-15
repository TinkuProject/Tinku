// src/pages/index.jsx
'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Image from 'next/image';

import {
  FaArrowRight,
  FaStore,
  FaMapMarkedAlt,
  FaCalendarAlt,
  FaMobileAlt,
  FaGooglePlay,
  FaApple,
  FaChevronLeft,
  FaChevronRight,
  FaCheckCircle,
  FaUsers,
  FaShieldAlt,
  FaBolt,
} from 'react-icons/fa';

const slides = [
  {
    id: 1,
    image: '/images/landing/cine.jpg',
    title: 'Descubre negocios locales',
    description:
      'Encuentra restaurantes, comercios, servicios y emprendimientos cerca de ti.',
  },
  {
    id: 2,
    image: '/images/landing/feco.jpg',
    title: 'Conoce eventos y actividades',
    description:
      'Explora eventos culturales, promociones y experiencias disponibles en tu ciudad.',
  },
  {
    id: 3,
    image: '/images/landing/entrada.jpeg',
    title: 'Explora lugares turísticos',
    description:
      'Descubre destinos, atractivos turísticos y espacios únicos en Cochabamba.',
  },
];

const features = [
  {
    icon: FaStore,
    title: 'Negocios y servicios',
    description:
      'Consulta información, fotografías, ubicación y datos de contacto de cada negocio.',
  },
  {
    icon: FaCalendarAlt,
    title: 'Eventos',
    description:
      'Encuentra actividades, eventos y experiencias disponibles en la plataforma.',
  },
  {
    icon: FaMapMarkedAlt,
    title: 'Ubicación en mapas',
    description:
      'Visualiza negocios, servicios, eventos y puntos importantes desde el mapa.',
  },
  {
    icon: FaBolt,
    title: 'Economía Tinku',
    description:
      'Compra Tinkus, accede a beneficios y realiza operaciones dentro de la plataforma.',
  },
];

const benefits = [
  'Encuentra negocios y servicios de forma sencilla.',
  'Consulta direcciones y ubicaciones desde el mapa.',
  'Descubre promociones, eventos y lugares turísticos.',
  'Gestiona tu negocio desde una sola plataforma.',
];

export default function HomePage() {
  const router = useRouter();

  const [currentSlide, setCurrentSlide] = useState(0);

  useEffect(() => {
    const interval = window.setInterval(() => {
      setCurrentSlide((previous) => (previous + 1) % slides.length);
    }, 5000);

    return () => window.clearInterval(interval);
  }, []);

  const previousSlide = () => {
    setCurrentSlide((previous) =>
      previous === 0 ? slides.length - 1 : previous - 1
    );
  };

  const nextSlide = () => {
    setCurrentSlide((previous) => (previous + 1) % slides.length);
  };

  const goToLogin = () => {
    router.push('/login');
  };

  const goToRegister = () => {
    router.push('/login?register=true');
  };

  const goToDownload = () => {
    const downloadSection = document.getElementById('descargar-app');

    downloadSection?.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    });
  };

  return (
    <main className="min-h-screen bg-white text-slate-900 overflow-x-hidden">
      {/* NAVBAR */}
      <header className="fixed top-0 left-0 right-0 z-50 border-b border-white/20 bg-white/85 backdrop-blur-xl">
        <nav className="max-w-7xl mx-auto px-5 md:px-8 h-20 flex items-center justify-between">
          <button
            type="button"
            onClick={() => router.push('/')}
            className="flex items-center gap-3"
          >
            <div className="relative w-12 h-12">
              <Image
                src="/images/LogoTinku.png"
                alt="Logo Tinku"
                fill
                sizes="48px"
                className="object-contain rounded-full"
                priority
              />
            </div>

            <div className="text-left">
              <p className="font-extrabold text-xl text-[#0077B6] leading-none">
                Tinku
              </p>

              <p className="text-[11px] text-slate-500 mt-1">
                Conecta, descubre y crece
              </p>
            </div>
          </button>

          <div className="hidden lg:flex items-center gap-8 text-sm font-medium text-slate-700">
            <a href="#inicio" className="hover:text-[#0077B6] transition">
              Inicio
            </a>

            <a
              href="#funcionalidades"
              className="hover:text-[#0077B6] transition"
            >
              Funcionalidades
            </a>

            <a
              href="#descargar-app"
              className="hover:text-[#0077B6] transition"
            >
              Aplicación móvil
            </a>

            <a href="#beneficios" className="hover:text-[#0077B6] transition">
              Beneficios
            </a>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={goToLogin}
              className="hidden sm:inline-flex px-4 py-2 rounded-lg font-semibold text-[#0077B6] hover:bg-sky-50 transition"
            >
              Iniciar sesión
            </button>

            <button
              type="button"
              onClick={goToRegister}
              className="px-4 py-2.5 rounded-xl bg-[#0077B6] hover:bg-[#005f92] text-white font-semibold shadow-md transition"
            >
              Registrarse
            </button>
          </div>
        </nav>
      </header>

      {/* HERO */}
      <section
        id="inicio"
        className="relative pt-32 pb-20 md:pt-40 md:pb-28 bg-gradient-to-br from-[#EAF7FF] via-white to-[#DBF1FF]"
      >
        <div className="absolute top-24 left-[-120px] w-80 h-80 bg-sky-300/20 rounded-full blur-3xl" />

        <div className="absolute bottom-0 right-[-140px] w-96 h-96 bg-blue-400/20 rounded-full blur-3xl" />

        <div className="max-w-7xl mx-auto px-5 md:px-8 relative">
          <div className="grid lg:grid-cols-2 gap-14 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white border border-sky-100 shadow-sm text-sm text-[#0077B6] font-semibold">
                <FaMapMarkedAlt />
                Plataforma digital para Cochabamba
              </div>

              <h1 className="mt-7 text-4xl sm:text-5xl xl:text-6xl font-black leading-tight text-slate-900">
                Descubre todo lo que
                <span className="block text-[#0077B6]">
                  Cochabamba tiene para ti
                </span>
              </h1>

              <p className="mt-6 text-lg md:text-xl text-slate-600 leading-relaxed max-w-2xl">
                Encuentra negocios, servicios, eventos y lugares turísticos
                desde una plataforma moderna, segura y fácil de utilizar.
              </p>

              <div className="mt-8 flex flex-col sm:flex-row gap-3">
                <button
                  type="button"
                  onClick={goToRegister}
                  className="inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-[#0077B6] hover:bg-[#005f92] text-white font-bold shadow-lg shadow-sky-200 transition hover:-translate-y-0.5"
                >
                  Crear una cuenta
                  <FaArrowRight />
                </button>

                <button
                  type="button"
                  onClick={goToDownload}
                  className="inline-flex items-center justify-center gap-3 px-7 py-4 rounded-xl bg-white border border-slate-200 hover:border-[#0077B6] text-slate-800 font-bold shadow-sm transition"
                >
                  <FaMobileAlt className="text-[#0077B6]" />
                  Descargar aplicación
                </button>
              </div>

              <div className="mt-9 grid grid-cols-3 gap-4 max-w-lg">
                <HeroMetric value="+100" label="Negocios" />
                <HeroMetric value="+50" label="Eventos" />
                <HeroMetric value="+1K" label="Usuarios" />
              </div>
            </div>

            {/* MOCKUP */}
            <div className="relative flex justify-center lg:justify-end">
              <div className="absolute top-12 left-2 md:left-16 w-44 h-44 bg-sky-400/20 rounded-full blur-3xl" />

              <div className="relative">
                <div className="absolute -left-16 top-24 hidden md:block bg-white rounded-2xl shadow-xl p-4 w-52 border border-slate-100 z-10">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-sky-100 flex items-center justify-center text-[#0077B6]">
                      <FaStore />
                    </div>

                    <div>
                      <p className="text-sm font-bold">Negocios cercanos</p>
                      <p className="text-xs text-slate-500">
                        Encuentra nuevas opciones
                      </p>
                    </div>
                  </div>
                </div>

                <div className="absolute -right-12 bottom-24 hidden md:block bg-white rounded-2xl shadow-xl p-4 w-52 border border-slate-100 z-10">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600">
                      <FaCheckCircle />
                    </div>

                    <div>
                      <p className="text-sm font-bold">Información validada</p>
                      <p className="text-xs text-slate-500">
                        Contenido seguro y confiable
                      </p>
                    </div>
                  </div>
                </div>

                <div className="relative w-[280px] sm:w-[320px] h-[590px] sm:h-[650px] rounded-[48px] bg-slate-950 p-3 shadow-2xl">
                  <div className="absolute top-4 left-1/2 -translate-x-1/2 w-28 h-7 bg-black rounded-full z-10" />

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

      {/* CARRUSEL */}
      <section className="py-20 bg-slate-950">
        <div className="max-w-7xl mx-auto px-5 md:px-8">
          <div className="text-center mb-10">
            <span className="text-sky-400 uppercase tracking-widest text-sm font-bold">
              Explora Tinku
            </span>

            <h2 className="mt-3 text-3xl md:text-4xl font-black text-white">
              Todo lo que necesitas en una sola aplicación
            </h2>
          </div>

          <div className="relative rounded-3xl overflow-hidden min-h-[480px] shadow-2xl">
            {slides.map((slide, index) => (
              <div
                key={slide.id}
                className={`absolute inset-0 transition-all duration-700 ${index === currentSlide
                    ? 'opacity-100 translate-x-0'
                    : 'opacity-0 translate-x-8 pointer-events-none'
                  }`}
              >
                <Image
                  src={slide.image}
                  alt={slide.title}
                  fill
                  sizes="100vw"
                  className="object-cover"
                />

                <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/55 to-black/15" />

                <div className="absolute inset-0 flex items-center px-8 md:px-16">
                  <div className="max-w-xl">
                    <span className="inline-flex px-3 py-1 rounded-full bg-sky-500/20 border border-sky-300/30 text-sky-200 text-sm font-semibold">
                      Experiencia Tinku
                    </span>

                    <h3 className="mt-5 text-3xl md:text-5xl font-black text-white">
                      {slide.title}
                    </h3>

                    <p className="mt-4 text-base md:text-lg text-slate-200 leading-relaxed">
                      {slide.description}
                    </p>

                    <button
                      type="button"
                      onClick={goToRegister}
                      className="mt-7 inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[#0077B6] hover:bg-[#0096D6] text-white font-semibold transition"
                    >
                      Explorar ahora
                      <FaArrowRight />
                    </button>
                  </div>
                </div>
              </div>
            ))}

            <button
              type="button"
              onClick={previousSlide}
              className="absolute left-4 top-1/2 -translate-y-1/2 w-11 h-11 rounded-full bg-white/20 hover:bg-white/30 backdrop-blur text-white flex items-center justify-center z-10"
              aria-label="Imagen anterior"
            >
              <FaChevronLeft />
            </button>

            <button
              type="button"
              onClick={nextSlide}
              className="absolute right-4 top-1/2 -translate-y-1/2 w-11 h-11 rounded-full bg-white/20 hover:bg-white/30 backdrop-blur text-white flex items-center justify-center z-10"
              aria-label="Imagen siguiente"
            >
              <FaChevronRight />
            </button>

            <div className="absolute bottom-5 left-1/2 -translate-x-1/2 flex gap-2 z-10">
              {slides.map((slide, index) => (
                <button
                  key={slide.id}
                  type="button"
                  onClick={() => setCurrentSlide(index)}
                  className={`h-2 rounded-full transition-all ${index === currentSlide
                      ? 'w-9 bg-sky-400'
                      : 'w-2 bg-white/60'
                    }`}
                  aria-label={`Mostrar imagen ${index + 1}`}
                />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* FUNCIONALIDADES */}
      <section id="funcionalidades" className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-5 md:px-8">
          <div className="text-center max-w-3xl mx-auto">
            <span className="text-[#0077B6] uppercase tracking-widest text-sm font-bold">
              Funcionalidades
            </span>

            <h2 className="mt-3 text-3xl md:text-4xl font-black text-slate-900">
              Una plataforma creada para conectar personas y negocios
            </h2>

            <p className="mt-4 text-slate-600 text-lg">
              Tinku reúne diferentes servicios digitales para mejorar la
              visibilidad de los emprendimientos y facilitar el acceso a la
              información.
            </p>
          </div>

          <div className="mt-14 grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map(({ icon: Icon, title, description }) => (
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
            ))}
          </div>
        </div>
      </section>

      {/* DESCARGA APP */}
      <section
        id="descargar-app"
        className="relative py-24 bg-gradient-to-br from-[#0077B6] to-[#003B64] overflow-hidden"
      >
        <div className="absolute -top-40 -right-32 w-96 h-96 rounded-full border-[70px] border-white/5" />

        <div className="absolute -bottom-48 -left-40 w-[500px] h-[500px] rounded-full border-[90px] border-white/5" />

        <div className="max-w-7xl mx-auto px-5 md:px-8 relative">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div className="relative flex justify-center">
              <div className="relative w-[270px] h-[560px] rounded-[44px] bg-slate-950 p-3 shadow-2xl rotate-[-5deg] hover:rotate-0 transition duration-500">
                <div className="relative w-full h-full rounded-[34px] overflow-hidden bg-white">
                  <Image
                    src="/images/Splash.jpg"
                    alt="Descargar aplicación móvil Tinku"
                    fill
                    sizes="270px"
                    className="object-cover"
                  />
                </div>
              </div>
            </div>

            <div>
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 border border-white/20 text-white text-sm font-semibold">
                <FaMobileAlt />
                Disponible para dispositivos móviles
              </span>

              <h2 className="mt-6 text-3xl md:text-5xl font-black text-white leading-tight">
                Lleva Tinku contigo a todas partes
              </h2>

              <p className="mt-5 text-lg text-sky-100 leading-relaxed max-w-xl">
                Descarga la aplicación móvil y descubre negocios, promociones,
                eventos y lugares turísticos desde tu teléfono.
              </p>

              <div className="mt-8 flex flex-col sm:flex-row gap-3">
                <a
                  href="/downloads/tinku-latest.apk"
                  className="inline-flex items-center justify-center gap-3 px-6 py-4 rounded-xl bg-white text-slate-900 hover:bg-slate-100 font-bold shadow-lg transition"
                >
                  <FaGooglePlay className="text-2xl text-emerald-600" />

                  <span className="text-left">
                    <span className="block text-[11px] font-medium text-slate-500">
                      Descargar DEMO para
                    </span>

                    <span className="block leading-none">Android</span>
                  </span>
                </a>

                <button
                  type="button"
                  className="inline-flex items-center justify-center gap-3 px-6 py-4 rounded-xl bg-white/10 border border-white/20 text-white font-bold"
                >
                  <FaApple className="text-2xl" />

                  <span className="text-left">
                    <span className="block text-[11px] font-medium text-sky-100">
                      Próximamente en
                    </span>

                    <span className="block leading-none">App Store</span>
                  </span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* BENEFICIOS */}
      <section id="beneficios" className="py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-5 md:px-8">
          <div className="grid lg:grid-cols-2 gap-14 items-center">
            <div>
              <span className="text-[#0077B6] uppercase tracking-widest text-sm font-bold">
                Beneficios
              </span>

              <h2 className="mt-3 text-3xl md:text-4xl font-black text-slate-900">
                Una experiencia diseñada para usuarios y emprendedores
              </h2>

              <p className="mt-5 text-lg text-slate-600">
                Tinku facilita la conexión entre ciudadanos, turistas,
                emprendedores y proveedores de servicios.
              </p>

              <div className="mt-8 space-y-4">
                {benefits.map((benefit) => (
                  <div key={benefit} className="flex items-start gap-3">
                    <FaCheckCircle className="mt-1 text-emerald-500 shrink-0" />

                    <p className="text-slate-700">{benefit}</p>
                  </div>
                ))}
              </div>

              <button
                type="button"
                onClick={goToRegister}
                className="mt-9 inline-flex items-center gap-3 px-6 py-3.5 rounded-xl bg-[#0077B6] hover:bg-[#005f92] text-white font-bold transition"
              >
                Comenzar ahora
                <FaArrowRight />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-5">
              <BenefitCard
                icon={<FaUsers />}
                value="+1.000"
                label="Usuarios conectados"
              />

              <BenefitCard
                icon={<FaStore />}
                value="+100"
                label="Negocios publicados"
              />

              <BenefitCard
                icon={<FaShieldAlt />}
                value="Seguro"
                label="Contenido administrado"
              />

              <BenefitCard
                icon={<FaMapMarkedAlt />}
                value="Local"
                label="Enfocado en Cochabamba"
              />
            </div>
          </div>
        </div>
      </section>

      {/* CTA FINAL */}
      <section className="py-20 bg-white">
        <div className="max-w-6xl mx-auto px-5 md:px-8">
          <div className="rounded-3xl bg-slate-950 p-8 md:p-14 text-center relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-r from-[#0077B6]/30 to-transparent" />

            <div className="relative">
              <h2 className="text-3xl md:text-4xl font-black text-white">
                Comienza a explorar Tinku hoy
              </h2>

              <p className="mt-4 text-slate-300 text-lg max-w-2xl mx-auto">
                Regístrate y descubre una nueva forma de encontrar negocios,
                servicios, eventos y lugares turísticos.
              </p>

              <div className="mt-8 flex flex-col sm:flex-row justify-center gap-3">
                <button
                  type="button"
                  onClick={goToRegister}
                  className="px-7 py-3.5 rounded-xl bg-[#0077B6] hover:bg-[#0096D6] text-white font-bold transition"
                >
                  Crear cuenta
                </button>

                <button
                  type="button"
                  onClick={goToLogin}
                  className="px-7 py-3.5 rounded-xl border border-white/20 bg-white/10 hover:bg-white/15 text-white font-bold transition"
                >
                  Iniciar sesión
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="bg-slate-950 text-slate-300 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-5 md:px-8 py-10">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-3">
              <div className="relative w-11 h-11">
                <Image
                  src="/images/LogoTinku.png"
                  alt="Tinku"
                  fill
                  sizes="44px"
                  className="object-contain rounded-full"
                />
              </div>

              <div>
                <p className="font-bold text-white">Tinku</p>
                <p className="text-xs text-slate-400">
                  Conecta, descubre y crece
                </p>
              </div>
            </div>

            <p className="text-sm text-center">
              © {new Date().getFullYear()} Tinku. Todos los derechos reservados.
            </p>

            <div className="flex gap-5 text-sm">
              <button
                type="button"
                onClick={goToLogin}
                className="hover:text-white transition"
              >
                Iniciar sesión
              </button>

              <button
                type="button"
                onClick={goToRegister}
                className="hover:text-white transition"
              >
                Registrarse
              </button>
            </div>
          </div>
        </div>
      </footer>
    </main>
  );
}

function HeroMetric({ value, label }) {
  return (
    <div className="p-3 rounded-xl bg-white/70 border border-white shadow-sm backdrop-blur">
      <p className="text-xl font-black text-[#0077B6]">{value}</p>
      <p className="text-xs text-slate-500">{label}</p>
    </div>
  );
}

function BenefitCard({ icon, value, label }) {
  return (
    <article className="min-h-44 rounded-2xl bg-white border border-slate-200 shadow-sm p-5 flex flex-col justify-between hover:shadow-lg transition">
      <div className="w-12 h-12 rounded-xl bg-sky-100 text-[#0077B6] text-xl flex items-center justify-center">
        {icon}
      </div>

      <div>
        <p className="text-2xl font-black text-slate-900">{value}</p>
        <p className="mt-1 text-sm text-slate-500">{label}</p>
      </div>
    </article>
  );
}
