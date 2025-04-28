package bitdecay.flixel.debug;

#if debug
import flixel.FlxBasic;
import flixel.FlxG;

class DebugSuite extends FlxBasic {
	public static var ME(default, null):DebugSuite;

	public var tools:Array<DebugTool<Dynamic>> = [];

	public static function init(...tools:DebugTool<Dynamic>) {
		if (ME != null) {
			ME.destroy();
			ME = null;
		}

		ME = new DebugSuite();
		ME.tools = tools;
		ME.initSuite();
	}

	function new() {
		super();
	}

	public function getTool<T>(cls:Class<T>):Null<T> {
		for (tool in tools) {
			if (Std.isOfType(tool, cls)) {
				return cast tool;
			}
		}
		return null;
	}

	function initSuite() {
		var existingData:Dynamic = FlxG.save.data.debugSuite;
		if (existingData == null #if forceClean || true #end) {
			existingData = {};
			FlxG.save.data.debugSuite = existingData;
			FlxG.save.flush();
		}

		for (t in tools) {
			t.init();
		}
	}
}
#end
