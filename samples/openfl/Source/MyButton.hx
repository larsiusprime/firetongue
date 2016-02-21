package;
import flash.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

/**
 * ...
 * @author 
 */
class MyButton extends Sprite
{

	public function new(up:DisplayObject, over:DisplayObject, ?down:DisplayObject) 
	{
		super();
		
		if(up != null)
			addChild(up);
		
		if(down != null)
			addChild(down);
		
		if(over != null)
			addChild(over);
		
		mouseEnabled = true;
		buttonMode = true;
		
		this.up = up;
		this.down = down;
		this.over = over;
		
		if (this.down == null)
		{
			this.down = this.up;
		}
		
		addEventListener(MouseEvent.MOUSE_OVER, onOver, false, 0, true);
		addEventListener(MouseEvent.MOUSE_OUT, onUp, false, 0, true);
		addEventListener(MouseEvent.MOUSE_DOWN, onDown, false, 0, true);
		addEventListener(MouseEvent.CLICK, onOver, false, 0, true);
		
		onUp(null);
	}
	
	private function onUp(m:MouseEvent) {
		down.visible = over.visible = false;
		up.visible = true;
	}
	
	private function onOver(m:MouseEvent) {
		down.visible = up.visible = false;
		over.visible = true;
	}
	
	private function onDown(m:MouseEvent) {
		over.visible = up.visible = false;
		down.visible = true;
	}
	
	private var up:DisplayObject;
	private var down:DisplayObject;
	private var over:DisplayObject;
	
}