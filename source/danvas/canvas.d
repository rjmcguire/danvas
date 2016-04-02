module danvas.canvas;

import std.regex;
import std.string;
import std.stdio;
import std.conv;

public import dsfml.window;
import dsfml.graphics;

import danvas.events;

class RenderingContext
{
private:
	Canvas _parent;
	RenderWindow _sfmlWindow;

	// Properties
	string _fillStyle = null;
	string _strokeStyle = null;

	uint _lineWidth = 1;

	Color _fillColor;
	Color _strokeColor;

	// Converts a CSS color string to an SFML color.
	Color _parseColor(string cssColor) 
	{
		cssColor = strip(cssColor);

		auto hexRegex = regex(r"^#([A-Fa-f0-9]{6})$");
		auto rgbRegex = regex(r"^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+(?:\.\d+)?))?\)$");

		auto hexMatch = matchFirst(cssColor, hexRegex);
		auto rgbMatch = matchFirst(cssColor, rgbRegex);

		if(!hexMatch.empty)
		{
			string stripped = hexMatch[1];
			int hex = parse!int(stripped, 16);

			ubyte r = ((hex >> 16) & 0xFF);
			ubyte g = ((hex >> 8) & 0xFF);
			ubyte b = ((hex) & 0xFF);

			return Color(r, g, b);
		}
		else if (!rgbMatch.empty)
		{
			if(rgbMatch.length == 4) 
			{
				return Color(
					to!ubyte(rgbMatch[1]),
					to!ubyte(rgbMatch[2]),
					to!ubyte(rgbMatch[3])
				);
			}
			else if(rgbMatch.length == 5)
			{
				return Color(
					to!ubyte(rgbMatch[1]),
					to!ubyte(rgbMatch[2]),
					to!ubyte(rgbMatch[3]),
					to!ubyte(to!float(rgbMatch[4]) * 255.0f)
				);
			}
		}
		else
		{
			writeln("Failed to parse CSS color: " ~ cssColor);
		}

		return Color.Black;
	}

public:
	this(Canvas parent, RenderWindow window)
	{
		_parent = parent;
		_sfmlWindow = window;
	}

	/*
	 * The fill color of the rendering context.
	 * This is used to determine the color that any given fill method will use.
	 */
	@property
	{
		string fillStyle(string fillStyle) 
		{
			_fillStyle = fillStyle;
			_fillColor = _parseColor(_fillStyle);

			return _fillStyle;
		}

		string fillStyle()
		{
			return _fillStyle;
		}
	}

	/*
	 * The stroke color of the rendering context.
	 * This is used to determine the color that any given stroke method will use.
	 */
	@property
	{
		string strokeStyle(string strokeStyle) 
		{
			_strokeStyle = strokeStyle;
			_strokeColor = _parseColor(_strokeStyle);

			return _strokeStyle;
		}

		string strokeStyle()
		{
			return _strokeStyle;
		}
	}

	/*
	 * The width of any line drawn by the context.
	 */
	@property
	{
		uint lineWidth(uint width)
		{
			_lineWidth = width;
			return _lineWidth;
		}

		uint lineWidth()
		{
			return _lineWidth;
		}
	}

	/*
	 * Fills a portion of the screen with a rectangle of the given dimensions.
	 */
	void fillRect(float x, float y, float width, float height) 
	{
		RectangleShape rectangle = new RectangleShape(Vector2f(width, height));

		rectangle.position(Vector2f(x, y));

		if(_fillStyle !is null)
		{
			rectangle.fillColor(_fillColor);
		}

		if(_strokeStyle !is null)
		{
			rectangle.outlineColor(_strokeColor);
		}

		rectangle.outlineThickness(_lineWidth);

		_sfmlWindow.draw(rectangle);
	}

	/*
	 * Fills a portion of the screen with a black rectangle.
	 */
	void clearRect(float x, float y, float width, float height)
	{
		string oldStyle = _fillStyle !is null ? _fillStyle : "#000000";

		fillStyle("#000000");
		fillRect(x, y, width, height);

		fillStyle(oldStyle);
	}
}

