package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public static var p1Scale:Float;
	public static var p2Scale:Float;
	public static var defWidth:Float;
	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	private var earlyHitMult:Float = 0.5;

	var ogW:Float;
	var ogH:Float;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public static var scales:Array<Float> = [0.85, 0.8, 0.75, 0.7, 0.66, 0.6, 0.55, 0.50, 0.46];
	public static var swidths:Array<Float> = [141, 124, 116, 108, 102, 93, 85, 77, 71];
	public static var posRest:Array<Int> = [0, 0, 0, 0, 25, 35, 50, 60, 70];

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;

	public var isPixel:Bool;
	var daValueToAdd:Float;
	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote(value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURTNOTE_assets');

					if(isSustainNote)
						missHealth = 0.1;
					else
						missHealth = 0.3;

					hitCausesMiss = true;
				case 'No Animation':
					noAnimation = true;
			}
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		var mania:Int = PlayState.SONG.mania;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		var daStage:String = PlayState.curStage;

		switch (daStage) {
			case 'school' | 'schoolEvil':
				isPixel = true;
			default:
				isPixel = false;
		}

		if (isPixel)
			frames = Paths.getSparrowAtlas('PIXEL_NOTE_assets');
		else
			frames = Paths.getSparrowAtlas('NOTE_assets');

		loadNoteAnims();

		antialiasing = ClientPrefs.globalAntialiasing;

		if(noteData > -1) {
			/*
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
			
			colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
			*/

			x += swidths[mania] * swagWidth * (noteData % Main.ammo[mania]);
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				animation.play(ClientPrefs.noteOrder[Main.gfxIndex[mania][noteData]]);
			}

			if (isSustainNote)
				x += 30;
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
			{
				alpha = 0.6;
				if(ClientPrefs.downScroll) flipY = true;
	
				//x += width / 2;
	
				animation.play(ClientPrefs.noteOrder[Main.gfxIndex[mania][noteData]] + ' tail');
	
				updateHitbox();
	
				//x -= width / 2;
	
				if (PlayState.curStage.startsWith('school'))
					x += 30;
	
				if (prevNote.isSustainNote)
				{
					prevNote.animation.play(ClientPrefs.noteOrder[Main.gfxIndex[mania][noteData]] + ' hold');
	
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
					prevNote.updateHitbox();
					// prevNote.setGraphicSize();
				}
			}

			defWidth = width;
	}

	function reloadNote(texture:String = null) {
		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		if (texture == null) {
			if (isPixel)
				frames = Paths.getSparrowAtlas('PIXEL_NOTE_assets');
			else
				frames = Paths.getSparrowAtlas('NOTE_assets');
		} else {
			frames = Paths.getSparrowAtlas(texture);
		}

		loadNoteAnims();
		animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}

		defWidth = width;
	}

	function loadNoteAnims() {
		for (i in 0...9)
		{
			animation.addByPrefix(Main.gfxLetter[i], Main.gfxLetter[i] + '0');

			if (isSustainNote)
			{
				animation.addByPrefix(Main.gfxLetter[i] + ' hold', Main.gfxLetter[i] + ' hold');
				animation.addByPrefix(Main.gfxLetter[i] + ' tail', Main.gfxLetter[i] + ' tail');
			}
		}

		ogW = width;
		ogH = height;
		if (!isSustainNote)
			setGraphicSize(Std.int(ogW * scales[PlayState.SONG.mania]));
		else
			setGraphicSize(Std.int(ogW * scales[PlayState.SONG.mania]), Std.int(ogH * scales[0]));
		defWidth = width;
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add('purpleholdend', [PURP_NOTE + 4]);
			animation.add('greenholdend', [GREEN_NOTE + 4]);
			animation.add('redholdend', [RED_NOTE + 4]);
			animation.add('blueholdend', [BLUE_NOTE + 4]);

			animation.add('purplehold', [PURP_NOTE]);
			animation.add('greenhold', [GREEN_NOTE]);
			animation.add('redhold', [RED_NOTE]);
			animation.add('bluehold', [BLUE_NOTE]);
		} else {
			animation.add('greenScroll', [GREEN_NOTE + 4]);
			animation.add('redScroll', [RED_NOTE + 4]);
			animation.add('blueScroll', [BLUE_NOTE + 4]);
			animation.add('purpleScroll', [PURP_NOTE + 4]);
		}
	}

	override function update(elapsed:Float)
		{
			super.update(elapsed);

			if (isSustainNote) {
				alpha = 0.5;
			}
	
			if (mustPress)
			{
				// The * 0.5 is so that it's easier to hit them too late, instead of too early
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * (isSustainNote ? 0.5 : 1)))
					canBeHit = true;
				else
					canBeHit = false;
	
				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
					tooLate = true;
			}
			else
			{
				canBeHit = false;
	
				if (strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
			
			if (tooLate)
			{
				if (alpha > 0.3)
					alpha = 0.3;
			}

			/*
			if (!inEditor) {
				ogW = width;
				ogH = height;
				if (!isSustainNote)
					setGraphicSize(Std.int(ogW * scales[PlayState.mania] * 1.5));
				else
					setGraphicSize(Std.int(ogW * scales[PlayState.mania] * 1.5), Std.int(ogH * scales[0] * 1.5));
			}*/
		}
	}
