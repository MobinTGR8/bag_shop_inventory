"""
Render Mermaid.js diagrams to PNG images using Playwright with Chromium.

This script creates an HTML page with each Mermaid diagram, loads it in
Chromium, and takes screenshots of each diagram. Outputs PNG files to the
project root directory.

Usage:
    python3 /full/path/to/scripts/render_diagrams.py
"""

import asyncio
import json
import sys
from pathlib import Path

# ── Ensure we are in the project root ──────────────────────────────
REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = REPO_ROOT

# ── Diagram definitions (Mermaid source) ───────────────────────────
DIAGRAMS = [
    {
        "name": "flow_chart",
        "title": "Flow Chart — POS Workflow",
        "mermaid": """
graph TD
    A[Open POS Screen] --> B[Search/Search Product]
    B --> C{Found?}
    C -->|Yes| D[Add to Cart]
    C -->|No| E[Try Barcode Scan]
    E --> C
    
    D --> F{More Items?}
    F -->|Yes| B
    F -->|No| G[Review Cart]
    
    G --> H[Select Payment Method]
    H --> I{CASH?}
    H --> J{CARD?}
    H --> K{UPI?}
    H --> L{SPLIT?}
    
    I & J & K & L --> Q[Show Payment Simulation]
    Q --> R{Simulation OK?}
    R -->|Yes| S[Create Sale Order]
    R -->|No, Retry| H
    
    S --> T[Insert Stock Movements -SALE]
    T --> U[Generate Invoice]
    U --> V[Clear Cart]
    V --> W[Return to POS]
"""
    },
    {
        "name": "er_diagram",
        "title": "Entity Relationship Diagram",
        "mermaid": """
erDiagram
    companies ||--o{ products : "has"
    companies ||--o{ categories : "has"
    companies ||--o{ brands : "has"
    companies ||--o{ warehouses : "has"
    companies ||--o{ customers : "has"
    companies ||--o{ suppliers : "has"
    companies ||--o{ sales_orders : "has"
    companies ||--o{ purchase_orders : "has"
    companies ||--o{ staff : "has"
    companies ||--o{ stock_movements : "has"

    products ||--o{ inventory : "stocks"
    products ||--o{ sales_order_items : "sold in"
    products ||--o{ purchase_order_items : "ordered in"
    products ||--o{ stock_movements : "moved"
    products }o--|| categories : "belongs to"
    products }o--|| brands : "branded by"

    warehouses ||--o{ inventory : "contains"
    warehouses ||--o{ stock_movements : "originates from"

    sales_orders ||--o{ sales_order_items : "contains"
    sales_orders }o--|| customers : "placed by"

    purchase_orders ||--o{ purchase_order_items : "contains"
    purchase_orders }o--|| suppliers : "from"

    staff ||--o{ sales_orders : "created by"
    staff ||--o{ purchase_orders : "created by"
    staff ||--o{ stock_movements : "recorded by"

    companies {
        uuid id PK
        varchar name
        varchar shop_name
        varchar phone
        varchar email
        uuid owner_id
    }

    products {
        uuid id PK
        uuid company_id FK
        varchar sku UK
        varchar name
        text description
        uuid category_id FK
        uuid brand_id FK
        varchar bag_type
        varchar material
        varchar color
        varchar size
        varchar dimensions
        decimal weight_grams
        varchar barcode UK
        decimal unit_cost
        decimal selling_price
        decimal wholesale_price
        int min_stock
        int max_stock
        int reorder_point
        boolean is_active
        boolean has_warranty
        int warranty_months
        jsonb image_urls
    }

    inventory {
        uuid id PK
        uuid product_id FK
        uuid warehouse_id FK
        int quantity
        int reserved_quantity
        int available_quantity
        varchar batch_number
        date manufacturing_date
        date expiry_date
        varchar condition
        text notes
        timestamp last_counted
    }

    sales_orders {
        uuid id PK
        uuid company_id FK
        uuid customer_id FK
        varchar invoice_number UK
        varchar status
        date sale_date
        decimal total_amount
        decimal amount_paid
        varchar payment_method
        varchar payment_status
        jsonb payment_split
        uuid created_by
    }

    purchase_orders {
        uuid id PK
        uuid company_id FK
        uuid supplier_id FK
        varchar po_number UK
        varchar status
        date order_date
        date expected_delivery
        date actual_delivery
        decimal total_amount
        text notes
    }

    stock_movements {
        uuid id PK
        uuid company_id FK
        uuid product_id FK
        uuid warehouse_id FK
        varchar movement_type
        int quantity_change
        int quantity_before
        varchar reference_type
        uuid reference_id
        text notes
        uuid created_by
        timestamp created_at
    }

    staff {
        uuid id PK
        uuid user_id FK
        uuid company_id FK
        varchar name
        varchar email
        varchar phone
        varchar role
        jsonb permissions
        boolean is_active
    }

    categories {
        uuid id PK
        uuid company_id FK
        varchar name
        text description
    }

    brands {
        uuid id PK
        uuid company_id FK
        varchar name
        varchar website
    }

    warehouses {
        uuid id PK
        uuid company_id FK
        varchar name
        varchar type
        boolean is_default
    }

    customers {
        uuid id PK
        uuid company_id FK
        varchar name
        varchar phone
    }

    suppliers {
        uuid id PK
        uuid company_id FK
        varchar name
    }
"""
    },
    {
        "name": "database_schema",
        "title": "Database Schema — Purchase Order & Receive Flow",
        "mermaid": """
graph TD
    subgraph "Purchase Flow"
        PO[("📋 purchase_orders")]
        POI[("📋 purchase_order_items")]
        Suppliers[("📋 suppliers")]
    end

    subgraph "Inventory"
        Inv[("📦 inventory")]
        SM[("📦 stock_movements")]
        WH[("📦 warehouses")]
    end

    subgraph "Products"
        Prod[("🎒 products")]
        Cat[("🎒 categories")]
        Brand[("🎒 brands")]
    end

    subgraph "Sales"
        SO[("🧾 sales_orders")]
        SOI[("🧾 sales_order_items")]
        Cust[("🧾 customers")]
    end

    subgraph "Admin"
        Comp[("🏢 companies")]
        Staff[("👥 staff")]
    end

    PO -->|company_id| Comp
    PO -->|supplier_id| Suppliers
    POI -->|purchase_order_id| PO
    POI -->|product_id| Prod
    POI -->|warehouse_id| WH

    SM -->|company_id| Comp
    SM -->|product_id| Prod
    SM -->|warehouse_id| WH
    Inv -->|product_id| Prod
    Inv -->|warehouse_id| WH

    SO -->|company_id| Comp
    SO -->|customer_id| Cust
    SOI -->|sales_order_id| SO
    SOI -->|product_id| Prod
    SOI -->|warehouse_id| WH

    Prod -->|category_id| Cat
    Prod -->|brand_id| Brand
    Prod -->|company_id| Comp

    Staff -->|company_id| Comp
"""
    },
    {
        "name": "system_architecture",
        "title": "System Architecture",
        "mermaid": """
graph TB
    subgraph "Flutter Client Application"
        UI["🎨 UI Layer<br/>Screens &amp; Widgets"]
        State["📊 State Management<br/>Riverpod"]
        Repo["🗄️ Repository Layer"]
        Sync["🔄 Sync Service<br/>Outbox Pattern"]
        PDF["📄 PDF Services"]
    end

    subgraph "Supabase Backend"
        Auth["🔐 Auth"]
        DB[("🗃️ PostgreSQL")]
        RT["⚡ Realtime"]
        Storage["📁 Object Storage"]
    end

    subgraph "User"
        UserOp["👤 User Actions"]
    end

    UserOp --> UI
    UI --> State
    State --> Repo
    Repo -->|Online| DB
    Repo -->|Offline| Sync
    Sync -->|Background| DB
    UI --> PDF
    State --> Auth
"""
    },
    {
        "name": "purchase_receive_flow",
        "title": "Purchase Order & Receive Flow",
        "mermaid": """
graph TD
    PO[Create Purchase Order] --> POItems[Add Items & Quantities]
    POItems --> POSubmit[Submit PO]
    POSubmit --> POStatus{{PENDING}}
    
    POStatus -->|Supplier Delivers| Receive[Open Receive Screen]
    Receive --> LoadItems[Load PO Items]
    LoadItems --> CheckQty[Enter Received Quantities]
    CheckQty --> Validate{{Valid?}}
    Validate -->|Qty OK| Mvmt["Insert +PURCHASE Movements"]
    Validate -->|Qty Exceeds| Error[Show Error]
    Error --> CheckQty
    
    Mvmt --> UpdateItems["Update received_quantity"]
    UpdateItems --> CheckFull{{All Received?}}
    CheckFull -->|Yes| Complete[Status → RECEIVED ✓]
    CheckFull -->|No| Partial[Status → PENDING ⏳]
"""
    },
]


