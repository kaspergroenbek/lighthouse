# Support Article: Smart Thermostat v2 Troubleshooting Guide

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
6. Check if your router has MAC address filtering enabled and add the thermostat's MAC address (found at Settings > System > About)

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
- Verify that geofencing is enabled and your phone's location services are active
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
- In-app chat: NordHjem Home app > Help > Chat with Support
