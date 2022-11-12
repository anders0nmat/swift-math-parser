
public struct Expression: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var internalName: String { BuiltinOperators.expression }

	public var nodeType: EvaluableType { .arguments(.oneOrMore) }

	public func evaluate() throws -> ExpressionResult {
		try node.children!.first!.evaluate()
	}
}
