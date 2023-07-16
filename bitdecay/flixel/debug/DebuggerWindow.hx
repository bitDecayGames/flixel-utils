package bitdecay.flixel.debug;

import flixel.FlxG;
import openfl.display.BitmapData;
import bitdecay.flixel.debug.DebugDraw;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import flixel.util.FlxColor;
import flixel.system.debug.DebuggerUtil;
import flixel.system.debug.Window;

/**
 * A simple window that provides toggle buttons for each custom debug draw layers
**/
class DebuggerWindow extends Window {
	/**
	 * How often to update the stats, in ms. The lower, the more performance-intense!
	 */
	static inline var UPDATE_DELAY:Int = 250;

	public static inline var TEXT_SIZE:Int = 11;

	private var callCountLabel:TextField;

	public function new(icon:BitmapData) {
		super("Layers", icon, 0, 0, false);

		var gutter:Int = 5;
		var nextY:Int = Std.int(_header.height) + gutter;

		addChild(callCountLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.WHITE, TEXT_SIZE));
		callCountLabel.text = "Draw Calls: ---";

		minSize.x = callCountLabel.width;

		nextY += Std.int(callCountLabel.height + gutter);

		for (layerName => _ in DebugDraw.layer_enabled) {
			var layerLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.BLACK, TEXT_SIZE);
			addChild(layerLabel);
			layerLabel.border = true;
			layerLabel.borderColor = FlxColor.BLACK;
			layerLabel.background = true;
			layerLabel.backgroundColor = FlxColor.WHITE;
			layerLabel.text = layerName;
			layerLabel.addEventListener(MouseEvent.CLICK, (me) -> {
				DebugDraw.layer_enabled[layerName] = !DebugDraw.layer_enabled[layerName];
				layerLabel.backgroundColor = DebugDraw.layer_enabled[layerName] ? FlxColor.WHITE : FlxColor.GRAY;
			});

			nextY += Std.int(layerLabel.height + gutter);
			minSize.x = Math.max(minSize.x, layerLabel.width);
		}

		minSize.x += gutter * 2;
		minSize.y = nextY;

		updateSize();
	}

	var _currentTime:Int;
	var _lastTime:Int = 0;
	var _updateTimer:Int = 0;

	override function update() {
		super.update();

		var time:Int = _currentTime = FlxG.game.ticks;
		var elapsed:Int = time - _lastTime;

		if (elapsed > UPDATE_DELAY) {
			elapsed = UPDATE_DELAY;
		}
		_lastTime = time;

		_updateTimer += elapsed;

		if (_updateTimer > UPDATE_DELAY) {
			callCountLabel.text = 'Draw Calls: ${DebugDraw.ME.lastCallCount}';
		}
	}
}