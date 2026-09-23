import XCTest
@testable import BrotherPrintPlugin

class BrotherPrintTests: XCTestCase {
    func testKnownErrorCode() {
        let implementation = BrotherPrint()
        XCTAssertEqual(implementation.getErrorCode(for: 0), "Ready")
        XCTAssertEqual(implementation.getErrorCode(for: 4), "Paper Jam")
    }

    func testKnownPrinterModel() {
        let implementation = BrotherPrint()
        XCTAssertEqual(implementation.printerModelName(for: 28), "QL-810W")
        XCTAssertEqual(implementation.printerModelName(for: 29), "QL-820NWB")
    }

    func testUnknownValues() {
        let implementation = BrotherPrint()
        XCTAssertEqual(implementation.getErrorCode(for: -1), "Unknown error")
        XCTAssertEqual(implementation.printerModelName(for: -1), "Unknown Model")
    }
}
