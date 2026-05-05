# brother-print for Capacitor and Ionic

Easily print to Brother label printers using the Brother SDK, integrated with Capacitor and Ionic.

This plugin was developed for personal use, but feel free to use it if it fits your needs.

## Compatibility

- iOS and Android
- Supports Brother QL-820NWB and QL-810W label printers

## Important Notes

- For **iOS Bluetooth printing**, include the necessary `Info.plist` entries (see below).
- For **iOS WiFi printing**, include the relevant `Info.plist` entries (see below).
- For **Android**, Brother's proprietary Android SDK AAR is required at build time (see below).

## Installation

```bash
npm install brother-print
npx cap sync
```

## Android Setup

This package does not distribute Brother's proprietary Android SDK. Before building Android, copy Brother's Android SDK AAR into this plugin's local Maven path:

```bash
mkdir -p node_modules/brother-print/android/libs/maven/com/brother/sdk/BrotherPrintLibrary/1.0.0
cp /path/to/BrotherPrintLibrary.aar node_modules/brother-print/android/libs/maven/com/brother/sdk/BrotherPrintLibrary/1.0.0/BrotherPrintLibrary-1.0.0.aar
npx cap sync android
```

For local plugin development, use the same path under this repository:

```bash
mkdir -p android/libs/maven/com/brother/sdk/BrotherPrintLibrary/1.0.0
cp /path/to/BrotherPrintLibrary.aar android/libs/maven/com/brother/sdk/BrotherPrintLibrary/1.0.0/BrotherPrintLibrary-1.0.0.aar
```

The Android plugin manifest declares the permissions required for WiFi and Bluetooth printing:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Bluetooth permissions are requested by the plugin before Bluetooth search/print/status operations.

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

Use the returned value as `deviceIdentifier` for Bluetooth printing. iOS commonly returns the printer serial number, while Android commonly returns the Bluetooth MAC address.

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
    const res = await BrotherPrint.printImage({
      printMethod: 'wifi', // Options: 'wifi' or 'bluetooth'
      deviceIdentifier: '10.111.0.10', // IP address for WiFi or value returned by searchBluetoothPrinters()
      base64String: 'base64string', // Exclude 'data:image/png;base64,' prefix
    });
    console.log('Print success:', res);
  } catch (error) {
    console.error('Error printing:', error);
  }
}
```

### Print a Base64 PDF

```javascript
import { BrotherPrint } from 'brother-print';

async function printBase64PDF() {
  try {
    const res = await BrotherPrint.printPDF({
      printMethod: 'wifi', // Options: 'wifi' or 'bluetooth'
      deviceIdentifier: '10.111.0.10', // IP address for WiFi or value returned by searchBluetoothPrinters()
      base64String: 'base64string', // Exclude 'data:image/png;base64,' prefix
    });
    console.log('Print success:', res);
  } catch (error) {
    console.error('Error printing:', error);
  }
}
```

## iOS Bluetooth Setup

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

## iOS WiFi Setup

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
