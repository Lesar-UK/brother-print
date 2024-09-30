export interface BrotherPrintPlugin {
  searchWifiPrinters(): Promise<{ printers: string[] }>;
  searchBluetoothPrinters(): Promise<{ printers: string[] }>;
  base64Print(): Promise<{ value: string }>;
  checkPrinterStatus(): Promise<{ status: string }>;
}
