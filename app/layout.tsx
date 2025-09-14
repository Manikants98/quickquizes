"use client";
import { ColorSchemeScript, MantineProvider } from "@mantine/core";
import { Notifications } from "@mantine/notifications";
import { useEffect, useState } from "react";
import { LoadingScreen } from "./admin/components/LoadingScreen";
import "./globals.css";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const [isClient, setIsClient] = useState(false);
  const [savedTheme, setSavedTheme] = useState("blue");
  const [isLoading, setIsLoading] = useState(true);
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    setIsClient(true);
    const theme = localStorage.getItem("quickquiz-theme-color") || "blue";
    setSavedTheme(theme);

    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === "quickquiz-theme-color") {
        setSavedTheme(e.newValue || "blue");
      }
    };

    window.addEventListener("storage", handleStorageChange);
    return () => window.removeEventListener("storage", handleStorageChange);
  }, []);

  const handleLoadingComplete = () => {
    setIsLoading(false);
    // Small delay for smooth transition
    setTimeout(() => {
      setShowContent(true);
    }, 300);
  };

  console.error = () => {};
  return (
    <html lang="en" suppressHydrationWarning>
      <head suppressHydrationWarning>
        <ColorSchemeScript />
        <title>QuickQuiz - Admin Panel</title>
        <meta
          name="description"
          content="AI-powered quiz creation and management platform"
        />
      </head>
      <body suppressHydrationWarning>
        <MantineProvider
          defaultColorScheme="auto"
          theme={{
            primaryColor: isClient ? savedTheme : "blue",
            fontFamily: "var(--font-geist-sans), sans-serif",
          }}
        >
          <LoadingScreen
            isVisible={isLoading}
            onComplete={handleLoadingComplete}
          />
          <div
            style={{
              opacity: showContent ? 1 : 0,
              transition: "opacity 0.5s ease-in-out",
            }}
          >
            <Notifications position="top-right" />
            {children}
          </div>
        </MantineProvider>
      </body>
    </html>
  );
}
