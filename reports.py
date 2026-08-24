"""Sales reporting helper. Sink lives here, not in app.py."""
import sqlite3

DB_PATH = "shop.db"


def sales_by_region(region):
    # SQL INJECTION: region concatenated into the aggregate query.
    cur = sqlite3.connect(DB_PATH).cursor()
    cur.execute("SELECT SUM(total) FROM orders WHERE region = '" + region + "'")
    return cur.fetchall()
