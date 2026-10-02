import type { Metadata } from "next";
import { InfoCard, PageHero, SectionTitle } from "../components";

export const metadata: Metadata = {
  title: "Hướng dẫn cài đặt và sử dụng",
  description:
    "Hướng dẫn cài đặt Mathos trên Windows và quy trình sử dụng dành riêng cho học sinh, giáo viên.",
};

const installSteps = [
  {
    number: "01",
    title: "Tải từ nguồn chính thức",
    copy: "Truy cập trang Tải game trên mathos.vn, kiểm tra số phiên bản và tải gói Windows x64. Không nhận file cài đặt từ nguồn không rõ ràng.",
  },
  {
    number: "02",
    title: "Kiểm tra gói tải về",
    copy: "Đối chiếu tên phiên bản và mã SHA256 khi mã này được công bố. Đây là bước giúp xác nhận file tải về không bị thay đổi.",
  },
  {
    number: "03",
    title: "Giải nén đầy đủ",
    copy: "Nhấp chuột phải vào file ZIP, chọn Giải nén tất cả và đặt toàn bộ nội dung trong cùng một thư mục. Không chạy game trực tiếp bên trong file ZIP.",
  },
  {
    number: "04",
    title: "Mở Mathos.exe",
    copy: "Chạy Mathos.exe trong thư mục vừa giải nén. Không di chuyển riêng file EXE khỏi các file dữ liệu đi kèm.",
  },
  {
    number: "05",
    title: "Đăng nhập và bắt đầu",
    copy: "Tạo tài khoản bằng email hoặc đăng nhập tài khoản đã có. Thiết bị cần kết nối Internet khi đăng ký và đăng nhập.",
  },
];

const studentSteps = [
  ["1", "Tạo tài khoản cá nhân", "Dùng email có thể truy cập và mật khẩu riêng. Không dùng chung tài khoản với bạn khác."],
  ["2", "Hoàn thành phần mở đầu", "Theo dõi câu chuyện, làm quen với Karl và thực hiện hướng dẫn điều khiển đầu tiên."],
  ["3", "Đọc kỹ thử thách", "Xác định dữ kiện, yêu cầu và dạng câu hỏi trước khi chọn thẻ hoặc trả lời."],
  ["4", "Giải bài toán", "Thực hiện trắc nghiệm, kéo thả, ghép cặp hoặc nhập đáp án theo hướng dẫn trên màn hình."],
  ["5", "Dùng kết quả để chiến đấu", "Chọn tấn công, phòng thủ hay hồi phục phù hợp với tình huống và lượng tài nguyên hiện có."],
  ["6", "Thoát game đúng cách", "Quay về màn hình chính rồi thoát game. Nên tiếp tục trên cùng thiết bị để giữ tiến trình hiện tại."],
];

const teacherPlan = [
  ["5 phút", "Chuẩn bị", "Kiểm tra game mở được, mạng ổn định và học sinh đăng nhập đúng tài khoản."],
  ["10 phút", "Làm quen", "Cho học sinh hoàn thành hướng dẫn, nhận diện dữ kiện và cách tương tác."],
  ["20 phút", "Thực hành", "Học sinh chơi thử thách; giáo viên quan sát cách lập luận thay vì chỉ ghi nhận đáp án."],
  ["10 phút", "Thảo luận", "So sánh chiến thuật, phân tích lỗi thường gặp và chốt lại kiến thức xác suất."],
];

