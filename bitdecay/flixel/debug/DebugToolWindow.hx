package bitdecay.flixel.debug;

import flixel.FlxG;
import flixel.system.debug.Window;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSignal;

class DebugToolWindow extends Window {
	public var onResize = new FlxTypedSignal<(Int, Int) -> Void>();
	public var onReposition = new FlxTypedSignal<(Int, Int) -> Void>();
	public var onUpdate = new FlxTypedSignal<(Float) -> Void>();
	public var dirty = false;

	// This is not ideal as the window should be updating the underlying tool... but that's how I built it
	// before I realized the windows are automatically updated by flixel when the game is paused
	override function update() {
		super.update();
		onUpdate.dispatch(FlxG.elapsed);
	}

	override function updateSize():Void {
		super.updateSize();
		onResize.dispatch(Std.int(_width), Std.int(_height));
	}

	override function reposition(X:Float, Y:Float) {
		super.reposition(X, Y);
		onReposition.dispatch(Std.int(x), Std.int(y));
	}
}
