# brother-print for capacitor

Print to a Brother label printer via the Brother SDK using Capacitor.

## Install

```bash
npm install brother-print
npx cap sync
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
