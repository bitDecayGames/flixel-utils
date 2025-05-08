package bitdecay.flixel.debug;

import openfl.display.BitmapData;
import bitdecay.flixel.debug.DebugUI.SimpleButtonCfg;

/**
 * A bare bones window. Provide a list of button configurations and this will
 * automatically build them into a window. Nothing more, nothing less.
**/
class SimpleDebugToolWindow extends DebugToolWindow {
	public function new(title:String, ?icon:BitmapData, btnCfgs:Array<SimpleButtonCfg>) {
		super(title, icon, 0, 0, false);

		var nextY = _header.height + 5;
		for (c in btnCfgs) {
			var label = DebugUI.makeLabelButton(5, nextY, c);
			addChild(label);

			nextY += Std.int(label.height + 5);
			minSize.x = Math.max(minSize.x, label.width + 10);
			minSize.y = Math.max(minSize.y, nextY);
		}
	}
}