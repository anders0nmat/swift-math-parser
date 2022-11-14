
public protocol Evaluable {
	var node: EvaluableTreeNode! { get set }
	var nodeType: EvaluableType { get }

	var internalName: String { get }

	var argumentName: NameFunc { get }

	func evaluate() throws -> ExpressionResult
	func getVariable(_ name: String) -> EvaluableTreeNode?

	mutating func processArgs(_ args: [String])

	func encode(to encoder: Encoder) throws
	mutating func decode(from decoder: Decoder) throws
}

public enum EvaluableCodingKeys: String, CodingKey {
	case type = "type"
	case children = "children"
}

extension Evaluable {
	public var nodeType: EvaluableType { .arguments(0) }

	public var argumentName: NameFunc { { "arg\($0 + 1)" } }

	public func getVariable(_ name: String) -> EvaluableTreeNode? { node?.parent?.getVariable(name) }

	public mutating func processArgs(_ args: [String]) {}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: EvaluableCodingKeys.self)
		try container.encode(internalName, forKey: .type)
		if node.children != nil {
			try container.encode(node.children!, forKey: .children)
		}
	}

	public mutating func decode(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: EvaluableCodingKeys.self)
		let storedName = try container.decode(String.self, forKey: .type)
		if storedName != internalName { throw ExpressionError.unknownOperation(storedName) }
		node.children = try container.decodeIfPresent([EvaluableTreeNode].self, forKey: .children)
	}
}

public enum ExpressionResult: Equatable {
	case number(Double)
	case function(Set<String>)

	public var value: Double {
		switch self {
			case .number(let value): return value
			case .function(_): return Double.nan
		}
	}
}

public enum EvaluableType: Equatable {
	/**
		Infix operators with variable argument count and insertion with respect to priority

		arg0 <op> arg1 <op> arg2

		example: 1 + 1 + 1
	*/
	case priority(UInt)
	/**
		Prefix operator with customizable argument count (0, n, any, any + 1)

		<op>(arg0, arg1, arg2)

		example: atan2(1, -2)
	*/
	case arguments(ArgumentCount)
	/**
		Infix operator with customizable argument count (>= 1) where first argument is in front of operator
		ArgumentCount counts the *additional* arguments after the prefix one

		arg0 <op>(arg1, arg2)

		example: 2 ^ 4
	*/
	case prefixArgument(ArgumentCount)
}

public typealias ArgumentCount = Int

extension ArgumentCount {
	static let zeroOrMore: ArgumentCount = -1
	static let oneOrMore: ArgumentCount = -2
}

public typealias NameFunc = (Array.Index) -> String?
