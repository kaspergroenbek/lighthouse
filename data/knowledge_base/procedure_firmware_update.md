# Service Procedure: Firmware Update

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
3. Insert the USB-C drive into the thermostat's USB-C port
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
4. Rollbacks are performed via USB (thermostat) or Zigbee (meter/sensor)
