# Support Article: Device Connectivity Troubleshooting

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
   - Solution: Change your router's WiFi channel to a less congested one (use a WiFi analyzer app to find the best channel)

3. Router firmware or settings
   - Some routers aggressively disconnect idle devices to save power
   - Solution: Disable "green mode" or "power saving" features on your router
   - Ensure your router's firmware is up to date

4. DHCP lease expiration
   - If the DHCP lease is too short, devices may lose their IP address
   - Solution: Set a longer DHCP lease time (24 hours recommended) or assign a static IP to the device

### Device Cannot Find WiFi Network

Symptoms: WiFi network does not appear in the device's network list during setup.

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
- In-app chat: NordHjem Home app > Help > Chat with Support
