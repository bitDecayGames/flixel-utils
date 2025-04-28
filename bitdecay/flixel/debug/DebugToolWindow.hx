package bitdecay.flixel.debug;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.system.debug.Window;

class DebugToolWindow extends Window {
	public var onResize = new FlxTypedSignal<(Int, Int) -> Void>();
	public var onReposition = new FlxTypedSignal<(Int, Int) -> Void>();

	override function updateSize():Void {
		super.updateSize();
		onResize.dispatch(Std.int(_width), Std.int(_height));
	}

	override function reposition(X:Float, Y:Float) {
		super.reposition(X, Y);
		onReposition.dispatch(Std.int(x), Std.int(y));
	}
}
