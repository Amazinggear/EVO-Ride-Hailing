import type { Metadata } from "next";
import localFont from "next/font/local";
import { Alexandria } from "next/font/google";
import "./globals.css";

const alexandria = Alexandria({
  subsets: ["arabic", "latin"],
  variable: "--font-alexandria",
  weight: ["300", "400", "500", "600", "700"],
});

const cyBold = localFont({
  src: "../../public/fonts/Cy_Text_Bold.otf",
  variable: "--font-cy-bold",
});

export const metadata: Metadata = {
  title: "EVO Admin — لوحة التحكم",
  description: "لوحة تحكم EVO للكباتن والرحلات والمحافظ",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl">
      <body className={`${alexandria.variable} ${cyBold.variable} bg-background text-foreground font-alexandria antialiased`}>
        {children}
      </body>
    </html>
  );
}
