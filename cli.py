#!/usr/bin/env python3
"""
DWMB CLI — command-line utility for admin tasks.

Usage:
    python cli.py status
    python cli.py seed
    python cli.py backup
    python cli.py restore <backup_file>
    python cli.py stats
"""
import asyncio
import sys
import os

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))


def cmd_status():
    """Check system status."""
    import httpx
    try:
        resp = httpx.get("http://localhost:8000/api/import/tmdb/status", timeout=5)
        data = resp.json()
        print(f"App: OK (HTTP {resp.status_code})")
        print(f"TMDB: {'Configured' if data.get('configured') else 'Not configured'}")
    except Exception as e:
        print(f"App: FAILED ({e})")

    # Check DB
    try:
        from app.database import async_session
        from sqlalchemy import text
        async def check_db():
            async with async_session() as session:
                result = await session.execute(text("SELECT 1"))
                return result.scalar() == 1
        if asyncio.run(check_db()):
            print("Database: OK")
        else:
            print("Database: FAILED")
    except Exception as e:
        print(f"Database: FAILED ({e})")


def cmd_seed():
    """Run database seed script."""
    print("Running seed script...")
    os.system("cd db/seeds && python 02_seed_data.py")
    print("Seed complete.")


def cmd_stats():
    """Show database statistics."""
    import subprocess

    queries = {
        "Entities": "SELECT COUNT(*) FROM meta.entity",
        "Kind types": "SELECT COUNT(*) FROM meta.entity_kind WHERE is_abstract = false",
        "Relations": "SELECT COUNT(*) FROM meta.semantic_relation",
        "Users": "SELECT COUNT(*) FROM meta.user_account",
        "Comments": "SELECT COUNT(*) FROM meta.comment",
    }

    for label, query in queries.items():
        result = subprocess.run(
            ["docker", "compose", "exec", "-T", "db", "psql", "-U", "dwmb", "-d", "dwmb", "-t", "-A", "-c", query],
            capture_output=True, text=True
        )
        count = result.stdout.strip() if result.returncode == 0 else "?"
        print(f"{label:12s} {count}")


def cmd_backup():
    """Create database backup."""
    import subprocess
    from datetime import datetime

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"backups/dwmb_backup_{timestamp}.sql"

    os.makedirs("backups", exist_ok=True)

    print(f"Creating backup: {backup_file}")
    result = subprocess.run(
        ["docker", "compose", "exec", "-T", "db", "pg_dump", "-U", "dwmb", "-d", "dwmb", "--schema=meta"],
        capture_output=True, text=True
    )

    if result.returncode == 0:
        with open(backup_file, "w") as f:
            f.write(result.stdout)
        size = os.path.getsize(backup_file)
        print(f"Backup complete: {backup_file} ({size:,} bytes)")
    else:
        print(f"Backup failed: {result.stderr}")
        sys.exit(1)


def cmd_restore(backup_file: str):
    """Restore database from backup."""
    import subprocess

    if not os.path.exists(backup_file):
        print(f"File not found: {backup_file}")
        sys.exit(1)

    print(f"Restoring from: {backup_file}")
    with open(backup_file, "r") as f:
        sql = f.read()

    result = subprocess.run(
        ["docker", "compose", "exec", "-T", "db", "psql", "-U", "dwmb", "-d", "dwmb"],
        input=sql, capture_output=True, text=True
    )

    if result.returncode == 0:
        print("Restore complete.")
    else:
        print(f"Restore failed: {result.stderr}")
        sys.exit(1)


def cmd_migrate():
    """Run pending migrations."""
    import subprocess

    migrations = [
        "db/migrations/001_rbac.sql",
        "db/migrations/002_workflow.sql",
        "db/migrations/003_comments.sql",
    ]

    for migration in migrations:
        if os.path.exists(migration):
            print(f"Applying: {migration}")
            with open(migration, "r") as f:
                sql = f.read()
            result = subprocess.run(
                ["docker", "compose", "exec", "-T", "db", "psql", "-U", "dwmb", "-d", "dwmb"],
                input=sql, capture_output=True, text=True
            )
            if result.returncode == 0:
                print(f"  OK")
            else:
                print(f"  FAILED: {result.stderr[:200]}")

    print("Migrations complete.")


def main():
    if len(sys.argv) < 2:
        print("DWMB CLI — command-line utility")
        print("")
        print("Commands:")
        print("  status    Check system status")
        print("  seed      Run database seed")
        print("  stats     Show database statistics")
        print("  backup    Create database backup")
        print("  restore   Restore from backup")
        print("  migrate   Run pending migrations")
        print("")
        print("Usage: python cli.py <command>")
        sys.exit(0)

    command = sys.argv[1]

    if command == "status":
        cmd_status()
    elif command == "seed":
        cmd_seed()
    elif command == "stats":
        cmd_stats()
    elif command == "backup":
        cmd_backup()
    elif command == "restore":
        if len(sys.argv) < 3:
            print("Usage: python cli.py restore <backup_file>")
            sys.exit(1)
        cmd_restore(sys.argv[2])
    elif command == "migrate":
        cmd_migrate()
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
