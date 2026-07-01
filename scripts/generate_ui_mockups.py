"""Generate Figma-importable PNG UI mockups.

Outputs a simple wireframe set into: assets/ui_mockups/

Usage (Windows / PowerShell):
  I:/bag_shop_inventory/.venv/Scripts/python.exe scripts/generate_ui_mockups.py

Design notes:
- Purposefully minimal, high-contrast wireframes for academic proposal screenshots.
- 1080x2400 canvas (Android-ish). Easy to import into Figma as images.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CANVAS_W = 1080
CANVAS_H = 2400
PADDING = 64
RADIUS = 28


@dataclass(frozen=True)
class Palette:
    bg: tuple[int, int, int] = (247, 248, 250)
    card: tuple[int, int, int] = (255, 255, 255)
    stroke: tuple[int, int, int] = (212, 219, 227)
    text: tuple[int, int, int] = (20, 24, 28)
    muted: tuple[int, int, int] = (104, 117, 132)
    primary: tuple[int, int, int] = (28, 100, 242)


PAL = Palette()


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    # Use PIL default if system fonts are unavailable.
    try:
        # Windows usually has Segoe UI
        name = "segoeuib.ttf" if bold else "segoeui.ttf"
        return ImageFont.truetype(name, size)
    except Exception:
        return ImageFont.load_default()


def rr(draw: ImageDraw.ImageDraw, xy, radius: int, fill, outline=None, width: int = 2):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy, s: str, *, size: int = 40, bold: bool = False, fill=None):
    f = _load_font(size=size, bold=bold)
    draw.text(xy, s, font=f, fill=fill or PAL.text)


def measure(draw: ImageDraw.ImageDraw, s: str, *, size: int = 40, bold: bool = False):
    f = _load_font(size=size, bold=bold)
    return draw.textbbox((0, 0), s, font=f)


def hline(draw: ImageDraw.ImageDraw, x1: int, x2: int, y: int, *, color=None, width: int = 2):
    draw.line((x1, y, x2, y), fill=color or PAL.stroke, width=width)


def make_base(title: str, subtitle: str | None = None) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (CANVAS_W, CANVAS_H), PAL.bg)
    d = ImageDraw.Draw(img)

    # Phone frame
    rr(d, (24, 24, CANVAS_W - 24, CANVAS_H - 24), radius=72, fill=PAL.bg, outline=PAL.stroke, width=6)

    # Status bar
    status_h = 90
    rr(d, (48, 48, CANVAS_W - 48, 48 + status_h), radius=40, fill=PAL.bg, outline=None, width=0)
    text(d, (72, 68), "9:41", size=34, bold=True)
    # Battery/WiFi placeholders
    rr(d, (CANVAS_W - 220, 66, CANVAS_W - 92, 92), radius=14, fill=PAL.card, outline=PAL.stroke, width=2)
    rr(d, (CANVAS_W - 260, 66, CANVAS_W - 232, 92), radius=12, fill=PAL.card, outline=PAL.stroke, width=2)

    # App bar
    appbar_y = 48 + status_h + 18
    appbar_h = 132
    rr(d, (48, appbar_y, CANVAS_W - 48, appbar_y + appbar_h), radius=40, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (88, appbar_y + 36), title, size=44, bold=True)
    if subtitle:
        text(d, (88, appbar_y + 86), subtitle, size=30, fill=PAL.muted)

    return img, d


def add_button(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, label: str, *, primary=False):
    fill = PAL.primary if primary else PAL.card
    outline = None if primary else PAL.stroke
    rr(draw, (x, y, x + w, y + h), radius=26, fill=fill, outline=outline, width=2)

    bbox = measure(draw, label, size=36, bold=True)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = x + (w - tw) // 2
    ty = y + (h - th) // 2 - 2
    text(draw, (tx, ty), label, size=36, bold=True, fill=(255, 255, 255) if primary else PAL.text)


def add_input(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, label: str, value_hint: str):
    text(draw, (x, y), label, size=30, fill=PAL.muted)
    rr(draw, (x, y + 44, x + w, y + 44 + 96), radius=24, fill=PAL.card, outline=PAL.stroke, width=2)
    text(draw, (x + 28, y + 44 + 28), value_hint, size=34, fill=(140, 152, 166))


def add_card(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, title: str, lines: int = 2):
    rr(draw, (x, y, x + w, y + h), radius=32, fill=PAL.card, outline=PAL.stroke, width=2)
    text(draw, (x + 32, y + 28), title, size=36, bold=True)
    for i in range(lines):
        hline(draw, x + 32, x + w - 32, y + 90 + i * 54, color=PAL.stroke, width=2)


def screen_login_register(out_dir: Path):
    img, d = make_base("Bag Shop Inventory", "Login / Register")
    body_top = 48 + 90 + 18 + 132 + 30

    # Logo placeholder
    rr(d, (PADDING, body_top, CANVAS_W - PADDING, body_top + 220), radius=44, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (PADDING + 36, body_top + 76), "LOGO", size=52, bold=True, fill=PAL.muted)

    y = body_top + 260
    add_input(d, PADDING, y, CANVAS_W - 2 * PADDING, "Email", "name@shop.com")
    y += 170
    add_input(d, PADDING, y, CANVAS_W - 2 * PADDING, "Password", "••••••••")

    y += 200
    add_button(d, PADDING, y, CANVAS_W - 2 * PADDING, 110, "Login", primary=True)
    y += 140
    add_button(d, PADDING, y, (CANVAS_W - 2 * PADDING - 24) // 2, 110, "Register")
    add_button(d, PADDING + (CANVAS_W - 2 * PADDING - 24) // 2 + 24, y, (CANVAS_W - 2 * PADDING - 24) // 2, 110, "Forgot?")

    img.save(out_dir / "01_login_register.png")


def screen_dashboard(out_dir: Path):
    img, d = make_base("Dashboard", "Today overview")
    body_top = 48 + 90 + 18 + 132 + 30

    # KPI cards
    w = (CANVAS_W - 2 * PADDING - 28) // 2
    add_card(d, PADDING, body_top, w, 220, "Sales")
    add_card(d, PADDING + w + 28, body_top, w, 220, "Low Stock")

    y = body_top + 260
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 280, "Quick Actions", lines=3)

    y += 320
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 540, "Recent Activity", lines=6)

    img.save(out_dir / "02_dashboard.png")


def screen_product_list_details(out_dir: Path):
    img, d = make_base("Products", "List + Details")
    body_top = 48 + 90 + 18 + 132 + 30

    # Search
    rr(d, (PADDING, body_top, CANVAS_W - PADDING, body_top + 104), radius=26, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (PADDING + 28, body_top + 30), "Search by name / barcode", size=34, fill=(140, 152, 166))

    # List
    y = body_top + 134
    for i in range(5):
        rr(d, (PADDING, y, CANVAS_W - PADDING, y + 170), radius=30, fill=PAL.card, outline=PAL.stroke, width=2)
        text(d, (PADDING + 28, y + 24), f"Product {i + 1}", size=34, bold=True)
        text(d, (PADDING + 28, y + 78), "Type • Material • Size", size=30, fill=PAL.muted)
        text(d, (CANVAS_W - PADDING - 240, y + 58), "Stock: 24", size=30, bold=True)
        y += 190

    # Details panel hint
    add_card(d, PADDING, y + 10, CANVAS_W - 2 * PADDING, 420, "Product Details", lines=5)

    img.save(out_dir / "03_product_list_details.png")


def screen_barcode_scan(out_dir: Path):
    img, d = make_base("Scan Barcode", "Camera")
    body_top = 48 + 90 + 18 + 132 + 30

    # Camera viewport
    rr(d, (PADDING, body_top, CANVAS_W - PADDING, body_top + 1240), radius=44, fill=(28, 32, 36), outline=PAL.stroke, width=2)

    # Scan frame
    frame_w = CANVAS_W - 2 * PADDING - 120
    frame_h = 520
    fx = PADDING + 60
    fy = body_top + 360
    rr(d, (fx, fy, fx + frame_w, fy + frame_h), radius=36, fill=(0, 0, 0, 0), outline=(255, 255, 255), width=4)
    hline(d, fx + 40, fx + frame_w - 40, fy + frame_h // 2, color=(28, 100, 242), width=6)

    # Bottom sheet
    sheet_y = body_top + 1280
    rr(d, (PADDING, sheet_y, CANVAS_W - PADDING, sheet_y + 560), radius=44, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (PADDING + 32, sheet_y + 28), "Result", size=36, bold=True)
    text(d, (PADDING + 32, sheet_y + 86), "Barcode: 1234567890", size=30, fill=PAL.muted)
    add_button(d, PADDING + 32, sheet_y + 150, CANVAS_W - 2 * PADDING - 64, 110, "Open Product", primary=True)
    add_button(d, PADDING + 32, sheet_y + 290, CANVAS_W - 2 * PADDING - 64, 110, "Add New Product")

    img.save(out_dir / "04_barcode_scan.png")


def screen_purchase_orders(out_dir: Path):
    img, d = make_base("Purchase Orders", "List → Details → Receive")
    body_top = 48 + 90 + 18 + 132 + 30

    add_card(d, PADDING, body_top, CANVAS_W - 2 * PADDING, 240, "Create PO", lines=2)

    y = body_top + 280
    for i in range(4):
        rr(d, (PADDING, y, CANVAS_W - PADDING, y + 190), radius=30, fill=PAL.card, outline=PAL.stroke, width=2)
        text(d, (PADDING + 28, y + 26), f"PO-2026-00{i + 1}", size=34, bold=True)
        text(d, (PADDING + 28, y + 78), "Supplier • Expected date", size=30, fill=PAL.muted)
        text(d, (CANVAS_W - PADDING - 280, y + 122), "Status: Open", size=30, bold=True)
        y += 210

    add_card(d, PADDING, y + 10, CANVAS_W - 2 * PADDING, 520, "Receive Items", lines=6)

    img.save(out_dir / "05_purchase_orders.png")


def screen_sales_pos(out_dir: Path):
    img, d = make_base("Sales / POS", "Cart → Checkout")
    body_top = 48 + 90 + 18 + 132 + 30

    # Product quick add
    rr(d, (PADDING, body_top, CANVAS_W - PADDING, body_top + 104), radius=26, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (PADDING + 28, body_top + 30), "Scan / Search product", size=34, fill=(140, 152, 166))

    # Cart items
    y = body_top + 134
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 860, "Cart", lines=9)

    # Totals + checkout
    y += 900
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 260, "Totals", lines=3)
    y += 300
    add_button(d, PADDING, y, CANVAS_W - 2 * PADDING, 120, "Checkout", primary=True)

    img.save(out_dir / "06_sales_pos.png")


def screen_inventory_movement(out_dir: Path):
    img, d = make_base("Inventory Movements", "History / Audit")
    body_top = 48 + 90 + 18 + 132 + 30

    # Filters
    rr(d, (PADDING, body_top, CANVAS_W - PADDING, body_top + 120), radius=30, fill=PAL.card, outline=PAL.stroke, width=2)
    text(d, (PADDING + 28, body_top + 18), "Warehouse", size=28, fill=PAL.muted)
    text(d, (PADDING + 28, body_top + 58), "Main Warehouse ▼", size=34, bold=True)

    y = body_top + 150
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 1540, "Movement List", lines=16)

    img.save(out_dir / "07_inventory_movement_history.png")


def screen_admin_panel(out_dir: Path):
    img, d = make_base("Admin Panel", "Invite Codes + Staff")
    body_top = 48 + 90 + 18 + 132 + 30

    add_card(d, PADDING, body_top, CANVAS_W - 2 * PADDING, 360, "Invite Code", lines=4)
    add_button(d, PADDING + 32, body_top + 220, CANVAS_W - 2 * PADDING - 64, 110, "Generate New Code", primary=True)

    y = body_top + 400
    add_card(d, PADDING, y, CANVAS_W - 2 * PADDING, 1240, "Staff List", lines=14)

    img.save(out_dir / "08_admin_panel.png")


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    out_dir = repo_root / "assets" / "ui_mockups"
    out_dir.mkdir(parents=True, exist_ok=True)

    screen_login_register(out_dir)
    screen_dashboard(out_dir)
    screen_product_list_details(out_dir)
    screen_barcode_scan(out_dir)
    screen_purchase_orders(out_dir)
    screen_sales_pos(out_dir)
    screen_inventory_movement(out_dir)
    screen_admin_panel(out_dir)

    print(f"Generated mockups in: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
