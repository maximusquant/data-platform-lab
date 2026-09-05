from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text

ENGINE = create_engine(
    "postgresql://postgres:postgres_pass@localhost:5433/raw_data"
)
DATA_DIR = Path(__file__).parent.parent / "data"

# 1. Автоматически создаем схему raw в Postgres, если её еще нет
with ENGINE.connect() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw;"))
    conn.commit()

files_to_tables = {
    "olist_customers_dataset.csv": "raw_customers",
    "olist_geolocation_dataset.csv": "raw_geolocation",
    "olist_order_items_dataset.csv": "raw_order_items",
    "olist_order_payments_dataset.csv": "raw_payments",
    "olist_order_reviews_dataset.csv": "raw_reviews",
    "olist_orders_dataset.csv": "raw_orders",
    "olist_products_dataset.csv": "raw_products",
    "olist_sellers_dataset.csv": "raw_sellers",
    "product_category_name_translation.csv": "raw_category_translation",
}

for csv_name, table_name in files_to_tables.items():
    file_path = DATA_DIR / csv_name
    if file_path.exists():
        print(f"Читаем {csv_name}...")
        df = pd.read_csv(file_path)
        # 2. Указываем schema="raw" для выгрузки
        df.to_sql(table_name, ENGINE, schema="raw", if_exists="replace", index=False)
        print(f" Таблица raw.{table_name} заполнена ({len(df)} строк)")
    else:
        print(f" Файл {csv_name} не найден в директории {DATA_DIR}")

print("\n Все данные Olist успешно загружены в схему RAW!")