-- =============================================================================
-- load_knowledge_base.sql — Snowsight-compatible version (INSERT INTO ... VALUES)
-- =============================================================================
-- Purpose:  Creates raw tables in RAW.KNOWLEDGE_BASE for document tracking,
--           extracted text, and chunked content. Loads document metadata and
--           markdown content directly via INSERT INTO ... VALUES.
--           This version runs in Snowflake's web UI (Snowsight) without SnowSQL.
--
-- Original: lighthouse/snowflake/ingestion/load_knowledge_base.sql (PUT + stage)
--
-- Tables:
--   documents       — Document tracking/metadata registry
--   document_text   — Extracted text content per document
--   document_chunks — Chunked text segments for search indexing
--
-- Idempotency: Uses CREATE OR REPLACE TABLE — safe to re-run.
-- =============================================================================

SET LIGHTHOUSE_ENV = '{{ env }}';
SET LIGHTHOUSE_RAW_DB = 'LIGHTHOUSE_' || $LIGHTHOUSE_ENV || '_RAW';

USE WAREHOUSE INGESTION_WH;
EXECUTE IMMEDIATE 'USE DATABASE ' || $LIGHTHOUSE_RAW_DB;
USE SCHEMA KNOWLEDGE_BASE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RAW TABLE DDL
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE documents (
    document_id     VARCHAR(50)         COMMENT 'Natural key — document identifier',
    file_name       VARCHAR(255)        COMMENT 'Original file name',
    file_type       VARCHAR(20)         COMMENT 'File type: markdown, text',
    source_path     VARCHAR(500)        COMMENT 'Source file path in stage',
    category        VARCHAR(50)         COMMENT 'Category: manual, procedure, policy, support_article',
    _loaded_at      TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Platform ingestion timestamp'
)
COMMENT = 'Document tracking table for NordHjem knowledge base';

CREATE OR REPLACE TABLE document_text (
    document_id     VARCHAR(50)         COMMENT 'FK to documents',
    extracted_text  VARCHAR(16777216)   COMMENT 'Full extracted text content',
    _extracted_at   TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Text extraction timestamp'
)
COMMENT = 'Extracted text content from knowledge base documents';

CREATE OR REPLACE TABLE document_chunks (
    chunk_id                VARCHAR(50)         COMMENT 'Natural key — chunk identifier',
    document_id             VARCHAR(50)         COMMENT 'FK to documents',
    chunk_sequence_number   INTEGER             COMMENT 'Chunk sequence within document (1-based)',
    chunk_text              VARCHAR(16777216)   COMMENT 'Chunked text segment (~512 tokens)',
    _chunked_at             TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP() COMMENT 'Chunking timestamp'
)
COMMENT = 'Chunked document text for search indexing and embedding';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. INSERT — Register documents in tracking table with metadata
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO documents (document_id, file_name, file_type, source_path, category)
VALUES
    ('DOC-001', 'manual_energy_meter_pro.md',          'markdown', '@kb_stage/documents/manual_energy_meter_pro.md.gz',          'manual'),
    ('DOC-002', 'manual_smart_thermostat_v2.md',       'markdown', '@kb_stage/documents/manual_smart_thermostat_v2.md.gz',       'manual'),
    ('DOC-003', 'policy_data_retention.md',            'markdown', '@kb_stage/documents/policy_data_retention.md.gz',            'policy'),
    ('DOC-004', 'procedure_device_installation.md',    'markdown', '@kb_stage/documents/procedure_device_installation.md.gz',    'procedure'),
    ('DOC-005', 'procedure_firmware_update.md',        'markdown', '@kb_stage/documents/procedure_firmware_update.md.gz',        'procedure'),
    ('DOC-006', 'support_connectivity_issues.md',      'markdown', '@kb_stage/documents/support_connectivity_issues.md.gz',      'support_article'),
    ('DOC-007', 'support_thermostat_troubleshooting.md','markdown','@kb_stage/documents/support_thermostat_troubleshooting.md.gz','support_article');

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. INSERT — Load document text content directly (replaces PUT + stage read)
-- ─────────────────────────────────────────────────────────────────────────────

-- DOC-001: manual_energy_meter_pro.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-001',
'# NordHjem Energy Meter Pro — Product Manual

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
- Run the calibration procedure against a known utility meter reading');

