package mat.generation;

#if (macro || mat_runtime)

import mat.utils.Error;

import mat.utils.Context;
import haxe.macro.Expr.Expr;
import haxe.macro.Type.TypedExpr;

/**
	Contains data regarding a single, stored expression.

	`typedExpr` is the typed representation of the expression.

	`placeholder` is the Haxe-compiler provided `@:storedTypedExpr X` untyped placeholder
	expression.

	`storedId` is `X` from the `placeholder` expression. Essentially, it's the index of the stored
	typed expression. 
**/
typedef StoredExprData = {
	typedExpr: TypedExpr,
	placeholder: Expr,
	storedId: Int
};

/**
	Utility functions relating to `mat.generation.StoredExprData`.
**/
class StoredExprDataUtils {
	/**
		Given an untyped expression, this function returns its `StoredExprData`.

		If the expression is a normal, untyped expression, it will be typed and stored.

		If the expression is already a stored placeholder (`@:storedTypedExpr X`), the typed
		expression will be retrieved with a new valid placeholder.
	**/
	public static function fromExpr(expression: Expr, isRecursive: Bool = false): Null<StoredExprData> {
		return switch(expression.expr) {
			case EMeta({name: ":storedTypedExpr", params: []}, idExpr): {
				final typedExpr = Context.typeExpr(expression);
				{
					typedExpr: typedExpr,

					// Originally, I just placed `expression` here, but that would result in a
					// Haxe compiler error: `Not_found`. Re-storing it seems to work though.
					placeholder: Context.storeTypedExpr(typedExpr),
					storedId: getStoredIdFromLiteralExpr(idExpr)
				};
			}
			case _ if(!isRecursive): {
				fromExpr(Context.storeExpr(expression), isRecursive);
			}
			case _: {
				Error.StoreExprGeneratedUnexpectedExpression.here();
				null;
			}
		}
	}

	static function getStoredIdFromLiteralExpr(expression: Expr): Int {
		return switch(expression) {
			case { expr: EConst(CInt(v, "" | null)) }: {
				Std.parseInt(v) ?? Error.InvalidStoredTypeId.here();
			}
			case _: {
				Error.ExpectedStoredTypeIdAsIntLiteral.here();
			}
		}
	}
}

#end
