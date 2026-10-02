import type { Metadata } from "next";
import { DownloadBand, PageHero, SectionTitle } from "../components";

export const metadata: Metadata = { title: "Thế giới", description: "Khám phá thế giới Mathos và Khu Rừng Mù Sương." };

export default function WorldPage() {
  return <main id="noi-dung">
    <PageHero eyebrow="Thế giới Mathos" title="Một thế giới nơi quy luật đang tan vỡ" description="Những mảnh Trật Tự bị phân tán, kéo theo biến động ở khắp các vùng đất. Hành trình khôi phục bắt đầu trong làn sương." image="/images/mathos-world.webp" />
    <section className="section"><div className="container split-grid">
      <div className="framed-image"><img src="/images/misty-map.jpg" alt="Bản đồ Khu Rừng Mù Sương" loading="lazy" /><div className="image-caption"><span>Dungeon 01</span><strong>Khu Rừng Mù Sương</strong></div></div>
      <div><SectionTitle eyebrow="Vùng đang mở" title="Khu Rừng Mù Sương" /><p className="body-large">Nơi mọi con đường đều ẩn sau màn sương và mỗi lựa chọn đều mang một xác suất. Người chơi tiến qua năm chặng để giải mã các quy luật đang bị bóp méo.</p><div className="world-facts"><div><span>Số chặng</span><strong>05</strong></div><div><span>Chủ đề</span><strong>Xác suất</strong></div><div><span>Đối thủ chính</span><strong>Stochas</strong></div></div></div>
    </div></section>
    <section className="section section-deep"><div className="container split-grid split-reverse">
      <div className="boss-panel"><div className="boss-aura" /><img src="/images/stochas.webp" alt="Stochas, đối thủ trong Khu Rừng Mù Sương" loading="lazy" /></div>
      <div><SectionTitle eyebrow="Đối thủ của trật tự" title="Stochas" /><p className="body-large">Một thực thể khai thác sự ngẫu nhiên và biến những khả năng nhỏ nhất thành hỗn loạn. Để vượt qua Stochas, sức mạnh đơn thuần là chưa đủ — người chơi phải hiểu xác suất và chọn thời điểm hành động.</p><p className="muted-note">Các vùng đất tiếp theo sẽ chỉ được giới thiệu khi nội dung đã hoàn tất kiểm thử.</p></div>
    </div></section>
    <DownloadBand />
  </main>;
}