-- DOC-002: manual_smart_thermostat_v2.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-002',
'# NordHjem Smart Thermostat v2 — Product Manual

## Overview

The NordHjem Smart Thermostat v2 (model NH-TH-V2) is an intelligent climate control device designed for Nordic homes and offices. It features adaptive learning algorithms that optimize heating schedules based on occupancy patterns, weather forecasts, and energy pricing signals.

## Specifications

- Display: 3.5-inch capacitive touchscreen (320x480 resolution)
- Connectivity: WiFi 802.11 b/g/n/ac (2.4 GHz and 5 GHz)
- Protocol support: Matter 1.0, Apple HomeKit, Google Home, Amazon Alexa
- Temperature range: 5°C to 35°C (adjustable in 0.5°C increments)
- Temperature accuracy: ±0.3°C
- Humidity sensor: ±3% RH accuracy
- Power: 24V AC (C-wire required) or USB-C backup power
- Dimensions: 105mm x 105mm x 22mm
- Operating environment: 0°C to 50°C, 10-90% RH non-condensing

## Installation Requirements

Before installing the Smart Thermostat v2, verify the following:

1. A compatible HVAC system with 24V AC power (C-wire present)
2. WiFi network with 2.4 GHz or 5 GHz band available at installation location
3. Signal strength of at least -65 dBm at the thermostat mounting point
4. Wall mounting surface capable of supporting the device (included mounting plate and screws)
5. Minimum clearance of 1.2 meters from floor level for accurate temperature readings

## Initial Setup

1. Mount the base plate on the wall using the included screws and anchors
2. Connect the HVAC wiring to the labeled terminals (R, W, Y, G, C)
3. Attach the thermostat unit to the base plate until it clicks into place
4. The device will power on and display the setup wizard
5. Select your language (Danish, Swedish, Norwegian, English, Finnish)
6. Connect to your WiFi network by selecting the SSID and entering the password
7. Download the NordHjem Home app and scan the QR code displayed on the thermostat
8. Follow the in-app pairing process to complete registration

## Heating Schedule Programming

The thermostat supports up to 4 daily time periods for each day of the week:

- Morning comfort (default: 06:00-08:00, 21°C)
- Daytime economy (default: 08:00-16:00, 18°C)
- Evening comfort (default: 16:00-22:00, 21°C)
- Night setback (default: 22:00-06:00, 17°C)

After two weeks of manual adjustments, the learning algorithm will begin suggesting optimized schedules based on your usage patterns.

## Firmware Updates

Firmware updates are delivered automatically over WiFi. The thermostat checks for updates daily at 03:00 local time. Updates are applied during low-activity periods to minimize disruption. You can also manually check for updates via Settings > System > Firmware Update.

Current firmware version can be viewed at Settings > System > About.

## Troubleshooting

If the thermostat displays an amber blinking LED:
- Check WiFi connectivity (Settings > Network > WiFi Status)
- Verify signal strength is above -70 dBm
- Restart the device by holding the side button for 10 seconds
- If the issue persists, perform a factory reset (Settings > System > Factory Reset)

For temperature reading inaccuracies:
- Ensure the thermostat is not exposed to direct sunlight
- Verify no heat sources are within 30cm of the device
- Allow 30 minutes after installation for readings to stabilize');

-- DOC-003: policy_data_retention.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-003',
'# NordHjem Energy — Data Retention Policy

## Document Information

- Policy ID: GOV-POL-001
- Version: 1.0
- Effective date: 2025-01-01
- Owner: NordHjem Data Governance Office
- Review cycle: Annual

## Purpose

This policy defines the retention periods for all data categories processed by NordHjem Energy''s data platform. It ensures compliance with GDPR, Nordic energy sector regulations, and NordHjem''s internal data governance standards.

## Scope

This policy applies to all data stored in the NordHjem Lighthouse data platform, including structured data (OLTP, CRM), semi-structured data (IoT telemetry), unstructured data (knowledge base documents), and derived analytical data (dimensional models, metrics).

## Retention Periods by Data Category

### Customer Personal Data

- Active customer records: Retained for the duration of the customer relationship plus 24 months
- Inactive customer records: Anonymized 24 months after last contract end date
- Customer communication history: 36 months from date of communication
- Customer consent records: Retained for 60 months after consent withdrawal

