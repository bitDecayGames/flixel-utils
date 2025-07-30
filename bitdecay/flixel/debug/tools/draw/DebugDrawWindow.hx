package bitdecay.flixel.debug.tools.draw;


#if FLX_DEBUG
import bitdecay.flixel.debug.DebugUI.SimpleButtonCfg;
import flixel.util.FlxSignal.FlxTypedSignal;
import bitdecay.flixel.debug.tools.draw.DebugDraw;
import flixel.FlxG;
import flixel.system.debug.DebuggerUtil;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.text.TextField;
#end

/**
 * A simple window that provides toggle buttons for each custom debug draw layers
**/
class DebugDrawWindow extends DebugToolWindow {
	#if FLX_DEBUG

	public static inline var TEXT_SIZE:Int = 11;

	private var callCountLabel:TextField;

	private var collapseLabel:TextField;
	public var collapsed(default, set):Bool = false;
	private var fullSizeMin:Float = 0;
	private var collapsedSizeMin:Float = 0;

	private var labels = new Map<String, TextField>();

	public var onLayerToggle = new FlxTypedSignal<(String, Bool) -> Void>();
	public var onCollapseToggle = new FlxTypedSignal<(Bool) -> Void>();

	var gutter = 5;
	var buttonStartY:Int = 0;

	public function new(icon:BitmapData) {
		super("Debug Draw", icon, 0, 0, false);

		var nextY:Int = Std.int(_header.height) + gutter;

		var collapseBtnCfg:SimpleButtonCfg = {
			label: "Collapse",
			textSize: TEXT_SIZE,
			labelColor: FlxColor.BLACK,
			borderColor: FlxColor.BLACK,
			bgColor: FlxColor.WHITE,
			onClick: (_, _) -> { collapsed = !collapsed; }
		};
		collapseLabel = DebugUI.makeLabelButton(gutter, nextY, collapseBtnCfg);
		addChild(collapseLabel);

		nextY += Std.int(collapseLabel.height + gutter);

		addChild(callCountLabel = DebuggerUtil.createTextField(gutter, nextY, FlxColor.WHITE, TEXT_SIZE));
		callCountLabel.text = "Draw Calls: ---";

		minSize.x = _title.x + _title.width;

		nextY += Std.int(callCountLabel.height + gutter);

		collapsedSizeMin = nextY;
		buttonStartY = nextY;
	}



	public function setLayers(layers:Map<String, Bool>) {
		minSize.x = callCountLabel.width;

		var nextY = buttonStartY;

		for (layerName => layerOn in layers) {
			var layerEnabled = layerOn;
			var layerBtnCfg:SimpleButtonCfg = {
				label: layerName,
				textSize: TEXT_SIZE,
				labelColor: FlxColor.BLACK,
				borderColor: FlxColor.BLACK,
				bgColor: FlxColor.WHITE,
				onClick: (l, _) -> {
					layerEnabled = !layerEnabled;
					l.backgroundColor = layerEnabled ? FlxColor.WHITE : FlxColor.GRAY;
					onLayerToggle.dispatch(layerName, layerEnabled);
				}
			};
			var layerLabel = DebugUI.makeLabelButton(gutter, nextY, layerBtnCfg);
			addChild(layerLabel);

			labels.set(layerName, layerLabel);
			layerLabel.backgroundColor = DebugDraw.layer_enabled[layerName] ? FlxColor.WHITE : FlxColor.GRAY;

			nextY += Std.int(layerLabel.height + gutter);
			minSize.x = Math.max(minSize.x, layerLabel.width);
		}

		minSize.x += gutter * 2;
		fullSizeMin = nextY;
	}

	public function updateDrawCallCount(num:Int) {
		callCountLabel.text = 'Draw Calls: ${num}';
	}

	public function set_collapsed(newCollapse:Bool) {
			if (newCollapse) {
				collapseLabel.text = "Expand";
				minSize.y = collapsedSizeMin;
				maxSize.y = collapsedSizeMin;
			} else {
				collapseLabel.text = "Collapse";
				minSize.y = fullSizeMin;
				maxSize.y = fullSizeMin;
			}
			collapseLabel.visible = false;
			collapseLabel.visible = true;

			for (l in labels) {
				l.visible = !newCollapse;
			}

			updateSize();
			bound();
			reposition(x, y);

			onCollapseToggle.dispatch(newCollapse);
			return collapsed = newCollapse;
	}
	#end
}
