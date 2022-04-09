package mat.generation;

#if macro

import haxe.macro.Expr;

using mat.generation.ExprHelpers;

function parseStaticCalls(e: Expr) {
	final fl = new ForLoop();
	parseStaticCall(e, fl);
	return fl;
}

function parseStaticCall(e: Expr, fl: ForLoop) {
	 switch(e.expr) {
		case ECall(eCall, params): {
			final name = isMagicArrayToolsFunction(eCall);
			if(name != null) {
				final target = params[0];
				final callData = parseStaticCall(target, fl);
				if(!callData) {
					fl.setCoreIterated(target);
				}
				fl.callModifier(name, params.slice(1), e.pos);
				return true;
			}
		}
		case _:
	}
	return false;
}

function isMagicArrayToolsFunction(e: Expr): Null<String> {
	switch(e.expr) {
		case EField(i, f): {
			if(isMagicArrayTools(i)) {
				return f;
			}
		}
		case _:
	}
	return null;
}

function isMagicArrayTools(e: Expr) {
	return switch(e.expr) {
		case EConst(i): {
			switch(i) {
				case CIdent(c): c == "MagicArrayTools";
				case _: false;
			}
		}
		case _: false;
	}
}
#end