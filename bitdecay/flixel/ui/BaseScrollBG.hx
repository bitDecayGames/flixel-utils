package bitdecay.flixel.ui;

import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * Scrollable background sprite that repeats on both X and Y axes
**/
class BaseScrollBG extends FlxTiledSprite {
	public var scrollSpeed = FlxPoint.get();

	public function new(?graphic:FlxGraphicAsset, X:Float, Y:Float, width:Int, height:Int) {
		super(graphic, width, height);
		setPosition(X, Y);
	}

	public function setScrollSpeed(dir:FlxPoint, speed:Float) {
		scrollSpeed.copyFrom(dir).normalize().scale(speed);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		scrollX += scrollSpeed.x * elapsed;
		scrollY += scrollSpeed.y * elapsed;
	}
}