def build_html(diagrams: list[dict]) -> str:
    """Build a single HTML page containing all Mermaid diagrams."""
    mermaid_blocks = []
    for d in diagrams:
        escaped = d["mermaid"].replace("`", "\\`")
        mermaid_blocks.append(f"""<div class="diagram" id="diagram-{d['name']}">
  <h2>{d['title']}</h2>
  <div class="mermaid">
{d['mermaid']}
  </div>
</div>""")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bag Shop Inventory — Diagrams</title>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    font-family: 'Segoe UI', -apple-system, sans-serif;
    background: #FFFFFF;
    padding: 40px;
  }}
  .diagram {{
    margin-bottom: 60px;
    padding: 30px;
    border: 1px solid #E8ECF2;
    border-radius: 16px;
    background: #FAFAFC;
    page-break-inside: avoid;
  }}
  .diagram h2 {{
    font-size: 20px;
    font-weight: 700;
    color: #1E3A5F;
    margin-bottom: 24px;
    padding-bottom: 12px;
    border-bottom: 3px solid #1E3A5F;
    display: inline-block;
  }}
  .mermaid {{
    display: flex;
    justify-content: center;
    margin: 0 auto;
  }}
  .mermaid svg {{
    max-width: 100%;
    height: auto !important;
  }}
