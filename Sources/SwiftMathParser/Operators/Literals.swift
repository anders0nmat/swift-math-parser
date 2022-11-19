
public struct NumberLiteral: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var internalName: String { BuiltinOperators.literal }

	public var value: Double {
		Double("\(sign == .plus ? "+" : "-")\(valueString)\(valueString.last == "." ? "0" : "")") ?? .nan
	}

	internal var valueString: String
	internal var sign: FloatingPointSign

	public init(_ value: Double) {
		self.init(String(value.magnitude), sign: value.sign)
	}

	public init(_ value: String) {
		self.init(value, sign: value.first == "-" ? .minus : .plus)
	}

	public init(_ value: String = "0", sign: FloatingPointSign) {
		if value.first == "+" || value.first == "-" {
			self.valueString = String(value.suffix(from: value.index(after: value.startIndex)))
		}
		else {
			self.valueString = value
		}
		self.sign = sign
	}

	internal mutating func addDigit(_ digit: String) -> Bool {
		if Double(valueString + digit + (digit.last == "." ? "0" : "")) != nil {
			valueString += digit
			return true
		}
		return false
	}

	public mutating func processArgs(_ args: [String]) {
		if let num = Double(args.first ?? "") {
			self.sign = num.sign
			self.valueString = String(num.magnitude)
		}
	}

	public func evaluate() throws -> ExpressionResult { .number(value) }

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}
}

public struct EmptyLiteral: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var internalName: String { BuiltinOperators.empty }

	public func evaluate() throws -> ExpressionResult {
		throw ExpressionError.missingArgument(at: node)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(internalName)
	}
}

public struct ConstLiteral: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var internalName: String

	internal var value: Double

	init(internalName: String, value: Double) {
		self.internalName = internalName
		self.value = value
	}

	public func evaluate() throws -> ExpressionResult { .number(value) }
}

public struct VariableLiteral: Evaluable {
	public unowned var node: EvaluableTreeNode!

	public var internalName: String { BuiltinOperators.variable(nil) }

	internal var variableName: String

	init(name: String) {
		self.variableName = name
	}

	public func evaluate() throws -> ExpressionResult {
		if let resultNode = node.getVariable(variableName) {
			return try resultNode.evaluate()
		}
		return .function([variableName])
	}

	public mutating func processArgs(_ args: [String]) {
		if let name = args.first {
			self.variableName = name
		}
		else {
			self.variableName = "x" 
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(BuiltinOperators.variable(variableName))
	}

	// Not needed because it is encoded as argument string. Handled by processArgs
	// public func decode(from decoder: Decoder)
}
