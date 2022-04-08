package mat.generation;

#if macro

import haxe.macro.Expr;

class MagicCallback {
	public var expr: Expr;
	public var init: Null<Expr>;

	public var usedName: Bool;

	public function new(e: Expr, name: String) {
		init = null;
		usedName = false;

		final p = e.pos;
		switch(e.expr) {
			case EFunction(k, f): {
				init = {
					pos: p,
					expr: EVars([{
						name: name,
						expr: e
					}])
				};
				expr = macro @:pos(p) $i{name}(_);
				usedName = true;
			}
			case EConst(CIdent(str)): {
				if(str == "_") {
					expr = macro @:pos(p) _;
				} else {
					expr = macro @:pos(p) $e(_);
				}
			}
			case EField(_, _): {
				expr = macro @:pos(p) $e(_);
			}
			case _: {
				expr = e;
			}
		}
	}
}

#end
