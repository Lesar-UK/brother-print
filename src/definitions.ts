export interface BrotherPrintPlugin {
  searchWifiPrinters(): Promise<{ printers: string[] }>;
  searchBluetoothPrinters(): Promise<{ printers: string[] }>;
  base64Print(): Promise<{ message: string }>;
  base64PDFPrint(): Promise<{ message: string }>;
  checkPrinterStatus(): Promise<{ status: string[] }>;
}
