import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()
url = os.getenv("DATABASE_URL")

print(f"Testing connection to: {url[:60]}...")

try:
    conn = psycopg2.connect(url)
    print("✅ Connection successful!")
    
    cur = conn.cursor()
    cur.execute("SELECT version();")
    version = cur.fetchone()
    print(f"PostgreSQL version: {version[0]}")
    
    conn.close()
except Exception as e:
    print(f"❌ Failed: {e}")