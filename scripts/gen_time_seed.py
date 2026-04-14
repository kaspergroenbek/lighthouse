#!/usr/bin/env python3
"""Generate dbt/seeds/dim_time_seed.csv — all 1440 minutes of a day."""
import csv
import os

def time_of_day_band(hour: int) -> str:
    if hour < 6:
        return 'night'
    elif hour < 12:
        return 'morning'
    elif hour < 18:
        return 'afternoon'
    else:
        return 'evening'

def main():
    out_path = os.path.join(os.path.dirname(__file__), '..', 'dbt', 'seeds', 'dim_time_seed.csv')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(out_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['time_key', 'hour', 'minute', 'time_of_day_band', 'is_business_hour'])

        for h in range(24):
            for m in range(60):
                time_key = h * 100 + m
                band = time_of_day_band(h)
                is_biz = 8 <= h <= 16
                writer.writerow([time_key, h, m, band, str(is_biz).upper()])

    with open(out_path) as f:
        row_count = sum(1 for _ in f) - 1
    print(f"Generated {out_path} with {row_count} rows")

if __name__ == '__main__':
    main()
