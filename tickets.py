"""Support-ticket search helper. Sink lives here, not in app.py."""
import sqlite3

DB_PATH = "shop.db"


def tickets_by_subject(subject):
    # SQL INJECTION: subject concatenated into the LIKE query.
    cur = sqlite3.connect(DB_PATH).cursor()
    cur.execute("SELECT id, subject FROM tickets WHERE subject LIKE '%" + subject + "%'")
    return cur.fetchall()
