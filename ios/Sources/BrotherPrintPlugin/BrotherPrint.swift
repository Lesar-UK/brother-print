import Foundation
import BRLMPrinterKit
import Capacitor

@objc public class BrotherPrint: CAPPlugin {

    // Function to print a base64 image
    @objc public func base64Print(_ call: CAPPluginCall) {

        guard let printMethod = call.getString("printMethod") else {
            call.reject("Must provide a print method, either 'bluetooth' or 'wifi")
            return
        }

        guard printMethod == "bluetooth" || printMethod == "wifi" else {
            call.reject("Only 'bluetooth' or 'wifi' print method is supported")
            return
        }

        guard let deviceIdentifier = call.getString("deviceIdentifier") else {
            call.reject("Must provide an IP address or Bluetooth serial number")
            return
        }

        guard let base64Image = call.getString("base64Image") else {
            call.reject("Must provide an base64 string")
            return
        }

        var channel: BRLMChannel?

        if printMethod == "wifi" {
            channel = BRLMChannel(wifiIPAddress: deviceIdentifier)
        } else if(printMethod == "bluetooth") {
            channel = BRLMChannel(bluetoothSerialNumber: deviceIdentifier)
        }

        // Open printer connection
        let generateResult = BRLMPrinterDriverGenerator.open(channel!)
        guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = generateResult.driver else {
            print("Error - Open Channel: \(generateResult.error.code)")
            call.reject("Error - Open Channel: \(generateResult.error.code)")
            return
        }
        defer {
            printerDriver.closeChannel()
        }

        // Declare printSettings outside the if-let block
        var printSettings: BRLMPrintSettingsProtocol?

        /// Get printer status
        let statusResult = printerDriver.getPrinterStatus()

        // Check if there's an error in retrieving the printer status
        if statusResult.error.code != .noError {
            print("Error - Unable to retrieve printer status: \(statusResult.error.code)")
            call.reject("Unable to retrieve printer status: \(statusResult.error.code)")
            return
        }

        // Use the printerStatus model to determine the printer model
        let printerStatus = statusResult.status
        let printerModel = printerStatus!.model

        // Select appropriate print settings based on the printer model
        switch printerModel {
        case .QL_820NWB, .QL_810W:
            if let qlPrintSettings = BRLMQLPrintSettings(defaultPrintSettingsWith: printerModel) {
                qlPrintSettings.labelSize = BRLMQLPrintSettingsLabelSize.rollW62
                qlPrintSettings.autoCut = true
                qlPrintSettings.printOrientation = BRLMPrintSettingsOrientation.landscape
                qlPrintSettings.halftone = BRLMPrintSettingsHalftone.errorDiffusion
                printSettings = qlPrintSettings
            }
        default:
            print("Error - Unsupported printer model")
            call.reject("Unsupported printer model")
            return
        }

        // Ensure printSettings was set
        guard let finalPrintSettings = printSettings else {
            print("Error - Unable to create print settings")
            call.reject("Error - Unable to create print settings")
            return
        }

        // Safely unwrap base64 image data
        guard let encodedBase64Image = Data(base64Encoded: base64Image, options: []) else {
            print("Error - decoding base64 string to Data")
            call.reject("Error - decoding base64 string to Data")
            return
        }

        // Safely create UIImage from the decoded data
        guard let decodedImage = UIImage(data: encodedBase64Image) else {
            print("Error - creating image from decoded data")
            call.reject("Error - creating image from decoded data")
            return
        }

        // Ensure the image has a valid CGImage before sending it to the printer
        guard let cgImage = decodedImage.cgImage else {
            print("Error - retrieving CGImage from UIImage")
            call.reject("Error - retrieving CGImage from UIImage")
            return
        }

        // Send the print job
        let printError = printerDriver.printImage(with: cgImage, settings: finalPrintSettings)

        if printError.code != .noError {
            print("Error - Print Image: \(printError.code)")
            call.reject("Error - Print Image: \(printError.code)")
        } else {
            print("Success - Print Image")
            call.resolve()
        }
    }

    // Function to search for WiFi printers
    @objc public func searchWifiPrinters(_ call: CAPPluginCall) {
        print("Search Wifi Printers function called...")

        // Create a search option object
        let searchOption = BRLMNetworkSearchOption()

        searchOption.searchDuration = 5  // search for 10 seconds
        searchOption.printerList = ["QL-820NWB","QL-810W"]

        var resultList: [String] = []

        BRLMPrinterSearcher.startNetworkSearch(searchOption) { channel in
            print("Channel: \(channel.channelInfo)")
            resultList.append(channel.channelInfo)
        }

        call.resolve([
            "printers": resultList
        ])
    }

    // Function to search for Bluetooth printers
    @objc public func searchBluetoothPrinters(_ call: CAPPluginCall) {

        let channels = BRLMPrinterSearcher.startBluetoothSearch().channels

        var resultList: [String] = []

        channels.forEach { channel in
            print("Channel: \(channel.channelInfo)")
            if let extraInfo = channel.extraInfo {
                resultList.append(extraInfo[BRLMChannelExtraInfoKeySerialNumber] as! String)
            }
        }

        call.resolve([
            "printers": resultList
        ])
    };

