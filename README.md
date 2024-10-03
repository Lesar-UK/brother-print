# brother-print for Capacitor and Ionic

Easily print to Brother label printers using the Brother SDK, integrated with Capacitor and Ionic.

This plugin was developed for personal use, but feel free to use it if it fits your needs.

## Compatibility

- iOS only (currently)
- Supports Brother QL-820NWB and QL-810W label printers

## Important Notes

- For **Bluetooth printing**, include the necessary `Info.plist` entries (see below).
- For **WiFi printing**, include the relevant `Info.plist` entries (see below).

## Installation

```bash
npm install brother-print
npx cap sync
```

## Usage

### Search for Bluetooth Printers

```javascript
import { BrotherPrint } from 'brother-print';

async function searchBluetoothPrinters() {
  try {
    const { printers } = await BrotherPrint.searchBluetoothPrinters();
    console.log('Found printers:', printers);
  } catch (error) {
    console.error('Error finding printers:', error);
  }
}
```

### Search for WiFi Printers

```javascript
import { BrotherPrint } from 'brother-print';

async function searchWifiPrinters() {
  try {
    const { printers } = await BrotherPrint.searchWifiPrinters();
    console.log('Found printers:', printers);
  } catch (error) {
    console.error('Error finding printers:', error);
  }
}
```

### Print a Base64 Image

```javascript
import { BrotherPrint } from 'brother-print';

async function printBase64Image() {
  try {
    const res = await BrotherPrint.base64Print({
      printMethod: 'wifi', // Options: 'wifi' or 'bluetooth'
      deviceIdentifier: '10.111.0.10', // IP address for WiFi or Serial number for Bluetooth
      base64Image: 'base64string', // Exclude 'data:image/png;base64,' prefix
    });
    console.log('Print success:', res);
  } catch (error) {
    console.error('Error printing:', error);
  }
}
```

## Bluetooth Setup

For Bluetooth functionality, add the following keys to your `Info.plist` file:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.brother.ptcbp</string>
</array>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Discover compatible Bluetooth printers.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to find and communicate with printers.</string>
```

> **Note:** If you're submitting the app to the App Store, you’ll need to get a Product Plan ID (PPID) from Brother [here](https://secure6.brother.co.jp/mfi/MFiInputForm.aspx). For local development, this is not required.

## WiFi Setup

For WiFi functionality, add the following keys to your `Info.plist` file:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Required to discover printers on the local network.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Required to find printers on the local network.</string>
<key>NSBonjourServices</key>
<array>
    <string>_pdl-datastream._tcp</string>
    <string>_printer._tcp</string>
    <string>_ipp._tcp</string>
</array>
```