</style>
</head>
<body>
{"".join(mermaid_blocks)}
</body>
</html>"""


async def render_diagrams():
    """Render each diagram to a separate PNG file using Playwright."""
    from playwright.async_api import async_playwright

    # Build the HTML
    html_content = build_html(DIAGRAMS)
    html_path = OUT_DIR / "_diagrams_page.html"
    html_path.write_text(html_content, encoding="utf-8")

    print(f"📄 HTML page created: {html_path}")
    file_url = html_path.resolve().as_uri()

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(
            viewport={"width": 1400, "height": 900},
            device_scale_factor=2,
        )

        await page.goto(file_url, wait_until="networkidle")

        # Wait for Mermaid to render
        try:
            await page.wait_for_function(
                "() => document.querySelectorAll('.mermaid svg').length > 0",
                timeout=30000,
            )
            await asyncio.sleep(2)  # Extra settling time
        except Exception as e:
            print(f"⚠️  Warning waiting for Mermaid: {e}")

        # Take a screenshot of each diagram
        for d in DIAGRAMS:
            name = d["name"]
            selector = f"#diagram-{name}"
            try:
                element = await page.query_selector(selector)
                if element:
                    png_path = OUT_DIR / f"diagram_{name}.png"
                    await element.screenshot(path=str(png_path))
                    size_kb = png_path.stat().st_size / 1024
                    print(f"✅ {name}.png — {size_kb:.0f} KB")
                else:
                    print(f"❌ Element not found: {selector}")
            except Exception as e:
                print(f"❌ Failed to screenshot {name}: {e}")

        # Also take a full page screenshot
        full_png = OUT_DIR / "diagrams_all.png"
        await page.screenshot(path=str(full_png), full_page=True)
        print(f"✅ diagrams_all.png — {full_png.stat().st_size / 1024:.0f} KB")

        await browser.close()

    print(f"\n✨ Done! {len(DIAGRAMS)} individual PNGs + 1 full-page PNG generated.")
    print(f"📁 Files are in: {OUT_DIR}")


if __name__ == "__main__":
    asyncio.run(render_diagrams())
