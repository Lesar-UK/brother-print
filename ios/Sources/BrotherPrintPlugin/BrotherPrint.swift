import Foundation
import BRLMPrinterKit
import Capacitor
import CoreBluetooth

@objc public class BrotherPrint: CAPPlugin, CBCentralManagerDelegate {

    private var bluetoothCentralManager: CBCentralManager?
    private var pendingBluetoothSearchCalls: [CAPPluginCall] = []
    private var bluetoothAuthorizationScanStarted = false

    // Function to print a base64 image
    @objc public func printImage(_ call: CAPPluginCall) {

        guard let printMethod = call.getString("printMethod") else {
            call.reject("Must provide a print method, either 'bluetooth' or 'wifi'")
            return
        }

        guard let deviceIdentifier = call.getString("deviceIdentifier") else {
            call.reject("Must provide an IP address or Bluetooth serial number")
            return
        }

        guard let base64Image = call.getString("base64String") else {
            call.reject("Must provide a base64 string")
            return
        }

        // Open a channel based on print method (Wi-Fi or Bluetooth)
        guard let channel = getPrintChannel(printMethod: printMethod, deviceIdentifier: deviceIdentifier, call: call) else { return }

        // Open printer connection
        let generateResult = BRLMPrinterDriverGenerator.open(channel)
        guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = generateResult.driver else {
            call.reject("Error - Open Channel: \(generateResult.error.code)")
            return
        }
        defer {
            printerDriver.closeChannel()
        }

        // Get printer status
        let statusResult = printerDriver.getPrinterStatus()
        guard statusResult.error.code == .noError, let printerStatus = statusResult.status else {
            call.reject("Unable to retrieve printer status: \(statusResult.error.code)")
            return
        }

        // Get the label size
        var isSuccess: Bool = false
        let labelSizeResult = printerStatus.mediaInfo?.getQLLabelSize(&isSuccess)

        // Safely unwrap labelSizeResult
        guard isSuccess, let labelSize = labelSizeResult else {
            call.reject("Error - Unable to retrieve label size from the printer")
            return
        }

        // Determine printer model and configure print settings
        guard let printSettings = configurePrintSettings(for: printerStatus.model, labelType: labelSize) else {
            call.reject("Unsupported printer model or label type")
            return
        }

        // Convert base64 image data to CGImage
        guard let cgImage = base64ToCGImage(base64Image: base64Image) else {
            call.reject("Error - Unable to convert base64 image to CGImage")
            return
        }

        // Send the print job
        let printError = printerDriver.printImage(with: cgImage, settings: printSettings)

        if printError.code != .noError {
            call.reject(printError.errorDescription)
        } else {
            call.resolve(["message": "Success"])
        }
    }

    // Function to print a base64 PDF
    @objc public func printPDF(_ call: CAPPluginCall) {
        guard let printMethod = call.getString("printMethod") else {
            call.reject("Must provide a print method, either 'bluetooth' or 'wifi'")
            return
        }

        guard let deviceIdentifier = call.getString("deviceIdentifier") else {
            call.reject("Must provide an IP address or Bluetooth serial number")
            return
        }

        guard let base64PDF = call.getString("base64String") else {
            call.reject("Must provide a base64-encoded PDF string")
            return
        }

        // Decode the base64 PDF string to Data
        guard let pdfData = Data(base64Encoded: base64PDF) else {
            call.reject("Error - Unable to decode base64 PDF")
            return
        }

        // Create a temporary file URL to save the PDF
        let tempDirectory = FileManager.default.temporaryDirectory
        let pdfFileURL = tempDirectory.appendingPathComponent("temp.pdf")

        // Write the PDF data to the temporary file
        do {
            try pdfData.write(to: pdfFileURL)
        } catch {
            call.reject("Error - Unable to write PDF to temporary file: \(error.localizedDescription)")
            return
        }

        // Open a channel based on the print method
        guard let channel = getPrintChannel(printMethod: printMethod, deviceIdentifier: deviceIdentifier, call: call) else { return }

        // Open printer connection
        let generateResult = BRLMPrinterDriverGenerator.open(channel)
        guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = generateResult.driver else {
            call.reject("Error - Open Channel: \(generateResult.error.code)")
            return
        }
        defer {
            printerDriver.closeChannel()
        }

        // Get printer status
        let statusResult = printerDriver.getPrinterStatus()
        guard statusResult.error.code == .noError, let printerStatus = statusResult.status else {
            call.reject("Unable to retrieve printer status: \(statusResult.error.code)")
            return
        }

        // Get the label size
        var isSuccess: Bool = false
        let labelSizeResult = printerStatus.mediaInfo?.getQLLabelSize(&isSuccess)

        // Safely unwrap labelSizeResult
        guard isSuccess, let labelSize = labelSizeResult else {
            call.reject("Error - Unable to retrieve label size from the printer")
            return
        }

        // Determine printer model and configure print settings
        guard let printSettings = configurePrintSettings(for: printerStatus.model, labelType: labelSize) else {
            call.reject("Unsupported printer model or label type")
            return
        }

        // Send the print job with the PDF URL
        let printError = printerDriver.printPDF(with: pdfFileURL, settings: printSettings)
        if printError.code != .noError {
            call.reject(printError.errorDescription)
        } else {
            call.resolve(["message": "PDF printed successfully"])
        }
    }