class Canvas 
{
private:
	uint _width;
	uint _height;
	string _title;
	RenderWindow _sfmlWindow;
	RenderingContext _context;
	EventHandler _eventHandler;

public:
	this(int width, int height, string title)
	{
		_width = cast(uint) width;
		_height = cast(uint) height;
		_title = title;

		_sfmlWindow = new RenderWindow(VideoMode(_width, _height), title, Window.Style.Close);
		_context = new RenderingContext(this, _sfmlWindow);
		_eventHandler = new EventHandler;
	}

	/*
	 * Calls the internal SFML window's display method.
	 */
	void display()
	{
		_sfmlWindow.display();
	}

	/*
	 * Returns the internal SFML window's isOpen() value.
	 */
	bool shouldClose()
	{
		return !_sfmlWindow.isOpen();
	}

	/*
	 * Handles SFML events and converts them to canvas-like event name strings.
	 */
	void dispatchEvents()
	{
		Event event;

		while(_sfmlWindow.pollEvent(event))
		{
			if(event.type == Event.EventType.Closed)
			{
				_sfmlWindow.close();
				return;
			}

			string eventName = null;
			CanvasEvent canvasEvent = new CanvasEvent;

			switch(event.type)
			{
				case Event.EventType.Resized:
					eventName = "resize";
					break;
				case Event.EventType.LostFocus:
					eventName = "unfocus";
					break;
				case Event.EventType.GainedFocus:
					eventName = "focus";
					break;
				case Event.EventType.KeyPressed:
					eventName = "keydown";
					canvasEvent = new CanvasKeyEvent(event.key.code);
					break;
				case Event.EventType.KeyReleased:
					eventName = "keyup";
					canvasEvent = new CanvasKeyEvent(event.key.code);
					break;
				case Event.EventType.MouseWheelMoved:
					eventName = "mousewheel";
					canvasEvent = new CanvasMouseEvent(event.mouseWheel.x, event.mouseWheel.y).setDelta(event.mouseWheel.delta);
					break;
				case Event.EventType.MouseButtonPressed:
					eventName = "mousedown";
					canvasEvent = new CanvasMouseEvent(event.mouseButton.x, event.mouseButton.y).setWhich(event.mouseButton.button);
					break;
				case Event.EventType.MouseButtonReleased:
					eventName = "mouseup";
					canvasEvent = new CanvasMouseEvent(event.mouseButton.x, event.mouseButton.y).setWhich(event.mouseButton.button);
					break;
				case Event.EventType.MouseMoved:
					eventName = "mousemove";
					canvasEvent = new CanvasMouseEvent(event.mouseMove.x, event.mouseMove.y);
					break;

				default: break;
			}

			_eventHandler.callMethod(eventName, canvasEvent);
		}
	}

	/*
	 * Registers an event within the event handler.
	 */
	void on(string eventName, void function(CanvasEvent) method)
	{
		_eventHandler.registerEvent(eventName, method);
	}

	/*
	 * Fires an even with the given name. 
	 * This is useful for custom events.
	 */
	void fire(string eventName)
	{
		_eventHandler.callMethod(eventName, new CanvasEvent);
	}

	/*
	 * The rendering context of the canvas object.
	 */
	RenderingContext getContext() 
	{
		return _context;
	}

	/*
 	 * The width of the window and simulated canvas element. 
 	 * When set, this will resize the RenderWindow and set the object's _width variable.
	 */
	@property 
	{
		uint width(uint width)
		{
			_width = width;
			_sfmlWindow.size(Vector2u(_width, _height));

			return _width;
		}

		uint width()
		{
			return _width;
		}
	}

	/*
 	 * The height of the window and simulated canvas element. 
 	 * When set, this will resize the RenderWindow and set the object's _height variable.
	 */
	@property 
	{
		uint height(uint height)
		{
			_height = height;
			_sfmlWindow.size(Vector2u(_width, _height));

			return _height;
		}

		uint height()
		{
			return _height;
		}
	}
}