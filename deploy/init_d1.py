#!/usr/bin/env python3
"""
Initialize D1 database for UptimeFlare
Creates the database if it doesn't exist and sets up the required tables
"""
import os
import sys
import json
import requests
import time

CLOUDFLARE_API_TOKEN = os.environ.get('CLOUDFLARE_API_TOKEN')
CLOUDFLARE_ACCOUNT_ID = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
D1_DATABASE_NAME = 'uptimeflare_d1-cbnflight'

if not CLOUDFLARE_API_TOKEN or not CLOUDFLARE_ACCOUNT_ID:
    print("ERROR: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID must be set")
    sys.exit(1)

headers = {
    'Authorization': f'Bearer {CLOUDFLARE_API_TOKEN}',
    'Content-Type': 'application/json'
}

def get_d1_database():
    """Get existing D1 database or create if it doesn't exist"""
    url = f'https://api.cloudflare.com/client/v4/accounts/{CLOUDFLARE_ACCOUNT_ID}/d1/database'

    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"ERROR: Failed to list D1 databases: {response.text}")
        sys.exit(1)

    databases = response.json().get('result', [])
    for db in databases:
        if db['name'] == D1_DATABASE_NAME:
            print(f"Found existing D1 database: {db['uuid']}")
            return db['uuid']

    # Create new database
    print(f"Creating new D1 database: {D1_DATABASE_NAME}")
    response = requests.post(url, headers=headers, json={'name': D1_DATABASE_NAME})

    if response.status_code not in [200, 201]:
        print(f"ERROR: Failed to create D1 database: {response.text}")
        sys.exit(1)

    db_id = response.json()['result']['uuid']
    print(f"Created new D1 database: {db_id}")
    return db_id

def init_tables(db_id):
    """Initialize tables in D1 database"""
    url = f'https://api.cloudflare.com/client/v4/accounts/{CLOUDFLARE_ACCOUNT_ID}/d1/database/{db_id}/query'

    # SQL to create tables
    sql_statements = [
        """
        CREATE TABLE IF NOT EXISTS monitor_status (
            id TEXT PRIMARY KEY,
            status TEXT NOT NULL,
            last_check INTEGER NOT NULL,
            last_status_change INTEGER
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS monitor_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            monitor_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            status TEXT NOT NULL,
            latency INTEGER,
            CHECK (status IN ('operational', 'degraded', 'down'))
        )
        """,
        """
        CREATE INDEX IF NOT EXISTS idx_monitor_history_monitor_id
        ON monitor_history(monitor_id, timestamp DESC)
        """,
        """
        CREATE TABLE IF NOT EXISTS incidents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            monitor_id TEXT NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            status TEXT NOT NULL
        )
        """,
        """
        CREATE INDEX IF NOT EXISTS idx_incidents_monitor_id
        ON incidents(monitor_id, start_time DESC)
        """
    ]

    for sql in sql_statements:
        payload = {
            'sql': sql.strip()
        }

        response = requests.post(url, headers=headers, json=payload)

        if response.status_code != 200:
            print(f"WARNING: Failed to execute SQL: {response.text}")
        else:
            print(f"✓ Executed SQL successfully")

        time.sleep(0.5)  # Rate limiting

def main():
    print("Initializing D1 database for UptimeFlare...")

    db_id = get_d1_database()

    print("\nInitializing database tables...")
    init_tables(db_id)

    # Export D1_ID for GitHub Actions
    github_env = os.environ.get('GITHUB_ENV')
    if github_env:
        with open(github_env, 'a') as f:
            f.write(f'D1_ID={db_id}\n')
        print(f"\n✓ Set D1_ID={db_id} in GITHUB_ENV")
    else:
        print(f"\n✓ D1_ID={db_id}")

    print("\n✓ Database initialization complete!")

if __name__ == '__main__':
    main()

