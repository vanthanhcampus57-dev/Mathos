import type { Metadata } from "next";
import { SiteFooter, SiteHeader } from "./components";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://mathos.vn"),
  title: {
    default: "Mathos — Học xác suất qua phiêu lưu chiến thuật",
    template: "%s | Mathos",
  },
  description:
    "Mathos là game nhập vai học toán trên Windows, nơi kiến thức xác suất trở thành sức mạnh để chiến đấu và khám phá thế giới.",
  icons: {
    icon: "/images/mathos-emblem.webp",
    shortcut: "/images/mathos-emblem.webp",
  },
  openGraph: {
    type: "website",
    locale: "vi_VN",
    siteName: "Mathos",
    title: "Mathos — Chinh phục xác suất bằng tư duy và chiến thuật",
    description:
      "Khám phá game nhập vai học toán trên Windows, nơi mỗi câu trả lời đúng mở ra một chiến thuật mới.",
    images: [{ url: "/og.jpg", width: 1200, height: 630, alt: "Mathos — Học xác suất qua phiêu lưu" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Mathos — Học xác suất qua phiêu lưu",
    description: "Game nhập vai học toán và chiến thuật dành cho Windows.",
    images: ["/og.jpg"],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="vi">
      <body>
        <a className="skip-link" href="#noi-dung">Bỏ qua điều hướng</a>
        <SiteHeader />
        {children}
        <SiteFooter />
      </body>
    </html>
  );
}
