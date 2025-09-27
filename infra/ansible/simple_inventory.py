#!/usr/bin/env python3

import json
import argparse
import sys

def get_host_inventory(hostname):
    """
    Return inventory for a specific host by hostname.
    """

    # Host configurations
    hosts = {
        'portainer': {
            'ansible_host': '192.168.68.124',
            'ansible_user': 'jimmy',
            'repo_path': '/home/jimmy/home-server',
            'environment': 'production',
            'postgres_user': 'admin',
            'postgres_password': 'secure123',
            'postgres_db': 'maindb'
        },
        'portainer2': {
            'ansible_host': '192.168.68.126',
            'ansible_user': 'jimmy',
            'repo_path': '/home/jimmy/home-server',
            'environment': 'production'
        },
        'portainer3': {
            'ansible_host': '192.168.68.182',
            'ansible_user': 'jimmy',
            'repo_path': '/home/jimmy/home-server',
            'environment': 'production'
        },
        'kuro': {
            'ansible_host': '192.168.68.120',
            'ansible_user': 'jimmy',
            'repo_path': '/home/jimmy/home-server',
            'environment': 'production'
        },
        'maple': {
            'ansible_host': '192.168.68.128',
            'ansible_user': 'one',
            'repo_path': '/home/one/home-server',
            'environment': 'production'
        }
    }

    return hosts.get(hostname, {})

def get_all_hosts():
    """
    Return simple inventory with all hosts.
    """
    inventory = {
        '_meta': {'hostvars': {}},
        'all': {'hosts': []}
    }

    hosts = ['portainer', 'portainer2', 'portainer3', 'kuro', 'maple']

    for hostname in hosts:
        host_vars = get_host_inventory(hostname)
        if host_vars:
            inventory['all']['hosts'].append(hostname)
            inventory['_meta']['hostvars'][hostname] = host_vars

    return inventory

def main():
    parser = argparse.ArgumentParser(description='Simple Ansible Inventory')
    parser.add_argument('--list', action='store_true', help='List all hosts')
    parser.add_argument('--host', help='Get variables for specific hostname')
    parser.add_argument('hostname', nargs='?', help='Hostname to get inventory for')

    args = parser.parse_args()

    if args.list:
        print(json.dumps(get_all_hosts(), indent=2))
    elif args.host:
        print(json.dumps(get_host_inventory(args.host), indent=2))
    elif args.hostname:
        host_data = get_host_inventory(args.hostname)
        if host_data:
            print(json.dumps(host_data, indent=2))
        else:
            print(f"Host '{args.hostname}' not found", file=sys.stderr)
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()