import type { Metadata } from "next";
import { DownloadBand, InfoCard, PageHero, SectionTitle } from "../components";

export const metadata: Metadata = { title: "Cách chơi", description: "Tìm hiểu vòng lặp học tập, dạng câu hỏi và hệ thống chiến đấu trong Mathos." };

export default function HowToPlayPage() {
  return <main id="noi-dung">
    <PageHero eyebrow="Cách chơi" title="Đọc tình huống. Giải bài toán. Chọn chiến thuật." description="Mỗi lượt chơi nối liền tư duy toán học với hành động trong trận chiến." />
    <section className="section"><div className="container"><SectionTitle eyebrow="Vòng lặp cốt lõi" title="Ba bước để làm chủ mỗi thử thách" align="center" /><div className="three-grid step-grid"><InfoCard icon="01" title="Phân tích">Quan sát dữ kiện và xác định điều bài toán đang yêu cầu.</InfoCard><InfoCard icon="02" title="Tương tác">Chọn, ghép, kéo thả hoặc nhập đáp án phù hợp.</InfoCard><InfoCard icon="03" title="Hành động">Dùng lợi thế nhận được để tấn công, phòng thủ hoặc hồi phục.</InfoCard></div></div></section>
    <section className="section section-deep"><div className="container split-grid">
      <div><SectionTitle eyebrow="Nhiều cách luyện tập" title="Không lặp lại một kiểu câu hỏi" /><p className="body-large">Mathos luân phiên bốn dạng tương tác để người chơi vừa tính toán, vừa nhận diện quan hệ và diễn giải kết quả.</p><ul className="feature-list"><li><strong>Trắc nghiệm</strong><span>Chọn kết quả hoặc lập luận phù hợp.</span></li><li><strong>Kéo và thả</strong><span>Sắp xếp dữ kiện vào đúng vị trí.</span></li><li><strong>Ghép cặp</strong><span>Kết nối biểu diễn với ý nghĩa tương ứng.</span></li><li><strong>Nhập đáp án</strong><span>Tự tính toán và điền kết quả.</span></li></ul></div>
      <div className="cards-showcase cards-static"><img className="game-card card-left" src="/images/card-defend.webp" alt="Thẻ Phòng thủ" loading="lazy" /><img className="game-card card-center" src="/images/card-strike.webp" alt="Thẻ Tấn công" loading="lazy" /><img className="game-card card-right" src="/images/card-heal.webp" alt="Thẻ Hồi phục" loading="lazy" /></div>
    </div></section>
    <section className="section"><div className="container"><SectionTitle eyebrow="Chiến thuật cơ bản" title="Ba lựa chọn, nhiều thời điểm quyết định" align="center" /><div className="three-grid"><InfoCard icon="⚔" title="Tấn công">Chuyển lợi thế thành sát thương để kết thúc trận đấu.</InfoCard><InfoCard icon="⬡" title="Phòng thủ">Chuẩn bị trước đòn nguy hiểm và bảo toàn nhịp chơi.</InfoCard><InfoCard icon="✚" title="Hồi phục">Lấy lại sức mạnh để tiếp tục hành trình dài hơn.</InfoCard></div></div></section>
    <DownloadBand />
  </main>;
}
