package mat.generation;

#if macro

using mat.generation.ExprHelpers;

import haxe.macro.Expr;

class MagicCallback {
	public var expr: Expr;
	public var init: Null<Expr>;

	public var usedName: Bool;

	public function new(e: Expr, name: String) {
		init = null;
		usedName = false;

		var newExpr = e;

		switch(e.expr) {
			case EFunction(k, f): {
				if(k == FArrow && f.expr != null && f.args.length == 1) {
					final funcExpr = f.expr.isReturn();
					if(funcExpr != null) {
						final arg = f.args[0];
						newExpr = {
							pos: e.pos,
							expr: EParenthesis(funcExpr
								.replaceIdentWithUnderscore(arg.name)
								.stripImplicitReturnMetadata())
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
				expr = macro @:pos(p) $i{name}(_);
				usedName = true;
			}
			case EConst(CIdent(str)): {
				if(str == "_") {
					expr = macro @:pos(p) _;
				} else {
					expr = macro @:pos(p) $newExpr(_);
				}
			}
			case EField(_, _): {
				expr = macro @:pos(p) $newExpr(_);
			}
			case _: {
				expr = newExpr;
			}
		}
	}
}

#end
