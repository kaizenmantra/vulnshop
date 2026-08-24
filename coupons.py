"""Coupon lookup helper. Sink lives here, not in app.py."""
import sqlite3

DB_PATH = "shop.db"


def lookup_coupon(code):
    # SQL INJECTION: coupon code concatenated into the query.
    cur = sqlite3.connect(DB_PATH).cursor()
    cur.execute("SELECT discount FROM coupons WHERE code = '" + code + "'")
    return cur.fetchall()
