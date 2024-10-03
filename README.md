# brother-print for capacitor and ionic.

Print to a Brother label printer via the Brother SDK using Capacitor and Ionic.

At the moment this plugin is a personal use plugin for my own requirements, but feel free to use.

At present it is only compatible with QL-820NWB and QL-810W label printers.

## Things to know

- Currently only supporting iOS at the moment
- Currently only prints to QL-820NWB & QL-810W
- If you are using Bluetooth, ensure you include the relevant info.plist values below
- If you are using Wifi, ensure you include the relevant info.plist values below

## Install

```bash
npm install brother-print
npx cap sync
```

## Usage

### Searching connected Bluetooth printers

```bash
import { BrotherPrint } from 'brother-print'

async function searchBluetoothPrinters() {
    try {
        let { printers } = await BrotherPrint.searchBluetoothPrinters();
        console.log('Found printers', printers);
    } catch(error) {
        console.log('Problem finding printers', error);
    }
}
```

### Searching available Wifi printers

```bash
import { BrotherPrint } from 'brother-print'

async function searchWifiPrinters() {
    try {
        let { printers } = await BrotherPrint.searchWifiPrinters();
        console.log('Found printers', printers);
    } catch(error) {
        console.log('Problem finding printers', error);
    }
}
```

### Send a base64 image to a printer

```bash
import { BrotherPrint } from 'brother-print'

async function printBase64Image() {
    try {
        let res = await BrotherPrint.base64Print({
            printMethod: 'wifi', // wifi or bluetooth
            deviceIdentifier: '10.111.0.10', // IP address for wifi or Serial number for bluetooth.
            base64Image: 'base64 string' // Without data URI scheme i.e. data:image/png;base64,
        });
    } catch(error) {
        console.log('Problem printing', error);
    }
}
```

### If you are using Bluetooth

Add the following to your info.plist.

If you are submitting to the App Store you are required to get a Product Plan ID (PPID) from Brother. This For protyping and local development this is not needed.

Get your PPID by visiting: https://secure6.brother.co.jp/mfi/MFiInputForm.aspx

```bash
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.brother.ptcbp</string>
</array>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Discover compatible Bluetooth printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to find and communicate with printers.</string>
```

With Bluetooth, you will also need to register with Brother directly. Fill in this form:

### If you are using Wifi

Add the following to your info.plist

```bash
<key>NSLocalNetworkUsageDescription</key>
<string>The local network is needed to find printers</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>The local network is needed to find printers</string>
<key>NSBonjourServices</key>
<array>
    <string>_pdl-datastream._tcp</string>
    <string>_printer._tcp</string>
    <string>_ipp._tcp</string>
</array>
```

## API

<docgen-index>

- [`searchWifiPrinters()`](#searchwifiprinters)
- [`searchBluetoothPrinters()`](#searchbluetoothprinters)
- [`base64Print()`](#base64print)
- [`checkPrinterStatus()`](#checkprinterstatus)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### searchWifiPrinters()

```typescript
searchWifiPrinters() => Promise<{ printers: string[]; }>
```

**Returns:** <code>Promise&lt;{ printers: string[]; }&gt;</code>

---

### searchBluetoothPrinters()

```typescript
searchBluetoothPrinters() => Promise<{ printers: string[]; }>
```

**Returns:** <code>Promise&lt;{ printers: string[]; }&gt;</code>

---

### base64Print()

```typescript
base64Print() => Promise<{ message: string; }>
```

**Returns:** <code>Promise&lt;{ message: string; }&gt;</code>

---

### checkPrinterStatus()

```typescript
checkPrinterStatus() => Promise<{ status: string[]; }>
```

**Returns:** <code>Promise&lt;{ status: string[]; }&gt;</code>

---

</docgen-api>
