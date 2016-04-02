module danvas.canvas;

import dsfml.window;
import dsfml.graphics;

import danvas.events;

class RenderingContext
{
private:
	RenderWindow _sfmlWindow;

	// Properties
	string _fillStyle;
	string _strokeStyle;

public:
	this(RenderWindow window)
	{
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
			return _strokeStyle;
		}

		string strokeStyle()
		{
			return _strokeStyle;
		}
	}

	/*
	 * Fills a portion of the screen with a white rectangle.
	 */
	void clearRect(int x, int y, int width, int height)
	{

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
		_context = new RenderingContext(_sfmlWindow);
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
					break;
				case Event.EventType.KeyReleased:
					eventName = "keyup";
					break;
				case Event.EventType.MouseWheelMoved:
					eventName = "mousewheel";
					break;
				case Event.EventType.MouseButtonPressed:
					eventName = "mousedown";
					break;
				case Event.EventType.MouseButtonReleased:
					eventName = "mouseup";
					break;
				case Event.EventType.MouseMoved:
					eventName = "mousemove";
					break;

				default: break;
			}

			_eventHandler.callMethod(eventName, event);
		}
	}

	/*
	 * Registers an event within the event handler.
	 */
	void on(string eventName, void function(Event) method)
	{
		_eventHandler.registerEvent(eventName, method);
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