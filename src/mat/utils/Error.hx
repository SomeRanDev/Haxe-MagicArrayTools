package mat.utils;

#if (macro || mat_runtime)

import mat.utils.Context;
import haxe.macro.Expr;
import haxe.PosInfos;

/**
	All errors that can occur within this project.
**/
@:using(mat.utils.Error.ErrorHelpers)
enum abstract Error(String) {
	var InvalidStoredTypeId = "`@:storedTypedExpr` `Int` expression identifier was not a valid `Int`. This error should be impossible and may be a Haxe compiler bug, please report.";
	var ExpectedStoredTypeIdAsIntLiteral = "Expected `@:storedTypedExpr` identifier expression as `Int` literal with no suffix. This error should be impossible unless Haxe compiler infrastructure changed, please report.";
	var StoredExprCouldNotBeObtained = "Stored expression data could not be obtained";
	var StoreExprGeneratedUnexpectedExpression = "`Context.storeExpr` returned an expression that wasn't `@:storedTypedExpr X`. This error should be impossible unless Haxe compiler infrastructure changed, please report.";
	var InvalidIterateSubject = "`MagicArrayTools` function was used without calling `magiter` first. Please call `magiter` before running any other functions.";
	var CannotMergeCompleteLoopBuilder = "Cannot merge LoopBuilder that does not return array.";
	var MagiterRequiresKnownType = "`magiter` must be used on an expression with an inferrable type. Please wrap your expression in a colon-cast: `(EXPR : TYPE).magiter()`";
	var UnderscoreInMultiArgumentCallback = "Using underscore identifier (_) in magic callback that has {0} arguments. Please use numbered underscore identifiers to refer to the arguments (_1, _2, etc).";

	public inline function asString(): String {
		return this;
	}

	public inline function toFormattedString(replacements: Array<String>): String {
		var result = this;
		for (i in 0...replacements.length) {
            result = StringTools.replace(result, '{$i}', replacements[i]);
        }
        return result;
	}
}

/**
	Functions that should be called directly on the error cases.

	For example:
	```haxe
	Error.InvalidStoredTypeId.at(expression.pos);
	```
**/
class ErrorHelpers {
	public static function at(error: Error, position: Position): Any {
		return Context.error(error.asString(), position);
	}

	public static function atFormatted(
		error: Error,
		position: Position,
		replacements: Array<String>
	): Any {
		return Context.error(error.toFormattedString(replacements), position);
	}

	public static function currentPos(error: Error): Any {
		return at(error, Context.currentPos());
	}

	public static function here(error: Error): Any {
		throw error.asString();
	}
}

#end
