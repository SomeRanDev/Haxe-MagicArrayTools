package generation;

#if macro

using generation.ExprHelpers;

import haxe.macro.Expr;

function isMeta(e: Expr, metaName: String): Expr {
	switch(e.expr) {
		case EMeta(s, e): {
			if(s.name == metaName) {
				return e;
			}
		}
		case _:
	}
	return null;
}

class GetForResult {
	public var expr: Expr;
	public var exprs: Iterator<Expr>;
	public function new(expr: Expr, exprs: Iterator<Expr>) { this.expr = expr; this.exprs = exprs; }
}

function getFor(e: Expr) {
	return switch(e.expr) {
		case EFor(it, exprs): {
			return new GetForResult(it, exprs.getBlockExprs());
		}
		case _: throw "EFor expected.";
	}
}

function getBlockExprs(e: Expr): Iterator<Expr> {
	return e.getBlockExprsArray().iterator();
}

function getBlockExprsArray(e: Expr): Array<Expr> {
	return switch(e.expr) {
		case EBlock(exprs): {
			exprs;
		}
		case _: throw "EBlock expected.";
	}
}

function getBlockExprsWithMerge(e: Expr): Array<Expr> {
	final mergeExpr = e.isMeta(":mergeBlock");
	if(mergeExpr == null) throw "@:mergeBlock expected.";
	return mergeExpr.getBlockExprsArray();
}

function getNextWithMeta(exprs: Iterator<Expr>, expectedMeta: String): Expr {
	if(!exprs.hasNext()) throw "next Expr expected.";
	final withMetaExpr = exprs.next();
	final e = withMetaExpr.isMeta(expectedMeta);
	if(e == null) throw 'meta @$expectedMeta expected.';
	return e;
}

#end
