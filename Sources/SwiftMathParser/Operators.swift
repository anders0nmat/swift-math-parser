
import Foundation

internal var operators: [String: Evaluable] = buildOperators([
	Expression(),
	EmptyLiteral(),
	VariableLiteral(name: ""),

	GenericPriorityOperator(internalName: "+", priority: 10, argName: { "summand\($0 + 1)" }) { $0.reduce(Double(0)) { $0 + $1 } },
	GenericPriorityOperator(internalName: "*", priority: 40, argName: { "factor\($0 + 1)" }) { $0.reduce(Double(1)) { $0 * $1 } },

	GenericOperator(internalName: "abs", args: ["arg"]) { abs($0[0]) },
	GenericOperator(internalName: "pow", args: ["base", "exponent"]) { pow($0[0], $0[1]) },

	GenericPrefixOperator(internalName: "^", args: ["base", "exponent"]) { pow($0[0], $0[1]) },

	ConstLiteral(internalName: "pi", value: .pi),
])

fileprivate func buildOperators(_ arr: [Evaluable]) -> [String: Evaluable] {
	arr.reduce(into: [String: Evaluable]()) { $0[$1.internalName] = $1 }
}

public func addOperator(_ op: Evaluable) {
	operators[op.internalName] = op
}

public func addOperator(_ container: EvaluableContainer) {
	addOperator(container.expression)
}

public enum BuiltinOperators {
	static let literal = "#number"
	static let empty = "#empty"
	static let expression = "#expr"
	static func variable(_ name: String?) -> String { "#var" + (name != nil ? ":\(name!)" : "") }
}
