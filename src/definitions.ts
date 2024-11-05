export interface BrotherPrintPlugin {
  searchWifiPrinters(): Promise<{ printers: string[] }>;
  searchBluetoothPrinters(): Promise<{ printers: string[] }>;
  printImage(): Promise<{ message: string }>;
  printPDF(): Promise<{ message: string }>;
  checkPrinterStatus(): Promise<{ status: string[] }>;
}
