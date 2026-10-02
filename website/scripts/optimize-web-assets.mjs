import { mkdir, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const websiteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const gameRoot = path.resolve(websiteRoot, "..");
const publicImages = path.join(websiteRoot, "public", "images");

await mkdir(publicImages, { recursive: true });

const assets = [
  ["assets/branding/mathos_logo_main.png", "mathos-logo.webp", 900, 90],
  ["assets/branding/mathos_logo_emblem.png", "mathos-emblem.webp", 420, 90],
  ["assets/backgrounds/auth/login_academy_bg_clean.png", "academy-bg.webp", 1600, 82],
  ["assets/prologue/beat_01/prologue_bg_01_mathos_world.png", "mathos-world.webp", 1600, 82],
  ["assets/characters/player/karl/karl_portrait.png", "karl.webp", 1000, 85],
  ["assets/characters/bosses/dungeon_1/stochas_boss.png", "stochas.webp", 512, 88],
  ["assets/ui/combat/cards_v1/STRIKE.png", "card-strike.webp", 378, 88],
  ["assets/ui/combat/cards_v1/DEFEND.png", "card-defend.webp", 378, 88],
  ["assets/ui/combat/cards_v1/HEAL.png", "card-heal.webp", 378, 88],
];

for (const [input, output, width, quality] of assets) {
  const source = path.join(gameRoot, input);
  const destination = path.join(publicImages, output);
  await sharp(source)
    .rotate()
    .resize({ width, withoutEnlargement: true })
    .webp({ quality, alphaQuality: 100, effort: 6, smartSubsample: true })
    .toFile(destination);
}

const ogSource = path.join(websiteRoot, "public", "og.png");
try {
  await stat(ogSource);
  await sharp(ogSource)
    .resize(1200, 630, { fit: "cover", position: "centre" })
    .jpeg({ quality: 86, mozjpeg: true })
    .toFile(path.join(websiteRoot, "public", "og.jpg"));
} catch {
  // The source PNG is intentionally removed after the first successful optimization.
}

console.log(`Optimized ${assets.length} website images.`);
