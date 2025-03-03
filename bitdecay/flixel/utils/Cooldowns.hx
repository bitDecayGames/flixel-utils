package bitdecay.flixel.utils;

import flixel.FlxG;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxPool;

// A class to manage cooldowns. Don't forget to call the update() function on this
class Cooldowns {
	var pool:FlxPool<Cd>;
	var cds:Map<String, Cd>;

	public function new(?size:Int) {
		cds = new Map<String, Cd>();
		pool = new FlxPool<Cd>(Cd.new);
		pool.preAllocate(size != null ? size : 0);
	}

	// Sets a new cooldown, overwriting existing cooldown one if it exists
	public function set(key:String, time:Float) {
		var cd = pool.get();
		cd.set(key, time);
		cds.set(key, cd);
	}

	// Returns true if the cooldown key exists and is active
	public function has(key:String):Bool { 
		return cds.exists(key);
	}

	// Returns the remainder of a cooldown if it exists and is active, zero otherwise
	public function get(key:String):Float {
		if (!has(key)) {
			return 0;
		}

		return cds.get(key).remaining;
	 }

	 // Internal helper to get Cd objects out of our map. Assumes caller knows if it should
	 // exist or not
	 private function getCd(key:String):Cd {
		return cds.get(key);
	 }

	// Removes a cooldown if it exists
	public function remove(key:String):Bool { 
		return cds.remove(key);
	}

	// Returns the progress of the cooldown as a percentage if it exists, zero otherwise
	public function getProgress(key:String):Float {
		if (!has(key)) {
			return 0;
		}

		var cd = getCd(key);
		return (cd.initial - cd.remaining) / cd.initial;
	}

	// returns the remaining time of the cooldown as a percentage if it exists, zero otherwise
	public function getRemaining(key:String):Float {
		if (!has(key)) {
			return 0;
		}

		var cd = getCd(key);
		return 1 - ((cd.initial - cd.remaining) / cd.initial);
	}

	public function update(elapsed:Float) {
		var keys = cds.keys();
		for (key in keys) {
			var cd = getCd(key);
			cd.remaining -= elapsed;
			if (cd.remaining <= 0) {
				if (cd.onComplete != null) {
					cd.onComplete();
				}
				pool.put(cd);
				cds.remove(key);
			}
		}
	}
}

private class Cd implements IFlxDestroyable {
	public var key:String;
	public var initial:Float;
	public var remaining:Float;
	public var onComplete:()->Void;

	public function new() {}

	public function set(key:String, time:Float) {
		this.key = key;
		initial = time;
		remaining = time;
	}

	public function destroy() {
		key = "";
		initial = 0;
		remaining = 0;
		onComplete = null;
	}
}