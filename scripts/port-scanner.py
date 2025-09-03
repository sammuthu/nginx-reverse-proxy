#!/usr/bin/env python3
"""
Port Scanner - Find available ports for new services
"""

import socket
import json
import argparse
import sys
from pathlib import Path

def is_port_open(port, host='127.0.0.1'):
    """Check if a port is available for use"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result != 0  # True if port is available

def load_registry():
    """Load the port registry"""
    registry_path = Path(__file__).parent.parent / 'docs' / 'port-registry.json'
    if registry_path.exists():
        with open(registry_path, 'r') as f:
            return json.load(f)
    return None

def get_allocated_ports(registry):
    """Get all allocated ports from registry"""
    allocated = set()
    if registry:
        for service in registry.get('services', []):
            if service.get('port'):
                allocated.add(service['port'])
        allocated.update(registry.get('reserved_ports', []))
    return allocated

def find_available_ports(start=3000, end=10000, count=10):
    """Find available ports in a range"""
    registry = load_registry()
    allocated = get_allocated_ports(registry)
    available = []
    
    for port in range(start, end):
        if port not in allocated and is_port_open(port):
            available.append(port)
            if len(available) >= count:
                break
    
    return available

def suggest_port_for_type(service_type):
    """Suggest appropriate port range based on service type"""
    ranges = {
        'frontend': (3000, 3999),
        'nextjs': (3000, 3999),
        'react': (3000, 3999),
        'vue': (3000, 3999),
        'dev': (4000, 4999),
        'docker': (5000, 5999),
        'custom': (6000, 6999),
        'app': (7000, 7999),
        'web': (8000, 8999),
        'api': (9000, 9999),
        'fastapi': (9000, 9999),
        'express': (9000, 9999),
    }
    
    start, end = ranges.get(service_type.lower(), (3000, 10000))
    available = find_available_ports(start, end, 5)
    
    return available

def main():
    parser = argparse.ArgumentParser(description='Find available ports for services')
    parser.add_argument('--range', type=str, help='Port range to scan (e.g., 3000-4000)')
    parser.add_argument('--type', type=str, help='Service type (frontend, api, docker, etc.)')
    parser.add_argument('--count', type=int, default=10, help='Number of ports to find')
    parser.add_argument('--check', type=int, help='Check if specific port is available')
    
    args = parser.parse_args()
    
    if args.check:
        # Check specific port
        if is_port_open(args.check):
            print(f"✅ Port {args.check} is available")
            sys.exit(0)
        else:
            print(f"❌ Port {args.check} is in use")
            # Try to find what's using it
            import subprocess
            try:
                result = subprocess.run(['lsof', '-i', f':{args.check}'], 
                                      capture_output=True, text=True)
                if result.stdout:
                    print("\nUsed by:")
                    lines = result.stdout.strip().split('\n')[1:]  # Skip header
                    for line in lines[:3]:  # Show first 3 processes
                        print(f"  {line}")
            except:
                pass
            sys.exit(1)
    
    elif args.type:
        # Find ports for specific service type
        print(f"🔍 Finding available ports for {args.type} service...")
        available = suggest_port_for_type(args.type)
        
        if available:
            print(f"\n✅ Suggested ports for {args.type}:")
            for port in available[:args.count]:
                print(f"  • {port}")
        else:
            print(f"❌ No available ports found for {args.type}")
    
    elif args.range:
        # Scan specific range
        parts = args.range.split('-')
        if len(parts) != 2:
            print("Error: Range must be in format START-END (e.g., 3000-4000)")
            sys.exit(1)
        
        start, end = int(parts[0]), int(parts[1])
        print(f"🔍 Scanning ports {start}-{end}...")
        available = find_available_ports(start, end, args.count)
        
        if available:
            print(f"\n✅ Available ports:")
            for port in available:
                print(f"  • {port}")
        else:
            print(f"❌ No available ports found in range {start}-{end}")
    
    else:
        # Default: show commonly available ports
        print("🔍 Finding commonly available ports...")
        
        registry = load_registry()
        if registry:
            print("\n📋 Currently allocated ports:")
            for service in sorted(registry['services'], key=lambda x: x.get('port', 99999)):
                if service.get('port'):
                    status = '🟢' if service['status'] == 'active' else '🟡'
                    print(f"  {status} {service['port']:5} - {service['name']}")
        
        print("\n✅ Available ports:")
        for range_info in [
            ("Frontend (3000-3999)", 3000, 3999, 5),
            ("API (9000-9999)", 9000, 9999, 5),
            ("Custom (6000-6999)", 6000, 6999, 5),
        ]:
            label, start, end, count = range_info
            available = find_available_ports(start, end, count)
            if available:
                print(f"\n  {label}:")
                for port in available:
                    print(f"    • {port}")

if __name__ == '__main__':
    main()