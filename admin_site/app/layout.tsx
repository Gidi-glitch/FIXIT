

import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Fix It Marketplace — Admin Portal",
  description: "Admin dashboard for Fix It Marketplace",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, padding: 0, fontFamily: "'Plus Jakarta Sans', sans-serif" }}>
        {children}
      </body>
    </html>
  );
}