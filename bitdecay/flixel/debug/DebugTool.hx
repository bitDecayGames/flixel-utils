package bitdecay.flixel.debug;

import flixel.FlxBasic;

#if FLX_DEBUG
import bitdecay.flixel.debug.DebugToolWindow;
import bitdecay.flixel.system.QuickLog;
import flixel.FlxG;
import flixel.system.ui.FlxSystemButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
using flixel.util.FlxBitmapDataUtil;
#end

/**
 * The base class for a debug tool.
 *
 * Note: This tool compiles both with and without the FLX_DEBUG flag set.
 * This allows for easier use within projects. Any subclass of this should
 * follow the same pattern by making it's public interface as a set of no-op
 * calls when not running with FLX_DEBUG
**/
class DebugTool<T:DebugToolWindow> extends FlxBasic {
	#if FLX_DEBUG
	var name:String;
	var button:FlxSystemButton;
	var window:T;
	var data:Dynamic;

	public var enabled(default, set) = true;

	public function new(dataName:String, iconData:Array<Array<Float>>) {
		super();
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

	override public function update(elapsed:Float) {
		
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
	function loadData():Bool {
		if (!FlxG.save.isBound)
			return false;

		data = Reflect.getProperty(FlxG.save.data.debugSuite, name);
		enabled = data.enabled;

		@:privateAccess {
			window._width = data.windowWid;
			window._height = data.windowHei;
			window.updateSize();
			window.reposition(data.windowX, data.windowY);
		}

		return true;
	}

	function set_enabled(value:Bool) {
		if (button != null)
			button.toggled = !value;

		window.visible = value;

		data.enabled = value;
		FlxG.save.flush();

		return enabled = value;
	}

	function makeWindow(icon:BitmapData):T {
		throw "Debug Tools must override makeWindow";
	}

	function handleResize(width:Int, height:Int):Void {
		var saveData:BaseToolData = data;
		saveData.windowWid = width;
		saveData.windowHei = height;
		FlxG.save.flush();
	}

	function handleReposition(x:Int, y:Int):Void {
		var saveData:BaseToolData = data;
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
	#end
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
