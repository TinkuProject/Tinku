'use client';
import Image from 'next/image';

export default function LoginPageLayout({
    children,
    leftImageSrc = '/images/login4.jpg',
    logoSrc = '/images/LogoTinku.png',
}) {
    return (
        <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-white font-sans">
            <div className="relative flex flex-col md:flex-row w-full max-w-5xl min-h-[600px] z-10 rounded-3xl bg-white/80 backdrop-blur-xl shadow-lg transition-all duration-300">
                {/* Left hero image */}
                <div className="md:w-1/2 h-full">
                    <Image
                        src={leftImageSrc}
                        alt="Imagen decorativa"
                        width={600}
                        height={600}
                        priority
                        className="w-full h-full object-cover rounded-t-3xl md:rounded-l-3xl md:rounded-tr-none"
                    />
                </div>

                {/* Right panel */}
                <div className="md:w-1/2 p-10 flex flex-col justify-center">
                    <div className="flex justify-center mb-3">
                        <Image
                            src={logoSrc}
                            alt="Logo Tinku"
                            width={130}
                            height={130}
                            className="rounded-full shadow-md"
                            priority
                        />
                    </div>

                    {/* Slot para formulario / spinner */}
                    {children}
                </div>
            </div>
        </section>
    );
}