### Contract and Billing Data

- Active contracts: Retained for the duration of the contract
- Expired contracts: 60 months after contract end date (Danish Bookkeeping Act requirement)
- Invoices and payment records: 60 months from invoice date (tax compliance)
- Credit notes and adjustments: 60 months from issuance date

### Device and Telemetry Data

- Raw telemetry events: 13 months (rolling window)
- Daily aggregated telemetry: 60 months
- Device status history: 36 months after device decommission
- Alert event history: 24 months

### Service and Support Data

- Service tickets: 36 months after ticket closure
- Case comments and interaction logs: 36 months after associated ticket closure
- Customer satisfaction surveys: 24 months

### Knowledge Base Documents

- Product manuals: Retained until product end-of-life plus 24 months
- Service procedures: Retained until superseded plus 12 months
- Policy documents: Retained until superseded plus 60 months
- Support articles: Reviewed annually, archived after 24 months of no access

### Analytical and Derived Data

- Staging layer data: Mirrors source retention (no independent retention)
- Intermediate layer data: Ephemeral, rebuilt on each transformation run
- Dimensional model data: Follows the retention of the longest-lived source contributing to each record
- SCD Type 2 history: Retained for the full retention period of the underlying entity
- Metric aggregations: 60 months

## Data Deletion Process

When data reaches its retention limit:

1. Automated retention jobs identify records past their retention date
2. Records are flagged for deletion in a staging queue
3. A 30-day grace period allows for review before permanent deletion
4. Deletion is executed and logged in the data governance audit trail
5. Downstream derived data is refreshed to reflect the deletion

## Exceptions

Retention periods may be extended in the following cases:

- Active legal proceedings or regulatory investigations
- Customer dispute resolution in progress
- Explicit written request from the Data Protection Officer
- Regulatory audit notification

All exceptions must be documented and reviewed quarterly.

## Compliance

This policy is designed to comply with:

- EU General Data Protection Regulation (GDPR) Articles 5(1)(e) and 17
- Danish Bookkeeping Act (Bogforingsloven) Section 10
- Swedish Accounting Act (Bokforingslagen) Chapter 7
- Norwegian Accounting Act (Bokforingsloven) Section 13');

-- DOC-004: procedure_device_installation.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-004',
'# Service Procedure: Device Installation

## Document Information

- Procedure ID: SVC-PROC-001
- Version: 2.1
- Effective date: 2025-01-01
- Owner: NordHjem Field Operations

## Purpose

This procedure defines the standard process for on-site installation of NordHjem smart home devices by certified installation partners. It covers pre-installation checks, physical installation, device commissioning, and post-installation verification.

## Scope

Applies to all NordHjem device installations including Smart Thermostat v2, Energy Meter Pro, Temp Sensor Mini, and Solar Integration Kit. Both residential and commercial installations follow this procedure.

## Pre-Installation Checklist

Before arriving at the customer site, the installer must verify:

1. Customer contract is active and installation is scheduled in the NordHjem Partner Portal
2. All required devices and accessories are in the installation kit
3. Device serial numbers match the work order
4. Customer has been notified of the installation window (SMS + email, 24 hours prior)
5. Site survey data is reviewed (electrical panel type, WiFi coverage, mounting locations)

## Installation Steps

### Step 1: Site Arrival and Safety Check

- Confirm customer identity and obtain verbal consent to proceed
- Perform visual inspection of the electrical panel and installation area
- Verify WiFi signal strength at each planned device location using the NordHjem Partner app
- If signal strength is below -70 dBm, recommend a WiFi extender before proceeding

### Step 2: Physical Installation

For each device type, follow the device-specific installation guide:

- Thermostat: Mount base plate, connect HVAC wiring, attach unit
- Energy Meter: DIN rail mount, install CT clamps, connect neutral reference
- Temp Sensor: Wall mount with adhesive or screws, insert batteries
- Solar Kit: DIN rail mount adjacent to inverter, connect monitoring cables

### Step 3: Device Commissioning

1. Power on each device and verify it enters setup mode
2. Connect each device to the customer''s WiFi network via the Partner app
3. Register each device to the customer''s NordHjem account
4. Verify real-time data transmission (readings should appear within 60 seconds)
5. For energy meters, compare initial readings against the utility meter for validation

