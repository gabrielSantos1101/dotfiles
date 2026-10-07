#!/usr/bin/env python3
import json
import sys
import time
import os

# CPU delta tracking
prev_total = 0
prev_idle = 0

def read_cpu_percent():
    global prev_total, prev_idle
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline()
        parts = [float(x) for x in line.split()[1:]]
        total = sum(parts)
        idle = parts[3] if len(parts) > 3 else (parts[4] if len(parts) > 4 else 0)
        if prev_total == 0:
            prev_total, prev_idle = total, idle
            time.sleep(0.1)
            with open('/proc/stat', 'r') as f:
                line = f.readline()
            parts = [float(x) for x in line.split()[1:]]
            total = sum(parts)
            idle = parts[3] if len(parts) > 3 else (parts[4] if len(parts) > 4 else 0)
        total_delta = total - prev_total
        idle_delta = idle - prev_idle
        prev_total, prev_idle = total, idle
        if total_delta <= 0:
            return 0
        usage = (total_delta - idle_delta) / total_delta * 100
        return max(0, min(100, usage))
    except Exception:
        return 0

def read_memory():
    try:
        meminfo = {}
        with open('/proc/meminfo', 'r') as f:
            for line in f:
                if ':' in line:
                    key, val = line.split(':', 1)
                    val = val.strip().split()[0]
                    meminfo[key] = int(val) * 1024
        total = meminfo.get('MemTotal', 0)
        available = meminfo.get('MemAvailable')
        if available is None:
            available = meminfo.get('MemFree', 0) + meminfo.get('Buffers', 0) + meminfo.get('Cached', 0)
        used = total - available if total > 0 else 0
        used_percent = (used / total * 100) if total > 0 else 0
        used_gb = round(used / (1024**3), 1)
        total_gb = round(total / (1024**3), 1)
        return {
            "usedPercent": int(round(used_percent)),
            "usedGB": used_gb,
            "totalGB": total_gb
        }
    except Exception:
        return {"usedPercent": 0, "usedGB": 0, "totalGB": 0}

def read_temperature():
    try:
        best_temp = 0
        best_priority = -1
        for zone in sorted(os.listdir('/sys/class/thermal')):
            if not zone.startswith('thermal_zone'):
                continue
            zone_path = os.path.join('/sys/class/thermal', zone)
            try:
                with open(os.path.join(zone_path, 'type'), 'r') as f:
                    ztype = f.read().strip()
                with open(os.path.join(zone_path, 'temp'), 'r') as f:
                    temp_raw = int(f.read().strip())
                temp_c = temp_raw // 1000 if temp_raw > 1000 else temp_raw
                if temp_c <= 0 or temp_c > 150:
                    continue
                priority = 0
                if any(k in ztype for k in ['x86_pkg_temp', 'package', 'cpu', 'acpitz']):
                    priority = 3
                elif 'core' in ztype:
                    priority = 2
                elif 'soc' in ztype or 'gpu' in ztype:
                    priority = 1
                if priority > best_priority or (priority == best_priority and temp_c > best_temp):
                    best_temp = temp_c
                    best_priority = priority
            except Exception:
                continue
        return int(best_temp) if best_temp > 0 else 0
    except Exception:
        return 0

def main():
    try:
        while True:
            cpu = read_cpu_percent()
            mem = read_memory()
            temp = read_temperature()
            print(json.dumps({
                "cpu": round(cpu, 0),
                "ram": mem,
                "temp": temp
            }))
            sys.stdout.flush()
            time.sleep(1)
    except Exception as e:
        pass

if __name__ == '__main__':
    main()
