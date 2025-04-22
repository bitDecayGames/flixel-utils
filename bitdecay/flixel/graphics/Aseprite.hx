package bitdecay.flixel.graphics;

import haxe.io.Path;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxJsonAsset;
import flixel.system.FlxAssets.FlxGraphicAsset;

import bitdecay.flixel.graphics.AsepriteTypes.AseAtlasSliceKey;
import bitdecay.flixel.graphics.AsepriteTypes.AseAtlasFrame;
import bitdecay.flixel.graphics.AsepriteTypes.AseAtlas;

class Aseprite {
	// a cache to prevent us from reparsing json multiple times
	private static var atlasCache:Map<String, AseAtlas> = [];

	/**
	 * loads all animations from the atlas file onto the provided sprite
	**/
	public static function loadAllAnimations(into:FlxSprite, data:String) {
		if (!atlasCache.exists(data)) {
			var asAtlas:FlxJsonAsset<AseAtlas> = data;
			atlasCache.set(data, asAtlas.getData());
		}

		var atlas = atlasCache.get(data);

		var imgAsset = Path.join([Path.directory(data), atlas.meta.image]);

		if (!alreadyCached(imgAsset)) {
			loadAsepriteAtlas(data);
		}

		var width = 0;
		var height = 0;
		if (atlas.frames is Array) {
			width = Std.int(atlas.frames[0].sourceSize.w);
			height = Std.int(atlas.frames[0].sourceSize.h);
		} else {
			var hash:AsepriteTypes.Hash<AsepriteTypes.AseAtlasFrame> = atlas.frames;
			var frame = hash.keyValueIterator().next();
			width = Std.int(frame.value.sourceSize.w);
			height = Std.int(frame.value.sourceSize.h);
		}

		// passing animated false here to just save generating frames we won't be using
		into.loadGraphic(imgAsset, false, width, height);

		// Loading the frames as FlxAtlasFrames will parse the duration off of the frames
		// for us.
		var atlasData = FlxAtlasFrames.fromAseprite(imgAsset, data);
		into.frames = atlasData;

		var tags:Array<AsepriteTypes.AseAtlasTag> = atlas.meta.frameTags;
		if (tags.length == 0) {
			// if we have no tags, load frames as individual animations for ease-of-use
			var frameData = atlas.frames;
			if (frameData is Array) {
				var frameDataArr:Array<AseAtlasFrame> = cast frameData;
				for (i in 0...frameDataArr.length) {
					into.animation.add(frameDataArr[i].filename, [i], false);
				}
			} else {
				// TODO:
			}
		}
		for (tag in tags) {
			var loop = tag.repeat != 1;
			var frames = [for (i in tag.from...tag.to + 1) i];
			if (tag.direction == "reverse") {
				frames.reverse();
			}
			into.animation.add(tag.name, frames, loop);
		}

		into.animation.add("all_frames", [for (i in 0...into.frames.frames.length) i], true);
	}

	/**
	 * Returns the aseprite data for the requested slice
	**/
	public static function getSliceKey(data:String, sliceName:String):AseAtlasSliceKey {
		if (!atlasCache.exists(data)) {
			var asAtlas:FlxJsonAsset<AseAtlas> = data;
			atlasCache.set(data, asAtlas.getData());
		}

		var atlas = atlasCache.get(data);

		var regex = ~/(.*)_(\d+)/;
		var matches = regex.match(sliceName);

		if (matches) {
			var matchSlices = atlas.meta.slices.filter((s) -> {
				s.name == regex.matched(1);
			});
			if (matchSlices.length > 0) {
				var slice = matchSlices[0];
				var frame = Std.parseInt(regex.matched(2));
				if (slice.keys.length > frame) {
					return slice.keys[frame];
				}
			}
		}

		return null;
	}

	/**
	 * returns the frame associated with the requested slice
	**/
	public static function getSliceFrame(data:String, sliceName:String) {
		if (!atlasCache.exists(data)) {
			var asAtlas:FlxJsonAsset<AseAtlas> = data;
			atlasCache.set(data, asAtlas.getData());
		}

		var atlas = atlasCache.get(data);

		var imgAsset = Path.join([Path.directory(data), atlas.meta.image]);

		if (!alreadyCached(imgAsset)) {
			loadAsepriteAtlas(data);
		}

		var atlasData = FlxAtlasFrames.fromAseprite(imgAsset, data);

		return atlasData.getByName(sliceName);
	}

	/**
	 * loads the requested slice image from the atlas onto the provided sprite
	**/
	public static function loadSlice(into:FlxSprite, data:String, sliceName:String) {
		into.frame = getSliceFrame(data, sliceName);
		into.width = into.frame.frame.width;
		into.height = into.frame.frame.height;
	}

	private static function alreadyCached(asset:FlxGraphicAsset):Bool {
		var graphic:FlxGraphic = FlxG.bitmap.add(asset);
		if (graphic == null)
			return false;

		return FlxAtlasFrames.findFrame(graphic) != null;
	}

	private static function loadAsepriteAtlas(data:String) {
		if (!atlasCache.exists(data)) {
			var asAtlas:FlxJsonAsset<AseAtlas> = data;
			atlasCache.set(data, asAtlas.getData());
		}

		var atlas = atlasCache.get(data);

		var imgAsset = Path.join([Path.directory(data), atlas.meta.image]);
		var atlasData = FlxAtlasFrames.fromAseprite(imgAsset, data);

		var slices:Array<AsepriteTypes.AseAtlasSlice> = atlas.meta.slices;
		for (slice in slices) {
			texturePackerSliceHelper(atlas.frames, slice, atlasData, true);
		}
	}

	private static function texturePackerSliceHelper(frameData:AsepriteTypes.HashOrArray<AsepriteTypes.AseAtlasFrame>, slice:AsepriteTypes.AseAtlasSlice,
			frames:FlxAtlasFrames, useFrameDuration = false):Void {
		if (frameData is Array) {
			for (key in slice.keys) {
				var refFrame = frameData[key.frame];

				var frameName = '${slice.name}_${key.frame}';

				var frameRect = FlxRect.get(refFrame.frame.x + key.bounds.x, refFrame.frame.y + key.bounds.y, key.bounds.w, key.bounds.h);

				// we use the slice size here. Unclear if this will cause issues elsewhere
				final sourceSize = FlxPoint.get(key.bounds.w, key.bounds.h);
				final offset = FlxPoint.get(refFrame.spriteSourceSize.x, refFrame.spriteSourceSize.y);
				final duration = (useFrameDuration && refFrame.duration != null) ? refFrame.duration / 1000 : 0;
				frames.addAtlasFrame(frameRect, sourceSize, offset, frameName, 0, false, false, duration);
			}
		} else {
			var msg = "--json-hash Aseprite exports currently do not support slices. Use --json-array instead";
			trace(msg);
			throw msg;
		}
	}
}
