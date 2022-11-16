
import Foundation

internal var operators: [String: Evaluable] = buildOperators([
	Expression(),
	EmptyLiteral(),
	VariableLiteral(name: ""),

	GenericPriorityOperator(internalName: "+", priority: 10, argName: { "summand\($0 + 1)" }) { $0.reduce(Double(0)) { $0 + $1 } },
	GenericPriorityOperator(internalName: "-", priority: 15, argName: { $0 == 0 ? "minuend" : "subtrahend\($0)" }) { $0.suffix(from: 1).reduce($0[0]) { $0 - $1 } },
	GenericPriorityOperator(internalName: "*", priority: 40, argName: { "factor\($0 + 1)" }) { $0.reduce(Double(1)) { $0 * $1 } },
	GenericPrefixOperator(internalName: "/", args: ["dividend", "divisor"]) { $0[1] != 0 ? $0[0] / $0[1] : .nan },

	GenericOperator(internalName: "()", args: ["expression"]) { $0[0] },

	GenericOperator(internalName: "abs", args: ["value"]) { abs($0[0]) },

	GenericOperator(internalName: "sin", args: ["value"]) { sin($0[0]) },
	GenericOperator(internalName: "cos", args: ["value"]) { cos($0[0]) },
	GenericOperator(internalName: "tan", args: ["value"]) { tan($0[0]) },

	GenericOperator(internalName: "arcsin", args: ["value"]) { asin($0[0]) },
	GenericOperator(internalName: "arccos", args: ["value"]) { acos($0[0]) },
	GenericOperator(internalName: "arctan", args: ["value"]) { atan($0[0]) },

	GenericOperator(internalName: "exp", args: ["exponent"]) { exp($0[0]) },
	GenericOperator(internalName: "ln", args: ["value"]) { log($0[0]) },

	GenericOperator(internalName: "log10", args: ["value"]) { log10($0[0]) },
	GenericOperator(internalName: "log2", args: ["value"]) { log2($0[0]) },
	GenericOperator(internalName: "logab", args: ["base", "value"]) {
		let logBase = log($0[0])
		let logExp = log($0[1])
		if !logBase.isFinite || logBase == 0 { return .nan }
		return logExp / logBase
	},

	GenericOperator(internalName: "pow", args: ["base", "exponent"]) { pow($0[0], $0[1]) },
	GenericPrefixOperator(internalName: "^", args: ["base", "exponent"]) { pow($0[0], $0[1]) },

	GenericPrefixOperator(internalName: "sqr", args: []) { $0[0] * $0[0] },
	GenericOperator(internalName: "sqrt", args: ["radiant"]) { $0[0].squareRoot() },

	GenericPrefixOperator(internalName: "cbe", args: []) { $0[0] * $0[0] * $0[0] },
	GenericOperator(internalName: "cbrt", args: ["radiant"]) { cbrt($0[0]) },

	ConstLiteral(internalName: "pi", value: Double.pi),
	ConstLiteral(internalName: "e", value: 2.718_281_828_459_045),
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
