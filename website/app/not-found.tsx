import Link from "next/link";

export default function NotFound() { return <main id="noi-dung" className="not-found"><img src="/images/mathos-emblem.webp" alt="" /><span className="eyebrow">Lạc trong màn sương</span><h1>Không tìm thấy trang</h1><p>Đường dẫn này chưa tồn tại hoặc đã được di chuyển.</p><Link className="button button-primary" href="/">Trở về trang chủ</Link></main>; }
