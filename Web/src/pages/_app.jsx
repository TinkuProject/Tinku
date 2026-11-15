// src/pages/_app.jsx
import "@/styles/globals.css";
import { UserProvider, useUser } from "../context/UserContext";
import { useRouter } from "next/router";
import { useEffect } from "react";
import { Toaster } from "react-hot-toast";

// CSS seguro para SSR
import "leaflet/dist/leaflet.css";

/**
 * =========================
 * PROTECTED ROUTE
 * =========================
 */
function ProtectedRoute({ children }) {
  const { user, loading } = useUser();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      const redirectPath = encodeURIComponent(router.asPath);
      router.replace(`/login?redirect=${redirectPath}`);
    }
  }, [user, loading, router]);

  // 🔥 Mejor UX
  if (loading) {
    return (
      <div style={{ padding: "2rem", textAlign: "center" }}>
        Cargando sesión...
      </div>
    );
  }

  if (!user) return null;

  return children;
}

/**
 * =========================
 * APP ROOT
 * =========================
 */
export default function App({ Component, pageProps }) {
  return (
    <UserProvider>
      {Component.auth ? (
        <ProtectedRoute>
          <Component {...pageProps} />
        </ProtectedRoute>
      ) : (
        <Component {...pageProps} />
      )}

      {/* 🔔 Toaster global */}
      <Toaster
        position="top-right"
        reverseOrder={false}
        toastOptions={{
          style: { borderRadius: "10px", fontSize: "0.95rem" },
          success: {
            iconTheme: { primary: "#10B981", secondary: "white" },
          },
          error: {
            iconTheme: { primary: "#EF4444", secondary: "white" },
          },
        }}
      />
    </UserProvider>
  );
}