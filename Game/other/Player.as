﻿package other {

	import org.flixel.*;	
	import org.flixel.plugin.photonstorm.FlxControl;
	import org.flixel.plugin.photonstorm.FlxControlHandler;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import org.flixel.system.FlxTile;
	import org.flixel.FlxEmitter;
	


	public class Player extends FlxSprite {



		[Embed(source = '../assets/player.png')] private var playerPNG:Class;
	
		protected var _bullets:FlxGroup;
		protected var _aim:uint;		
		
		private var pngWidth:int = 16;
		private var pngHeight:int = 18;		

		private var moveSpeed:int = 400;
		private var jumpPower:int = 800;

		private var maxHealth:int = 100;

		private var spawnX:int = 48;
		private var spawnY:int = 48;

		// lower the # the faster automatic firing of the bullets repeats.
		private var maxRateOfFire:Number = .15;
		private var rateOfFire:Number = -1; // -1 causes rateOfFire to trigger a new assessment and revert to maxRateOfFire.


		// sfx
		[Embed(source = '../assets/playerDeath.mp3')] private var playerDeathSFX:Class;
		private var playerDeathSound:FlxSound;

		[Embed(source = '../assets/playerJump.mp3')] private var playerJumpSFX:Class;
		private var playerJumpSound:FlxSound;






		// Player

		public function Player(X:int, Y:int,Bullets:FlxGroup):void {
			super(X,Y);
		
			// spawn locations
			spawnX = X;
			spawnY = Y;
			
			// health
			health = maxHealth;
	
			// graphic
			loadGraphic(playerPNG, true, true, pngWidth, pngHeight, true);
			width = 12;
			height = 18;

			// graphic offset
			offset.x = 2;
			offset.y = 0;

			// animations
			addAnimation("normal", [0,1,0,2],10,true);
			addAnimation("jump", [2],0,false);
			addAnimation("stopped", [0],0,false);

			// bullet stuff
			_bullets = Bullets;
			

			// control handler
			if (FlxG.getPlugin(FlxControl) == null)
			{
				FlxG.addPlugin(new FlxControl);
			}
			FlxControl.create(this, FlxControlHandler.MOVEMENT_ACCELERATES, FlxControlHandler.STOPPING_DECELERATES, 1, true, false);
			FlxControl.player1.setCursorControl(false, false, true, true);
			FlxControl.player1.setJumpButton("SPACE", FlxControlHandler.KEYMODE_PRESSED, 200, FlxObject.FLOOR, 250, 200);
			FlxControl.player1.setMovementSpeed(400, 0, 100, 200, 400, 0);

			//	downward gravity of 400px/sec
			FlxControl.player1.setGravity(0, 400);

			facing = RIGHT;

			// jump sfx
			playerJumpSound = new FlxSound();
			playerJumpSound.loadEmbedded(playerJumpSFX, false, false);		
			playerJumpSound.volume = .3;

			// death sfx
			playerDeathSound = new FlxSound();
			playerDeathSound.loadEmbedded(playerDeathSFX, false, false);

		}


		override public function update():void {
			
			super.update();

			// revive
			if(health <= 0) {
				trace("[*] Reviving player..");
				respawn(null,null);
			}

			// move left
			if(FlxG.keys.LEFT) {

				facing = LEFT;
				velocity.x -= moveSpeed * FlxG.elapsed;
				if(FlxG.keys.SPACE) { 
					this.angularVelocity = -800; // sprite rotation
				}

			}
			// move right
			else if(FlxG.keys.RIGHT) { 
				facing = RIGHT;
				velocity.x += moveSpeed * FlxG.elapsed;
				if(FlxG.keys.SPACE) { 
					this.angularVelocity = 800; // sprite rotation
				}

			}
	
			// aim direction
			_aim = facing;

			// 'd' key to flip gravity
			if(FlxG.keys.D) {
				FlxControl.player1.flipGravity();			

			}
			
			// 'r' key to respawn
			if(FlxG.keys.R) {
				respawn(null,null);
			}
			
			
			// 'space' pressed
			if(FlxG.keys.SPACE) { 
				if(velocity.y == 0)
					playerJumpSound.play(false)
			}

			// shooting
			if(FlxG.keys.S || FlxG.keys.justPressed("S"))
			{
				// rate of fire is for when holding "S" your weapon will switch to fully automatic mode. rate of fire will vary depending on powerups and weapons.
				rateOfFire -= FlxG.elapsed;
				if(rateOfFire <= 0) {
					// to get the midle point of player
					getMidpoint(_point);
					// recycling is designed to help you reuse game objects without always re-allocating or "newing" them.
					(_bullets.recycle(Bullet) as Bullet).shoot(_point,_aim);

					// reset rate of fire. once rate of fire drops below or equals zero; a new bullet will be created at that time.
					rateOfFire = maxRateOfFire;
				}
			}
			if(FlxG.keys.justReleased("S")) { 
				// we reset the rate of fire so that it will jump back into the if statement above firing when the S key is hit again and will still retain automatic firing without hiccups.
				rateOfFire = -1;
			}
			
			
			// player not jumping
			if(isTouching(FLOOR))
			{
				this.angularVelocity = 0;			
				this.angle = 0;				
			}
			/*if(velocity.y == 0) { 
				this.angularVelocity = 0;			
				this.angle = 0;
			}*/

			// player jumping
			if(velocity.y != 0) {
				play("jump");
			}

			// player not moving
			else if(velocity.x == 0) { 
				play("stopped");
			}

			// player moving
			else {
				play("normal");
			}
	
			// player outside of world bounds
			if(this.x <= 0 || this.y <= 0) {
				flicker(.5);
				respawn(null,null);
			}
			else if(x >= FlxG.worldBounds.right || y >= FlxG.worldBounds.bottom ) { 
				flicker(.5);
				respawn(null,null);
			}
		}


		// get bullet spawn point
		public function getBulletSpawnPosition():FlxPoint
		 {
			 var p: FlxPoint = new FlxPoint(x+7, y+9);
			 return p;
		 }
		
		// kill
		override public function kill():void {
			trace("Killed player");
		}

		// respawn
		public function respawn(tile:*, obj:*):void {
			this.alive = false;
			var spawnTimer:Timer = new Timer(300, 1);
			spawnTimer.start();
			spawnTimer.addEventListener(TimerEvent.TIMER_COMPLETE, spawnTimerFinalize);
			playerDeathSound.play(false);
		}


		// spawn timer complete
		private function spawnTimerFinalize(e:TimerEvent):void {
			e.target.removeEventListener(TimerEvent.TIMER_COMPLETE, spawnTimerFinalize);
			this.flicker(.5);
			this.reset(spawnX,spawnY);			
			this.alive = true;
			this.health = 100;
		}


	}//class
}//package
