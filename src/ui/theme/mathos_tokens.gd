class_name MathosTokens
extends RefCounted

## Centralized Mathos Design Tokens (Fantasy-Math Theme).
## Provides single-source-of-truth constants for colors, font sizes, spacing, and radiuses.

const VERSION: String = "0.1.0-rc3"

# --- SURFACES & BACKGROUNDS ---
const BG_APP: Color = Color(0.06, 0.08, 0.12, 1.0)              # #0f141e - Deep slate navy
const SURFACE_PRIMARY: Color = Color(0.10, 0.14, 0.21, 0.95)     # #1a2435 - Base panel surface
const SURFACE_SECONDARY: Color = Color(0.14, 0.19, 0.29, 0.95)   # #24304a - Inset / sub-panel surface
const SURFACE_ELEVATED: Color = Color(0.18, 0.24, 0.36, 0.98)    # #2e3d5c - Raised card / header
const SURFACE_MODAL: Color = Color(0.22, 0.29, 0.43, 0.98)       # #384a6e - Overlays & dialogs
const SURFACE_CARD: Color = Color(0.12, 0.16, 0.24, 0.90)        # #1f293d - Card background
const SURFACE_OVERLAY: Color = Color(0.04, 0.05, 0.08, 0.75)     # Dimmer backdrop

# --- BRAND & ACCENT COLORS ---
const COLOR_GOLD_PRIMARY: Color = Color(0.96, 0.77, 0.26, 1.0)   # #f5c542 - Arcane Gold
const COLOR_GOLD_HOVER: Color = Color(1.0, 0.84, 0.38, 1.0)     # #ffdb61 - Bright Gold
const COLOR_GOLD_PRESSED: Color = Color(0.82, 0.63, 0.18, 1.0)   # #d1a12e - Deep Gold
const COLOR_GOLD_MUTED: Color = Color(0.48, 0.39, 0.13, 0.60)   # Dimmed Gold for disabled

const COLOR_CYAN_MANA: Color = Color(0.22, 0.74, 0.97, 1.0)     # #38bdf8 - Mana Cyan / Focus ring
const COLOR_CYAN_HOVER: Color = Color(0.48, 0.83, 0.98, 1.0)    # #7dd3fc - Hover Cyan
const COLOR_CYAN_PRESSED: Color = Color(0.07, 0.58, 0.84, 1.0)  # #0284c7 - Deep Cyan

const COLOR_EMERALD_SUCCESS: Color = Color(0.06, 0.73, 0.51, 1.0) # #10b981 - Correct / Victory
const COLOR_RED_DESTRUCTIVE: Color = Color(0.94, 0.27, 0.27, 1.0) # #ef4444 - Error / Defeat / Cancel
const COLOR_RED_HOVER: Color = Color(0.97, 0.42, 0.42, 1.0)      # #f87171 - Hover Red
const COLOR_RED_PRESSED: Color = Color(0.73, 0.15, 0.15, 1.0)    # #dc2626 - Deep Red
const COLOR_AMBER_WARNING: Color = Color(0.96, 0.62, 0.07, 1.0)   # #f59e0b - Warning / Caution

# --- TYPOGRAPHY COLORS ---
const TEXT_TITLE: Color = Color(0.97, 0.98, 1.0, 1.0)           # #f8fafc - Bright Title White
const TEXT_HEADING: Color = Color(0.96, 0.77, 0.26, 1.0)         # #f5c542 - Gold Heading
const TEXT_BODY: Color = Color(0.89, 0.91, 0.94, 1.0)            # #e2e8f0 - Readable Body Slate
const TEXT_SECONDARY: Color = Color(0.58, 0.64, 0.72, 1.0)       # #94a3b8 - Muted Subtitle/Meta
const TEXT_MUTED: Color = Color(0.39, 0.45, 0.55, 1.0)           # #64748b - Dim Labels
const TEXT_ON_ACCENT: Color = Color(0.05, 0.07, 0.10, 1.0)       # #0d121a - Dark text on Gold
const TEXT_DISABLED: Color = Color(0.40, 0.45, 0.52, 0.60)       # Disabled text

# --- BORDER COLORS ---
const BORDER_DEFAULT: Color = Color(0.24, 0.31, 0.44, 0.80)     # Subtle outline
const BORDER_HOVER: Color = Color(0.48, 0.83, 0.98, 0.90)       # Cyan hover ring
const BORDER_FOCUS: Color = Color(0.22, 0.74, 0.97, 1.0)        # Focus indicator
const BORDER_SELECTED: Color = Color(0.96, 0.77, 0.26, 1.0)     # Gold selected outline
const BORDER_CORRECT: Color = Color(0.06, 0.73, 0.51, 1.0)      # Green success border
const BORDER_INCORRECT: Color = Color(0.94, 0.27, 0.27, 1.0)    # Red error border
const BORDER_SUBTLE: Color = Color(0.18, 0.23, 0.32, 0.60)      # Inner separator

# --- SPACING SCALE (pixels) ---
const SPACING_XS: int = 4
const SPACING_SM: int = 8
const SPACING_MD: int = 12
const SPACING_LG: int = 16
const SPACING_XL: int = 24
const SPACING_XXL: int = 32

# --- CORNER RADIUS SCALE (pixels) ---
const RADIUS_NONE: int = 0
const RADIUS_SM: int = 4
const RADIUS_MD: int = 8
const RADIUS_LG: int = 12
const RADIUS_FULL: int = 999

# --- FONT SIZE SCALE (pixels) ---
const FONT_SIZE_TITLE: int = 28
const FONT_SIZE_HEADING: int = 22
const FONT_SIZE_SUBTITLE: int = 18
const FONT_SIZE_BODY: int = 16
const FONT_SIZE_META: int = 14
const FONT_SIZE_SMALL: int = 12
