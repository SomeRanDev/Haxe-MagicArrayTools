package mat.generation;

#if macro

using mat.generation.ExprHelpers;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class ForLoop {
	var init: Expr;
	var initVars: Array<Expr>;
	var loops: Array<ForLoopInternals>;
	var result: Null<Expr>;

	var initVarNames: Map<String,Int>;

	public function new() {
		init = macro final result = [];
		initVars = [];
		loops = [];
		result = macro result;
		initVarNames = [];
	}

	public function setCoreIterated(e: Expr) {
		if(loops.length == 0) {
			loops.push(new ForLoopInternals(e));
		} else {
			throw "Cannot assign core-iterated, but for-loops already exist.";
		}
	}

	public function addPreAction(a: Expr, incrementMainVar: Bool = false) {
		for(l in loops) {
			l.addPreAction(a, incrementMainVar);
		}
	}

	public function build() {
		final exprs = loops.map(fl -> fl.build());
		return macro {
			$init;
			@:mergeBlock $b{initVars};
			@:mergeBlock $b{exprs};
			$result;
		}
	}

	public function callModifier(name: String, e: Array<Expr>) {
		switch(name) {
			case "map": if(e.length == 1) map(e[0]);
			case "filter": if(e.length == 1) filter(e[0]);
		}
	}

	public function map(e: Expr) {
		final callbackData = new MagicCallback(e, genName("map"));
		if(callbackData.usedName) usedName("map");
		if(callbackData.init != null) initVars.push(callbackData.init);

		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) final __ = $e2;
		addPreAction(pre, true);
	}

	public function filter(e: Expr) {
		final callbackData = new MagicCallback(e, genName("filter"));
		if(callbackData.usedName) usedName("filter");
		if(callbackData.init != null) initVars.push(callbackData.init);

		final e2 = callbackData.expr;
		final p = e.pos;
		final pre = macro @:pos(p) if(!($e2)) continue;
		addPreAction(pre);
	}

	function genName(str: String) {
		if(!initVarNames.exists(str)) {
			initVarNames[str] = 1;
		}
		final id = initVarNames[str];
		return str + id;
	}
	
	function usedName(str: String) {
		initVarNames[str]++;
	}
}

#end
