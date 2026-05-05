import { WebPlugin } from '@capacitor/core';

import type { BrotherPrintPlugin, PrintOptions, PrinterStatusResult } from './definitions';

export class BrotherPrintWeb extends WebPlugin implements BrotherPrintPlugin {
  async searchWifiPrinters(): Promise<{ printers: string[] }> {
    console.warn('searchWifiPrinters is not available on the web');
    return { printers: [] }; // Return an empty list for web
  }

  async searchBluetoothPrinters(): Promise<{ printers: string[] }> {
    console.warn('searchBluetoothPrinters is not available on the web');
    return { printers: [] }; // Return an empty list for web
  }

  async printImage(_options: PrintOptions): Promise<{ message: string }> {
    void _options;
    console.warn('base64Print is not available on the web');
    return { message: 'Not available on web' }; // Return an default message
  }

  async printPDF(_options: PrintOptions): Promise<{ message: string }> {
    void _options;
    console.warn('base64Print is not available on the web');
    return { message: 'Not available on web' }; // Return an default message
  }

  async checkPrinterStatus(_options: Omit<PrintOptions, 'base64String'>): Promise<PrinterStatusResult> {
    void _options;
    console.warn('checkPrinterStatus is not available on the web');
    return { status: [] }; // Return an empty list
  }
}