### Step 4: Post-Installation Verification

- Run the automated installation test suite from the Partner app
- Verify all devices show "online" status in the customer''s NordHjem Home app
- Walk the customer through the app interface and basic controls
- Provide the customer with printed quick-start guides for each device
- Obtain customer signature on the installation completion form

## Certification Requirements

After completing the installation, the installer must:

1. Submit the installation completion form via the Partner Portal
2. Upload photos of each installed device and the electrical panel
3. Record all device serial numbers and their assigned locations
4. Request certification inspection if required (commercial installations, or installations involving electrical panel modifications)

## Escalation

If any installation step cannot be completed:

- Contact NordHjem Technical Support at +45 70 20 30 40
- Log the issue in the Partner Portal with photos and description
- Do not leave partially installed devices powered on without customer consent
- Schedule a follow-up visit within 5 business days');

-- DOC-005: procedure_firmware_update.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-005',
'# Service Procedure: Firmware Update

## Document Information

- Procedure ID: SVC-PROC-002
- Version: 1.3
- Effective date: 2025-01-15
- Owner: NordHjem Device Engineering

## Purpose

This procedure defines the process for updating firmware on NordHjem smart home devices, covering both automatic over-the-air (OTA) updates and manual update procedures for devices that cannot receive OTA updates.

## Firmware Release Process

NordHjem follows a staged rollout process for firmware updates:

1. Internal testing (1 week) — QA team validates on test devices
2. Beta rollout (1 week) — 5% of devices in the field receive the update
3. Staged rollout (2 weeks) — 25%, 50%, 75%, 100% of devices over 4 days
4. Mandatory update deadline — 30 days after full rollout begins

## Automatic OTA Updates

All NordHjem devices with WiFi connectivity support automatic OTA updates:

- Devices check for updates daily at 03:00 local time
- Updates are downloaded in the background and applied during low-activity periods
- The device will restart automatically after applying the update (typically 30-90 seconds)
- If the update fails, the device rolls back to the previous firmware version
- Failed updates are reported to the NordHjem device management platform

### OTA Update Requirements

- Device must be connected to WiFi with at least -70 dBm signal strength
- Device must have stable power supply during the update process
- Sufficient flash memory must be available (checked automatically)

## Manual Firmware Update

For devices that cannot receive OTA updates (poor WiFi, failed OTA attempts), a manual update can be performed:

### Via NordHjem Home App

1. Open the NordHjem Home app and navigate to the device
2. Go to Settings > System > Firmware Update
3. Tap "Check for Updates"
4. If an update is available, tap "Install Now"
5. Keep the app open and the phone near the device until the update completes
6. The device will restart and display the new firmware version

### Via USB (Thermostat Only)

1. Download the firmware file from the NordHjem Partner Portal
2. Copy the firmware file to a USB-C flash drive (FAT32 format)
3. Insert the USB-C drive into the thermostat''s USB-C port
4. The thermostat will detect the firmware file and prompt for installation
5. Confirm the update on the touchscreen
6. Wait for the update to complete (do not remove the USB drive during the process)

### Via Zigbee (Energy Meter and Temp Sensor)

1. Ensure the Zigbee gateway device is within range
2. Initiate the update from the NordHjem Partner Portal
3. The gateway will push the firmware to the target device
4. Update progress is visible in the Partner Portal
5. Zigbee updates may take 15-30 minutes due to lower bandwidth

## Post-Update Verification

After any firmware update:

1. Verify the device shows the expected firmware version
2. Confirm the device is online and transmitting data
3. Check that all configured schedules and settings are preserved
4. Monitor the device for 24 hours for any anomalies

## Known Issues by Firmware Version

| Device | Version | Known Issue | Resolution |
|--------|---------|-------------|------------|
| Smart Thermostat v2 | 2.1.0 | Heating schedule resets after 24 hours | Update to 2.2.0 |
| Smart Thermostat v2 | 2.1.0 | WiFi reconnection delay after router restart | Update to 2.2.0 |
| Energy Meter Pro | 1.4.2 | Occasional negative readings on phase 3 | Update to 1.5.0 |
| Energy Meter Pro | 1.5.0 | Zigbee gateway connection drops under high load | Update to 1.5.1 |

## Rollback Procedure

