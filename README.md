# brother-print for Capacitor and Ionic

Easily print to Brother label printers using the Brother SDK, integrated with Capacitor and Ionic.

This plugin was developed for personal use, but feel free to use it if it fits your needs.

This plugin uses Brother's official Print SDK 4.13.2 on both iOS and Android. The former unofficial `BRLMPrinterKit` CocoaPod dependency is no longer used.

## Compatibility

- iOS and Android
- Supports Brother QL-820NWB and QL-810W label printers

## Important Notes

- For **iOS Bluetooth printing**, include the necessary `Info.plist` entries (see below).
- For **iOS WiFi printing**, include the relevant `Info.plist` entries (see below).
- For **Android**, Brother Print SDK 4.13.2 and Android 8.0 or later are required (see below).

## Installation

```bash
npm install github:Lesar-UK/brother-print#0.0.16
```

## iOS SDK Setup

This package does not distribute Brother's proprietary iOS SDK. For Bluetooth Classic/MFi printers such as the QL-820NWB, Brother requires the `BT_Net` framework; the similarly named `Net` framework does not support this connection type.

Before running `pod install` or syncing the iOS project:

1. Download Brother Print SDK for iPhone/iPad 4.13.2 from the [Brother Developer Center](https://support.brother.com/g/s/es/dev/en/mobilesdk/download/index.html).
2. Extract the download and locate exactly `libs/BT_Net/BRLMPrinterKit.xcframework`.
3. Copy the framework into the installed package:

```bash
mkdir -p node_modules/brother-print/ios/Frameworks
cp -R /path/to/bpsdki4132/libs/BT_Net/BRLMPrinterKit.xcframework \
  node_modules/brother-print/ios/Frameworks/BRLMPrinterKit.xcframework
```

The final directory must be:

```text
node_modules/brother-print/ios/Frameworks/BRLMPrinterKit.xcframework/
```

Then sync the iOS project:

```bash
npx cap sync ios
```

The framework must be restored after deleting `node_modules`, running a clean `npm ci`, or upgrading this package. When developing this plugin directly, use the equivalent repository path:

```text
ios/Frameworks/BRLMPrinterKit.xcframework/
```

Do not use the SDK's `Net/BRLMPrinterKit.xcframework`; use the `BT_Net` build exactly.

## Android Setup

This package does not distribute Brother's proprietary Android SDK. The AAR cannot be restored from Git alone because Brother requires developers to accept its licence before downloading it.

After installing the package or rebuilding `node_modules`:

1. Download Brother Print SDK for Android 4.13.2 from the [Brother Developer Center](https://support.brother.com/g/s/es/dev/en/mobilesdk/download/index.html).
2. Extract the download and locate `libs/BrotherPrintLibrary.aar`.
3. Copy it into the installed package using:

```bash
mkdir -p node_modules/brother-print/android/libs/maven/com/brother/sdk/BrotherPrintLibrary/4.13.2
cp /path/to/BrotherPrintLibrary.aar \
  node_modules/brother-print/android/libs/maven/com/brother/sdk/BrotherPrintLibrary/4.13.2/BrotherPrintLibrary-4.13.2.aar
```

The final directory must contain both files:

```text
node_modules/brother-print/android/libs/maven/com/brother/sdk/BrotherPrintLibrary/4.13.2/
├── BrotherPrintLibrary-4.13.2.aar
└── BrotherPrintLibrary-4.13.2.pom
```

Then sync the Android project:

```bash
npx cap sync android
```

The AAR must be copied again after deleting `node_modules`, running a clean `npm ci`, or upgrading this package. Keep the original SDK download in approved private storage so a new development machine or CI environment can be restored.

When developing this plugin directly, use the equivalent path under the repository instead of `node_modules/brother-print`:

```text
android/libs/maven/com/brother/sdk/BrotherPrintLibrary/4.13.2/BrotherPrintLibrary-4.13.2.aar
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
      // model: 'QL-810W', // Optional fallback; Android detects the connected model when available
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
      // model: 'QL-810W', // Optional fallback; Android detects the connected model when available
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
