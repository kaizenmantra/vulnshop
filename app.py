"""
vulnshop — an intentionally vulnerable demo web app.

⚠️  DO NOT DEPLOY. FOR SECURITY-DEMO / EDUCATION ONLY.

This tiny Flask app carries three deliberately planted, textbook vulnerabilities
so a fix-verification agent can watch one of them get fixed and prove it:

  V1  SQL injection      /login    (user input f-string'd into a SQL query)
  V2  Command injection  /export   (user input passed to os.system)
  V3  Reflected XSS      /search   (untrusted input rendered unescaped)

Everything else is kept minimal on purpose, so a scanner reports exactly these
three findings and nothing else.
"""
import os
import sqlite3

from flask import Flask, request, render_template_string

app = Flask(__name__)
DB_PATH = "shop.db"


def get_db():
    return sqlite3.connect(DB_PATH)


@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username", "")
    password = request.form.get("password", "")
    cur = get_db().cursor()

    # V1 — SQL INJECTION: user input formatted straight into the query string.
    query = f"SELECT id FROM users WHERE username = '{username}' AND password = '{password}'"
    cur.execute(query)

    return "Welcome" if cur.fetchone() else ("Invalid credentials", 401)


@app.route("/export")
def export():
    filename = request.args.get("file", "report.csv")

    # V2 — COMMAND INJECTION: user input concatenated into an OS command.
    os.system("cat exports/" + filename)

    return "Export started"


@app.route("/search")
def search():
    q = request.args.get("q", "")

    # V3 — REFLECTED XSS: untrusted input rendered into HTML without escaping.
    page = "<h1>Results for " + q + "</h1>"
    return render_template_string(page)


@app.route("/invoice")
def invoice():
    email = request.args.get("email", "")

    # V5 — SQL INJECTION: customer email concatenated into the query.
    cur = sqlite3.connect("shop.db").cursor()
    cur.execute("SELECT id, total FROM invoices WHERE email = '" + email + "'")
    return str(cur.fetchall())


if __name__ == "__main__":
    app.run()
