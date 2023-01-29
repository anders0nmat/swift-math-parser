
public struct Expression: Evaluable {
	public unowned var node: EvaluableTreeNode!
    
    public var variableLookup: ((String) -> ExpressionResult?)?

	public var internalName: String { BuiltinOperators.expression }
    
    public var argumentName: NameFunc { {_ in nil} } // Top level expressions do not need names

	public var nodeType: EvaluableType { .arguments(.oneOrMore) }
    
    public func getVariable(_ name: String) -> ExpressionResult? {
        if let externalLookup = self.variableLookup {
            return externalLookup(name)
        }
        return node.parent?.getVariable(name)
    }

	public func evaluate() throws -> ExpressionResult {
		try node.children!.first!.evaluate()
	}
}
