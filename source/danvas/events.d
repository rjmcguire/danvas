module danvas.events;

import dsfml.window;

class CanvasEvent
{}

class CanvasMouseEvent : CanvasEvent 
{
	int x;
	int y;
	int which;
	int delta;

	this(int x, int y)
	{
		this.x = x;
		this.y = y;
	}

	CanvasMouseEvent setWhich(Mouse.Button button)
	{
		if(button == Mouse.Button.Left)
		{
			which = 1;
		}

		if(button == Mouse.Button.Middle)
		{
			which = 2;
		}

		if(button == Mouse.Button.Right)
		{
			which = 3;
		}

		return this;
	}

	CanvasMouseEvent setDelta(int delta) 
	{
		this.delta = delta;
		return this;
	}
}

class CanvasKeyEvent : CanvasEvent
{
	Keyboard.Key keyCode;

	this(Keyboard.Key keyCode)
	{
		this.keyCode = keyCode;
	}
}

class EventHandler
{
private:
	void function(CanvasEvent)[string] _methods;

public:
	void registerEvent(string name, void function(CanvasEvent) method)
	{
		_methods[name] = method;
	}

	void callMethod(string name, CanvasEvent event)
	{
		if(name in _methods)
		{
			_methods[name](event);
		}
	}
}
