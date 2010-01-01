/**
* TelePong
*
* SimplePong with hormones, now with teletransportation power!
* 
* @author Yëco
* 
* */

package {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.text.*;
    
    [SWF(width = "465", height = "465", frameRate = "50", backgroundColor="0x000000")]
    public class TelePong extends Sprite {
        
        private var isGameOver:Boolean;
        private var gameOverCount:int;
        
        // Weight to prevent the re-start would not see the score remain
        private const GAME_OVER_WAIT:int = 50;
        
        private const SCREEN_W:int = 465;
        private const SCREEN_H:int = 465;
        
        private const PADDLE_OFFSET:Number = 25;
        private var PADDLE_XS:Array = [ PADDLE_OFFSET, SCREEN_W - PADDLE_OFFSET ];
        
        private const PADDLE_HX:int = 7;
        private const PADDLE_HY:int = 50;
        
        // Coordinates of the center of the paddle
        private var paddleX:Number = PADDLE_XS[side];
        private var paddleY:Number;
        
        // Left paddle
        private var side:int = 0;
        
        //Teletransport?
        private var teleporting:Boolean;
        
        private var ballX:Number;
        private var ballY:Number;
        private var ballVX:Number;
        private var ballVY:Number;
        private var ballSpeed:Number;
        private const BALL_RADIUS:Number = 7;
        //private const BALL_SIZE:Number = 20;
        
        private var paddle:Shape = new Shape();
        private var ball:Shape = new Shape();
        
        private var score:int;
        
        private var gameOverText:TextField;
        private var scoreText:TextField;
        private var instructionText:TextField;
        
        // I can't see the motion blur to brighten dark
        private var rLum:Number = 40;

        private var gLum:Number = 220;

        private var bLum:Number = 0;
        
        private var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter(
            [rLum, gLum, bLum, 0, 0,
            rLum, gLum, bLum, 0, 0,
            rLum, gLum, bLum, 0, 0,
            0, 0, 0, 1, 0]
        );
        private var glowFilter:GlowFilter = new GlowFilter(0x2ADC00, 1, 8, 8);
        private var paddleFilters:Array = [ new BlurFilter(0, 0, 2), colorMatrixFilter, glowFilter ];
        
        public function TelePong() {
            function createText(x:Number, y:Number, fontSize:Number):TextField {
                var tf:TextField = new TextField();
                tf.defaultTextFormat = new TextFormat("standard 07_53", fontSize, 0x2ADC00);
                tf.selectable = false;
                tf.x = x;
                tf.y = y;
                return tf;
            }
            
            gameOverText = createText(180, 150, 20);
            gameOverText.text = "GAME OVER :P";
            gameOverText.autoSize = TextFieldAutoSize.CENTER;
            gameOverText.visible = isGameOver;
            addChild(gameOverText);
            
            scoreText = createText(155, 20, 60);
            scoreText.autoSize = TextFieldAutoSize.RIGHT;
            addChild(scoreText);
            
            instructionText = createText(280, 180, 23);
            instructionText.text = "CLICK TO TELEPORT!";
            instructionText.autoSize = TextFieldAutoSize.RIGHT;
            addChild(instructionText);
            
            var g:Graphics = paddle.graphics;
            g.beginFill(0x2ADC00);
            g.drawRoundRect( -PADDLE_HX, -PADDLE_HY, PADDLE_HX * 2, PADDLE_HY * 2, 0, 0);
            g.endFill();
            addChild(paddle);
            
            g = ball.graphics;
            g.beginFill(0xFFFFFF);
           
            g.drawCircle(0, 0, BALL_RADIUS);
            
           /**
           * TODO: Fix square ball
           * g.drawRect( BALL_SIZE, BALL_SIZE, BALL_SIZE, BALL_SIZE); 
           
           * **/ 
          
            g.endFill();
            ball.filters = [ glowFilter ]; // Not really sure about the blur on the ball
            addChild(ball);
            
            initGame();
            
            addEventListener(Event.ENTER_FRAME, enterFrameHandler);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
        }
        
        public function initGame():void {
            ballSpeed = 10; //Increase difficulty
            score = 0;
            scoreText.text = "0";
            
            side = 0;
            paddleX = PADDLE_XS[side];
            teleporting = false;
            setPaddleBlur(0);
            
            ballX = SCREEN_W;
            ballY = random(SCREEN_H * 0.1, SCREEN_H * 0.9);
            ballVX = -ballSpeed;
            ballVY = 0;
            
            isGameOver = false;
        }
        
        private function setPaddleBlur(blur:Number):void {
            paddleFilters[0].blurX = blur;
            paddle.filters = paddleFilters;
        }
        
        private function enterFrameHandler(event:Event):void {
            if (teleporting) {
                var d:Number = (PADDLE_XS[side] - paddleX) * 0.2;
                d += sign(d) * 4;
                if (Math.abs(PADDLE_XS[side] - paddleX) < d) {
                    paddleX = PADDLE_XS[side];
                    setPaddleBlur(0);
                    teleporting = false;
                } else {
                    paddleX += d;
                    setPaddleBlur(Math.abs(d * 0.65));
                }
            }
            paddleY = clamp(mouseY, PADDLE_HY, SCREEN_H - PADDLE_HY);
            
            if (!isGameOver) {
                if (!teleporting) {
                    if ((ballVX < 0 && side == 0 && ballX + ballVX < PADDLE_XS[0] + PADDLE_HX) || 
                        (ballVX > 0 && side == 1 && ballX + ballVX > PADDLE_XS[1] - PADDLE_HX)) {
                        if (Math.abs(ballY - paddleY) > PADDLE_HY + BALL_RADIUS * 0.8) {
                            isGameOver = true;
                            gameOverCount = 0;
                        } else {
                            ballSpeed = clamp(ballSpeed + 0.2, 0, 15);
                            
                            ballVX = -sign(ballVX) * ballSpeed;
                            ballVY += random( -ballSpeed, ballSpeed);
                            ballVY = clamp(ballVY, -ballSpeed, ballSpeed);
                            
                            score = clamp(score + 1, 0, 9999);
                            scoreText.text = String(score);
                        }
                    }
                }
                if (!inRange(ballX, -BALL_RADIUS, SCREEN_W + BALL_RADIUS)) {
                    isGameOver = true;
                    gameOverCount = 0;
                }
            } else {
                gameOverCount++;
            }
            if (!inRange(ballY + ballVY, BALL_RADIUS, SCREEN_H - BALL_RADIUS)) {
                ballVY = -ballVY;
            }
            ballX += ballVX;
            ballY += ballVY;
            
            paddle.x = paddleX;
            paddle.y = paddleY;
            ball.x = ballX;
            ball.y = ballY;
            
            gameOverText.visible = isGameOver && (gameOverCount > GAME_OVER_WAIT);
        }
        
        private function mouseDownHandler(MouseEvent:Event):void {
            side = 1 - side;
            teleporting = true;
            
            if (gameOverText.visible) {
                initGame();
            }
            instructionText.visible = false;
        }
        
        private function random(n:Number, m:Number):Number {
            return n + Math.random() * (m - n);
        }
        private function sign(n:Number):Number {
            if (n > 0) { return 1; }
            if (n < 0) { return -1; }
            return 0;
        }
        private function clamp(n:Number, min:Number, max:Number):Number {
            if (n < min) { n = min; }
            if (n > max) { n = max; }
            return n;
        }
        private function inRange(n:Number, min:Number, max:Number):Boolean {
            return (n >= min && n <= max);
        }
    }
}