If a firmware update causes issues:

1. Contact NordHjem Technical Support immediately
2. Do not attempt to downgrade firmware without authorization
3. Support will assess whether a rollback is necessary and provide the rollback firmware file
4. Rollbacks are performed via USB (thermostat) or Zigbee (meter/sensor)');

-- DOC-006: support_connectivity_issues.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-006',
'# Support Article: Device Connectivity Troubleshooting

## Article Information

- Article ID: SUP-ART-002
- Last updated: 2025-02-20
- Category: Troubleshooting
- Applies to: All NordHjem connected devices

## Overview

NordHjem devices communicate via WiFi (thermostats, energy meters) and Zigbee (temperature sensors, some energy meters). This article covers common connectivity issues and their resolutions for all device types.

## WiFi Connectivity Issues

### Intermittent Disconnections

Symptoms: Device goes offline for periods of 1-3 hours, then reconnects automatically. Status alternates between "online" and "offline" in the app.

Common causes and solutions:

1. Weak WiFi signal at device location
   - Check signal strength in the NordHjem Home app (device > Settings > Network)
   - Acceptable range: -30 to -67 dBm (good to fair)
   - Marginal range: -67 to -70 dBm (may cause intermittent issues)
   - Poor range: below -70 dBm (likely to cause disconnections)
   - Solution: Install a WiFi extender or mesh node near the device

2. Router channel congestion
   - If you live in an apartment building, neighboring WiFi networks may cause interference
   - Solution: Change your router''s WiFi channel to a less congested one (use a WiFi analyzer app to find the best channel)

3. Router firmware or settings
   - Some routers aggressively disconnect idle devices to save power
   - Solution: Disable "green mode" or "power saving" features on your router
   - Ensure your router''s firmware is up to date

4. DHCP lease expiration
   - If the DHCP lease is too short, devices may lose their IP address
   - Solution: Set a longer DHCP lease time (24 hours recommended) or assign a static IP to the device

### Device Cannot Find WiFi Network

Symptoms: WiFi network does not appear in the device''s network list during setup.

Troubleshooting:

1. Verify the network is broadcasting its SSID (not hidden)
2. If using a hidden network, manually enter the SSID during setup
3. Check that the network uses WPA2 or WPA3 security (WEP is not supported)
4. Ensure the router is not at maximum client capacity
5. Restart the router and try again

## Zigbee Connectivity Issues

### Temperature Sensor Not Reporting

Symptoms: Temp Sensor Mini shows "no data" in the app, last reading is stale.

Troubleshooting:

1. Check battery level — replace batteries if below 10%
2. Verify the Zigbee gateway (usually the Energy Meter Pro) is online and within range
3. Maximum Zigbee range: 10 meters through walls, 30 meters line-of-sight
4. Move the sensor closer to the gateway or add a Zigbee repeater
5. Re-pair the sensor: remove it from the app, reset the sensor (hold button 10 seconds), and add it again

### Zigbee Network Congestion

Symptoms: Multiple Zigbee devices experience slow updates or missed readings.

This can occur in installations with many Zigbee devices (more than 10) or in buildings with other Zigbee networks.

Solutions:

1. Ensure the Zigbee gateway firmware is up to date (1.5.1 or later for Energy Meter Pro)
2. Distribute Zigbee repeater devices evenly throughout the space
3. Avoid placing Zigbee devices near microwave ovens or USB 3.0 hubs (2.4 GHz interference)
4. If using multiple NordHjem gateways, ensure they are on different Zigbee channels

## Network Architecture Recommendations

For optimal device connectivity, NordHjem recommends:

- Dedicated IoT VLAN or SSID for smart home devices (reduces congestion from other traffic)
- WiFi mesh system for homes larger than 100 square meters
- Minimum internet bandwidth: 5 Mbps upload for up to 10 devices
- Router placement: central location, elevated position, away from metal objects
- Regular router firmware updates (check quarterly)

## Monitoring Device Connectivity

Use the NordHjem Home app to monitor device health:

- Dashboard > Device Health shows real-time status of all devices
- Enable push notifications for offline alerts (Settings > Notifications > Device Offline)
- Weekly connectivity report available via email (Settings > Reports > Weekly Summary)

## When to Contact Support

