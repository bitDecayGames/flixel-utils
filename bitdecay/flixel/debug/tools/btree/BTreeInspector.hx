package bitdecay.flixel.debug.tools.btree;

import bitdecay.behavior.tree.Node;
import flixel.FlxG;
import haxe.io.Bytes;
import openfl.display.Loader;
import openfl.events.Event;
#if FLX_DEBUG
import bitdecay.behavior.tree.BTExecutor;
import bitdecay.flixel.debug.DebugTool.BaseToolData;
import openfl.display.BitmapData;
using flixel.util.FlxBitmapDataUtil;

/**
 * An output window that lets you paste BitmapData in the debugger overlay.
 */
class BTreeInspector extends DebugTool<BTreeInspectorWindow> {
	static inline var nodeIconData = "data:image/png;base64,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";
	static var iconData = [
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0],
		[0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	];

	// populated at runtime
	static var nodeIconBitmap:BitmapData = null;

	var pendingAdds:Map<String, BTExecutor> = [];

	var trees:Map<String, BTreeVisualizer> = [];

	var focusNode:Node = null;

	public function new() {
		super("btree", iconData);

		window.onClick.add(handleClick);

		FlxG.signals.preStateSwitch.add(clear);
	}

	function clear() {
		trees.clear();
		window.clear();
	}

	override function init() {
		super.init();

		var bytes = haxe.crypto.Base64.decode(nodeIconData.split(",")[1]);
        var loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) {
            nodeIconBitmap = cast(loader.content, openfl.display.Bitmap).bitmapData;
        });
        loader.loadBytes(bytes.getData());
	}

	override function loadData() {
		super.loadData();

		window.resize(window.width, window.height);

		// This probably isn't the right way to do this
		FlxG.plugins.addPlugin(this);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (nodeIconBitmap != null) {
			for (name => btree in pendingAdds) {
				var visualizer = new BTreeVisualizer(btree);
				visualizer.build();
				window.add(visualizer.composite, name);
				trees.set(name, visualizer);
			}
			pendingAdds.clear();
		}

		if (focusNode != null) {
			trace(Type.getClassName(Type.getClass(focusNode)));
			@:privateAccess
			window.setInfoText([Type.getClassName(Type.getClass(focusNode))].concat(focusNode.getDetail()).join("\n"));
		}

		@:privateAccess {
			for (name => treeVis in trees) {
				if (treeVis.dirty && window._curEntry.name == name) {
					treeVis.dirty = false;
					window.refreshCanvas();
					break;
				}
			}
		}
	}

	override function getDefaults():Dynamic {
		var defaults = super.getDefaults();
		defaults.googly = 1.25;
		return defaults;
	}

	function handleClick(name:String, x:Int, y:Int) {
		var vis = trees.get(name);
		focusNode = vis.nodeAtPoint(x, y);
	}

	override function makeWindow(icon:BitmapData):BTreeInspectorWindow {
		return new BTreeInspectorWindow(icon);
	}

	public function addTree(name:String, btree:BTExecutor) {
		pendingAdds.set(name, btree);
	}
}

typedef BTreeInspectorData = BaseToolData & {
	var ?googly:Float;
}
#end
