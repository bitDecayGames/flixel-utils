package bitdecay.flixel.debug.tools.btree;

#if debug
import bitdecay.behavior.tree.BTExecutor;
import bitdecay.behavior.tree.Node;
import bitdecay.flixel.debug.DebugTool.BaseToolData;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.events.Event;
using flixel.util.FlxBitmapDataUtil;

/**
 * An output window that lets you paste BitmapData in the debugger overlay.
 */
class BTreeInspector extends DebugTool<BTreeInspectorWindow> {
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
		window.onChange.add(handleChange);

		FlxG.signals.preStateSwitch.add(clear);
	}

	function clear() {
		trees.clear();
		window.clear();
	}

	override function init() {
		super.init();

		@:privateAccess
		var bytes = haxe.crypto.Base64.decode(BTreeIconData.nodeIconData.split(",")[1]);
        var loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) {
            nodeIconBitmap = cast(loader.content, openfl.display.Bitmap).bitmapData;
        });
        loader.loadBytes(bytes.getData());
	}

	override function loadData() {
		super.loadData();

		window.resize(window.width, window.height);
	}

	override function update() {
		if (nodeIconBitmap != null) {
			for (name => btree in pendingAdds) {
				var visualizer = new BTreeVisualizer(btree);
				visualizer.build();
				window.add(visualizer.composite, name, getNavSettings(name));
				trees.set(name, visualizer);
			}
			pendingAdds.clear();
		}

		if (focusNode != null) {
			@:privateAccess
			window.setInfoText([Type.getClassName(Type.getClass(focusNode))].concat(focusNode.getDetail()).join("\n"));
		} else {
			window.setInfoText("");
		}

		@:privateAccess {
			for (name => treeVis in trees) {
				if (window._curEntry.name == name) {
					if (treeVis.exec.ctx.dirty) {
						treeVis.exec.ctx.dirty = false;
						window.setContext(treeVis.exec.ctx);
					}
					if (treeVis.dirty) {
						treeVis.flushPendingDraws();
						treeVis.dirty = false;
						window.refreshCanvas();
						break;
					}
				}
			}
		}
	}

	override function getDefaults():Dynamic {
		var defaults = super.getDefaults();
		defaults.trees = [];
		return defaults;
	}

	function handleClick(name:String, x:Int, y:Int) {
		var vis = trees.get(name);
		var newFocus = vis.nodeAtPoint(x, y);
		vis.focusNode = newFocus;
		focusNode = newFocus;
	}

	function handleChange(name:String) {
		@:privateAccess {
			var data:BTreeInspectorData = data;
			for (saveTree in data.trees) {
				if (saveTree.name == name) {
					saveTree.zoom = window.zoom;
					saveTree.xOffset = window._curRenderOffsetRaw.x;
					saveTree.yOffset = window._curRenderOffsetRaw.y;
					FlxG.save.flush();
					return;
				}
			}

			var newVis:TreeNav = {
				name: name,
				zoom: window.zoom,
				xOffset: window._curRenderOffsetRaw.x,
				yOffset: window._curRenderOffsetRaw.y,
			}
			data.trees.push(newVis);
			FlxG.save.flush();
		}
	}

	function getNavSettings(name:String):TreeNav {
		var data:BTreeInspectorData = data;
		for (saveTree in data.trees) {
			@:privateAccess
			if (saveTree.name == name) {
				return saveTree;
			}
		}
		return null;
	}

	override function makeWindow(icon:BitmapData):BTreeInspectorWindow {
		return new BTreeInspectorWindow(icon);
	}

	public function addTree(name:String, btree:BTExecutor) {
		pendingAdds.set(name, btree);
	}
}

typedef BTreeInspectorData = BaseToolData & {
	var ?trees:Array<TreeNav>;
}

typedef TreeNav = {
	var ?name:String;
	var ?zoom:Float;
	var ?xOffset:Float;
	var ?yOffset:Float;
}
#end
