import type { Metadata } from "next";
import { InfoCard, PageHero, SectionTitle } from "../components";

export const metadata: Metadata = { title: "Hỗ trợ", description: "Hướng dẫn và câu hỏi thường gặp khi cài đặt, đăng nhập và chơi Mathos." };

const faqs = [
  ["Mathos có chơi trực tiếp trên trình duyệt không?", "Không. Website dùng để giới thiệu, cập nhật và cung cấp bản tải. Game được cài và chạy trên Windows."],
  ["Tài khoản có được lưu trên máy chủ không?", "Có. Thông tin tài khoản được xử lý bởi backend trên máy chủ. Tuy nhiên tiến trình chơi hiện được lưu cục bộ trên máy đang sử dụng."],
  ["Đổi máy có giữ nguyên tiến trình không?", "Chưa. Phiên bản hiện tại chưa có đồng bộ tiến trình đám mây. Hãy giữ lại dữ liệu ứng dụng trước khi đổi hoặc cài lại máy."],
  ["Vì sao chưa có nút tải?", "Bản Windows đang được kiểm thử và đóng gói. Nút tải chỉ được mở khi artifact đã được xác nhận đầy đủ và an toàn."],
];

export default function SupportPage() {
  return <main id="noi-dung"><PageHero eyebrow="Trung tâm hỗ trợ" title="Tìm câu trả lời nhanh" description="Thông tin cài đặt, tài khoản, dữ liệu chơi và trạng thái phát hành của Mathos." />
    <section className="section"><div className="container"><SectionTitle eyebrow="Hỗ trợ theo chủ đề" title="Bạn cần trợ giúp về điều gì?" align="center" /><div className="three-grid"><InfoCard icon="↓" title="Tải & cài đặt">Kiểm tra gói tải, giải nén và các tệp cần giữ cùng nhau.</InfoCard><InfoCard icon="◎" title="Tài khoản">Tạo tài khoản, đăng nhập và xử lý kết nối tới máy chủ.</InfoCard><InfoCard icon="⚙" title="Trong game">Tìm hiểu dữ liệu lưu, điều khiển và lỗi thường gặp.</InfoCard></div></div></section>
    <section className="section section-deep"><div className="container faq-wrap"><SectionTitle eyebrow="Câu hỏi thường gặp" title="Thông tin cần biết" />{faqs.map(([q,a]) => <details className="faq-item" key={q}><summary>{q}<span>+</span></summary><p>{a}</p></details>)}<div className="support-note"><strong>Chưa tìm thấy câu trả lời?</strong><p>Liên hệ đội ngũ Mathos tại <a href="mailto:vanthanhcampus57@gmail.com">vanthanhcampus57@gmail.com</a>.</p></div></div></section>
  </main>;
}
