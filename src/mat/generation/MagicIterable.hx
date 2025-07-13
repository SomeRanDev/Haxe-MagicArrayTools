package mat.generation;

#if (macro || mat_runtime)

import mat.generation.StoredExprData;

#end

/**
	The results generated from Magic Array Tools' functions are wrapped with
	`mat.generation.MagicIterable`. This ensures the functions can only be called on types after
	using `magiter`.
**/
@:noCompletion extern abstract MagicIterable<T>(T) from T to T {}

/**
	This type is wrapped around the result of `mat.generation.MagicIterable` to store the "for-loop
	object index" in the `haxe.macro.TypedExpr` for access later.
**/
@:noCompletion extern typedef MagicIterableWithData<T, @:const Data: Int> = MagicIterable<T>;

#if (macro || mat_runtime)

/**
	Utility functions relating to `mat.generation.MagicIterable`.
**/
class MagicIterableUtils {
	/**
		Returns a `haxe.macro.Expr.ExprDef.ECheckType` expression that wraps `expression` with
		`mat.generation.MagicIterable.MagicIterableWithData` that has `data` stored it its
		second generic argument.

		The intent of this is to store an arbitrary `data` value that's accessible from the typed
		version of this expression without changing the `haxe.macro.Type.TypedExprDef` contents 
		of said typed expression.
	**/
	public static function wrapExprWithData(
		expression: haxe.macro.Expr,
		complexType: haxe.macro.Expr.ComplexType,
		data: Int
	) {
		// Generate complex type of `MagicIterableWithData`.
		final iterateTypeWithData =
			macro : mat.generation.MagicIterable.MagicIterableWithData<$complexType, -1>;

		// Replace -1 with `data`.
		switch(iterateTypeWithData) {
			case TPath(path) if(path.params != null): {
				#if macro
				path.params[1] = TPExpr(macro $v{data});
				#end
			}
			case _:
		}

		// Wrap `expression` with `haxe.macro.Expr.ExprDef.ECheckType` to store `data` within the
		// type.
		return macro @:privateAccess ($expression : $iterateTypeWithData);
	}

	/**
		Given an `haxe.macro.Expr` that was wrapped by
		`mat.generation.MagicIteratble.wrapExprWithData`, this extracts the `Data` value.

		Returns `-1` if failed to extract due to a lack of typing information or invalid expression.
	**/
	public static function extractDataFromWrapped(ethis: haxe.macro.Expr): Int {
		final storedExprData = StoredExprDataUtils.fromExpr(ethis) ?? return -1;
		return switch(storedExprData.typedExpr.t) {
			case TType(_,
				[_, TInst(_.get() => {
					kind: KExpr({ expr: EConst(CInt(Std.parseInt(_) => v, _)) })
				}, _)]
			) if(v != null): {
				v;
			}
			case _: {
				-1;
			}
		}
	}
}

#end
