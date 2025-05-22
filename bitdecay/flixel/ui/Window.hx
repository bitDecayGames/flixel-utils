package bitdecay.flixel.ui;

import bitdecay.flixel.graphics.AsepriteTypes.AseAtlasSliceKey;
import bitdecay.flixel.ui.BaseScrollBG;
import flixel.addons.display.FlxSliceSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteContainer.FlxSpriteContainer;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;

/**
 * A basic window with a background and border built from a 9-slice.
 * Once constructed, both border and background can be further customized
 * for things like color and background scrolling.
**/
class Window extends FlxSpriteContainer {
	public var border:FlxSliceSprite;
	public var bg:BaseScrollBG;

	public function new(X:Float, Y:Float, width:Int, height:Int, borderNineTile:FlxFrame, data:AseAtlasSliceKey, bgFrame:FlxFrame) {
		super(X, Y);

		bg = new BaseScrollBG(FlxGraphic.fromFrame(bgFrame), data.center.x, data.center.y, Math.ceil(width - (data.bounds.w - data.center.w)),
			Math.ceil(height - (data.bounds.w - data.center.w)));
		border = new FlxSliceSprite(FlxGraphic.fromFrame(borderNineTile), FlxRect.get(data.center.x, data.center.y, data.center.w, data.center.h), width, height,
			FlxRect.get(data.bounds.x, data.bounds.y, data.bounds.w, data.bounds.h));

		border.stretchTop = true;
		border.stretchBottom = true;
		border.stretchLeft = true;
		border.stretchRight = true;

		add(bg);
		add(border);
	}
}