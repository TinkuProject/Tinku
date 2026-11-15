import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="es"> {/* ✅ idioma correcto */}
      <Head>
        {/* ✅ Meta tags básicos */}
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta
          name="description"
          content="Tinku - Plataforma de gestión y administración de usuarios."
        />

        {/* ✅ Favicon */}
        <link rel="icon" href="/images/Logo_Tinku.png" />

        {/* Opcional: preload de fuentes si usas Google Fonts */}
        {/* <link rel="preconnect" href="https://fonts.googleapis.com" /> */}
        {/* <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="true" /> */}
        {/* <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet" /> */}
      </Head>
      <body className="antialiased">
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
