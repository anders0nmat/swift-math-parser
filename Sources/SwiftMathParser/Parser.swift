
public enum ParsingState {
	case empty(EvaluableTreeNode)
    /// Includes Numbers and Variables
	case operation(EvaluableTreeNode)
	case priority(EvaluableTreeNode)
}

/*
public final class Parser {
	internal var root: EvaluableTreeNode
	internal weak var currNode: EvaluableTreeNode?

	public var expression: EvaluableTreeNode { root }

	public init() {
		root = EvaluableTreeNode(value: Expression())
		currNode = root.children!.first!
	}

	func advanceArgument() throws {
		if let currParent = currNode?.parent {
			self.currNode = try currParent.nextArg(after: currNode)
		}
	}

	public func parse(token: String, args: [String] = []) throws {
		guard let currNode = currNode else { throw ExpressionError.unknownError("Current Node is nil") }

		let currState: ParsingState!
		switch currNode.value.nodeType {
			case .priority(_): currState = .priority(currNode)
			case .arguments(_) where currNode.value is EmptyLiteral: currState = .empty(currNode)
			default: currState = .operation(currNode)
		}

		if let number = Double(token) {
			var num = NumberLiteral(number)
			num.processArgs(args)
			self.currNode = try EvaluableTreeNode(value: num).parse(state: currState)
		}
		else if var op = operators[token] {
			switch op.nodeType {
				case .priority(let rightPrio):
					op.processArgs(args)

					if case .priority(var leftPrio) = currNode.parent?.value.nodeType {
						// We are currently expecting a Binary Op
						var insertPoint: EvaluableTreeNode? = currNode.parent
						while case .priority(let parentPrio) = insertPoint?.parent?.value.nodeType, leftPrio > rightPrio {
							insertPoint = insertPoint!.parent
							leftPrio = parentPrio
						}

						if leftPrio <= rightPrio {
							self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: insertPoint?.children?.last)
						}
						else {
							self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: insertPoint)
						}
					}
					else {
						// Matches Operation and NumberLiteral
						self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: currNode)
					}
				case .arguments(_), .prefixArgument(_):
					op.processArgs(args)
					self.currNode = try EvaluableTreeNode(value: op).parse(state: currState)
			}
		}
		else if token == "->" {
			// point currNode to next argument
			try advanceArgument()
		}
		else {
			throw ExpressionError.unknownOperation("\(token)", args: args)
		}
	}

	public func parse(_ command: String) throws {
		let parts: [String] = command.split(separator: ":").map { String($0) }
		guard !parts.isEmpty else { throw ExpressionError.unknownOperation(command) }
		try parse(token: parts[0], args: [String](parts.suffix(from: 1)))
	}

	public func parse(_ commands: [String]) throws {
		for cmd in commands { try parse(cmd) }
	}

	public func parseDebug(token: String, args: [String] = [], printCommand: Bool = true) {
		do {
			if printCommand { print(">>>", token) }
			try parse(token: token, args: args)
		}
		catch ExpressionError.invalidInsertion(let msg, let at), ExpressionError.advanceArgument(let msg, let at) {
			print("ERROR:", msg, "at", at as Any)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}
	}

	public func parseDebug(_ command: String, printCommand: Bool = true) {
		do {
			if printCommand { print(">>>", command)}
			try parse(command)
		}
		catch ExpressionError.invalidInsertion(let msg, let at), ExpressionError.advanceArgument(let msg, let at) {
			print("ERROR:", msg, "at", at as Any)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}
	}

	public func parseDebug(_ commands: [String], printCommand: Bool = true) {
		for cmd in commands { parseDebug(cmd, printCommand: printCommand) }
	}
}

*/

/*

Maybe needed for CalculatorEngine in SwiftUI

public struct Parser {}

Also need infrastructure to give every evaluable a renderer function

*/

/**
	Parses String commands into a Math Expression Tree

	New commands can be added via the global addOperator() function.
	Some reserved commands are:
	"->" : Jumps to the next argument
	"+-" : Inverts the sign of the current number
	Any Number || "." : Will be inserted as (or appended to) the current number
*/
public struct Parser {
	internal var root: EvaluableTreeNode
	internal weak var currNode: EvaluableTreeNode?

