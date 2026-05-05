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

export interface PrinterStatus {
  model?: string;
  statusCode?: number | string;
  statusMessage?: string;
  media?: string;
  battery?: string;
}

export interface PrinterStatusResult {
  status: PrinterStatus;
}

export interface BrotherPrintPlugin {
  searchWifiPrinters(): Promise<PrinterSearchResult>;
  searchBluetoothPrinters(): Promise<PrinterSearchResult>;
  printImage(options: PrintOptions): Promise<PrintResult>;
  printPDF(options: PrintOptions): Promise<PrintResult>;
  checkPrinterStatus(options: Omit<PrintOptions, 'base64String'>): Promise<PrinterStatusResult>;
}
