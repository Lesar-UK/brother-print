import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(BrotherPrintPlugin)
public class BrotherPrintPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "BrotherPrintPlugin"

    public let jsName = "BrotherPrint"

    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "searchWifiPrinters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "searchBluetoothPrinters", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "printImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "printPDF", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkPrinterStatus", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = BrotherPrint()

    // Adding the searchWifiPrinters function
    @objc func searchWifiPrinters(_ call: CAPPluginCall) {
        implementation.searchWifiPrinters(call)
    }

    // Adding the searchBLEPrinters function
    @objc func searchBluetoothPrinters(_ call: CAPPluginCall) {
        implementation.searchBluetoothPrinters(call)
    }

    @objc func printImage(_ call: CAPPluginCall) {
        implementation.printImage(call)
    }

    @objc func printPDF(_ call: CAPPluginCall) {
        implementation.printPDF(call)
    }

    @objc func checkPrinterStatus(_ call: CAPPluginCall) {
        implementation.checkPrinterStatus(call)
    }
}