Contact NordHjem Support if:
- A device remains offline for more than 24 hours despite troubleshooting
- Multiple devices go offline simultaneously (may indicate a platform issue)
- Signal strength is adequate but the device still disconnects
- You need assistance configuring a dedicated IoT network

Support channels:
- Phone: +45 70 20 30 40 (Mon-Fri 08:00-18:00 CET)
- Email: support@nordhjem.example.com
- In-app chat: NordHjem Home app > Help > Chat with Support');

-- DOC-007: support_thermostat_troubleshooting.md
INSERT INTO document_text (document_id, extracted_text) VALUES ('DOC-007',
'# Support Article: Smart Thermostat v2 Troubleshooting Guide

## Article Information

- Article ID: SUP-ART-001
- Last updated: 2025-02-15
- Category: Troubleshooting
- Applies to: NordHjem Smart Thermostat v2 (NH-TH-V2)

## Common Issues and Solutions

### Issue 1: Thermostat Not Connecting to WiFi

Symptoms: Amber blinking LED, "No WiFi" message on display, device shows offline in app.

Troubleshooting steps:

1. Verify your WiFi network is operational (test with another device)
2. Check that the thermostat is within range of your router (signal strength should be above -70 dBm)
3. Confirm you are using a 2.4 GHz or 5 GHz network (the v2 supports both bands)
4. Restart the thermostat by holding the side button for 10 seconds
5. If the issue persists, forget the network and reconnect: Settings > Network > WiFi > Forget Network, then reconnect
6. Check if your router has MAC address filtering enabled and add the thermostat''s MAC address (found at Settings > System > About)

If none of these steps resolve the issue, the thermostat may need a firmware update via USB. Contact NordHjem Support for the firmware file.

### Issue 2: Heating Schedule Resets to Default

Symptoms: Custom heating schedule disappears after 24 hours, device reverts to factory default schedule.

This is a known issue with firmware version 2.1.0. The fix is available in firmware version 2.2.0.

Resolution:
1. Check your current firmware version at Settings > System > About
2. If running 2.1.0, update to 2.2.0 via Settings > System > Firmware Update
3. If OTA update is not available, contact Support for a manual update via USB
4. After updating, reprogram your heating schedule — it will persist correctly

### Issue 3: Temperature Reading Seems Inaccurate

Symptoms: Displayed temperature differs significantly from a reference thermometer.

Troubleshooting steps:

1. Allow 30 minutes after installation for the sensor to stabilize
2. Ensure the thermostat is not near heat sources (radiators, direct sunlight, electronics)
3. Verify the thermostat is mounted at least 1.2 meters from the floor
4. Check humidity levels — extreme humidity can affect readings
5. Compare with a calibrated reference thermometer placed at the same height and location
6. If the offset is consistent, apply a temperature correction: Settings > Calibration > Temperature Offset

### Issue 4: Thermostat Not Responding to Touch

Symptoms: Touchscreen does not register taps, display is on but unresponsive.

Troubleshooting steps:

1. Clean the screen with a soft, dry cloth (moisture or fingerprints can interfere)
2. Restart the device by holding the side button for 10 seconds
3. If the screen is frozen, perform a hard reset by disconnecting power at the circuit breaker for 30 seconds
4. After power is restored, the thermostat should boot normally
5. If the touchscreen remains unresponsive, the device may need replacement under warranty

### Issue 5: High Energy Consumption Despite Low Temperature Setting

Symptoms: Energy usage is higher than expected even with thermostat set to economy mode.

Possible causes:
- The learning algorithm may still be in its initial 2-week calibration period
- Check if "Away" mode is properly configured (Settings > Modes > Away)
- Verify that geofencing is enabled and your phone''s location services are active
- Inspect the HVAC system for issues (stuck valve, faulty relay)
- Review the heating schedule for overlapping comfort periods

## When to Contact Support

Contact NordHjem Support if:
- The thermostat displays an error code (E01 through E99)
- The device does not power on after verifying the C-wire connection
- Firmware update fails repeatedly (3 or more attempts)
- The device shows physical damage (cracked screen, burn marks)

Support channels:
- Phone: +45 70 20 30 40 (Mon-Fri 08:00-18:00 CET)
- Email: support@nordhjem.example.com
- In-app chat: NordHjem Home app > Help > Chat with Support');



