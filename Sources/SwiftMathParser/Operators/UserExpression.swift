
struct UserEvaluable: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var nodeType: EvaluableType { _nodeType }
	internal var _nodeType: EvaluableType

	public var internalName: String

	public var argumentName: NameFunc { { _argumentName.indices ~= $0 ? _argumentName[0] : nil } }
	internal var _argumentName: [String]

	internal var argMap: [String:Array.Index]

	internal var expr: EvaluableTreeNode /* x * 4 + y + z ^ w */

	init(internalName: String, expr: EvaluableTreeNode, argMap: [String:Array.Index], argName: [String]) throws {
		self.internalName = internalName
        self.expr = expr.copy()
        
		// self.expr.parent = node // Done while evaluating
		self.argMap = argMap
		self._argumentName = argName

		switch try self.expr.evaluate() {
			case .number(_):
				self._nodeType = .arguments(0)
			case .function(let args):
				if args != Set(argMap.keys) { throw ExpressionError.missingArgument("not all arguments are mapped") }
				let diffIndices = Set(argMap.values).symmetricDifference(0..<args.count)

				if diffIndices.count != 0 { throw ExpressionError.missingArgument("orphan children or indices out of range") }
				self._nodeType = .arguments(args.count)
		}
	}

	func evaluate() throws -> ExpressionResult {
		expr.parent = node
		defer { expr.parent = nil }
		return try expr.evaluate()
	}

	public func getVariable(_ name: String) -> ExpressionResult? {
		if let idx = argMap[name], node.children != nil, node.children!.indices ~= idx {
            return try? node.children![idx].evaluate()
		}
        return node.parent?.getVariable(name)
	}
}
