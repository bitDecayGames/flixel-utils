package states.transitions;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxSubState;

class TiledSpriteTransition extends FlxSubState {
	var callback:()->Void;

	public function new(base:FlxSprite, animName:String, cb:()->Void, tile:Bool = true) {
		super();

		this.callback = cb;

		if (tile) {
			// TODO: I'd love to use a FlxTiledSprite here, but animating those isn't straight forward
			var first = true;
			for (x in 0...Math.ceil(FlxG.width / base.width)) {
				for (y in 0...Math.ceil(FlxG.height / base.height)) {
					var t = new FlxSprite(x * base.width, y * base.height);
					add(t);
					t.loadGraphicFromSprite(base);
					t.scrollFactor.set();
					t.animation.play(animName);
					if (first) {
						t.animation.finishCallback = animDone;
						first = false;
					}
				}
			}
		} else {
			var sprite = new FlxSprite();
			sprite.loadGraphicFromSprite(base);
			sprite.screenCenter();
			sprite.scale.set(FlxG.width / sprite.width, FlxG.height / sprite.height);
			sprite.scrollFactor.set();
			sprite.animation.finishCallback = animDone;
			sprite.animation.play(animName);
			add(sprite);
		}
	}

	function animDone(name:String) {
		close();
		callback();
	}
}