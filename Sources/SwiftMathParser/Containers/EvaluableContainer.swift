
public protocol EvaluableContainer: Codable {
	var expression: Evaluable { get }
}

public struct UserConstContainer: EvaluableContainer {
	internal let const: ConstLiteral

	public var expression: Evaluable { const }

	public init(internalName: String, value: Double) {
		self.const = ConstLiteral(internalName: internalName, value: value)
	}

	enum Keys: String, CodingKey {
		case name, value
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: Keys.self)
		try container.encode(const.internalName, forKey: .name)
		try container.encode(const.value, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Keys.self)
		let internalName = try container.decode(String.self, forKey: .name)
		let value = try container.decode(Double.self, forKey: .value)
		self.const = ConstLiteral(internalName: internalName, value: value)
	}
}

public struct UserEvaluableContainer: EvaluableContainer {
	internal let expr: UserEvaluable
	
	public var expression: Evaluable { expr }

	public init(internalName: String, expression: EvaluableTreeNode) throws {
		var argMap: [String:Array.Index] = [:]
		var argName: [String] = []

		if case .function(let args) = try? expression.evaluate() {
			argName = Array(args)
			argMap = argName.enumerated().reduce(into: [String:Array<Any>.Index]()) {
				$0[$1.element] = $1.offset
			}
		} 

		try self.init(internalName: internalName, argName: argName, argMap: argMap, expression: expression)
	}

	public init(internalName: String, argMap: [String:Array.Index], expression: EvaluableTreeNode) throws {
		guard Set(0..<argMap.count) == Set(argMap.values) else { throw ExpressionError.missingArgument("Not all arguments are mapped") }

		let argNames = argMap.reduce(into: [String](repeating: "", count: argMap.count)) { $0[$1.value] = $1.key }
		try self.init(internalName: internalName, argName: argNames, argMap: argMap, expression: expression)
	}

	public init(internalName: String, argName: [String], argMap: [String:Array.Index], expression: EvaluableTreeNode) throws {
		self.expr = try UserEvaluable(internalName: internalName, expr: expression, argMap: argMap, argName: argName)
	}

	enum Keys: String, CodingKey {
		case name, mapping, args, expression
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: Keys.self)
		try container.encode(expr.internalName, forKey: .name)
		try container.encode(expr.argMap, forKey: .mapping)
		try container.encode(expr._argumentName, forKey: .args)
		try container.encode(expr.expr, forKey: .expression)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Keys.self)
		let internalName = try container.decode(String.self, forKey: .name)
		// <Any> of array is mandatory from compiler to use subtype .Index
		// but does not influence anything else
		let argMap = try container.decode([String:Array<Any>.Index].self, forKey: .mapping)
		let argName = try container.decode([String].self, forKey: .args)
		let expr = try container.decode(EvaluableTreeNode.self, forKey: .expression)

		self.expr = try UserEvaluable(internalName: internalName, expr: expr, argMap: argMap, argName: argName)        
	}
}
