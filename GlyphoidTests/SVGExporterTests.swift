import XCTest
@testable import Glyphoid

final class SVGExporterTests: XCTestCase {

    var exporter: SVGExporter!

    override func setUp() {
        super.setUp()
        exporter = SVGExporter()
    }

    // MARK: - Vector SVG

    func testVectorSVGContainsViewBox() {
        let svg = exporter.vectorSVG(character: "A", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertNotNil(svg)
        XCTAssertTrue(svg!.contains("viewBox=\"0 0 1000 1000\""))
    }

    func testVectorSVGContainsPath() {
        let svg = exporter.vectorSVG(character: "A", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertNotNil(svg)
        XCTAssertTrue(svg!.contains("<path"), "Expected SVG path element")
    }

    func testVectorSVGHasBlackFill() {
        let svg = exporter.vectorSVG(character: "A", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertNotNil(svg)
        XCTAssertTrue(svg!.contains("fill=\"#000000\""))
    }

    func testVectorSVGIsValidXML() {
        let svg = exporter.vectorSVG(character: "A", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertNotNil(svg)
        let data = svg!.data(using: .utf8)!
        XCTAssertNoThrow(try XMLDocument(data: data))
    }

    // MARK: - Text SVG

    func testTextSVGContainsViewBox() {
        let svg = exporter.textSVG(character: "→", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertTrue(svg.contains("viewBox=\"0 0 1000 1000\""))
    }

    func testTextSVGContainsTextElement() {
        let svg = exporter.textSVG(character: "→", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertTrue(svg.contains("<text"))
        XCTAssertTrue(svg.contains("text-anchor=\"middle\""))
        XCTAssertTrue(svg.contains("dominant-baseline=\"central\""))
    }

    func testTextSVGContainsCharacter() {
        let svg = exporter.textSVG(character: "→", fontFamily: "Helvetica Neue", style: "Regular")
        XCTAssertTrue(svg.contains("→"))
    }
}
