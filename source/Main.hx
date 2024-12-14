package;

import config.Config;
import openfl.system.System;
import flixel.FlxG;
import flixel.util.FlxColor;
import sys.FileSystem;
import openfl.display3D.Context3DTextureFormat;
import openfl.display.FPS;
import openfl.display.Sprite;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

import backend.Highscore;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{	
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public static var fpsDisplay:FPS_Mem;

	// #if web
	// 	var vHandler:VideoHandler;
	// #elseif desktop
	// 	var webmHandle:WebmHandler;
	// #end
	// public static var novid:Bool = Sys.args().contains("-novid");
	public static var novid = true;
	public static var flippymode:Bool = Sys.args().contains("-flippymode");

	public static var characters:Array<String> = [];
	public static var characterNames:Array<String> = [];
	public static var characterQuotes:Array<String> = [];
	public static var characterDesc:Array<String> = [];
	public static var characterCredits:Array<String> = [];
	public static var characterCampaigns:Map<String, Array<Array<String>>> = [];
	public static var characterColors:Map<String, FlxColor> = [];
	public static var charToSong:Map<String, String> = [];

	public static var lol:AudioStreamThing;

	public static function addCharacter(who:String, name:String, quote:String, desc:String, song:String, color:FlxColor = FlxColor.WHITE, ?credit:String)
	{
		characters.push(who);
		characterNames.push(name);
		characterQuotes.push(quote);
		characterDesc.push(desc);
		characterCredits.push(credit);
		characterColors[who] = color;
		charToSong[who] = song;
	}

	public static function setCampaign(who:String, campaign:Array<String>, difficulties:Array<String>)
	{
		var songs:Array<String> = [];
		var diffs:Array<String> = [];
		for (char in campaign)
		{
			songs.push(charToSong[char]);
			if (char == 'prisma2')
				campaign[campaign.indexOf('prisma2')] = 'prisma';
		}
		for (diff in difficulties)
		{
			switch (diff)
			{
				case 'normal':
					diffs.push("");
				default:
					diffs.push("-" + diff);
			}
		}

		characterCampaigns[who] = [songs, diffs, campaign];
	}

	public static function music(path:String, vol:Float = 1, looping = true)
	{
		if (lol != null)
		{
			lol.stop();
			lol.destroy();
		}
		lol = new AudioStreamThing(path);
		lol.volume = vol;
		lol.looping = looping;
		lol.play();
	}

	public static function unmusic()
	{
		if (lol != null)
		{
			lol.stop();
			lol.destroy();
		}
		lol = null;
	}

	public function new()
	{
		super();

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		addChild(new FlxGame(0, 0, Startup, 1, 144, 144, true));

		openfl.Lib.current.stage.application.onExit.add(function(code)
		{
			AudioStreamThing.destroyEverything();
			deleteDirRecursively("assets/temp");
		});

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if !mobile
		fpsDisplay = new FPS_Mem(10, 3, 0xFFFFFF);
		fpsDisplay.showFPS = true;
		addChild(fpsDisplay);
		switch (FlxG.save.data.fpsDisplayValue)
		{
			case 0:
				Main.fpsDisplay.showFPS = true;
				Main.fpsDisplay.showMem = true;
			case 1:
				Main.fpsDisplay.showFPS = true;
				Main.fpsDisplay.showMem = false;
			case 2:
				Main.fpsDisplay.showFPS = false;
		}
		#end

		// On web builds, video tends to lag quite a bit, so this just helps it run a bit faster.
		// #if web
		// VideoHandler.MAX_FPS = 30;
		// #end

		FlxG.signals.postStateSwitch.add(function()
		{
			System.gc();
			// cpp.vm.Gc.compact();
			// System.gc();
		});

		// FlxG.signals.preStateCreate.add(function(_)
		// {
		// 	Cashew.destroyAll();
		// });

		trace("-=Args=-");
		trace("novid: " + novid);
		trace("flippymode: " + flippymode);

		addCharacter("bf", "Boyfriend", "Beep.",
			"An up-and-coming singer trying to prove himself in front of his girlfriend and her parents. He may not be the sharpest tool in the shed, but he's got a knack for rap battles.",
			"Kickin", 0x31b0d1);
		addCharacter("dad", "Daddy Dearest", "Hands off my daughter.",
			"An ex-rockstar who has since settled down with Mommy Mearest. Currently spends his time trying to thwart the relationship between Boyfriend and his daughter.",
			"Demoniac", 0xaf66ce);
		addCharacter("spooky", "Skid & Pump", "It's spooky month!",
			"A pair of happy-go-lucky kids who love to celebrate the month of October. They tend to sing together. They also don't seem to ever take off their halloween costumes.",
			"Revenant", 0xffa245);
		addCharacter("pico", "Pico", "Don't worry, the safety's off.",
			"A crazed gunman or an assassin? Either way, he's got a firearm and he's not afraid to use it. Has a surprisingly deep voice despite his short stature.",
			"Trigger-Happy", 0xb7d855);
		addCharacter("mom", "Mommy Mearest", "Take care not to scratch the limo.",
			"A singer who's married to Daddy Dearest. She has a few henchman by her side and tends to cruise with them on her limo. Doesn't approve of the relationship between Boyfriend and her daughter.",
			"Playtime", 0xd8558e);
		addCharacter("lily", "Lily", "You're dinner tonight...literally.",
			"An amnesiac zombie who knows nothing but her name. In order to find her memory, she usually eats humans and travels around various towns.",
			"Zombie-Flower", 0xff99cc);
		addCharacter("atlanta", "Atlanta", "I'm pretty so-Fish-ticated myself!",
			"A literal fish out of water, she's trying her best to fit in with the land-dwellers. All while cracking fish puns in every sentence, she can be pretty obnoxious at times.",
			"Tune-A-Fish", 0x4c6b9b, "Ket Overkill");

		characterColors["gf"] = 0xa5004d;
		characterColors["prisma"] = 0x9fd5ed;
		characterColors["skid"] = 0xa2a2a2;
		characterColors["pump"] = 0xd57e00;
		characterColors["senpai"] = 0xfac146;
		characterColors["tankman"] = 0x383838;
		charToSong["prisma"] = "Fresnel";
		charToSong["prisma2"] = "SiO2";

		setCampaign("bf", ["spooky", "pico", "atlanta", "lily", "mom", "dad", "prisma2"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("dad", ["atlanta", "mom", "pico", "lily", "spooky", "bf", "prisma"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("spooky", ["lily", "bf", "pico", "mom", "dad", "atlanta", "prisma"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("pico", ["dad", "lily", "bf", "spooky", "atlanta", "mom", "prisma2"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("mom", ["pico", "dad", "spooky", "atlanta", "bf", "lily", "prisma"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("lily", ["bf", "atlanta", "dad", "mom", "pico", "spooky", "prisma2"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
		setCampaign("atlanta", ["mom", "spooky", "bf", "dad", "lily", "pico", "prisma2"], ["easy", "easy", "normal", "normal", "hard", "hard", "normal"]);
	}	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		Highscore.load();

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});
	}
	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		/*
		 * remove if you're modding and want the crash log message to contain the link
		 * please remember to actually modify the link for the github page to report the issues to.
		*/
		// 
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";
		#end

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end

	public static function changeFramerate(newRate:Int)
	{
		FlxG.updateFramerate = FlxG.drawFramerate = newRate;
	}

	public static function fpsSwitch()
	{
		if (Config.noFpsCap)
		{
			changeFramerate(999);
		}
		else
			changeFramerate(144);
	}

	static function deleteDirRecursively(path:String):Void
	{
		if (FileSystem.exists(path) && FileSystem.isDirectory(path))
		{
			var entries = FileSystem.readDirectory(path);
			if (entries != null)
			{
				for (entry in entries)
				{
					if (FileSystem.isDirectory(path + '/' + entry))
					{
						deleteDirRecursively(path + '/' + entry);
						FileSystem.deleteDirectory(path + '/' + entry);
					}
					else
					{
						FileSystem.deleteFile(path + '/' + entry);
					}
				}
				FileSystem.deleteDirectory(path);
			}
		}
	}
}
