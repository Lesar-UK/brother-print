export type BrotherPrintMethod = 'wifi' | 'bluetooth';

export interface PrinterSearchResult {
  printers: string[];
}

export interface PrintOptions {
  printMethod: BrotherPrintMethod;
  deviceIdentifier: string;
  base64String: string;
  model?: string;
  labelSize?: number;
}

export interface PrintResult {
  message: string;
}

export interface PrinterStatusResult {
  status: string[];
}

export interface BrotherPrintPlugin {
  searchWifiPrinters(): Promise<PrinterSearchResult>;
  searchBluetoothPrinters(): Promise<PrinterSearchResult>;
  printImage(options: PrintOptions): Promise<PrintResult>;
  printPDF(options: PrintOptions): Promise<PrintResult>;
  checkPrinterStatus(options: Omit<PrintOptions, 'base64String'>): Promise<PrinterStatusResult>;
}