    // Function to check the status of a printer
    @objc public func checkPrinterStatus(_ call: CAPPluginCall) {

        guard let printMethod = call.getString("printMethod") else {
            call.reject("Must provide a print method, either 'bluetooth' or 'wifi")
            return
        }

        guard printMethod == "bluetooth" || printMethod == "wifi" else {
            call.reject("Only 'bluetooth' or 'wifi' print method is supported")
            return
        }

        guard let deviceIdentifier = call.getString("deviceIdentifier") else {
            call.reject("Must provide an IP address or Bluetooth serial number")
            return
        }

        // Open a channel
        var channel: BRLMChannel?

        if printMethod == "wifi" {
            channel = BRLMChannel(wifiIPAddress: deviceIdentifier)
        } else if(printMethod == "bluetooth") {
            channel = BRLMChannel(bluetoothSerialNumber: deviceIdentifier)
        }

        // Open printer connection
        let generateResult = BRLMPrinterDriverGenerator.open(channel!)
        guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
              let printerDriver = generateResult.driver else {
            print("Error - Open Channel: \(generateResult.error.code)")
            call.reject("Error - Open Channel: \(generateResult.error.code)")
            return
        }
        defer {
            printerDriver.closeChannel()
        }

        /// Get printer status
        let statusResult = printerDriver.getPrinterStatus()

        // Check if there's an error in retrieving the printer status
        if statusResult.error.code != .noError {
            print("Error - Unable to retrieve printer status: \(statusResult.error.code)")
            call.reject("Unable to retrieve printer status: \(statusResult.error.code)")
            return
        }

        guard let printerStatus = statusResult.status else {
            print("Error - Printer status is nil")
            call.reject("Printer status is nil")
            return
        }

        let rawData = printerStatus.rawData

        // Prepare the data to send back to JavaScript
        let statusData: [String: Any] = [
            "model": printerModelName(for: printerStatus.model.rawValue),
            "statusCode": printerStatus.errorCode.rawValue,
            "statusMessage": getErrorCode(for: printerStatus.errorCode.rawValue),
        ]

        print("Printer Status: \(statusData)")

        call.resolve([
            "status": statusData
        ])
    };

    // Function to return error code in a human readable format.
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
            return "Batter Trouble"
        case 8:
            return "Tube Not Detected"
        case 9:
            return "Unsupported Charger"
        case 10:
            return "Unsupported Accessory"
        case 11:
            return "System error"
        case 12:
            return "Unknown error"
        default:
            return "Unknown error"
        }
    }
    
    // Function to get the printer model name
    func printerModelName(for model: Int) -> String {
        switch model {
        case 0:
            return "PJ-673"
        case 1:
            return "PJ-763MFi"
        case 2:
            return "PJ-773"
        case 3:
            return "MW-145MFi"
        case 4:
            return "MW-260MFi"
        case 5:
            return "MW-170"
        case 6:
            return "MW-270"
        case 7:
            return "RJ-4030Ai"
        case 8:
            return "RJ-4040"
        case 9:
            return "RJ-3050"
        case 10:
            return "RJ-3150"
        case 11:
            return "RJ-3050Ai"
        case 12:
            return "RJ-3150Ai"
        case 13:
            return "RJ-2050"
        case 14:
            return "RJ-2140"
        case 15:
            return "RJ-2150"
        case 16:
            return "RJ-4230B"
        case 17:
            return "RJ-4250WB"
        case 18:
            return "RJ-3230B"
        case 19:
            return "RJ-3250WB"
        case 20:
            return "TD-2120N"
        case 21:
            return "TD-2130N"
        case 22:
            return "TD-4100N"
        case 23:
            return "TD-4420DN"
        case 24:
            return "TD-4520DN"
        case 25:
            return "TD-4550DNWB"
        case 26:
            return "QL-710W"
        case 27:
            return "QL-720NW"
        case 28:
            return "QL-810W"
        case 29:
            return "QL-820NWB"
        case 30:
            return "QL-1110NWB"
        case 31:
            return "QL-1115NWB"
        case 32:
            return "PT-E550W"
        case 33:
            return "PT-P750W"
        case 34:
            return "PT-D800W"
        case 35:
            return "PT-E800W"
        case 36:
            return "PT-E850TKW"
        case 37:
            return "PT-P900W"
        case 38:
            return "PT-P950NW"
        case 39:
            return "PT-P300BT"
        case 40:
            return "PT-P710BT"
        case 41:
            return "PT-P715eBT"
        case 42:
            return "PT-P910BT"
        case 43:
            return "PJ-862"
        case 44:
            return "PJ-863"
        case 45:
            return "PJ-883"
        case 46:
            return "TD-2125N"
        case 47:
            return "TD-2125NWB"
        case 48:
            return "TD-2135N"
        case 49:
            return "TD-2135NWB"
        case 50:
            return "PT-E310BT"
        case 51:
            return "PT-E510"
        case 52:
            return "PT-E560BT"
        case 53:
            return "TD-2310D 203"
        case 54:
            return "TD-2310D 300"
        case 55:
            return "TD-2320D 203"
        case 56:
            return "TD-2320D 300"
        case 57:
            return "TD-2320DF 203"
        case 58:
            return "TD-2320DF 300"
        case 59:
            return "TD-2320DSA 203"
        case 60:
            return "TD-2320DSA 300"
        case 61:
            return "TD-2350D 203"
        case 62:
            return "TD-2350D 300"
        case 63:
            return "TD-2350DF 203"
        case 64:
            return "TD-2350DF 300"
        case 65:
            return "TD-2350DSA 203"
        case 66:
            return "TD-2350DSA 300"
        case 67:
            return "TD-2350DFSA 203"
        case 68:
            return "TD-2350DFSA 300"
        case 69:
            return "Unknown"
        default:
            return "Unknown Model"
        }
    }
}
