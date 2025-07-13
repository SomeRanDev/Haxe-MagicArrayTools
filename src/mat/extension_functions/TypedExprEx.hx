package mat.extension_functions;

#if (macro || mat_runtime)

import haxe.macro.Type.TypedExpr;

class TypedExprHelpers {
	public static function unwrapParenthesis(self: TypedExpr) {
		return switch(self.expr) {
			case TMeta(_, inner): unwrapParenthesis(inner);
			case _: self;
		}
	}
}

#end
