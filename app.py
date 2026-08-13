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
import functools
import os
import sqlite3

from flask import Flask, request, render_template_string, session

app = Flask(__name__)
app.secret_key = "dev"
DB_PATH = "shop.db"


def require_admin(view):
    """Only administrators may reach the wrapped view."""

    @functools.wraps(view)
    def guarded(*args, **kwargs):
        if not session.get("is_admin"):
            return ("Forbidden", 403)
        return view(*args, **kwargs)

    return guarded


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


@app.route("/admin/users")
@require_admin
def admin_users():
    """Search the user directory. Admin only."""
    term = request.args.get("q", "")
    cur = get_db().cursor()
    cur.execute(f"SELECT id, username FROM users WHERE username LIKE '%{term}%'")
    return {"users": [dict(id=r[0], username=r[1]) for r in cur.fetchall()]}


@app.route("/admin/logs")
def admin_logs():
    """Recent sign-in activity for the admin dashboard."""
    cur = get_db().cursor()
    cur.execute("SELECT id, username, org_id FROM users ORDER BY id DESC LIMIT 50")
    return {"activity": [dict(id=r[0], username=r[1], org=r[2]) for r in cur.fetchall()]}


if __name__ == "__main__":
    app.run()
