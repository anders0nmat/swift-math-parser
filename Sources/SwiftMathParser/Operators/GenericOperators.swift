
public struct GenericOperator: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var nodeType: EvaluableType { .arguments(argCount) }
	internal var argCount: ArgumentCount

	public var internalName: String

	public var argumentName: NameFunc

	internal var expression: ([Double]) -> Double

	public init(internalName: String, args: [String], expression: @escaping ([Double]) -> Double) {
		self.internalName = internalName
		self.argCount = args.count
		self.expression = expression
		self.argumentName = { args.indices ~= $0 ? args[$0] : nil }
	}

	public init(internalName: String, argCount: ArgumentCount,argName: @escaping NameFunc, expression: @escaping ([Double]) -> Double) {
		self.internalName = internalName
		self.argCount = argCount
		self.expression = expression
		self.argumentName = argName
	}

	public func evaluate() throws -> ExpressionResult {
		if node.children == nil { throw ExpressionError.missingArgument("nil arguments on operation", at: node) }
		if argCount > 0 && node.children!.count != argCount { throw ExpressionError.missingArgument("expected \(argCount) got: \(node.children!.count)", at: node) }
		if argCount == .oneOrMore && node.children!.count < 1 { throw ExpressionError.missingArgument("expected at least 1 argument but got less", at: node) }

		var argValues: [Double] = []
		var variables: Set<String> = []
		try node.children!.forEach {
			switch try $0.evaluate() {
				case .number(let value): argValues.append(value)
				case .function(let args): variables.formUnion(args)
			}
		}

		if !variables.isEmpty { return .function(variables) }

		return .number(expression(argValues))
	}
}

public struct GenericPrefixOperator: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var nodeType: EvaluableType { .prefixArgument(argCount) }
	internal var argCount: ArgumentCount

	public var internalName: String

	public var argumentName: NameFunc

	internal var expression: ([Double]) -> Double

	public init(internalName: String, args: [String], expression: @escaping ([Double]) -> Double) {
		self.internalName = internalName
		self.argCount = args.count - 1
		self.expression = expression
		self.argumentName = { args.indices ~= $0 ? args[$0] : nil }
	}

	public init(internalName: String, argCount: ArgumentCount, argName: @escaping NameFunc, expression: @escaping ([Double]) -> Double) {
		self.internalName = internalName
		self.argCount = argCount
		self.expression = expression
		self.argumentName = argName
	}

	public func evaluate() throws -> ExpressionResult {
		if node.children == nil { throw ExpressionError.missingArgument("nil arguments on prefix operation", at: node) }
		if argCount >= 0 && node.children!.count != argCount + 1 { throw ExpressionError.missingArgument("expected \(argCount + 1) got: \(node.children!.count)", at: node) }
		if argCount == .oneOrMore && node.children!.count < 2 { throw ExpressionError.missingArgument("expected at least 1 argument but got less", at: node) }

		var argValues: [Double] = []
		var variables: Set<String> = []
		try node.children!.forEach {
			switch try $0.evaluate() {
				case .number(let value): argValues.append(value)
				case .function(let args): variables.formUnion(args)
			}
		}

		if !variables.isEmpty { return .function(variables) }

		return .number(expression(argValues))
	}
}

public struct GenericPriorityOperator: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var nodeType: EvaluableType { .priority(priority) }
	internal var priority: UInt

	public var internalName: String

	public var argumentName: NameFunc

	internal var expression: ([Double]) -> Double

	public init(internalName: String, priority: UInt, argName: @escaping NameFunc, expression: @escaping ([Double]) -> Double) {
		self.internalName = internalName
		self.priority = priority
		self.expression = expression
		self.argumentName = argName
	}

	// public func willAdd(_ node: EvaluableTreeNode) -> (toInsert: [EvaluableTreeNode], toContinue: EvaluableTreeNode?)? {
	// 	if type(of: node.value) == Self.self && node.value.internalName == self.internalName {
	// 		return node.children != nil ? (toInsert: node.children!, toContinue: self.node) : nil
	// 	}
	// 	else {
	// 		return ([node], nil)
	// 	}
	// }

	public func evaluate() throws -> ExpressionResult {
		guard let children = node.children else { throw ExpressionError.missingArgument("nil Arguments for operation", at: node) }
		var argValues: [Double] = []
		var variables: Set<String> = []
		try children.forEach {
			switch try $0.evaluate() {
				case .number(let value): argValues.append(value)
				case .function(let args): variables.formUnion(args)
			}
		}

		if !variables.isEmpty { return .function(variables) }

		return .number(expression(argValues))
	}
}
