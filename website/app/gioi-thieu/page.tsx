import type { Metadata } from "next";
import { DownloadBand, InfoCard, PageHero, SectionTitle } from "../components";

export const metadata: Metadata = { title: "Giới thiệu", description: "Tìm hiểu mục tiêu, câu chuyện và định hướng học tập của Mathos." };

export default function AboutPage() {
  return <main id="noi-dung">
    <PageHero eyebrow="Về Mathos" title="Khi kiến thức trở thành sức mạnh" description="Mathos kết hợp hành trình nhập vai, chiến thuật thẻ bài và bài toán xác suất để người chơi học bằng cách ra quyết định." image="/images/mathos-world.webp" />
    <section className="section"><div className="container split-grid">
      <div><SectionTitle eyebrow="Tầm nhìn" title="Một trải nghiệm học tập đáng để khám phá" /><p className="body-large">Thay vì tách bài học khỏi trò chơi, Mathos đưa kiến thức vào trung tâm của mỗi trận đấu. Người chơi hiểu dữ kiện, cân nhắc khả năng và dùng kết quả để lựa chọn chiến thuật.</p><p>Phiên bản hiện tại tập trung vào chủ đề xác suất và hành trình Khu Rừng Mù Sương. Nội dung mới chỉ được công bố khi đã sẵn sàng để chơi.</p></div>
      <div className="portrait-panel"><img src="/images/karl.webp" alt="Nhân vật Karl trong Mathos" loading="lazy" /><div><span>Người đồng hành</span><strong>Karl</strong></div></div>
    </div></section>
    <section className="section section-deep"><div className="container"><SectionTitle eyebrow="Ba nguyên tắc" title="Mathos được xây dựng để" align="center" /><div className="three-grid"><InfoCard icon="◇" title="Khơi gợi tò mò">Biến khái niệm trừu tượng thành tình huống có mục tiêu, bối cảnh và phản hồi rõ ràng.</InfoCard><InfoCard icon="✦" title="Rèn tư duy">Khuyến khích người chơi đọc dữ kiện, thử chiến thuật và học từ mỗi lựa chọn.</InfoCard><InfoCard icon="⌁" title="Tôn trọng tiến độ">Không tạo áp lực cạnh tranh; tiến trình được lưu trên máy để người chơi tiếp tục khi thuận tiện.</InfoCard></div></div></section>
    <DownloadBand />
  </main>;
}
