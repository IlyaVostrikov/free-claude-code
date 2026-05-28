"""
Build structured data for RED coffee products for National Catalog import.
Generates CSV ready for mass import into Честный ЗНАК Национальный каталог.

Attributes based on:
- Declaration ЕАЭС N RU Д-RU.РА05.В.79559/24 (valid until 07.07.2029)
- Product subgroup: Бакалея / Растворимые завариваемые напитки (РЗН)
- ТН ВЭД: 0901 21 000 0 (кофе жареный с кофеином)
- ОКПД2: 10.83.11.110 (кофе жареный)
"""

import csv
import json

# Load parsed products
with open(r'D:\AI BASE\DEEPSEEK\coffee_docs\red_products.json', encoding='utf-8') as f:
    data = json.load(f)

# --- CONSTANTS (from declaration) ---
TNKVED = "0901210000"       # ТН ВЭД ЕАЭС (10 digits, no spaces)
OKPD2 = "10.83.11.110"       # ОКПД2
TRADEMARK = "R.E.D."         # Товарный знак
COUNTRY = "РОССИЯ"           # Страна производства (обжарка в РФ)
APPLICANT = 'ООО "Компания Кофе и Чая"'
DECLARATION = "ЕАЭС N RU Д-RU.РА05.В.79559/24"

# --- BUILD PRODUCT LIST ---
products = []

for group in data:
    brand = group['brand']
    # First row is in headers (misparsed from THEAD)
    all_rows = [group['headers']] + group['rows']

    for row in all_rows:
        if brand == 'RED':
            name = row[0]
            region = row[1]
            roast = row[2]
            descriptors = row[3]

            # Determine composition
            name_upper = name.upper()
            if '100% ARABICA' in name_upper or 'KENYA' in name_upper and 'TRABOCCA' not in name_upper:
                composition = "100% Арабика"
            elif 'TRABOCCA' in name_upper:
                composition = "100% Арабика"  # Kenya single origin
            else:
                # Blends - composition depends on blend
                composition = "Арабика, Робуста"

            # Determine coffee type
            if 'ФИЛЬТР' in name_upper:
                coffee_type = "Зерно (для фильтра)"
            elif 'ЭСПРЕССО' in name_upper:
                coffee_type = "Зерно (для эспрессо)"
            else:
                coffee_type = "Зерно"

            net_weight = "1000"
            weight_unit = "г"
            packaging = "Пакет"

        else:  # DRIP
            name = row[0]
            coffee_type = "Молотый"
            net_weight = "11"
            weight_unit = "г"
            composition = row[3]  # Brazil, Kenya, Indonesia/Brazil
            roast = row[4]
            descriptors = row[5]
            region = row[3]
            packaging = "Дрип-пакет"

        products.append({
            'brand': brand,
            'name': name,
            'type': coffee_type,
            'net_weight': net_weight,
            'weight_unit': weight_unit,
            'composition': composition,
            'roast': roast,
            'region': region,
            'descriptors': descriptors,
            'trademark': TRADEMARK,
            'tnved': TNKVED,
            'okpd2': OKPD2,
            'country': COUNTRY,
            'packaging': packaging,
            'declaration': DECLARATION,
        })

# --- WRITE CSV ---
csv_path = r'D:\AI BASE\DEEPSEEK\coffee_docs\RED_catalog_data.csv'
with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
    writer = csv.writer(f)
    # Header row
    writer.writerow([
        '№', 'Бренд', 'Полное наименование товара', 'Товарный знак',
        'ТН ВЭД ЕАЭС', 'ОКПД2', 'Страна производства',
        'Вид кофе', 'Масса нетто, г', 'Вид упаковки',
        'Состав', 'Степень обжарки', 'Регион происхождения',
        'Дескрипторы', 'Декларация о соответствии'
    ])
    for i, p in enumerate(products, 1):
        writer.writerow([
            i, p['brand'], p['name'], p['trademark'],
            p['tnved'], p['okpd2'], p['country'],
            p['type'], p['net_weight'], p['packaging'],
            p['composition'], p['roast'], p['region'],
            p['descriptors'], p['declaration']
        ])

# --- PRINT SUMMARY ---
print(f"Total products: {len(products)}")
print(f"  RED зерно: {sum(1 for p in products if p['brand']=='RED')}")
print(f"  RED дрипы: {sum(1 for p in products if p['brand']=='DRIP')}")
print(f"\nCSV saved to: {csv_path}")
print(f"\n--- Preview (first 5) ---")
for p in products[:5]:
    print(f"  {p['brand']} | {p['name']} | {p['type']} | {p['net_weight']}г | {p['roast']} | {p['region']}")
print(f"  ... + {len(products)-5} more")

# --- WRITE JSON for reference ---
json_path = r'D:\AI BASE\DEEPSEEK\coffee_docs\RED_catalog_data.json'
with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(products, f, ensure_ascii=False, indent=2)
print(f"\nJSON saved to: {json_path}")
