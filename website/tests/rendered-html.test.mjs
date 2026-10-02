import assert from "node:assert/strict";
import { access, readFile, readdir, stat } from "node:fs/promises";
import test from "node:test";

async function render(pathname = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
  const { default: worker } = await import(workerUrl.href);
  return worker.fetch(
    new Request(`http://localhost${pathname}`, { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server renders the Mathos homepage", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);
  const html = await response.text();
  assert.match(html, /Chinh phục xác suất/);
  assert.match(html, /Tải Mathos cho Windows/);
  assert.match(html, /Khu Rừng Mù Sương/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton|Your site is taking shape/i);
});

const routes = [
  ["/gioi-thieu", /Khi kiến thức trở thành sức mạnh/],
  ["/cach-choi", /Đọc tình huống/],
  ["/the-gioi", /Một thế giới nơi quy luật đang tan vỡ/],
  ["/tai-game", /v0\.1\.0-alpha — sẵn sàng tải/],
  ["/huong-dan", /Cài đặt và sử dụng theo từng vai trò/],
  ["/cap-nhat", /Cập nhật từ đội ngũ Mathos/],
  ["/ho-tro", /Tìm câu trả lời nhanh/],
  ["/chinh-sach", /Chính sách riêng tư/],
  ["/dieu-khoan", /Điều khoản sử dụng/],
];

for (const [pathname, content] of routes) {
  test(`server renders ${pathname}`, async () => {
    const response = await render(pathname);
    assert.equal(response.status, 200);
    const html = await response.text();
    assert.match(html, content);
    assert.match(html, /mathos-logo\.webp/);
  });
}

test("publishes the verified Windows release metadata", async () => {
  const response = await render("/tai-game");
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /\/releases\/Mathos-Windows-x64-v0\.1\.0-alpha\.zip/);
  assert.match(html, /112,52 MB/);
  assert.match(html, /C7082B44CBC27C4D49D545455D5D8BC66FCA66EE22F956618E10D2BAA3FB8E63/);
  assert.match(html, /SmartScreen/);
});

test("keeps Vietnamese copy normalized and uses Vietnamese-capable fonts", async () => {
  const appRoot = new URL("../app/", import.meta.url);
  const files = await readdir(appRoot, { recursive: true });
  const sourceFiles = files.filter((file) => /\.(ts|tsx|css)$/.test(file));

  for (const file of sourceFiles) {
    const source = await readFile(new URL(file, appRoot), "utf8");
    assert.equal(source, source.normalize("NFC"), `${file} must remain NFC-normalized`);
  }

  const css = await readFile(new URL("../app/globals.css", import.meta.url), "utf8");
  assert.match(css, /noto-serif-vietnamese\.woff2/);
  assert.match(css, /be-vietnam-pro-vietnamese-400\.woff2/);
  assert.match(css, /font-family:\s*var\(--font-display\)/);
  assert.doesNotMatch(css, /font-family:\s*Georgia/i);
  assert.doesNotMatch(css, /letter-spacing:\s*-\.0(?:25|4|45)em/);
});

test("ships optimized production images", async () => {
  const required = [
    "public/images/academy-bg.webp",
    "public/images/mathos-world.webp",
    "public/images/mathos-logo.webp",
    "public/images/mathos-emblem.webp",
    "public/images/karl.webp",
    "public/images/stochas.webp",
    "public/og.jpg",
    "public/fonts/noto-serif-vietnamese.woff2",
    "public/fonts/be-vietnam-pro-vietnamese-400.woff2",
  ];

  for (const file of required) {
    const url = new URL(`../${file}`, import.meta.url);
    await access(url);
    const metadata = await stat(url);
    assert.ok(metadata.size < 500 * 1024, `${file} should stay below 500 KB`);
  }
});
