import sqlite3

conn = sqlite3.connect('local_dev.db')
cursor = conn.cursor()

def add_column(table, column, definition):
    try:
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")
        print(f"✓ Added {column} to {table}")
    except sqlite3.OperationalError as e:
        if "duplicate column" in str(e):
            print(f"  {column} already exists in {table}")
        else:
            print(f"❌ Failed to add {column} to {table}: {e}")

print("Updating Database Schema...")

# Add lottie_file to pets
add_column("pets", "lottie_file", "VARCHAR(255)")

# Add hunger and last_fed_at to user_pets
add_column("user_pets", "hunger", "INTEGER DEFAULT 50")
add_column("user_pets", "last_fed_at", "DATETIME")

# Add reward_claimed to todos
add_column("todos", "reward_claimed", "BOOLEAN DEFAULT 0")

conn.commit()
conn.close()
print("Done.")
