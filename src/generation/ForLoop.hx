package generation;

#if macro

using generation.ExprHelpers;

import haxe.macro.Expr;

class ForLoopExpressions {
	var expr: Expr;
	var preActions: Array<Expr>;
	var action: Expr;

	public function new(e: Expr, p: Array<Expr>, a: Expr) {
		expr = e;
		preActions = p;
		action = a;
	}

	public static function fromExpr(e: Expr) {
		final f = e.getFor();
		final expr = f.expr;
		final preExpr = f.exprs.getNextWithMeta("magicForLoopPre");
		final preActions = preExpr.getBlockExprsWithMerge();
		final action = f.exprs.getNextWithMeta("magicForLoopAction");
		return new ForLoopExpressions(expr, preActions, action);
	}

	public function build(): Expr {
		return macro @magicForLoopLoop @:mergeBlock {
			for(it in $expr) {
				@magicForLoopPre @:mergeBlock $b{preActions}
				@magicForLoopAction @:mergeBlock $action;
			}
		}
	}
}

class ForLoop {
	var init: Expr;
	var loops: Array<ForLoopExpressions>;
	var result: Expr;

	public function new(e: Expr) {
		final subExpr = e.isMeta("magicForLoop");
		if(subExpr != null) {
			loadData(subExpr);
		} else {
			initData(e);
		}
	}

	function initData(e: Expr) {
		init = macro final result = [];
		loops = [
			new ForLoopExpressions(e, [], macro result.push(it))
		];
		result = macro result;
	}

	function loadData(e: Expr) {
		final exprs = e.getBlockExprs();
		init = exprs.getNextWithMeta("magicForLoopInit");
		while(exprs.hasNext()) {
			final withMetaExpr = exprs.next();
			final loopExpr = withMetaExpr.isMeta("magicForLoopLoop");
			if(loopExpr != null) {
				loops.push(ForLoopExpressions.fromExpr(loopExpr));
			} else {
				final resultExpr = withMetaExpr.isMeta("magicForLoopResult");
				if(resultExpr == null) throw "Expr with @magicForLoopResult expected.";
				result = resultExpr;
			}
		}
	}

	public function build() {
		final exprs = loops.map(fl -> fl.build());
		return macro @magicForLoop {
			@magicForLoopInit $init;
			$b{exprs};
			@magicForLoopResult $result;
		}
	}
}

#end
