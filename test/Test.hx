package;

using MagicArrayTools;

var failedAsserts = 0;

function assert(b: Bool, ?pos: haxe.PosInfos) {
	if(!b) {
		haxe.Log.trace("assert failed.", pos);
		failedAsserts++;
	}
}

function assertEquals<T>(a1: Array<T>, a2: Array<T>, ?pos: haxe.PosInfos) {
	var result = a1.length == a2.length;
	if(result) {
		for(i in 0...a1.length) {
			if(a1[i] != a2[i]) {
				result = false;
				break;
			}
		}
	}
	if(!result) {
		haxe.Log.trace("assert failed. " + a1 + " != " + a2 + "\n", pos);
		failedAsserts++;
	}
}

function main() {
	haxe.Log.trace("\033[32mTesting [Magic Array Tools]\n\033[0;37m", null);

	//**********************************************
	// * map
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.magiter().map(_), arr);
		assertEquals(arr.magiter().map(i -> i), arr);
		assertEquals(arr.magiter().map(function(i) { return i; }), arr);

		final arrStr = ["1", "2", "3", "4", "5"];

		assertEquals(arr.magiter().map("" + _), arrStr);
		assertEquals(arr.magiter().map(Std.string), arrStr);
		assertEquals(arr.magiter().map((i:Int) -> "" + i), arrStr);
		assertEquals(arr.magiter().map(function(i:Int) { return "" + i; }), arrStr);
	}

	//**********************************************
	// * filter
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.magiter().filter((true)), arr);
		assertEquals(arr.magiter().filter(i -> true), arr);

		assertEquals(arr.magiter().filter((false)), []);
		assertEquals(arr.magiter().filter(i -> false), []);

		final arr2 = [3, 4, 5];

		assertEquals(arr.magiter().filter(_ >= 3), arr2);
		assertEquals(arr.magiter().filter(i -> i >= 3), arr2);

		final arr3 = ["1"];

		assertEquals(arr.magiter().filter(_ == 1).map("" + _), arr3);
		assertEquals(arr.magiter().filter(i -> i == 1).map((i:Int) -> "" + i), arr3);
		assertEquals(arr.magiter().map("" + _).filter(_ == "1"), arr3);
		assertEquals(arr.magiter().map((i:Int) -> "" + i).filter(i -> i == "1"), arr3);
	}

	//**********************************************
	// * forEach
	//**********************************************
	{
		final arr = [1, 2, 3];

		var counter = 0;
		arr.magiter().forEach(counter++);

		assert(counter == 3);
	}

	//**********************************************
	// * forEachThen
	//**********************************************
	{
		final arr = [1, 2, 3];

		var counter = 0;
		arr.magiter().forEachThen(counter++);

		assert(counter == 3);
	}

	//**********************************************
	// * size
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().size() == arr.length);
		assert(arr.magiter().filter(_ < 3).size() == 2);
		assert(arr.magiter().map("" + _).size() == 5);
		assert(arr.magiter().filter(i -> false).size() == 0);
		assert(arr.magiter().filter(i -> true).size() == arr.length);

		// Post `size`.
		assertEquals(arr.magiter().size().map(Std.string), ["0","1","2","3","4"]);
		assertEquals(arr.magiter().size().filter(_ % 2 == 0), [0, 2, 4]);
	}

	//**********************************************
	// * count
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().count(i -> false) == 0);
		assert(arr.magiter().count(i -> true) == arr.length);
		assert((1...10).magiter().count(_ < 3) == 2);
		assert(arr.magiter().map(_ * 2).count(_ < 3) == 1);
		assert((1...10).magiter().map(_ * 2).count(_ < 3) == 1);
		assert(arr.magiter().concat([1, 2, 3]).count(i -> false) == 0);
		assert(arr.magiter().concat([1, 2, 3]).count(i -> true) == arr.length + 3);
	}

	//**********************************************
	// * isEmpty
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(!arr.magiter().isEmpty());
		assert(([] : Array<Dynamic>).magiter().isEmpty());
		assert(!(0...10).magiter().isEmpty());
		assert(arr.magiter().filter(i -> false).isEmpty());
		assert(!arr.magiter().filter(i -> true).isEmpty());
		assert(!arr.magiter().filter(_ > 3).isEmpty());
		assert(!arr.magiter().concat([]).isEmpty());
		assert(!([] : Array<Dynamic>).magiter().concat([1, 2, 3]).isEmpty());
	}

	//**********************************************
	// * find
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().find(_ == 1) == 1);
		assert(arr.magiter().find(i -> i == 3) == 3);
		assert(arr.magiter().map("" + _).find(_ == "5") == "5");
		assert(arr.magiter().map(12 * _).filter(_ < 30).find(_ == 24) == 24);
		assert(arr.magiter().concat([1]).find(_ == 1) == 1);
	}

	//**********************************************
	// * findIndex
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().findIndex(_ == 1) == 0);
		assert(arr.magiter().findIndex(i -> i == 3) == 2);
		assert(arr.magiter().map("" + _).findIndex(_ == "5") == 4);
		assert(arr.magiter().map(12 * _).filter(_ < 30).findIndex(_ == 24) == 1);
		assert(arr.magiter().concat([1]).findIndex(_ == 1) == 0);
	}

	//**********************************************
	// * indexOf
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().indexOf(3) == 2);
		assert(arr.magiter().indexOf(1) == 0);
		assert(arr.magiter().map("" + _).indexOf("5") == 4);
		assert(arr.magiter().map(12 * _).filter(_ < 30).indexOf(24) == 1);

		assert(arr.magiter().indexOf(2, 0) == 1);
		assert(arr.magiter().indexOf(5, 0, false) == 4);
		assert(arr.magiter().map("" + _).indexOf("1", 0) == 0);
		assert(arr.magiter().map(12 * _).filter(_ < 30).indexOf(24, 0, false) == 1);

		assert(arr.magiter().indexOf(4, 0, true) == 3);
		assert(arr.magiter().indexOf(1, 0, true) == 0);
		assert(arr.magiter().map("" + _).indexOf("3", 0, true) == 2);
		assert(arr.magiter().map(12 * _).filter(_ > 30).indexOf(36, 0, true) == 0);

		assert(arr.magiter().concat([1, 2, 3]).indexOf(3) == 2);
		assert(arr.magiter().concat([10, 11, 12]).indexOf(11) == 6);

		final arr2 = [1, 2, 3, 1, 2, 3];

		assert(arr2.magiter().indexOf(3, 4) == 5);
		assert(arr2.magiter().indexOf(1, 1) == 3);
	}

	//**********************************************
	// * every
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().every(_ > 0));
		assert(!arr.magiter().every(_ > 10));
		assert(arr.magiter().every(_ != -1));
		assert(!arr.magiter().concat([-1]).every(_ == -1));
	}

	//**********************************************
	// * some
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().some(_ == 1));
		assert(!arr.magiter().some(_ == -1));
		assert(arr.magiter().concat([-1]).some(_ == -1));
	}

	//**********************************************
	// * reduce
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().reduce(_1) == 1);
		assert(arr.magiter().reduce(_2) == 5);
		assert(arr.magiter().reduce(_1 + _2) == 15);
		assert(arr.magiter().reduce(_1 * _2) == 120);
		assert(arr.magiter().concat(6...10).reduce(_1 * _2) == 362880);
		assert(arr.magiter().reduce((a, b) -> a + b) == 15);
		assert(arr.magiter().reduce((a, b) -> a * b) == 120);
		assert(arr.magiter().concat(6...10).reduce((a, b) -> a * b) == 362880);
		assert(arr.magiter().reduce((a, b) -> Std.int(Math.max(a, b))) == 5);
		assert(arr.magiter().reduce(function(a, b) { return a + b; }) == 15);
		assert(arr.magiter().reduce((a, b) -> a) == 1);
	}

	//**********************************************
	// * asArray
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals((1...6).magiter().asArray(), arr);
		assert((0...4).magiter().asArray().toString() == #if js "0,1,2,3" #else "[0,1,2,3]" #end);
	}

	//**********************************************
	// * asList
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.magiter().asList().toString() == "{1, 2, 3, 4, 5}");
	}

	//**********************************************
	// * asVector
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.magiter().asVector().toArray(), arr);
		assertEquals(arr.magiter().map(12 * _).filter(_ < 30).asVector().toArray(), [12, 24]);
	}

	//**********************************************
	// * concat
	//**********************************************
	{
		final arr = [1, 2, 3];
		final arr2 = [4, 5, 6];

		assertEquals(arr.magiter().concat(arr2), [1, 2, 3, 4, 5, 6]);
		assertEquals(arr.magiter().filter(_ == 3).concat(arr2), [3, 4, 5, 6]);
		assertEquals(arr.magiter().concat(arr2).filter(_ == 3), [3]);
		assertEquals(arr.magiter().concat(arr2.magiter().filter(_ == 6)), [1, 2, 3, 6]);
		assertEquals(arr.magiter().filter(_ == 3).concat(arr2.magiter().filter(_ == 6)), [3, 6]);
		assertEquals(arr.magiter().concat(arr2.magiter().filter(_ == 6)).filter(_ == 3), [3]);
		assertEquals((0...10).magiter().concat((10...20).magiter().concat((20...30).magiter().concat(30...40))), (0...40).magiter().asArray());
	}

	//**********************************************
	// * fill
	//**********************************************
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.magiter().fill(123), [123, 123, 123, 123, 123]);
		assertEquals(arr.magiter().fill(123, 2), [1, 2, 123, 123, 123]);
		assertEquals(arr.magiter().fill(123, 1 + 1 + 1), [1, 2, 3, 123, 123]);
		assertEquals(arr.magiter().fill(123, 5 * 5 - 23, 1 + 2), [1, 2, 123, 4, 5]);
		assertEquals(arr.magiter().concat(5...6).fill(123, 1 + 3, 5 * 1), [1, 2, 3, 4, 123, 5]);

		final onetwothree = 123;
		assertEquals(arr.magiter().fill(onetwothree, 2 * 2), [1, 2, 3, 4, 123]);
	}

	//**********************************************
	// * Test Static-Extension Conflicts
	//**********************************************
	{
		final t1 = new TestConflict1();
		assert(t1.map() == 4321);
	}

	// ---

	if(failedAsserts == 0) {
		haxe.Log.trace("\033[32m[Magic Array Tools] Test Successful!\033[0;37m", null);
	} else {
		haxe.Log.trace("\033[31m[Magic Array Tools] Test Failed " + failedAsserts + " Asserts!\033[0;37m", null);
		#if (sys || hxnodejs)
		Sys.exit(1);
		#end
	}
}

class TestConflict1 {
	public function new() {}
	public function map() return 4321;
}
