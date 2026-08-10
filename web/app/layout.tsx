import type { Metadata, Viewport } from "next";
import { Space_Grotesk, Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider, ThemeScript } from "@/lib/theme";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";

const display = Space_Grotesk({
  subsets: ["latin"],
  weight: ["500", "700"],
  variable: "--font-display",
  fallback: ["Inter Tight", "ui-sans-serif", "system-ui", "sans-serif"],
  display: "swap",
});

const body = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-body",
  fallback: ["-apple-system", "BlinkMacSystemFont", "Segoe UI", "sans-serif"],
  display: "swap",
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  weight: ["500", "700"],
  variable: "--font-mono",
  fallback: ["ui-monospace", "SFMono-Regular", "Menlo", "Consolas", "monospace"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "FoldReady — your iOS app, ready for the iPhone Fold",
  description:
    "A Fold-Ready Score for your iOS app, and the porting work to be featured on the iPhone Fold day one. Static + pixel audit of your source tree, then fixed-price adaptation to the 7.8 inch inner display.",
};

export const viewport: Viewport = {
  themeColor: "#0F172A",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable} ${mono.variable}`}>
      <head>
        <ThemeScript />
      </head>
      <body>
        <ThemeProvider>
          <Nav />
          {children}
          <Footer />
        </ThemeProvider>
      </body>
    </html>
  );
}