    // Function to search for WiFi printers
    @objc public func searchWifiPrinters(_ call: CAPPluginCall) {
        let searchOption = BRLMNetworkSearchOption()
        searchOption.searchDuration = 5
        searchOption.printerList = ["QL-820NWB", "QL-810W"]

        var resultList: [String] = []

        BRLMPrinterSearcher.startNetworkSearch(searchOption) { channel in
            resultList.append(channel.channelInfo)
        }

        call.resolve(["printers": resultList])
    }

    // Function to search for Bluetooth printers
    @objc public func searchBluetoothPrinters(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.pendingBluetoothSearchCalls.append(call)

            if let centralManager = self.bluetoothCentralManager {
                self.handleBluetoothState(centralManager)
                return
            }

            self.bluetoothCentralManager = CBCentralManager(
                delegate: self,
                queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: true]
            )
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleBluetoothState(central)
    }

    private func handleBluetoothState(_ central: CBCentralManager) {
        guard !pendingBluetoothSearchCalls.isEmpty else { return }

        switch CBManager.authorization {
        case .notDetermined:
            // Core Bluetooth has no explicit permission-request API. Starting a scan
            // causes iOS to present the prompt described by the app's plist entry.
            switch central.state {
            case .poweredOn:
                guard !bluetoothAuthorizationScanStarted else { return }
                bluetoothAuthorizationScanStarted = true
                central.scanForPeripherals(withServices: nil)
            case .poweredOff:
                rejectPendingBluetoothSearches("Bluetooth is turned off")
            case .unsupported:
                rejectPendingBluetoothSearches("Bluetooth is not supported on this device")
            case .unauthorized:
                rejectPendingBluetoothSearches("Bluetooth access is unauthorized")
            case .resetting, .unknown:
                // Wait for centralManagerDidUpdateState to provide a stable state.
                return
            @unknown default:
                rejectPendingBluetoothSearches("Bluetooth is unavailable")
            }
        case .restricted:
            rejectPendingBluetoothSearches(
                "Bluetooth access is restricted on this device"
            )
        case .denied:
            rejectPendingBluetoothSearches(
                "Bluetooth permission is denied. Enable it for ProVisit in Settings > Privacy & Security > Bluetooth"
            )
        case .allowedAlways:
            bluetoothAuthorizationScanStarted = false
            if central.isScanning {
                central.stopScan()
            }

            switch central.state {
            case .poweredOn:
                resolvePendingBluetoothSearches()
            case .poweredOff:
                rejectPendingBluetoothSearches("Bluetooth is turned off")
            case .unsupported:
                rejectPendingBluetoothSearches("Bluetooth is not supported on this device")
            case .unauthorized:
                rejectPendingBluetoothSearches("Bluetooth access is unauthorized")
            case .resetting, .unknown:
                // Wait for centralManagerDidUpdateState to provide a stable state.
                return
            @unknown default:
                rejectPendingBluetoothSearches("Bluetooth is unavailable")
            }
        @unknown default:
            rejectPendingBluetoothSearches("Bluetooth authorization status is unknown")
        }
    }

    private func rejectPendingBluetoothSearches(_ message: String) {
        let calls = pendingBluetoothSearchCalls
        pendingBluetoothSearchCalls.removeAll()
        calls.forEach { $0.reject(message) }
    }

    private func resolvePendingBluetoothSearches() {
        let resultList = BRLMPrinterSearcher.startBluetoothSearch().channels.compactMap { channel in
            channel.extraInfo?[BRLMChannelExtraInfoKeySerialNumber] as? String
        }
        let calls = pendingBluetoothSearchCalls
        pendingBluetoothSearchCalls.removeAll()
        calls.forEach { $0.resolve(["printers": resultList]) }
    }

    // Function to check the status of a printer
    @objc public func checkPrinterStatus(_ call: CAPPluginCall) {
        guard let printMethod = call.getString("printMethod"),
              let deviceIdentifier = call.getString("deviceIdentifier") else {
            call.reject("Must provide 'printMethod' and 'deviceIdentifier'")
            return
        }

        // Open a channel based on the print method
        guard let channel = getPrintChannel(printMethod: printMethod, deviceIdentifier: deviceIdentifier, call: call) else { return }

        // Open printer connection
        let generateResult = BRLMPrinterDriverGenerator.open(channel)
        guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = generateResult.driver else {
            call.reject("Error - Open Channel: \(generateResult.error.code)")
            return
        }
        defer {
            printerDriver.closeChannel()
        }

        // Get printer status
        let statusResult = printerDriver.getPrinterStatus()
        guard statusResult.error.code == .noError, let printerStatus = statusResult.status else {
            call.reject("Unable to retrieve printer status: \(statusResult.error.code)")
            return
        }

        // Prepare the data to send back to JavaScript
        let statusData: [String: Any] = [
            "model": printerModelName(for: printerStatus.model.rawValue),
            "statusCode": printerStatus.errorCode.rawValue,
            "statusMessage": getErrorCode(for: printerStatus.errorCode.rawValue)
        ]

        call.resolve(["status": statusData])
    }

    // Helper to get print channel based on method (Wi-Fi/Bluetooth)
    private func getPrintChannel(printMethod: String, deviceIdentifier: String, call: CAPPluginCall) -> BRLMChannel? {
        if printMethod == "wifi" {
            return BRLMChannel(wifiIPAddress: deviceIdentifier)
        } else if printMethod == "bluetooth" {
            return BRLMChannel(bluetoothSerialNumber: deviceIdentifier)
        } else {
            call.reject("Invalid print method: Must be 'bluetooth' or 'wifi'")
            return nil
        }
    }

    // Helper to configure print settings based on printer model
    private func configurePrintSettings(for model: BRLMPrinterModel, labelType: BRLMQLPrintSettingsLabelSize) -> BRLMPrintSettingsProtocol? {
        switch model {
        case .QL_820NWB, .QL_810W:
            let settings = BRLMQLPrintSettings(defaultPrintSettingsWith: model)
            settings!.labelSize = labelType
            settings!.autoCut = true
            settings!.printOrientation = BRLMPrintSettingsOrientation.landscape
            settings!.halftone = BRLMPrintSettingsHalftone.errorDiffusion
            settings!.printQuality = BRLMPrintSettingsPrintQuality.best
            return settings
        default:
            return nil
        }
    }

    // Helper to convert base64 image to CGImage
    private func base64ToCGImage(base64Image: String) -> CGImage? {
        guard let imageData = Data(base64Encoded: base64Image),
              let decodedImage = UIImage(data: imageData),
              let cgImage = decodedImage.cgImage else {
            return nil
        }
        return cgImage
    }

    // Helper to return error code in human-readable format
    func getErrorCode(for errorCode: Int) -> String {
        switch errorCode {
        case 0:
            return "Ready"
        case 1:
            return "No paper"
        case 2:
            return "Cover open"
        case 3:
            return "Busy"
        case 4:
            return "Paper Jam"
        case 5:
            return "Power Adapter Error"
        case 6:
            return "Battery Empty"
        case 7:
            return "Battery Trouble"
        default:
            return "Unknown error"
        }
    }

    // Helper to return the printer model name
    func printerModelName(for model: Int) -> String {
        switch model {
        case 28:
            return "QL-810W"
        case 29:
            return "QL-820NWB"
        default:
            return "Unknown Model"
        }
    }
}
