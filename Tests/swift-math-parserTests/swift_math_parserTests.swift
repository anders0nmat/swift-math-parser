import XCTest
@testable import SwiftMathParser

final class swift_math_parserTests: XCTestCase {
	func testSimpleFunction() throws {
		let parser = Parser()

		parser.parseDebug([ "2", "+", "5", "*", "2", "*", "1.5", "+", "1", "+", "1"])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.expression)
		print(String(data: data, encoding: .utf8)!)

		XCTAssertEqual(Int(try parser.expression.evaluate().value), 19)
	}

	func testNestedFunctions() throws {
		let parser = Parser()

		parser.parseDebug([ "pow", "2", "->", "abs", "-4", "+", "2", "+", "0", "->", "*", "1.5" ])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		
		// print(parser.root.displayName)

		XCTAssert(try parser.root.evaluate().value == 8)
	}

	func testConstantValues() throws {
		let parser = Parser()

		parser.parseDebug([ "2", "*", "pi" ], printCommand: true)

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		// print(parser.root.displayName)
		XCTAssert(try parser.root.evaluate().value == Double.pi * 2)
	}

	func testPrefixOperations() throws {
		let parser = Parser()

		parser.parseDebug([ "5", "^", "3" ])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		
		// print(parser.root.displayName)

		XCTAssertEqual(try parser.root.evaluate().value, 125)
	}

	func testUserExpression() throws {
		let parser = Parser()

		parser.parseDebug([BuiltinOperators.variable("x"), "+", BuiltinOperators.variable("y")])

		do {
			let container = try UserEvaluableContainer(internalName: "sum", argMap: ["x": 0, "y": 1], expression: parser.expression)

			let encoder = JSONEncoder()
			let data = try! encoder.encode(container)
			print(String(data: data, encoding: .utf8)!)

			addOperator(container)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}

		let parser2 = Parser()

		parser2.parseDebug([ "sum", "1", "->", "2", "->", "+", "2" ])

		let encoder2 = JSONEncoder()
		let data2 = try! encoder2.encode(parser2.expression)
		print(String(data: data2, encoding: .utf8)!)

		// print(parser2.root.displayName)

		XCTAssertEqual(try parser2.expression.evaluate().value, 5)
	}

	func testUserConstant() throws {
		let parser = Parser()
		
		parser.parseDebug(["2", "*", "pi"])

		do {
			let expr = UserConstContainer(internalName: "twopi", value: try parser.expression.evaluate().value)

			let encoder = JSONEncoder()
			let data = try! encoder.encode(expr)
			print(String(data: data, encoding: .utf8)!)

			addOperator(expr)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}

		let parser2 = Parser()

		parser2.parseDebug([ "twopi", "*", "0.5" ])

		let encoder2 = JSONEncoder()
		let data2 = try! encoder2.encode(parser2.root)
		print(String(data: data2, encoding: .utf8)!)

	
		// print(parser2.root.displayName)

		XCTAssert(try parser2.root.evaluate().value == Double.pi)
	}

	func testLoadFromJson() throws {
		let parser = Parser()

		parser.parseDebug([ "2", "+", "4", "*", "abs", "3" ])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.expression)
		print(String(data: data, encoding: .utf8)!)

		let decoder = JSONDecoder()
		let obj = try decoder.decode(EvaluableTreeNode.self, from: data)

		let encoder2 = JSONEncoder()
		let data2 = try! encoder2.encode(obj)
		print(String(data: data2, encoding: .utf8)!)
		
		// print(parser.root.displayName)
		XCTAssert(try obj.evaluate().value == 14)
	}
}