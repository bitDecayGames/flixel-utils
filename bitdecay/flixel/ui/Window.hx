package bitdecay.flixel.ui;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.FlxSprite;
import openfl.display.Graphics;
import bitdecay.flixel.extensions.FlxCameraExt;
import flixel.FlxCamera;
import bitdecay.flixel.graphics.AsepriteTypes.AseAtlasSliceKey;
import bitdecay.flixel.ui.BaseScrollBG;
import bitdecay.flixel.extensions.FlxObjectExt;
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
 *
 * Can have simple layouts and items added to the window that are automatically
 * clipped to the content area.
 *
 * **NOTE:** If individual sprites within `objects` are moved around after
 * being added to the window, call `updateClip()` to ensure proper rendering
**/
class Window extends FlxSpriteContainer {
	public var border:FlxSliceSprite;
	public var bg:BaseScrollBG;

	public var objects = new FlxSpriteContainer();

	public var padding:Int;
	public var layout:Layout;
    public var gridCells:Array<OccupiedCell> = [];

	private var lastClipOffset = FlxPoint.get();

	#if FLX_DEBUG
	var clipColor = FlxColor.PINK;
	var layoutPrimaryColor = FlxColor.YELLOW.getDarkened();
	var layoutSecondaryColor = FlxColor.BLUE.getLightened();
	#end

	public function new(X:Float, Y:Float, width:Int, height:Int, borderNineTile:FlxFrame, data:AseAtlasSliceKey, bgFrame:FlxFrame) {
		super(X, Y);

		// bg intentionally overlaps with the border one pixel on each side to prevent pixel gaps
		bg = new BaseScrollBG(
			FlxGraphic.fromFrame(bgFrame),
			data.center.x - 1,
			data.center.y - 1,
			Math.ceil(width - (data.bounds.w - data.center.w)) + 2,
			Math.ceil(height - (data.bounds.w - data.center.w)) + 2);
		border = new FlxSliceSprite(FlxGraphic.fromFrame(borderNineTile), FlxRect.get(data.center.x, data.center.y, data.center.w, data.center.h), width, height,
			FlxRect.get(data.bounds.x, data.bounds.y, data.bounds.w, data.bounds.h));

		border.stretchTop = true;
		border.stretchBottom = true;
		border.stretchLeft = true;
		border.stretchRight = true;

		objects.setPosition(bg.x, bg.y);

		add(bg);
		add(objects);
		add(border);

		objects.clipRect = FlxRect.get(0, 0, bg.width, bg.height);
	}

	public function withLayout(type:Layout) {
		this.layout = type;
	}

	public function addItem(obj:FlxSprite, ?cell:GridCell) {
		objects.add(obj);

		if (layout == null) {
			// no layout, so there aren't defined cells, but we can just put everything
			// in as 0,0
			gridCells.push({
				obj: obj,
				col: 0,
				row: 0
			});
			applyLayout();
			return;
		}

		switch (layout) {
			case Vertical(spacing):
				gridCells.push({
					obj: obj,
					col: 0,
					row: gridCells.length
				});
			case Horizontal(spacing):
				gridCells.push({
					obj: obj,
					col: gridCells.length,
					row: 0
				});
			case Grid(rows, columns, spacingX, spacingY):
				gridCells.push({
					obj: obj,
					col: cell.col,
					row: cell.row
				});
		}
		applyLayout();
	}

	function applyLayout() {
		if (layout == null) {
			updateClip();
			return;
		}

		var tempX = bg.x + padding;
		var tempY = bg.y + padding;
		for (gc in gridCells) {
			switch (layout) {
			case Vertical(spacing):
				gc.obj.x = bg.x + padding;
                gc.obj.y = tempY;
				tempY = gc.obj.y + gc.obj.height + spacing;
			case Horizontal(spacing):
				gc.obj.x = tempX;
                gc.obj.y = bg.y + padding;
				tempX = gc.obj.x + gc.obj.width + spacing;
			case Grid(rows, columns, spacingX, spacingY):
				var cellW = bg.width / columns;
				var cellH = bg.height / rows;
                gc.obj.x = bg.x + gc.col * cellW + (gc.col == 0 ? padding : spacingX);
                gc.obj.y = bg.y + gc.row * cellH + (gc.row == 0 ? padding : spacingY);
			}
		}

		updateClip();
	}

