import XCTest
@testable import SwiftMathParser

final class PriorityOperations: XCTestCase {

	func runStringSuit(_ suit: [(String, Double)]) throws {
		for (term, result) in suit {
			var parser = Parser()

			parser.parseDebug(string: term, printCommand: false)

			XCTAssertEqual(try parser.expression.evaluate().value, result, accuracy: 1e-15, "Expression: '\(term)'")
		}
	}

	func testCalcSingleOp() throws {
		let tests: [(String, Double)] = [
			("2 + 5", 7),
			("14 - 5", 9),
			("3 * 6", 18),
			("15 / 4", 3.75),

			("1.5 - 0.5", 1),
			("2.5 * 10", 25),
			("8.25 + 4.25", 12.5),
			("32.625 / -2.5", -13.05),

			("-52 * 0.1", -5.2),
			("-0 - -0", 0),
			("-0 - 0", 0),
			("-1 * 5", -5),
			("-1 / 5", -0.2),

			("3,5 + 1", 1), // Error for first and second part, "1" is read correctly
			("3-5 + 1", 1), // Error for first and second part, "1" is read correctly
		]

		XCTAssertNoThrow(try runStringSuit(tests))
	}

	func testCalcMultipleOp() throws {
		let tests: [(String, Double)] = [
			("12 + 4 * 3", 24),
			("2 * 1.5 * 20 + 6", 66),
			("11.25 * 2 + 5.2 * 5 + 1.5", 50),

			/*
			("12 + 4 * 3", 24),
			("12 + 4 * 3", 24),
			("12 + 4 * 3", 24),
			*/
		]

		XCTAssertNoThrow(try runStringSuit(tests))
	}

	func testSaveMultipleOp() throws {
		/* Needs comparing to all possible orders of JSON :/ */	
	}
}

final class NormalOperations: XCTestCase {

	func runStringSuit(_ suit: [(String, Double)]) throws {
		for (term, result) in suit {
			var parser = Parser()

			parser.parseDebug(string: term, printCommand: false)

			XCTAssertEqual(try parser.expression.evaluate().value, result, accuracy: 1e-15, "Expression: '\(term)'")
		}
	}

	func testCalcSingleOp() throws {
		let tests: [(String, Double)] = [
			("abs 5", 5),
			("abs 5.6", 5.6),
			("abs -5.6", 5.6),
			("abs -5", 5),

			("sqrt 16", 4),

			("sin pi", 0),
			("cos pi", -1),
		]

		XCTAssertNoThrow(try runStringSuit(tests))
	}

	func testCalcChainedOp() throws {

	}

	func testCalcMixedOp() throws {

	}

	func testSaveChainedOp() throws {

	}

	func testCalcPrefixOp() throws {

	}

	func testCalcVarargOp() throws {
		var parser = Parser()

		parser.parseDebug(["3", "cbe", "-", "2"])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.expression)
		print(String(data: data, encoding: .utf8)!)

		XCTAssertEqual(try parser.expression.evaluate().value, 25)
	}

	func testSplitNumber() throws {
		var parser = Parser()

		parser.parseDebug(["2", "+", "4", "6", ".", "5", "+-"])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.expression)
		print(String(data: data, encoding: .utf8)!)

		XCTAssertEqual(try parser.expression.evaluate().value, -44.5)
	}

	func testSimpleFunction() throws {
		var parser = Parser()

		parser.parseDebug([ "2", "+", "5", "*", "2", "*", "1.5", "+", "1", "+", "1"])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.expression)
		print(String(data: data, encoding: .utf8)!)

		XCTAssertEqual(Int(try parser.expression.evaluate().value), 19)
	}

	func testNestedFunctions() throws {
		var parser = Parser()

		parser.parseDebug([ "pow", "2", "->", "abs", "-4", "+", "2", "+", "0", "->", "*", "1.5" ])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		
		// print(parser.root.displayName)

		XCTAssert(try parser.root.evaluate().value == 8)
	}

	func testConstantValues() throws {
		var parser = Parser()

		parser.parseDebug([ "2", "*", "pi" ], printCommand: true)

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		// print(parser.root.displayName)
		XCTAssert(try parser.root.evaluate().value == Double.pi * 2)
	}

	func testPrefixOperations() throws {
		var parser = Parser()

		parser.parseDebug([ "5", "^", "3" ])

		let encoder = JSONEncoder()
		let data = try! encoder.encode(parser.root)
		print(String(data: data, encoding: .utf8)!)

		
		// print(parser.root.displayName)

		XCTAssertEqual(try parser.root.evaluate().value, 125)
	}

	func testUserExpression() throws {
		var parser = Parser()

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

		var parser2 = Parser()

		parser2.parseDebug([ "sum", "1", "->", "2", "->", "+", "2" ])

		let encoder2 = JSONEncoder()
		let data2 = try! encoder2.encode(parser2.expression)
		print(String(data: data2, encoding: .utf8)!)

		// print(parser2.root.displayName)

		XCTAssertEqual(try parser2.expression.evaluate().value, 5)
	}

	func testUserConstant() throws {
		var parser = Parser()
		
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

		var parser2 = Parser()

		parser2.parseDebug([ "twopi", "*", "0.5" ])

		let encoder2 = JSONEncoder()
		let data2 = try! encoder2.encode(parser2.root)
		print(String(data: data2, encoding: .utf8)!)

	
		// print(parser2.root.displayName)

		XCTAssert(try parser2.root.evaluate().value == Double.pi)
	}

	func testLoadFromJson() throws {
		var parser = Parser()

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

final class UserOperation: XCTestCase {
	func testCalcUserConstant() throws {

	}

	func testSaveUserConstant() throws {

	}

	func testCalcUserExpression() throws {

	}

	func testSaveUserExpression() throws {

	}
}

final class APIOperation: XCTestCase {
    func testExpressionVariableLookup() throws {
        var parser = Parser()
        
        parser.parseDebug(["2", "+", BuiltinOperators.variable("x")])
        
        var x = 1
        
        func lookup(_ name: String) -> ExpressionResult? {
            if name == "x" {
                defer {x += 1}
                return .number(Double(x))
            }
            return nil
        }
        
        parser.expression.setVariableLookup(lookup)
        
        XCTAssertEqual(try parser.expression.evaluate().value, 3)
        XCTAssertEqual(try parser.expression.evaluate().value, 4)
        XCTAssertEqual(try parser.expression.evaluate().value, 5)
        XCTAssertEqual(try parser.expression.evaluate().value, 6)
    }
}
