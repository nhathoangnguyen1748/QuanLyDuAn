import json
import urllib.request
import urllib.error

import os
import sys

SUPABASE_REF = os.environ.get("SUPABASE_REF", "xycjnudnvaqnyhvvigvm")
ACCESS_TOKEN = os.environ.get("SUPABASE_ACCESS_TOKEN", "")
if not ACCESS_TOKEN and sys.stdin.isatty():
    ACCESS_TOKEN = input("Nhập SUPABASE_ACCESS_TOKEN (sbp_...): ").strip()



def execute_sql(query):
    url = f"https://api.supabase.com/v1/projects/{SUPABASE_REF}/database/query"
    headers = {
        "Authorization": f"Bearer {ACCESS_TOKEN}",
        "Content-Type": "application/json"
    }
    data = json.dumps({"query": query}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        print(f"SQL Error: {e.code} - {err_msg}")
        raise

def escape_sql(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    # String
    s = str(val).replace("'", "''")
    return f"'{s}'"

def escape_json(val):
    if val is None:
        return "'[]'::jsonb"
    s = json.dumps(val, ensure_ascii=False).replace("'", "''")
    return f"'{s}'::jsonb"

def main():
    with open("scripts/seed_data.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    # 1. Categories
    print("Inserting categories...")
    for cat in data["categories"]:
        sql = f"""
        INSERT INTO categories (id, code, name, color_hex, description)
        VALUES (
            {escape_sql(cat['id'])},
            {escape_sql(cat['code'])},
            {escape_sql(cat['name'])},
            {escape_sql(cat.get('colorHex', 4008740141))},
            {escape_sql(cat.get('description'))}
        )
        ON CONFLICT (id) DO UPDATE SET
            code = EXCLUDED.code,
            name = EXCLUDED.name,
            color_hex = EXCLUDED.color_hex,
            description = EXCLUDED.description;
        """
        execute_sql(sql)
    print("Categories inserted successfully!")

    # 2. Products
    print("Inserting products...")
    for p in data["products"]:
        sql = f"""
        INSERT INTO products (
            id, sku_code, barcode, name, category_id, category_name,
            cost_price, selling_price, current_stock, min_safety_stock, max_stock,
            location_tag, unit, image_url, expiry_date, last_stock_out_date,
            created_at, notes
        ) VALUES (
            {escape_sql(p['id'])},
            {escape_sql(p['skuCode'])},
            {escape_sql(p.get('barcode', ''))},
            {escape_sql(p['name'])},
            {escape_sql(p['categoryId'])},
            {escape_sql(p['categoryName'])},
            {escape_sql(p.get('costPrice', 0))},
            {escape_sql(p.get('sellingPrice', 0))},
            {escape_sql(p.get('currentStock', 0))},
            {escape_sql(p.get('minSafetyStock', 10))},
            {escape_sql(p.get('maxStock', 500))},
            {escape_sql(p.get('locationTag', ''))},
            {escape_sql(p.get('unit', 'Gói'))},
            {escape_sql(p.get('imageUrl'))},
            {escape_sql(p.get('expiryDate'))},
            {escape_sql(p.get('lastStockOutDate'))},
            {escape_sql(p.get('createdAt'))},
            {escape_sql(p.get('notes'))}
        )
        ON CONFLICT (id) DO UPDATE SET
            sku_code = EXCLUDED.sku_code,
            barcode = EXCLUDED.barcode,
            name = EXCLUDED.name,
            category_id = EXCLUDED.category_id,
            category_name = EXCLUDED.category_name,
            cost_price = EXCLUDED.cost_price,
            selling_price = EXCLUDED.selling_price,
            current_stock = EXCLUDED.current_stock,
            min_safety_stock = EXCLUDED.min_safety_stock,
            max_stock = EXCLUDED.max_stock,
            location_tag = EXCLUDED.location_tag,
            unit = EXCLUDED.unit,
            image_url = EXCLUDED.image_url,
            expiry_date = EXCLUDED.expiry_date,
            last_stock_out_date = EXCLUDED.last_stock_out_date,
            created_at = EXCLUDED.created_at,
            notes = EXCLUDED.notes;
        """
        execute_sql(sql)
    print("Products inserted successfully!")

    # 3. Stock In Orders
    print("Inserting stock in orders...")
    for o in data["stockInOrders"]:
        sql = f"""
        INSERT INTO stock_in_orders (
            id, order_number, supplier_name, supplier_phone, items,
            created_at, created_by, notes, status
        ) VALUES (
            {escape_sql(o['id'])},
            {escape_sql(o['orderNumber'])},
            {escape_sql(o['supplierName'])},
            {escape_sql(o.get('supplierPhone'))},
            {escape_json(o.get('items', []))},
            {escape_sql(o['createdAt'])},
            {escape_sql(o.get('createdBy', 'Admin Kho'))},
            {escape_sql(o.get('notes'))},
            {escape_sql(o.get('status', 'COMPLETED'))}
        )
        ON CONFLICT (id) DO UPDATE SET
            order_number = EXCLUDED.order_number,
            supplier_name = EXCLUDED.supplier_name,
            supplier_phone = EXCLUDED.supplier_phone,
            items = EXCLUDED.items,
            created_at = EXCLUDED.created_at,
            created_by = EXCLUDED.created_by,
            notes = EXCLUDED.notes,
            status = EXCLUDED.status;
        """
        execute_sql(sql)
    print("Stock In Orders inserted successfully!")

    # 4. Stock Out Orders
    print("Inserting stock out orders...")
    for o in data["stockOutOrders"]:
        sql = f"""
        INSERT INTO stock_out_orders (
            id, order_number, type, receiver_name, destination_branch, items,
            created_at, created_by, notes, status
        ) VALUES (
            {escape_sql(o['id'])},
            {escape_sql(o['orderNumber'])},
            {escape_sql(o.get('type', 'retail'))},
            {escape_sql(o['receiverName'])},
            {escape_sql(o.get('destinationBranch'))},
            {escape_json(o.get('items', []))},
            {escape_sql(o['createdAt'])},
            {escape_sql(o.get('createdBy', 'Admin Kho'))},
            {escape_sql(o.get('notes'))},
            {escape_sql(o.get('status', 'COMPLETED'))}
        )
        ON CONFLICT (id) DO UPDATE SET
            order_number = EXCLUDED.order_number,
            type = EXCLUDED.type,
            receiver_name = EXCLUDED.receiver_name,
            destination_branch = EXCLUDED.destination_branch,
            items = EXCLUDED.items,
            created_at = EXCLUDED.created_at,
            created_by = EXCLUDED.created_by,
            notes = EXCLUDED.notes,
            status = EXCLUDED.status;
        """
        execute_sql(sql)
    print("Stock Out Orders inserted successfully!")

    # 5. Cycle Counts
    print("Inserting cycle count sessions...")
    for cc in data["cycleCounts"]:
        sql = f"""
        INSERT INTO cycle_count_sessions (
            id, session_code, title, scope, status, items,
            created_at, completed_at, auditor_name, notes
        ) VALUES (
            {escape_sql(cc['id'])},
            {escape_sql(cc['sessionCode'])},
            {escape_sql(cc['title'])},
            {escape_sql(cc.get('scope', 'Toàn kho'))},
            {escape_sql(cc.get('status', 'inProgress'))},
            {escape_json(cc.get('items', []))},
            {escape_sql(cc['createdAt'])},
            {escape_sql(cc.get('completedAt'))},
            {escape_sql(cc.get('auditorName', 'Admin'))},
            {escape_sql(cc.get('notes'))}
        )
        ON CONFLICT (id) DO UPDATE SET
            session_code = EXCLUDED.session_code,
            title = EXCLUDED.title,
            scope = EXCLUDED.scope,
            status = EXCLUDED.status,
            items = EXCLUDED.items,
            created_at = EXCLUDED.created_at,
            completed_at = EXCLUDED.completed_at,
            auditor_name = EXCLUDED.auditor_name,
            notes = EXCLUDED.notes;
        """
        execute_sql(sql)
    print("Cycle count sessions inserted successfully!")

    # 6. Warehouse Settings
    print("Inserting warehouse settings...")
    settings = data.get("settings", {})
    for k, v in settings.items():
        sql = f"""
        INSERT INTO warehouse_settings (key, value)
        VALUES ({escape_sql(k)}, {escape_sql(v)})
        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
        """
        execute_sql(sql)
    print("Warehouse settings inserted successfully!")

if __name__ == "__main__":
    main()
