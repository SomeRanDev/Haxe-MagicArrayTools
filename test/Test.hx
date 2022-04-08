package;

using MagicArrayTools;

function assert(b: Bool, ?pos: haxe.PosInfos) {
	if(!b) {
		throw "assert failed at " + pos.fileName + ":" + pos.lineNumber;
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
	assert(result, pos);
}

function main() {
	trace("Testing [Magic Array Tools]");

	/**********************************************
	 * map
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.map(_), arr);
		assertEquals(arr.map(i -> i), arr);
		assertEquals(arr.map(function(i) { return i; }), arr);

		final arrStr = ["1", "2", "3", "4", "5"];

		assertEquals(arr.map("" + _), arrStr);
		assertEquals(arr.map((i:Int) -> "" + i), arrStr);
		assertEquals(arr.map(function(i:Int) { return "" + i; }), arrStr);
	}

	/**********************************************
	 * filter
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.filter((true)), arr);
		assertEquals(arr.filter(i -> true), arr);

		assertEquals(arr.filter((false)), []);
		assertEquals(arr.filter(i -> false), []);

		final arr2 = [3, 4, 5];

		assertEquals(arr.filter(_ >= 3), arr2);
		assertEquals(arr.filter(i -> i >= 3), arr2);

		final arr3 = ["1"];

		assertEquals(arr.filter(_ == 1).map("" + _), arr3);
		assertEquals(arr.filter(i -> i == 1).map((i:Int) -> "" + i), arr3);
		assertEquals(arr.map("" + _).filter(_ == "1"), arr3);
		assertEquals(arr.map((i:Int) -> "" + i).filter(i -> i == "1"), arr3);
	}

	/**********************************************
	 * size
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.size() == arr.length);
		assert(arr.filter(_ < 3).size() == 2);
		assert(arr.map("" + _).size() == 5);
		assert(arr.filter(i -> false).size() == 0);
		assert(arr.filter(i -> true).size() == arr.length);
	}

	/**********************************************
	 * count
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.count(i -> false) == 0);
		assert(arr.count(i -> true) == arr.length);
		assert((1...10).count(_ < 3) == 2);
		assert(arr.map(_ * 2).count(_ < 3) == 1);
		assert((1...10).map(_ * 2).count(_ < 3) == 1);
	}

	/**********************************************
	 * isEmpty
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(!arr.isEmpty());
		assert([].isEmpty());
		assert(!(0...10).isEmpty());
		assert(arr.filter(i -> false).isEmpty());
		assert(!arr.filter(i -> true).isEmpty());
	}

	/**********************************************
	 * find
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.find(_ == 1) == 1);
		assert(arr.find(i -> i == 3) == 3);
		assert(arr.map("" + _).find(_ == "5") == "5");
		assert(arr.map(12 * _).filter(_ < 30).find(_ == 24) == 24);
	}

	/**********************************************
	 * indexOf
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.indexOf(3) == 2);
		assert(arr.indexOf(1) == 0);
		assert(arr.map("" + _).indexOf("5") == 4);
		assert(arr.map(12 * _).filter(_ < 30).indexOf(24) == 1);
	}

	/**********************************************
	 * asList
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assert(arr.asList().toString() == "{1, 2, 3, 4, 5}");
	}

	/**********************************************
	 * asVector
	 **********************************************/
	{
		final arr = [1, 2, 3, 4, 5];

		assertEquals(arr.asVector().toArray(), arr);
		assertEquals(arr.map(12 * _).filter(_ < 30).asVector().toArray(), [12, 24]);
	}

	//trace("--- " + (0...4).forEachThen(trace).asList().stringifyAndTrace());

	//trace([2].count(_ == 1));

	// ---

	trace("[Magic Array Tools] Test Successful!");
}