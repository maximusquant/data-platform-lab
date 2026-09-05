import clickhouse_connect
import pandas as pd
from sqlalchemy import create_engine

# 1. Подключение к Postgres
pg_engine = create_engine(
    "postgresql://postgres:postgres_pass@localhost:5433/raw_data"
)

# 2. Подключение к ClickHouse
ch_client = clickhouse_connect.get_client(
    host="localhost", port=8123, username="clickhouse", password="clickhouse_pass"
)

# Создаем базу raw в ClickHouse
ch_client.command("CREATE DATABASE IF NOT EXISTS raw")

tables = [
    "raw_customers",
    "raw_geolocation",
    "raw_order_items",
    "raw_payments",
    "raw_reviews",
    "raw_orders",
    "raw_products",
    "raw_sellers",
    "raw_category_translation",
]

print("Реплицируем таблицы из Postgres (raw) в ClickHouse (raw)...\n")

for table in tables:
    # Явно указываем схему raw в Postgres
    df = pd.read_sql(f"SELECT * FROM raw.{table}", pg_engine)

    # Кастомная конвертация типов для ClickHouse DDL
    ch_type_mapping = {
        "object": "String",
        "int64": "Int64",
        "float64": "Float64",
        "datetime64[ns]": "Nullable(DateTime)",
    }

    columns_ddl = []
    for col_name, dtype in df.dtypes.items():
        ch_type = ch_type_mapping.get(str(dtype), "String")
        columns_ddl.append(f"`{col_name}` {ch_type}")

    # Создаем таблицу в базе raw в ClickHouse
    ch_client.command(f"DROP TABLE IF EXISTS raw.{table}")
    create_table_query = f"""
    CREATE TABLE raw.{table} (
        {', '.join(columns_ddl)}
    ) ENGINE = MergeTree()
    ORDER BY tuple()
    """
    ch_client.command(create_table_query)

    # Приводим текстовые колонки к строкам
    for col in df.select_dtypes(include=["object"]).columns:
        df[col] = df[col].fillna("").astype(str)

    # Вставляем данные в БД raw
    ch_client.insert_df(table=table, df=df, database="raw")
    print(f" Таблица raw.{table} реплицирована ({len(df)} строк)")

print("\n Все 9 таблиц Olist успешно загружены в ClickHouse!")