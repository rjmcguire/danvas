module danvas.canvas;

import std.stdio;

public import dsfml.window: Keyboard;
import dsfml.graphics;

import danvas.renderingcontext;
import danvas.events;

class Canvas 
{
private:
	uint _width;
	uint _height;
	string _title;
	RenderWindow _sfmlWindow;
	RenderingContext _context;
	EventHandler _eventHandler;
	float _delta;
	Clock _deltaClock;
	Font[string] _fonts;

public:
	this(int width, int height, string title)
	{
		_width = cast(uint) width;
		_height = cast(uint) height;
		_title = title;

		_sfmlWindow = new RenderWindow(VideoMode(_width, _height), title, Window.Style.Close);
		_context = new RenderingContext(this, _sfmlWindow);
		_eventHandler = new EventHandler;

		_deltaClock = new Clock;
		_delta = 0.0f;
	}

	/*
	 * Calls the internal SFML window's display method.
	 */
	void display()
	{
		_sfmlWindow.display();		
		_delta = _deltaClock.restart().asSeconds() * 100.0f;
	}

	/*
	 * Calls the canvas's display method and then calls the next frame callback.
	 */
	void display(void function() callback)
	{
		display();
		callback();
	}

	/*
	 * Returns the internal SFML window's isOpen() value.
	 */
	bool shouldClose()
	{
		return !_sfmlWindow.isOpen();
	}

	/*
	 * Handles SFML events and converts them to a CanvasEvent.
	 * The Close type is hard coded to close the window. 
	 * The "resized" event will resize the view as well.
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
			// Resize the window's view if the window itself is resized.
			else if(event.type == Event.EventType.Resized)
			{
				_sfmlWindow.view = new View(FloatRect(0.0f, 0.0f, _width, _height));
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
					
					canvasEvent = new CanvasMouseEvent(
						event.mouseWheel.x, 
						event.mouseWheel.y
					).setDelta(event.mouseWheel.delta);

					break;

				case Event.EventType.MouseButtonPressed:
					eventName = "mousedown";
					
					canvasEvent = new CanvasMouseEvent(
						event.mouseButton.x,
						event.mouseButton.y
					).setWhich(event.mouseButton.button);

					break;

				case Event.EventType.MouseButtonReleased:
					eventName = "mouseup";
					
					canvasEvent = new CanvasMouseEvent(
						event.mouseButton.x,
						event.mouseButton.y
					).setWhich(event.mouseButton.button);

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
	 * Loads a given font file and adds it to the _fonts table with the given name.
	 */
	void loadFont(string name, string path)
	{
		Font font = new Font;

		if(!font.loadFromFile(path))
		{
			stderr.writeln("Failed to load font: " ~ path);
		} 
		else
		{
			_fonts[name] = font;
		}
	}

	/*
	 * Returns a font with the given name, for use in RenderingContext.
	 */
	Font getFont(string name)
	{
		if(name in _fonts)
		{
			return _fonts[name];
		}
		else
		{
			writeln("Nonexistent font: " ~ name);
		}

		return null;
	}

	/*
	 * The rendering context of the canvas object.
	 */
	RenderingContext getContext() 
	{
		return _context;
	}

	/*
	 * The current delta time.
	 */
	float getDelta()
	{
		return _delta;
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