	public function updateClip() {
		var xOffset = bg.x - objects.x;
		var yOffset = bg.y - objects.y;
		objects.clipRect.set(xOffset, yOffset, bg.width, bg.height);
		objects.clipRect = objects.clipRect;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		lastClipOffset.set(bg.x - objects.x, bg.y - objects.y);
		if (lastClipOffset.x != objects.clipRect.x || lastClipOffset.y != objects.clipRect.y) {
			updateClip();
		}
	}

	#if FLX_DEBUG
	override function drawDebug() {
		super.drawDebug();
		for (camera in getCamerasLegacy())
		{
			var gfx:Graphics = beginDrawDebug(camera);

			if (objects.clipRect != null) {
				var drawRect = FlxRect.get().copyFrom(objects.clipRect);
				drawRect.x += objects.x;
				drawRect.y += objects.y;
				getCameraRectFromWorldRect(drawRect, camera);
				gfx.lineStyle(1, FlxColor.PINK, 0.75);
				gfx.drawRect(drawRect.x + 0.5, drawRect.y + 0.5, drawRect.width - 1.0, drawRect.height - 1.0);
				drawRect.put();
			}

			if (layout == null) {
				continue;
			}
			
			switch(layout) {
				case Grid(rows, columns, spacingX, spacingY):
					var colWidth = bg.width / columns; 
					var rowHeight = bg.height / rows;
					var a = FlxPoint.get();
					var b = FlxPoint.get();

					for (r in 1...rows) {
						gfx.lineStyle(1, layoutPrimaryColor, 0.75);
						a.set(bg.x, bg.y + rowHeight * r);
						b.set(bg.x + bg.width, bg.y + rowHeight * r);
						FlxCameraExt.project(camera, a, a);
						FlxCameraExt.project(camera, b, b);
						gfx.moveTo(a.x, a.y);
						gfx.lineTo(b.x, b.y);

						if (spacingY > 0) {
							gfx.lineStyle(1, layoutSecondaryColor, 0.75);
							a.set(bg.x, bg.y + rowHeight * r + spacingY);
							b.set(bg.x + bg.width, bg.y + rowHeight * r + spacingY);
							FlxCameraExt.project(camera, a, a);
							FlxCameraExt.project(camera, b, b);
							gfx.moveTo(a.x, a.y);
							gfx.lineTo(b.x, b.y);
						}
					}
					for (c in 1...columns) {
						gfx.lineStyle(1, layoutPrimaryColor, 0.75);
						a.set(bg.x + colWidth * c, bg.y);
						b.set(bg.x + colWidth * c, bg.y + bg.height);
						FlxCameraExt.project(camera, a, a);
						FlxCameraExt.project(camera, b, b);
						gfx.moveTo(a.x, a.y);
						gfx.lineTo(b.x, b.y);

						if (spacingX > 0) {
							gfx.lineStyle(1, layoutSecondaryColor, 0.75);
							a.set(bg.x + colWidth * c + spacingX, bg.y);
							b.set(bg.x + colWidth * c + spacingX, bg.y + bg.height);
							FlxCameraExt.project(camera, a, a);
							FlxCameraExt.project(camera, b, b);
							gfx.moveTo(a.x, a.y);
							gfx.lineTo(b.x, b.y);
						}
					}
					a.put();
					b.put();
				default:
			}
		}
	}

	@:access(flixel.FlxCamera)
	function getCameraRectFromWorldRect(rect:FlxRect, camera:FlxCamera):FlxRect
	{
		_point.set(rect.x, rect.y);
		FlxCameraExt.project(camera, _point, _point);

		rect.set(_point.x, _point.y, rect.width, rect.height);
		rect = camera.transformRect(rect);

		if (isPixelPerfectRender(camera))
		{
			rect.floor();
		}

		return rect;
	}
	#end
}

enum Layout {
    Vertical(spacing:Float);
    Horizontal(spacing:Float);
    Grid(rows:Int, columns:Int, spacingX:Float, spacingY:Float);
}

enum ItemPosition {
    Vertical(index:Int);
    Horizontal(index:Int);
    Grid(x:Int, y:Int);
}

typedef GridCell = {
    col:Int,
    row:Int,
}

typedef OccupiedCell = GridCell & { 
	obj:FlxObject,
}
