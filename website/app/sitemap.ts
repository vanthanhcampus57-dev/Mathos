import type { MetadataRoute } from "next";
const routes = ["", "/gioi-thieu", "/cach-choi", "/huong-dan", "/the-gioi", "/tai-game", "/cap-nhat", "/ho-tro", "/chinh-sach", "/dieu-khoan"];
export default function sitemap(): MetadataRoute.Sitemap { return routes.map((route) => ({ url: `https://mathos.vn${route}`, lastModified: new Date("2026-09-25"), changeFrequency: route === "" || route === "/cap-nhat" ? "weekly" : "monthly", priority: route === "" ? 1 : 0.7 })); }
