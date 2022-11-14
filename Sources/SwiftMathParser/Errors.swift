
public enum ExpressionError: Error {
	case missingArgument(String = "", at: EvaluableTreeNode? = nil)
	case advanceArgument(String, at: EvaluableTreeNode? = nil)
	case invalidInsertion(String, at: EvaluableTreeNode? = nil)

	case unknownOperation(String, args: [String]? = nil)

	case unknownError(String)
}
