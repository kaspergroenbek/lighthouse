# NordHjem Energy Meter Pro — Product Manual

## Overview

The NordHjem Energy Meter Pro (model NH-EM-PRO) is a precision energy monitoring device that provides real-time visibility into electricity consumption and grid export for residential and commercial installations. It uses current transformer (CT) clamps for non-invasive measurement on single-phase and three-phase electrical systems.

## Specifications

- Measurement: Single-phase and three-phase (3x CT clamps included)
- Accuracy class: 0.5% (IEC 62053-22 compliant)
- Current range: 0-200A per phase
- Voltage range: 100-277V AC
- Sampling rate: 4,000 samples per second per channel
- Connectivity: WiFi 802.11 b/g/n, Zigbee 3.0 gateway
- Data transmission: Every 5 seconds (real-time), hourly aggregates stored locally
- Local storage: 90 days of hourly data (flash memory)
- Power: 230V AC direct connection or DIN rail adapter
- Dimensions: 90mm x 72mm x 58mm (DIN rail mount, 4 modules wide)
- Operating environment: -10°C to 55°C, 5-95% RH

## Installation Requirements

Installation must be performed by a certified electrician. The following conditions must be met:

1. Access to the main electrical distribution panel
2. Sufficient space for DIN rail mounting (4 module widths)
3. CT clamps must be installed on the correct phase conductors
4. Neutral reference connection required for voltage measurement
5. WiFi signal strength of at least -70 dBm at the panel location

## CT Clamp Installation

Proper CT clamp placement is critical for accurate readings:

1. Identify the phase conductors (L1, L2, L3 for three-phase systems)
2. Open each CT clamp and position it around a single conductor only
3. Ensure the arrow on the CT clamp points toward the load (away from the grid)
4. Close the clamp firmly until it clicks — verify no gaps in the magnetic core
5. Route CT clamp cables to the meter unit and connect to labeled inputs (CT1, CT2, CT3)

Common installation errors:
- CT clamp installed on wrong phase — causes readings to show incorrect values
- CT clamp direction reversed — causes negative readings
- CT clamp around multiple conductors — causes readings to cancel out
- CT clamp not fully closed — causes reduced accuracy

## Calibration

The Energy Meter Pro is factory-calibrated. Field calibration is available through the NordHjem Home app:

1. Navigate to Device Settings > Calibration
2. Enter a known reference reading from your utility meter
3. The device will calculate and apply a correction factor
4. Calibration verification runs automatically for 24 hours

## Data Access

Energy data is accessible through:
- NordHjem Home app (real-time dashboard, historical charts)
- NordHjem API (REST endpoints for integration)
- Local Zigbee network (for home automation systems)
- CSV export (via app, up to 12 months of data)

## Grid Export Monitoring

For installations with solar panels or battery storage, the Energy Meter Pro automatically detects bidirectional power flow. Export readings are reported separately from consumption in the app and API.

## Troubleshooting

If the meter shows offline status:
- Check WiFi connectivity via the status LED (solid green = connected, blinking = connecting)
- Verify power supply to the meter unit
- Check that the Zigbee gateway is within range (max 10m through walls)
- Restart the device by toggling the DIN rail circuit breaker

If readings appear incorrect:
- Verify CT clamp orientation (arrow toward load)
- Confirm CT clamps are on individual conductors, not bundled cables
- Check for CT clamp gaps — the core must be fully closed
- Run the calibration procedure against a known utility meter reading
