from html.parser import HTMLParser
import json

class PriceParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_red = False
        self.in_drip = False
        self.in_tbody = False
        self.in_row = False
        self.in_cell = False
        self.current_tag = ''
        self.cells = []
        self.row_cells = []
        self.products = []
        self.brand = ''

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if tag in ('h3', 'p'):
            self.current_tag = tag
        if tag == 'tbody':
            self.in_tbody = True
            self.row_cells = []
        if tag == 'tr' and self.in_tbody:
            self.in_row = True
            self.cells = []
        if tag in ('td', 'th') and self.in_row:
            self.in_cell = True

    def handle_data(self, data):
        data = data.strip()
        if not data:
            return
        if self.current_tag == 'h3':
            if 'R.E.D.' in data or 'RED' in data:
                self.in_red = True
                self.in_drip = False
                self.brand = 'RED'
            elif 'Дрип' in data or 'дрип' in data:
                self.in_drip = True
                self.in_red = False
                self.brand = 'DRIP'
            else:
                self.in_red = False
                self.in_drip = False

        if self.in_cell:
            self.cells.append(data)

    def handle_endtag(self, tag):
        if tag in ('h3', 'p'):
            self.current_tag = ''
        if tag in ('td', 'th'):
            self.in_cell = False
        if tag == 'tr' and self.in_row:
            self.in_row = False
            if self.cells:
                self.row_cells.append(self.cells)
            self.cells = []
        if tag == 'tbody':
            self.in_tbody = False
            if (self.in_red or self.in_drip) and self.row_cells:
                self.products.append({
                    'brand': self.brand,
                    'headers': self.row_cells[0] if self.row_cells else [],
                    'rows': self.row_cells[1:] if len(self.row_cells) > 1 else []
                })
            self.row_cells = []

with open(r'C:\Users\Илья\Desktop\Единый прайс.html', encoding='utf-8') as f:
    html = f.read()

parser = PriceParser()
parser.feed(html)

result = []
for p in parser.products:
    result.append({'brand': p['brand'], 'headers': p['headers'], 'rows': p['rows']})

with open(r'D:\AI BASE\DEEPSEEK\coffee_docs\red_products.json', 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f"Saved {sum(len(p['rows']) for p in result)} products to red_products.json")
