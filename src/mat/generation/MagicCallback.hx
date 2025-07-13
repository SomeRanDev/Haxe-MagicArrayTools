package mat.generation;

#if (macro || mat_runtime)

import mat.extension_functions.ExprEx;

import haxe.macro.Expr;

using mat.extension_functions.ExprEx;

/**
	Extracts the function content of a `MagicArrayTools.MagicCallbackExprOf` (`haxe.macro.Expr`)
	to be used in a generated loop.
**/
class MagicCallback {
	public var expr(default, null): Expr;
	public var init(default, null): Null<Expr>;

	public var usedName(default, null): Bool;

	public function new(e: Expr, name: String, argumentCount: Int) {
		expr = macro {}; // Silences null-safety
		init = null;
		usedName = false;

		var newExpr = e;

		switch(e.expr) {
			case EFunction(k, f): {
				if(k == FArrow && f.expr != null && f.args.length == argumentCount) {
					final funcExpr = f.expr.isReturn();
					if(funcExpr != null) {
						final funcExprWithUnderscoreParams = if(argumentCount == 1) {
							final arg = f.args[0];
							funcExpr.replaceIdentWithUnderscore(arg.name);
						} else {
							final argNames = f.args.map(a -> a.name);
							funcExpr.replaceMultipleIdentsWithNumberedUnderscore(argNames);
						}
						newExpr = {
							pos: e.pos,
							expr: EParenthesis(
								funcExprWithUnderscoreParams.stripImplicitReturnMetadata()
							)
						};
					}
				}
			}
			case _:
		}

		final p = newExpr.pos;
		switch(newExpr.expr) {
			case EFunction(k, f): {
				init = {
					pos: p,
					expr: EVars([{
						name: name,
						expr: newExpr
					}])
				};
				expr = generateCall(macro $i{name}, p, argumentCount);
				usedName = true;
			}
			case EConst(CIdent(str)): {
				var found = false;
				if(argumentCount > 1) {
					final index = isNumberedUnderscore(str);
					if(index != null) {
						expr = newExpr;
						found = true;
					}
				} else if(str == "_") {
					expr = newExpr;
					found = true;
				}

				if(!found) {
					expr = generateCall(macro $newExpr, p, argumentCount);
				}
			}
			case EField(_, _): {
				expr = generateCall(macro $newExpr, p, argumentCount);
			}
			case _: {
				expr = newExpr;
			}
		}
	}

	/**
		Wraps `expr` with an `ECall` using the proper underscore arguments based on the
		`argumentCount`.

		For example: `trace` would be converted to `trace(_)` with `argumentCount == 1` or
		`trace(_1, _2, _3)` with `argumentCount == 3`.
	**/
	static function generateCall(expr: Expr, pos: Position, argumentCount: Int) {
		return {
			expr: ECall(expr, generateUnderscoreArguments(argumentCount)),
			pos: pos
		};
	}

	static function generateUnderscoreArguments(argumentCount: Int): Array<Expr> {
		return if(argumentCount == 1) {
			[macro _];
		} else {
			[for(i in 0...argumentCount) macro $i{"_" + (i + 1)}];
		};
	}
}

#end
