package bitdecay.flixel.debug;

import bitdecay.flixel.system.QuickLog;
import flixel.FlxBasic;
import flixel.FlxG;

class DebugSuite extends FlxBasic {
	public static var ME(default, null):DebugSuite;

	public var tools:Array<DebugTool<Dynamic>> = [];

	/**
	 * Helper function to allow calling debug functions without the need to worry about
	 * if the debug flags are set and debug tooling is available. This will result in a
	 * no-op if the tool is unavailable
	 *
	 * @param toolClass the DebugTool class to be invoked
	 * @param fn        a function the tool will be passed to if found and debug enabled
	 *
	 * Example Usage:
	 *
	 * `DebugSuite.tool(DebugDraw, (t) -> {t.drawCameraRect(0, 0, 50, 50, FlxColor.YELLOW);});`
	**/
	public static function tool<T>(toolClass:Class<T>, fn:(t:T) -> Void) {
		#if debug
		var tool = ME.getTool(toolClass);
		if (tool == null) {
			QuickLog.warn('no tool found for "${toolClass}');
			return;
		}
		fn(tool);
		#end
	}

	public static function init(...tools:DebugTool<Dynamic>) {
		if (ME != null) {
			ME.destroy();
			ME = null;
		}

		ME = new DebugSuite();
		ME.tools = tools;
		#if FLX_DEBUG
		ME.initSuite();
		#end
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

	#if FLX_DEBUG
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
	#end
}
