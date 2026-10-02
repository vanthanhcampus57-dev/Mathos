import type { Metadata } from "next";
import { InfoCard, PageHero, SectionTitle } from "../components";

const release = {
  version: "v0.1.0-alpha",
  fileName: "Mathos-Windows-x64-v0.1.0-alpha.zip",
  url: "/releases/Mathos-Windows-x64-v0.1.0-alpha.zip",
  checksumUrl: "/releases/Mathos-Windows-x64-v0.1.0-alpha.zip.sha256",
  size: "112,52 MB",
  sha256: "C7082B44CBC27C4D49D545455D5D8BC66FCA66EE22F956618E10D2BAA3FB8E63",
};

export const metadata: Metadata = {
  title: "Tải game",
  description: "Tải Mathos v0.1.0-alpha chính thức cho Windows 10/11 64-bit.",
};

export default function DownloadPage() {
  return <main id="noi-dung">
    <PageHero
      eyebrow="Tải Mathos"
      title="Bắt đầu hành trình trên Windows"
      description="Tải bản alpha chính thức, giải nén đầy đủ rồi mở Mathos.exe để chơi. Tài khoản được kết nối với máy chủ Mathos tại api.mathos.vn."
    />
    <section className="section"><div className="container download-layout">
      <div className="release-card">
        <div className="release-top"><img src="/images/mathos-emblem.webp" alt="" /><div><span>Bản phát hành công khai</span><h2>{`${release.version} — sẵn sàng tải`}</h2></div></div>
        <p>Gói ZIP gồm <strong>Mathos.exe</strong> và <strong>Mathos.pck</strong>. Hãy giữ hai tệp trong cùng một thư mục sau khi giải nén.</p>
        <div className="release-meta">
          <div><span>Nền tảng</span><strong>Windows 10/11 64-bit</strong></div>
          <div><span>Dung lượng tải</span><strong>{release.size}</strong></div>
          <div><span>Ngày phát hành</span><strong>02/10/2026</strong></div>
        </div>
        <div className="button-row">
          <a className="button button-primary" href={release.url} download={release.fileName}>Tải Mathos {release.version}</a>
          <a className="button button-ghost" href="/huong-dan">Đọc hướng dẫn cài đặt</a>
        </div>
        <div className="release-checksum">
          <span>SHA-256</span>
          <code>{release.sha256}</code>
          <a href={release.checksumUrl} download={`${release.fileName}.sha256`}>Tải tệp checksum</a>
        </div>
      </div>
      <aside className="download-aside"><h2>Lưu ý quan trọng</h2><ul>
        <li>Chỉ tải game từ <strong>mathos.vn</strong> và đối chiếu mã SHA-256 khi cần.</li>
        <li>Giải nén toàn bộ gói ZIP; không chạy game trực tiếp bên trong tệp ZIP.</li>
        <li>Bản alpha chưa có chứng thư ký mã Windows nên SmartScreen có thể hiển thị cảnh báo.</li>
        <li>Tài khoản được lưu trên máy chủ; tiến trình chơi của bản này hiện lưu trên thiết bị.</li>
      </ul></aside>
    </div></section>
    <section className="section section-deep"><div className="container"><SectionTitle eyebrow="Cài đặt nhanh" title="Bắt đầu trong ba bước" align="center" /><div className="three-grid">
      <InfoCard icon="↓" title="Tải gói chính thức">Tải tệp {release.fileName} từ nút bên trên.</InfoCard>
      <InfoCard icon="□" title="Giải nén đầy đủ">Nhấp chuột phải vào tệp ZIP, chọn Giải nén tất cả và giữ Mathos.exe cùng Mathos.pck trong một thư mục.</InfoCard>
      <InfoCard icon="▶" title="Mở Mathos">Chạy Mathos.exe, tạo tài khoản hoặc đăng nhập để bắt đầu. Giáo viên và học sinh xem hướng dẫn riêng tại trang Hướng dẫn.</InfoCard>
    </div></div></section>
  </main>;
}