	public var expression: EvaluableTreeNode { root }

	public init() {
		root = EvaluableTreeNode(value: Expression())
		currNode = root.children!.first!
	}

	mutating func advanceArgument() throws {
		if let currParent = currNode?.parent {
			self.currNode = try currParent.nextArg(after: currNode)
		}
	}

	public mutating func parse(token: String, args: [String] = []) throws {
		guard let currNode = currNode else { throw ExpressionError.unknownError("Current Node is nil") }

		let currState: ParsingState!
		switch currNode.value.nodeType {
			case .priority(_): currState = .priority(currNode)
			case .arguments(_) where currNode.value is EmptyLiteral: currState = .empty(currNode)
			default: currState = .operation(currNode)
		}

		if Double(token) != nil || token.allSatisfy({ "0"..."9" ~= $0 || $0 == "." }) {
			if var modifiedValue = currNode.value as? NumberLiteral, modifiedValue.addDigit(token) {
				// Append
				currNode.value = modifiedValue
			}
			else if Double(token) != nil {
				// Create & Insert
				var num = NumberLiteral(token)
				num.processArgs(args)
				self.currNode = try EvaluableTreeNode(value: num).parse(state: currState)
			}
			else {
				// Malformed number e.g. "0.4.1"
				throw ExpressionError.invalidInsertion("Malformed number \(token)", at: currNode)
			}
		}
		else if token == "->" {
			// point currNode to next argument
			try advanceArgument()
		}
		else if token == "+-" && currNode.value is NumberLiteral {
			var modifiedValue = currNode.value as! NumberLiteral
			modifiedValue.sign = modifiedValue.sign == .minus ? .plus : .minus
			currNode.value = modifiedValue
		}
		else if var op = operators[token] {
			switch op.nodeType {
				case .priority(let rightPrio):
					op.processArgs(args)

					if case .priority(var leftPrio) = currNode.parent?.value.nodeType {
						// We are currently expecting a Binary Op
						var insertPoint: EvaluableTreeNode? = currNode.parent
						while case .priority(let parentPrio) = insertPoint?.parent?.value.nodeType, leftPrio > rightPrio {
							insertPoint = insertPoint!.parent
							leftPrio = parentPrio
						}

						if leftPrio <= rightPrio {
							self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: insertPoint?.children?.last)
						}
						else {
							self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: insertPoint)
						}
					}
					else {
						// Matches Operation and NumberLiteral
						self.currNode = try EvaluableTreeNode(value: op).parse(state: currState, insertAt: currNode)
					}
				case .arguments(_), .prefixArgument(_):
					op.processArgs(args)
					self.currNode = try EvaluableTreeNode(value: op).parse(state: currState)
			}
		}
		else {
			throw ExpressionError.unknownOperation("\(token)", args: args)
		}
	}

	public mutating func parse(_ command: String) throws {
		let parts: [String] = command.split(separator: ":").map { String($0) }
		guard !parts.isEmpty else { throw ExpressionError.unknownOperation(command) }
		try parse(token: parts[0], args: [String](parts.suffix(from: 1)))
	}

	public mutating func parse(_ commands: [String]) throws {
		for cmd in commands { try parse(cmd) }
	}

	public mutating func parseDebug(token: String, args: [String] = [], printCommand: Bool = true) {
		do {
			if printCommand { print(">>>", token) }
			try parse(token: token, args: args)
		}
		catch ExpressionError.invalidInsertion(let msg, let at), ExpressionError.advanceArgument(let msg, let at) {
			print("ERROR:", msg, "at", at as Any)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}
	}

	public mutating func parseDebug(_ command: String, printCommand: Bool = true) {
		do {
			if printCommand { print(">>>", command)}
			try parse(command)
		}
		catch ExpressionError.invalidInsertion(let msg, let at), ExpressionError.advanceArgument(let msg, let at) {
			print("ERROR:", msg, "at", at as Any)
		}
		catch {
			print("UNEXPECTED ERROR: \(error)")
		}
	}

	public mutating func parseDebug(_ commands: [String], printCommand: Bool = true) {
		for cmd in commands { parseDebug(cmd, printCommand: printCommand) }
	}
}

