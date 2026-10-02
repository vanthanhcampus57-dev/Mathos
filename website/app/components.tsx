import Link from "next/link";

const navItems = [
  ["/gioi-thieu", "Giới thiệu"],
  ["/cach-choi", "Cách chơi"],
  ["/huong-dan", "Hướng dẫn"],
  ["/the-gioi", "Thế giới"],
  ["/cap-nhat", "Cập nhật"],
];

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="container header-inner">
        <Link className="brand" href="/" aria-label="Mathos — Trang chủ">
          <img src="/images/mathos-logo.webp" alt="Mathos" />
        </Link>
        <nav className="desktop-nav" aria-label="Điều hướng chính">
          {navItems.map(([href, label]) => <a href={href} key={href}>{label}</a>)}
        </nav>
        <a className="button button-small button-primary header-cta" href="/tai-game">Tải game</a>
        <details className="mobile-menu">
          <summary aria-label="Mở trình đơn">Menu</summary>
          <nav aria-label="Điều hướng trên thiết bị di động">
            {navItems.map(([href, label]) => <a href={href} key={href}>{label}</a>)}
            <a href="/tai-game">Tải game</a>
            <a href="/ho-tro">Hỗ trợ</a>
          </nav>
        </details>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="container footer-main">
        <div className="footer-brand">
          <img src="/images/mathos-logo.webp" alt="Mathos" loading="lazy" />
          <p>Học xác suất qua phiêu lưu, lựa chọn và chiến thuật.</p>
          <p>Thực hiện bởi Hồ Viết Phi và Phạm Hoài Anh — lớp 11/1.</p>
        </div>
        <div className="footer-column"><h2>Khám phá</h2><a href="/gioi-thieu">Giới thiệu</a><a href="/cach-choi">Cách chơi</a><a href="/the-gioi">Thế giới</a></div>
        <div className="footer-column"><h2>Thông tin</h2><a href="/tai-game">Tải game</a><a href="/huong-dan">Hướng dẫn sử dụng</a><a href="/cap-nhat">Cập nhật</a><a href="/ho-tro">Hỗ trợ & FAQ</a></div>
        <div className="footer-column"><h2>Pháp lý</h2><a href="/chinh-sach">Chính sách riêng tư</a><a href="/dieu-khoan">Điều khoản sử dụng</a></div>
      </div>
      <div className="container footer-bottom"><span>© 2026 Mathos — dự án học sinh Trường Quốc tế Á Châu.</span><span>mathos.vn</span></div>
    </footer>
  );
}

export function SectionTitle({ eyebrow, title, align = "left" }: { eyebrow: string; title: string; align?: "left" | "center" }) {
  return <div className={`section-title ${align === "center" ? "section-title-center" : ""}`}><span className="eyebrow">{eyebrow}</span><h2>{title}</h2></div>;
}

export function PageHero({ eyebrow, title, description, image = "/images/academy-bg.webp" }: { eyebrow: string; title: string; description: string; image?: string }) {
  return (
    <section className="page-hero" style={{ backgroundImage: `linear-gradient(90deg, rgba(7,11,19,.96) 0%, rgba(7,11,19,.72) 54%, rgba(7,11,19,.45) 100%), url(${image})` }}>
      <div className="container page-hero-inner"><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>
    </section>
  );
}

export function DownloadBand() {
  return (
    <section className="download-band">
      <div className="download-rune" aria-hidden="true">✦</div>
      <div className="container download-band-inner">
        <div><span className="eyebrow">Sẵn sàng bước vào Mathos?</span><h2>Hành trình bắt đầu trên Windows</h2><p>Bản tải chính thức sẽ được công bố tại mathos.vn sau khi hoàn tất kiểm thử.</p></div>
        <a className="button button-primary" href="/tai-game">Xem trạng thái bản tải <span>→</span></a>
      </div>
    </section>
  );
}

export function InfoCard({ icon, title, children }: { icon: string; title: string; children: React.ReactNode }) {
  return <article className="info-card"><span className="info-icon" aria-hidden="true">{icon}</span><h3>{title}</h3><p>{children}</p></article>;
}