export default function GuidePage() {
  return (
    <main id="noi-dung">
      <PageHero
        eyebrow="Bắt đầu với Mathos"
        title="Cài đặt và sử dụng theo từng vai trò"
        description="Một hướng dẫn thống nhất để học sinh tự học an toàn và giáo viên tổ chức hoạt động trên lớp thuận lợi."
      />

      <section className="section guide-intro">
        <div className="container">
          <SectionTitle
            eyebrow="Chọn hướng dẫn phù hợp"
            title="Bạn sử dụng Mathos với vai trò nào?"
            align="center"
          />
          <div className="guide-role-grid">
            <a className="guide-role-card" href="#hoc-sinh">
              <span className="guide-role-mark">01</span>
              <div>
                <span className="eyebrow">Dành cho học sinh</span>
                <h2>Tự cài đặt, đăng nhập và bắt đầu hành trình</h2>
                <p>Phù hợp khi học ở nhà hoặc sử dụng máy tính được giáo viên phân công trong phòng máy.</p>
              </div>
              <span className="guide-role-arrow" aria-hidden="true">↓</span>
            </a>
            <a className="guide-role-card" href="#giao-vien">
              <span className="guide-role-mark">02</span>
              <div>
                <span className="eyebrow">Dành cho giáo viên</span>
                <h2>Chuẩn bị thiết bị và tổ chức một tiết học</h2>
                <p>Phù hợp khi triển khai trên máy chiếu, máy giáo viên hoặc nhiều máy trong phòng thực hành.</p>
              </div>
              <span className="guide-role-arrow" aria-hidden="true">↓</span>
            </a>
          </div>
          <div className="guide-status-note">
            <strong>Lưu ý về hai vai trò:</strong>
            <p>Đây là hai cách sử dụng Mathos. Phiên bản hiện tại chưa có bảng điều khiển hoặc tài khoản quản trị riêng dành cho giáo viên.</p>
          </div>
        </div>
      </section>

      <section className="section section-deep">
        <div className="container">
          <SectionTitle
            eyebrow="Áp dụng cho mọi người dùng"
            title="Cài đặt Mathos trên Windows"
          />
          <p className="body-large guide-lead">
            Mathos được phát hành dưới dạng gói ZIP dành cho Windows 10/11 64-bit. Hãy giữ nguyên toàn bộ file sau khi giải nén.
          </p>
          <div className="guide-step-list">
            {installSteps.map((step) => (
              <article className="guide-step" key={step.number}>
                <span>{step.number}</span>
                <div><h3>{step.title}</h3><p>{step.copy}</p></div>
              </article>
            ))}
          </div>
          <div className="guide-warning">
            <span aria-hidden="true">!</span>
            <div>
              <h3>Nếu Windows hiển thị cảnh báo bảo vệ</h3>
              <p>
                Bản thử nghiệm đầu tiên chưa có chứng thư ký mã Windows nên SmartScreen có thể hiển thị cảnh báo. Chỉ tiếp tục khi file được tải từ mathos.vn và khớp mã SHA256 công bố. Không tắt Windows Defender.
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="section" id="hoc-sinh">
        <div className="container">
          <div className="guide-role-heading">
            <span className="guide-role-number">01</span>
            <SectionTitle eyebrow="Dành cho học sinh" title="Cách học và chơi với Mathos" />
          </div>
          <div className="three-grid guide-use-grid">
            {studentSteps.map(([icon, title, copy]) => (
              <InfoCard icon={icon} title={title} key={title}>{copy}</InfoCard>
            ))}
          </div>
          <div className="guide-data-grid">
            <article>
              <span>Tài khoản</span>
              <h3>Được lưu trên máy chủ Mathos</h3>
              <p>Email, thông tin đăng nhập và hồ sơ tài khoản được lưu trên VPS. Không chia sẻ mật khẩu cho người khác.</p>
            </article>
            <article>
              <span>Tiến trình hiện tại</span>
              <h3>Được lưu trên thiết bị đang chơi</h3>
              <p>Nên dùng cùng một máy tính và không xóa thư mục dữ liệu của game nếu muốn tiếp tục đúng tiến trình.</p>
            </article>
          </div>
        </div>
      </section>

      <section className="section section-deep" id="giao-vien">
        <div className="container">
          <div className="guide-role-heading">
            <span className="guide-role-number">02</span>
            <SectionTitle eyebrow="Dành cho giáo viên" title="Chuẩn bị và tổ chức hoạt động học tập" />
          </div>
          <div className="guide-teacher-grid">
            <div>
              <h3>Trước giờ học</h3>
              <ul className="guide-checklist">
                <li>Cài và mở thử Mathos trên từng máy sẽ sử dụng.</li>
                <li>Kiểm tra kết nối Internet bằng cách đăng nhập thử.</li>
                <li>Phân công một máy cố định cho mỗi học sinh hoặc nhóm.</li>
                <li>Nhắc học sinh dùng tài khoản cá nhân, không dùng chung mật khẩu.</li>
                <li>Chuẩn bị mục tiêu kiến thức và chặng game phù hợp với tiết học.</li>
              </ul>
            </div>
            <aside className="guide-teacher-note">
              <span className="eyebrow">Gợi ý triển khai phòng máy</span>
              <h3>Có thể sao chép cùng một thư mục game</h3>
              <p>Sau khi giải nén và kiểm tra một bản chuẩn, giáo viên có thể sao chép toàn bộ thư mục đó sang các máy khác. Mỗi học sinh vẫn đăng nhập bằng tài khoản riêng.</p>
              <p>Không sao chép riêng Mathos.exe và không đổi tên các file dữ liệu đi kèm.</p>
            </aside>
          </div>

          <SectionTitle eyebrow="Kịch bản tham khảo" title="Một tiết học 45 phút" align="center" />
          <div className="guide-session-plan">
            {teacherPlan.map(([time, title, copy]) => (
              <article key={time}>
                <strong>{time}</strong>
                <div><h3>{title}</h3><p>{copy}</p></div>
              </article>
            ))}
          </div>

          <div className="guide-after-class">
            <h3>Sau giờ học</h3>
            <p>Yêu cầu học sinh thoát game đúng cách và ghi lại máy đã sử dụng. Phiên bản hiện tại chưa tổng hợp kết quả lớp học tự động; giáo viên nên dùng câu hỏi thảo luận hoặc phiếu học tập để ghi nhận lập luận của học sinh.</p>
          </div>
        </div>
      </section>

      <section className="download-band">
        <div className="download-rune" aria-hidden="true">?</div>
        <div className="container download-band-inner">
          <div>
            <span className="eyebrow">Cần hỗ trợ thêm?</span>
            <h2>Kiểm tra trang hỗ trợ hoặc liên hệ đội ngũ Mathos</h2>
            <p>Khi báo lỗi, hãy gửi kèm phiên bản Windows, phiên bản Mathos và ảnh chụp thông báo lỗi.</p>
          </div>
          <div className="button-row guide-support-actions">
            <a className="button button-primary" href="/tai-game">Đến trang tải game</a>
            <a className="button button-ghost" href="/ho-tro">Hỗ trợ &amp; FAQ</a>
          </div>
        </div>
      </section>
    </main>
  );
}
