package bitdecay.flixel.system;

import flixel.FlxG;

// Redirects logs to the Flixel logger if in debug mode.
// Otherwise, logs to standard logs
class QuickLog {
	public static inline function notice(msg:String) {
		#if FLX_DEBUG
		FlxG.log.notice(msg);
		#end
		trace('NOTICE: $msg');
	}

	public static inline function warn(msg:String) {
		#if FLX_DEBUG
		FlxG.log.warn(msg);
		#end
		trace('WARN: $msg');
	}

	public static inline function error(msg:String) {
		#if FLX_DEBUG
		FlxG.log.error(msg);
		#end
		trace('ERROR: $msg');
	}

	public static inline function critical(msg:String) {
		#if FLX_DEBUG
		FlxG.log.error('CRITICAL: $msg');
		#else
		throw 'CRITICAL: $msg';
		#end
	}
}
