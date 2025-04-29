package bitdecay.flixel.debug;

#if FLX_DEBUG
import bitdecay.flixel.debug.DebugToolWindow;
import bitdecay.flixel.system.QuickLog;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
using flixel.util.FlxBitmapDataUtil;

class DebugTool<T:DebugToolWindow> {
	var name:String;
	var button:FlxSystemButton;
	var window:T;

	public var enabled(default, set) = true;

	public function new(dataName:String, iconData:Array<Array<Float>>) {
		name = dataName;
		var icon = iconFromData(iconData);
		window = makeWindow(icon);
		if (window == null) {
			QuickLog.critical('window for debug tool "${name}" cannot be null');
		}
		window.onResize.add(handleResize);
		window.onReposition.add(handleReposition);
		window.onUpdate.add(update);
		FlxG.game.debugger.addWindow(window);
		button = FlxG.debugger.addButton(RIGHT, icon, () -> enabled = !enabled, true, true);
	}

	public function update() {
		
	}

	public function init() {
		if (!FlxG.save.isBound)
			return;

		var existingData:Dynamic = Reflect.getProperty(FlxG.save.data.debugSuite, name);
		if (existingData == null #if forceClean || true #end) {
			var defaults:Dynamic = getDefaults();
			Reflect.setField(FlxG.save.data.debugSuite, name, defaults);
			FlxG.save.flush();
		}

		loadData();
	}

	// Override to set defaults for the tooling
	function getDefaults():Dynamic {
		var baseDefaults:BaseToolData = {
			enabled: false,
			windowHei: 100,
			windowWid: 100,
			windowX: 50,
			windowY: 50
		};
		return baseDefaults;
	}

	// Handle any initial load when the app starts
	function loadData() {
		if (!FlxG.save.isBound)
			return;

		var toolData = Reflect.getProperty(FlxG.save.data.debugSuite, name);
		enabled = toolData.enabled;

		@:privateAccess {
			window._width = toolData.windowWid;
			window._height = toolData.windowHei;
			window.updateSize();
			window.reposition(toolData.windowX, toolData.windowY);
		}
	}

	function set_enabled(value:Bool) {
		if (button != null)
			button.toggled = !value;

		window.visible = value;

		Reflect.getProperty(FlxG.save.data.debugSuite, name).enabled = value;
		FlxG.save.flush();

		return enabled = value;
	}

	function makeWindow(icon:BitmapData):T {
		// Override to create tooling window
		return null;
	}

	function handleResize(width:Int, height:Int):Void {
		var saveData:BaseToolData = Reflect.getProperty(FlxG.save.data.debugSuite, name);
		saveData.windowWid = width;
		saveData.windowHei = height;
		FlxG.save.flush();
	}

	function handleReposition(x:Int, y:Int):Void {
		var saveData:BaseToolData = Reflect.getProperty(FlxG.save.data.debugSuite, name);
		saveData.windowX = x;
		saveData.windowY = y;
		FlxG.save.flush();
	}

	static function iconFromData(iconData:Array<Array<Float>>):BitmapData {
		var icon = new BitmapData(11, 11, true, FlxColor.TRANSPARENT);
		for (y in 0...iconData.length) {
			for (x in 0...iconData[y].length) {
				if (iconData[y][x] > 0) {
					icon.setPixel32(x, y, FlxColor.fromRGBFloat(1, 1, 1, iconData[y][x]));
				}
			}
		}
		return icon;
	}
}

/**
 * Base tooling data for something that can be enabled and has a window
**/
typedef BaseToolData = {
	var ?enabled:Bool;
	var ?windowX:Int;
	var ?windowY:Int;
	var ?windowWid:Int;
	var ?windowHei:Int;
}
#end
