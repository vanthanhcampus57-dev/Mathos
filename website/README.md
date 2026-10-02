# Mathos Website

Website giới thiệu chính thức của game học toán nhập vai Mathos. Website cung cấp thông tin về game, cách chơi, thế giới, cập nhật, hỗ trợ và bản tải Windows khi phát hành.

## Chạy local

```bash
npm ci
npm run dev
```

Mở `http://localhost:3000`.

## Kiểm tra

```bash
npm test
```

Lệnh kiểm tra sẽ build website và xác nhận toàn bộ route, nội dung tiếng Việt, font cùng các tài sản tối ưu.

## Tối ưu lại ảnh

```bash
npm run assets:optimize
```

Script đọc ảnh gốc từ thư mục `../assets` của dự án game và tạo các file WebP dùng trên website.

## Các trang

- `/`
- `/gioi-thieu`
- `/cach-choi`
- `/the-gioi`
- `/tai-game`
- `/cap-nhat`
- `/ho-tro`
- `/chinh-sach`
- `/dieu-khoan`

## Phát hành

Website được build bằng `vinext` để tạo đầu ra tương thích Cloudflare Worker. Bản production tại `mathos.vn` sẽ được triển khai sau khi hoàn tất nội dung pháp lý, gói game Windows và cấu hình VPS.
