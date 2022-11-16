
final public class EvaluableTreeNode: Codable {
	public weak var parent: EvaluableTreeNode?
	public var children: [EvaluableTreeNode]?

	public var value: Evaluable


		
	init(value: Evaluable, parent: EvaluableTreeNode? = nil, children: [EvaluableTreeNode]? = nil) {
		self.value = value
		self.value.node = self
		self.parent = parent
		if let children = children {
			self.children = children
			children.forEach {
				$0.parent = self
			}
		}
		else {
			switch self.value.nodeType {
				case .priority(_): self.children = []
				case .arguments(let count):
					if count == .zeroOrMore {
						self.children = []
					}
					else if count == .oneOrMore {
						self.children = [EvaluableTreeNode(value: EmptyLiteral(), parent: self)]
					}
					else if count > 0 {
						self.children = Array(0..<count).map { _ in EvaluableTreeNode(value: EmptyLiteral(), parent: self) }
					}
				case .prefixArgument(let count):
					if count == .zeroOrMore {
						self.children = [EvaluableTreeNode(value: EmptyLiteral(), parent: self)]
					}
					else if count == .oneOrMore {
						self.children = Array(0..<2).map { _ in EvaluableTreeNode(value: EmptyLiteral(), parent: self) }
					}
					else if count > 0 {
						self.children = Array(0..<(count + 1)).map { _ in EvaluableTreeNode(value: EmptyLiteral(), parent: self) }
					}
			}
		}
	}

	/* Convenience call for Evaluable */
	public func evaluate() throws -> ExpressionResult { try value.evaluate() }
	public func getVariable(_ name: String) -> EvaluableTreeNode? { value.getVariable(name) }

	internal func willAdd(_ node: EvaluableTreeNode) -> (toInsert: [EvaluableTreeNode], toContinue: EvaluableTreeNode?)? {
		switch value.nodeType {
			case .priority(_):
				if type(of: node.value) == type(of: value) && node.value.internalName == value.internalName {
					return node.children != nil ? (toInsert: node.children!, toContinue: self) : nil
				}
				else {
					return ([node], nil)
				}
			default: return ([node], nil)
		}
	}

	/* Tree functions */
	@discardableResult func add(_ child: EvaluableTreeNode) -> EvaluableTreeNode? {
		guard children != nil else { return nil }

		if let toAdd = willAdd(child) {
			children!.append(contentsOf: toAdd.toInsert)
			toAdd.toInsert.forEach { $0.parent = self }
			return toAdd.toContinue ?? toAdd.toInsert.last
		}
		return nil		
	}

	@discardableResult func insertParent(_ new: EvaluableTreeNode) -> EvaluableTreeNode? {
		guard let parent = parent else { return nil }

		new.add(self)
		return parent.replace(child: self, with: new)
	}

	@discardableResult func replace(child old: EvaluableTreeNode, with new: EvaluableTreeNode) -> EvaluableTreeNode? {
		guard children != nil else { return nil }
		guard let idx = find(old) else { return nil }

		if let toAdd = willAdd(new) {
			children!.replaceSubrange(idx...idx, with: toAdd.toInsert)
			toAdd.toInsert.forEach { $0.parent = self }
			return toAdd.toContinue ?? toAdd.toInsert.last
		}
		return nil
	}

	@discardableResult func replace(with new: EvaluableTreeNode) -> EvaluableTreeNode? { parent?.replace(child: self, with: new) }

	func find(_ child: EvaluableTreeNode) -> Array.Index? { children?.firstIndex(where: { $0 === child }) }

	func copy() -> EvaluableTreeNode {
		let node = EvaluableTreeNode(value: value)
		node.children = nil
		if children != nil {
			node.children = self.children!.map { 
				let child = $0.copy()
				child.parent = node	
				return child
			}
		}

		return node
	}
	

	/* Convenience Tree modifiers for use with Evaluable Objects */
	@discardableResult func add(_ child: Evaluable) -> EvaluableTreeNode? { add(EvaluableTreeNode(value: child)) }

	@discardableResult func insertParent(_ new: Evaluable) -> EvaluableTreeNode? { insertParent(EvaluableTreeNode(value: new)) }

	@discardableResult func replace(child old: EvaluableTreeNode, with new: Evaluable) -> EvaluableTreeNode? { replace(child: old, with: EvaluableTreeNode(value: new)) }

