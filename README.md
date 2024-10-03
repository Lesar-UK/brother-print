# brother-print for capacitor

Print to a Brother label printer via the Brother SDK using Capacitor.

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
base64Print() => Promise<{ value: string; }>
```

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

---

### checkPrinterStatus()

```typescript
checkPrinterStatus() => Promise<{ status: string; }>
```

**Returns:** <code>Promise&lt;{ status: string; }&gt;</code>

---

</docgen-api>
