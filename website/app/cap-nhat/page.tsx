import type { Metadata } from "next";
import { PageHero, SectionTitle } from "../components";

export const metadata: Metadata = { title: "Cập nhật", description: "Thông tin phát triển và ghi chú phát hành của Mathos." };

const updates = [
  { date: "25.09.2026", tag: "Website", title: "Mở cổng thông tin chính thức của Mathos", copy: "Hoàn thiện nền tảng giới thiệu thế giới, cách chơi và trạng thái bản tải Windows tại mathos.vn." },
  { date: "Đang thực hiện", tag: "Game", title: "Kiểm thử hành trình Khu Rừng Mù Sương", copy: "Rà soát năm chặng chơi, hệ thống câu hỏi xác suất, chiến đấu và luồng tài khoản trước khi phát hành." },
  { date: "Sắp tới", tag: "Phát hành", title: "Chuẩn bị gói Windows x64", copy: "Đóng gói EXE, PCK và tài sản trò chơi; kiểm tra trên máy sạch và công bố mã SHA256." },
];

export default function UpdatesPage() {
  return <main id="noi-dung"><PageHero eyebrow="Nhật ký phát triển" title="Cập nhật từ đội ngũ Mathos" description="Theo dõi những phần đã hoàn thành, nội dung đang kiểm thử và cột mốc phát hành tiếp theo." />
    <section className="section"><div className="container updates-wrap"><SectionTitle eyebrow="Mới nhất" title="Tiến độ dự án" />
      <div className="timeline">{updates.map((item) => <article className="update-item" key={item.title}><div className="update-date">{item.date}</div><div className="update-content"><span>{item.tag}</span><h2>{item.title}</h2><p>{item.copy}</p></div></article>)}</div>
    </div></section>
  </main>;
}
