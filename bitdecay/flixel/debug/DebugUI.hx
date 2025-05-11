package bitdecay.flixel.debug;

import flixel.util.FlxColor;
import openfl.text.TextField;
import flixel.system.debug.DebuggerUtil;
import openfl.events.MouseEvent;

class DebugUI {

	/**
	 * returns a 2D 10x10 array of 1's
	**/
	public static function emptyIconData():Array<Array<Float>> {
		return [for (i in 0...10) {
			[for (k in 0...10) {
				1;
			}];
		}];
	}

	/**
	 * Creates a basic clickable label based on the provided config
	**/
	public static function makeLabelButton(X:Float, Y:Float, cfg:SimpleButtonCfg):TextField {
		var btn = DebuggerUtil.createTextField(X, Y, cfg.labelColor, cfg.textSize != null ? cfg.textSize : 12);
		btn.text = cfg.label;

		btn.border = cfg.borderColor != FlxColor.TRANSPARENT;
		if (cfg.borderColor != null) {
			btn.borderColor = cfg.borderColor;
		}

		btn.textColor = FlxColor.BLACK;
		if (cfg.labelColor != null) {
			btn.textColor = cfg.labelColor;
		}

		var bgColor = FlxColor.WHITE;
		if (cfg.bgColor != null) {
			bgColor = cfg.bgColor;
		}

		btn.background = true;
		btn.backgroundColor = bgColor;
		var pressedColor = bgColor.getDarkened();
		btn.addEventListener(MouseEvent.MOUSE_DOWN, (e) -> {
			btn.backgroundColor = pressedColor;
		});
		btn.addEventListener(MouseEvent.MOUSE_UP, (e) -> {
			btn.backgroundColor = bgColor;
		});

		btn.addEventListener(MouseEvent.CLICK, (me) -> {
			cfg.onClick(btn, me);
		});
		return btn;
	}
}

typedef SimpleButtonCfg = {
	var label:String;
	var ?textSize:Int;
	var ?borderColor:FlxColor;
	var ?labelColor:FlxColor;
	var ?bgColor:FlxColor;
	var ?toggle:Bool;
	var onClick:(TextField, MouseEvent)->Void;
}