#!/usr/bin/env python3
"""
Migrate data from KV to D1 (if KV namespace exists)
This is optional and only runs if an old KV namespace is found
"""
import os
import sys
import json
import requests

CLOUDFLARE_API_TOKEN = os.environ.get('CLOUDFLARE_API_TOKEN')
CLOUDFLARE_ACCOUNT_ID = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
D1_ID = os.environ.get('D1_ID')
KV_NAMESPACE_NAME = 'uptimeflare_kv-cbnflight'

def get_kv_namespace():
    """Check if old KV namespace exists"""
    if not CLOUDFLARE_API_TOKEN or not CLOUDFLARE_ACCOUNT_ID:
        print("Skipping KV migration: Missing credentials")
        return None

    headers = {
        'Authorization': f'Bearer {CLOUDFLARE_API_TOKEN}',
        'Content-Type': 'application/json'
    }

    url = f'https://api.cloudflare.com/client/v4/accounts/{CLOUDFLARE_ACCOUNT_ID}/storage/kv/namespaces'

    try:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            print("No KV namespace found or unable to check. Skipping migration.")
            return None

        namespaces = response.json().get('result', [])
        for ns in namespaces:
            if ns['title'] == KV_NAMESPACE_NAME:
                print(f"Found old KV namespace: {ns['id']}")
                return ns['id']

        print("No old KV namespace found. Skipping migration.")
        return None
    except Exception as e:
        print(f"Error checking for KV namespace: {e}")
        return None

def main():
    print("Checking for KV to D1 migration...")

    kv_id = get_kv_namespace()

    if not kv_id:
        print("✓ No migration needed")
        return

    if not D1_ID:
        print("WARNING: D1_ID not set, cannot migrate data")
        return

    print(f"Migration would be performed from KV {kv_id} to D1 {D1_ID}")
    print("Note: This is a placeholder - actual migration logic would go here")
    print("✓ Migration check complete")

if __name__ == '__main__':
    main()

