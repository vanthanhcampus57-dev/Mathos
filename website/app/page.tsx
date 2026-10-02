import type { Metadata } from "next";
import { DownloadBand, SectionTitle } from "./components";

export const metadata: Metadata = {
  title: "Trang chủ",
  description: "Bước vào Mathos và học xác suất qua hành trình nhập vai chiến thuật trên Windows.",
};

const loops = [
  { number: "01", title: "Quan sát thử thách", copy: "Đọc tình huống, nhận diện dữ kiện và chọn cách tiếp cận phù hợp." },
  { number: "02", title: "Giải bằng tư duy", copy: "Trả lời câu hỏi xác suất qua trắc nghiệm, ghép cặp, kéo thả hoặc nhập đáp án." },
  { number: "03", title: "Biến kiến thức thành sức mạnh", copy: "Dùng kết quả để tấn công, phòng thủ và hồi phục trong trận chiến." },
];

const interactions = ["Trắc nghiệm", "Kéo và thả", "Ghép cặp", "Nhập đáp án"];

export default function Home() {
  return (
    <main id="noi-dung">
      <section className="hero hero-home">
        <div className="hero-glow hero-glow-one" />
        <div className="hero-glow hero-glow-two" />
        <div className="container hero-grid">
          <div className="hero-copy reveal">
            <span className="eyebrow">Game học toán nhập vai trên Windows</span>
            <h1>Chinh phục xác suất bằng <em>tư duy</em> và chiến thuật</h1>
            <p className="hero-lead">
              Bước vào thế giới Mathos, nơi mỗi bài toán là một lựa chọn chiến đấu và mỗi đáp án đúng đưa bạn gần hơn tới bí mật của Trật Tự.
            </p>
            <div className="button-row">
              <a className="button button-primary" href="/tai-game">Tải Mathos cho Windows <span>↗</span></a>
              <a className="button button-ghost" href="/cach-choi">Xem cách chơi</a>
            </div>
            <p className="hero-note"><span className="status-dot" /> Bản Windows x64 đang được hoàn thiện</p>
          </div>
          <div className="hero-art" aria-label="Khung cảnh học viện phép thuật trong Mathos">
            <div className="hero-sigil"><img src="/images/mathos-emblem.webp" alt="Biểu tượng Mathos" /></div>
            <div className="hero-stat hero-stat-top"><span>Chủ đề</span><strong>Xác suất</strong></div>
            <div className="hero-stat hero-stat-bottom"><span>Hành trình đầu tiên</span><strong>Khu Rừng Mù Sương</strong></div>
          </div>
        </div>
        <div className="hero-scroll"><span /> Khám phá hành trình</div>
      </section>

      <section className="signal-strip" aria-label="Điểm nổi bật">
        <div className="container signal-grid">
          <div><strong>04</strong><span>Dạng tương tác toán học</span></div>
          <div><strong>05</strong><span>Chặng trong hành trình đầu</span></div>
          <div><strong>∞</strong><span>Cách kết hợp chiến thuật</span></div>
        </div>
      </section>

      <section className="section section-story">
        <div className="container split-grid">
          <div>
            <SectionTitle eyebrow="Một thế giới bị phân mảnh" title="Khôi phục Trật Tự bằng sức mạnh của tri thức" />
            <p className="body-large">Khi những quy luật của Mathos bị phá vỡ, các vùng đất chìm trong hỗn loạn. Bạn đồng hành cùng Karl, giải mã thử thách và thu hồi những mảnh Trật Tự đã thất lạc.</p>
            <a className="text-link" href="/the-gioi">Khám phá thế giới <span>→</span></a>
          </div>
          <div className="framed-image framed-map">
            <img src="/images/misty-map.jpg" alt="Bản đồ Khu Rừng Mù Sương" loading="lazy" />
            <div className="image-caption"><span>Vùng đang mở</span><strong>Khu Rừng Mù Sương</strong></div>
          </div>
        </div>
      </section>

      <section className="section section-deep">
        <div className="container">
          <SectionTitle eyebrow="Học bằng hành động" title="Một vòng lặp học tập có chiến thuật" align="center" />
          <div className="loop-grid">
            {loops.map((item) => (
              <article className="loop-card" key={item.number}>
                <span className="loop-number">{item.number}</span>
                <h3>{item.title}</h3>
                <p>{item.copy}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container split-grid split-reverse">
          <div className="cards-showcase" aria-label="Ba thẻ chiến thuật trong Mathos">
            <img className="game-card card-left" src="/images/card-defend.webp" alt="Thẻ Phòng thủ" loading="lazy" />
            <img className="game-card card-center" src="/images/card-strike.webp" alt="Thẻ Tấn công" loading="lazy" />
            <img className="game-card card-right" src="/images/card-heal.webp" alt="Thẻ Hồi phục" loading="lazy" />
          </div>
          <div>
            <SectionTitle eyebrow="Tư duy tạo nên chiến thuật" title="Không chỉ trả lời đúng — hãy dùng đúng lúc" />
            <p className="body-large">Mỗi quyết định ảnh hưởng trực tiếp đến trận đấu. Tấn công để tạo áp lực, phòng thủ trước nguy hiểm hoặc hồi phục để tiếp tục hành trình.</p>
            <div className="tag-list">
              {interactions.map((item) => <span key={item}>{item}</span>)}
            </div>
            <a className="text-link" href="/cach-choi">Tìm hiểu cơ chế chơi <span>→</span></a>
          </div>
        </div>
      </section>

      <section className="section section-world-preview">
        <div className="world-backdrop" />
        <div className="container world-copy">
          <span className="eyebrow">Hành trình đầu tiên</span>
          <h2>Khu Rừng<br /><em>Mù Sương</em></h2>
          <p>Tiến qua năm chặng thử thách, đối mặt với Stochas và khám phá cách xác suất định hình mọi lựa chọn trong rừng sâu.</p>
          <a className="button button-ghost" href="/the-gioi">Xem vùng đất</a>
        </div>
      </section>

      <DownloadBand />
    </main>
  );
}