	@discardableResult func replace(with new: Evaluable) -> EvaluableTreeNode? { replace(with: EvaluableTreeNode(value: new))}

	/* Codable conformance */

	public init(from decoder: Decoder) throws {
		if let container = try? decoder.container(keyedBy: EvaluableCodingKeys.self) {
			// let container = try decoder.container(keyedBy: EvaluableCodingKeys.self)
			let internalName = try container.decode(String.self, forKey: .type)
			if let op = operators[internalName] {
				self.value = op
				self.value.node = self
				try self.value.decode(from: decoder)
			}
			else {
				throw ExpressionError.unknownOperation(internalName)
			}

			var childArr = try container.nestedUnkeyedContainer(forKey: .children)
			self.children = []
			while !childArr.isAtEnd {
				let newNode = try EvaluableTreeNode(from: childArr.superDecoder())
				newNode.parent = self
				self.children?.append(newNode)
			}
		}
		else {
			// No object to be found, assume literal value
			let singleValue = try decoder.singleValueContainer()
			if let number = try? singleValue.decode(Double.self) {
				self.value = NumberLiteral(number)
				self.value.node = self
			}
			else if let command = try? singleValue.decode(String.self) {
				let parts: [String] = command.split(separator: ":").map { String($0) }
				guard !parts.isEmpty else { throw ExpressionError.unknownOperation(command) }
				if let op = operators[parts[0]] {
					self.value = op
					self.value.node = self
					self.value.processArgs([String](parts.suffix(from: 1)))
				}
				else {
					throw ExpressionError.unknownOperation(parts[0], args: [String](parts.suffix(from: 1)))
				}
			}
			else {
				throw ExpressionError.unknownError("Unknown single value type")
			}
		}
		
	}

	public func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}

	/* Parsing & Processing */

	public func parse(state: ParsingState, insertAt: EvaluableTreeNode? = nil) throws -> EvaluableTreeNode {
		switch value.nodeType {
			case .arguments(_):
				switch state {
					case .empty(let node):
						if let newNode = node.replace(with: self) { return try newNode.nextArg(after: newNode.parent) }
						throw ExpressionError.invalidInsertion("Can't replace Empty Node", at: node)
					case .operation(let node), .priority(let node):
						throw ExpressionError.invalidInsertion(
							"Can't insert \(String(describing: value.self)) here",
							at: node
						)
				}
			case .priority(_):
				switch state {
					case .empty(let node): 
						throw ExpressionError.invalidInsertion("Can't insert \(String(describing: value.self)) here", at: node)
					default:
						if let new = insertAt?.insertParent(self)?.add(EmptyLiteral()) {
							return new
						}
						throw ExpressionError.invalidInsertion(
							"Can't insert \(String(describing: value.self)) here. Did priority resolution fail?",
							at: insertAt
						)
				}
			case .prefixArgument(_):
				switch state {
					case .empty(let node):
						if let new = node.replace(with: self) {
							return try new.nextArg(after: new.parent)
						}
						throw ExpressionError.invalidInsertion("Can't replace Empty Node", at: node)
					case .operation(let node):
						if let new = node.insertParent(self) {
							if new.children != nil && !new.children!.isEmpty {
								new.children![0] = new.children!.popLast()!
								return try new.nextArg(after: node)
							}
							throw ExpressionError.invalidInsertion(
								"\(String(describing: value.self)) has no children", at: new
							)
						}
						throw ExpressionError.invalidInsertion(
							"Can't insert \(String(describing: value.self)) here", at: node
						)
					case .priority(let node):
						throw ExpressionError.invalidInsertion(
							"Can't insert \(String(describing: value.self)) here", at: node
						)
				}
		}
		
	}

	public func nextArg(after prev: EvaluableTreeNode?) throws -> EvaluableTreeNode {
		if prev == nil || children == nil || children!.isEmpty { return self }
		if prev === parent { return children!.first! }

		if prev === children!.last {
			switch value.nodeType {
				case .priority(_): return parent == nil ? self : try parent!.nextArg(after: self)
				default: return self
			}
		}

		if let idx = find(prev!) { return children![idx + 1] }
			throw ExpressionError.advanceArgument("\(String(describing: prev!)) is no child/parent of self", at: self)
	}
}
