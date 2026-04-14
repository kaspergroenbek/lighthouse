#!/usr/bin/env python3
"""Generate dbt/seeds/dim_date_seed.csv for 2024-01-01 through 2026-12-31."""
import csv
import datetime
import os

# Fixed Danish public holidays (month, day)
FIXED_HOLIDAYS = {
    (1, 1),    # New Year's Day
    (6, 5),    # Constitution Day
    (12, 24),  # Christmas Eve
    (12, 25),  # Christmas Day
    (12, 26),  # Second Christmas Day
}

def is_danish_fixed_holiday(d: datetime.date) -> bool:
    return (d.month, d.day) in FIXED_HOLIDAYS

def main():
    start = datetime.date(2024, 1, 1)
    end = datetime.date(2026, 12, 31)

    out_path = os.path.join(os.path.dirname(__file__), '..', 'dbt', 'seeds', 'dim_date_seed.csv')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(out_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'date_key', 'full_date', 'day_of_week', 'day_of_week_num',
            'week_number_iso', 'month', 'month_name', 'quarter', 'year',
            'is_weekend', 'is_danish_public_holiday', 'fiscal_year', 'fiscal_quarter'
        ])

        current = start
        while current <= end:
            iso_year, iso_week, iso_dow = current.isocalendar()
            date_key = int(current.strftime('%Y%m%d'))
            full_date = current.isoformat()
            day_of_week = current.strftime('%A')
            day_of_week_num = iso_dow
            week_number_iso = iso_week
            month_num = current.month
            month_name = current.strftime('%B')
            quarter = (current.month - 1) // 3 + 1
            year = current.year
            is_weekend = iso_dow >= 6
            is_holiday = is_danish_fixed_holiday(current)
            fiscal_year = current.year
            fiscal_quarter = quarter

            writer.writerow([
                date_key, full_date, day_of_week, day_of_week_num,
                week_number_iso, month_num, month_name, quarter, year,
                str(is_weekend).upper(), str(is_holiday).upper(),
                fiscal_year, fiscal_quarter
            ])
            current += datetime.timedelta(days=1)

    with open(out_path) as f:
        row_count = sum(1 for _ in f) - 1
    print(f"Generated {out_path} with {row_count} rows")

if __name__ == '__main__':
    main()
