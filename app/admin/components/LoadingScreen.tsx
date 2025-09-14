"use client";
import { Box, Center, Loader, Text } from "@mantine/core";
import { useEffect, useState } from "react";

const animationStyles = `
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  @keyframes slideUp {
    from { 
      transform: translateY(20px); 
      opacity: 0; 
    }
    to { 
      transform: translateY(0); 
      opacity: 1; 
    }
  }
  
  @keyframes pulse {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.05); }
  }
  
  .loading-screen-fadeIn {
    animation: fadeIn 0.3s ease-out;
  }
  
  .loading-screen-slideUp-1 {
    animation: slideUp 0.6s ease-out 0.2s both;
  }
  
  .loading-screen-slideUp-2 {
    animation: slideUp 0.6s ease-out 0.4s both;
  }
  
  .loading-screen-slideUp-3 {
    animation: slideUp 0.6s ease-out 0.6s both;
  }
  
  .loading-screen-pulse {
    animation: pulse 2s ease-in-out infinite;
  }
`;

interface LoadingScreenProps {
  isVisible: boolean;
  onComplete?: () => void;
}

export function LoadingScreen({ isVisible, onComplete }: LoadingScreenProps) {
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    if (isVisible) {
      const styleElement = document.createElement("style");
      styleElement.textContent = animationStyles;
      document.head.appendChild(styleElement);

      setShowContent(true);
      const timer = setTimeout(() => {
        onComplete?.();
      }, 1500);

      return () => {
        clearTimeout(timer);
        if (styleElement.parentNode) {
          styleElement.parentNode.removeChild(styleElement);
        }
      };
    }
  }, [isVisible, onComplete]);

  if (!isVisible) return null;

  return (
    <Box
      className="loading-screen-fadeIn"
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background:
          "linear-gradient(135deg, var(--mantine-primary-color-6) 0%, var(--mantine-primary-color-8) 100%)",
        zIndex: 9999,
      }}
    >
      <Center h="100vh" style={{ flexDirection: "column" }}>
        {showContent && (
          <>
            {/* Logo/Brand */}
            <Box mb="xl" className="loading-screen-slideUp-1">
              <Text
                size="48px"
                fw={700}
                c="white"
                className="loading-screen-pulse"
                style={{
                  fontFamily: "var(--mantine-font-family)",
                  letterSpacing: "-0.02em",
                }}
              >
                QuickQuiz
              </Text>
            </Box>

            {/* Loading spinner */}
            <Box className="loading-screen-slideUp-2">
              <Loader size="lg" color="white" />
            </Box>

            {/* Loading text */}
            <Text
              mt="lg"
              c="white"
              size="sm"
              opacity={0.9}
              className="loading-screen-slideUp-3"
            >
              Loading your admin panel...
            </Text>
          </>
        )}
      </Center>
    </Box>
  );
}
