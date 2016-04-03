module danvas.canvas;

import std.regex;
import std.string;
import std.stdio;
import std.conv;
import std.math;

public import dsfml.window : Keyboard;
import dsfml.graphics;

import danvas.events;

class Image
{
private:
	Texture _sfmlTexture;
	string _source;

public:
	this()
	{
		_source = null;
	}

	this(string source)
	{
		src(source);
	}

	/*
	 * The file path of the image.
	 * When set, _texture will be loaded from the given source.
	 */
	@property
	{
		string src(string source)
		{
			_source = source;
			_sfmlTexture = new Texture;

			if(!_sfmlTexture.loadFromFile(_source))
			{
				stderr.writeln("Failed to load image: " ~ source);
			}

			return _source;
		}

		string src()
		{
			return _source;
		}
	}
}

class Size
{
	int width, height;

	this(int width, int height)
	{
		this.width = width;
		this.height = height;
	}
}

class RenderingContext
{
private:
	Canvas _parent;
	RenderWindow _sfmlWindow;

	// Properties
	string _fillStyle = null;
	string _strokeStyle = null;

	uint _lineWidth = 1;
	string _lineCap = "butt";

	Color _fillColor;
	Color _strokeColor;

	string _fontString = null;
	string _fontName = null;
	uint _fontSize;

	string _textAlign = "left";
	string _textBaseline = "top";

	Vector2f[] _lineVertices;

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
				// CSS RGBA alpha values are from 0.0 to 1.0, whereas SFML uses 0-255.
				// For this reason, the given alpha is bounds checks and multiplied by 255.

				float a = to!float(rgbMatch[4]);

				if(a < 0) 
				{
					a = 0.0f;
				}

				if(a > 1)
				{
					a = 1.0f;
				}

				a *= 255.0f;

				return Color(
					to!ubyte(rgbMatch[1]),
					to!ubyte(rgbMatch[2]),
					to!ubyte(rgbMatch[3]),
					to!ubyte(a)
				);
			}
		}
		else
		{
			writeln("Failed to parse CSS color: " ~ cssColor);
		}

		return Color.Black;
	}

	Shape _getLineCap()
	{
		switch(_lineCap)
		{
			case "round":
				CircleShape cap = new CircleShape(_lineWidth / 2.0f);
				cap.fillColor = _strokeColor;

				return cap;

			case "square":
				RectangleShape cap = new RectangleShape(Vector2f(_lineWidth, _lineWidth));
				cap.fillColor = _strokeColor;

				return cap;

			default: break;
		}

		return null;
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
	 * The context's current font.
	 */
	@property
	{
		string font(string fontString)
		{
			_fontString = fontString;

			auto fontStringRegex = regex(r"^(\d+)px\s*(.+)$");
			auto fontStringMatch = matchFirst(_fontString, fontStringRegex);

			if(!fontStringMatch.empty)
			{
				_fontSize = to!uint(fontStringMatch[1]);
				_fontName = fontStringMatch[2];
			}
			else
			{
				writeln("Invalid font string: " ~ _fontString);
			}

			return _fontString;
		}

		string font()
		{
			return _fontString;
		}
	}

	/*
	 * The text align of the context. 
	 * This determines the X offset of any text drawn in the context.
	 */
	@property
	{
		string textAlign(string textAlign)
		{
			if(cmp(textAlign, "right") == 0 || cmp(textAlign, "center") == 0 || cmp(textAlign, "left") == 0)
			{
				_textAlign = textAlign;
			}
			else
			{
				writeln("Invalid textAlign: " ~ textAlign);
			}

			return textAlign;
		}

		string textAlign()
		{
			return _textAlign;
		}
	}

	/*
	 * The text baseline of the context. 
	 * This determines the Y offset of any text drawn in the context.
	 */
	@property
	{
		string textBaseline(string textBaseline)
		{
			if(cmp(textBaseline, "top") == 0 || cmp(textBaseline, "middle") == 0 || cmp(textBaseline, "bottom") == 0)
			{
				_textBaseline = textBaseline;
			}
			else
			{
				writeln("Invalid textBaseline: " ~ textBaseline);
			}

			return textBaseline;
		}

		string textBaseline()
		{
			return _textBaseline;
		}
	}

	/*
	 * The style of line cap draw on all lines.
	 * Options are butt, round, and square.
	 */
	@property
	{
		string lineCap(string lineCap)
		{
			if(cmp(lineCap, "butt") == 0 || cmp(lineCap, "round") == 0 || cmp(lineCap, "square") == 0)
			{
				_lineCap = lineCap;
			}
			else
			{
				writeln("Invalid lineCap: " ~ lineCap);
			}

			return lineCap;
		}

		string lineCap()
		{
			return _lineCap;
		}
	}

	/*
	 * Fills a portion of the screen with a rectangle of the given dimensions.
	 */
	void fillRect(float x, float y, float width, float height) 
	{
		RectangleShape rectangle = new RectangleShape(Vector2f(width, height));

		rectangle.position = Vector2f(x, y);

		if(_fillStyle !is null)
		{
			rectangle.fillColor = _fillColor;
		}

		_sfmlWindow.draw(rectangle);
	}

	/*
	 * Draws a rectangle outline around the given dimensions.
	 */
	void strokeRect(float x, float y, float width, float height)
	{
		RectangleShape rectangle = new RectangleShape(Vector2f(width, height));

		rectangle.position = Vector2f(x, y);

		rectangle.fillColor = Color.Transparent;

		if(_strokeStyle !is null)
		{
			rectangle.outlineColor = _strokeColor;
		}

		rectangle.outlineThickness = _lineWidth;

		_sfmlWindow.draw(rectangle);
	}

	/*
	 * Fills a portion of the screen with a black rectangle.
	 */
	void clearRect(float x, float y, float width, float height)
	{
		string oldStyle = _fillStyle !is null ? _fillStyle : "#000000";

		fillStyle = "#000000";
		fillRect(x, y, width, height);

		fillStyle = oldStyle;
	}

	/*
	 * Draws a text with the context's current font.
	 */
	void fillText(string value, float x, float y)
	{
		if(_fontString is null)
		{
			writeln("RenderingContext has no font.");
			return;
		}

		Text text = new Text;

		text.setFont(_parent.getFont(_fontName));
		text.setCharacterSize(_fontSize);
		text.setColor(_fillColor);
		text.setString(value);

		switch(_textAlign)
		{
			case "center":
				x -= text.getGlobalBounds().width / 2;
				break;

			case "right":
				x -= text.getGlobalBounds().width;
				break;

			default: break;
		}

		switch(_textBaseline)
		{
			case "middle":
				y -= text.getGlobalBounds().height / 2;
				break;

			case "bottom":
				y -= text.getGlobalBounds().height;
				break;

			default: break;
		}

		text.position = Vector2f(x, y);

		_sfmlWindow.draw(text);
	}

	/*
	 * Returns the width and height of the given text.
	 */
	Size measureText(string value)
	{
		if(_fontString is null)
		{
			writeln("RenderingContext has no font.");
			return new Size(-1, -1);
		}

		Text text = new Text;

		text.setFont(_parent.getFont(_fontName));
		text.setCharacterSize(_fontSize);
		text.setString(value);

		return new Size(
			cast(int) text.getGlobalBounds().width, 
			cast(int) text.getGlobalBounds().height
		);
	}

	/*
	 * Resets the list of vertices in the current line.
	 */
	void beginPath()
	{
		_lineVertices = [];
	}

	/*
	 * Moves the starting point of the current line to the given coordinates.
	 */
	void moveTo(float x, float y)
	{
		if(_lineVertices.length == 0)
		{
			_lineVertices ~= Vector2f(x, y);
		}
	}

	/*
	 * Functions the same as moveTo, without a vertices length test.
	 */
	void lineTo(float x, float y)
	{
		_lineVertices ~= Vector2f(x, y);
	}

	/*
	 * Adds a point equal to the first point in the line.
	 */
	void closePath()
	{
		lineTo(_lineVertices[0].x, _lineVertices[0].y);
	}

	/*
	 * Renders the line vertices.
	 */
	void stroke()
	{
		if(_lineVertices.length > 1)
		{
			foreach(i, vertex; _lineVertices)
			{
				Vector2f next;
				float distance, angle;

				if(i >= _lineVertices.length - 1) 
				{
					next = _lineVertices[i - 1];
				}
				else
				{
					next = _lineVertices[i + 1];

					// Calculate the distance between the two vertices and the angle between them.
					distance = sqrt(pow(next.x - vertex.x, 2.0f) + pow(next.y - vertex.y, 2.0f));
					angle = atan2((next.y - vertex.y), (next.x - vertex.x)) * (180 / PI);

					RectangleShape line = new RectangleShape(Vector2f(distance, _lineWidth));

					line.position = vertex;
					line.origin = Vector2f(0, _lineWidth / 2.0f);
					line.rotation = angle;

					line.fillColor = _strokeColor;

					_sfmlWindow.draw(line);
				}

				// Calculate the distance between the two vertices and the angle between them.
				distance = sqrt(pow(next.x - vertex.x, 2.0f) + pow(next.y - vertex.y, 2.0f));
				angle = atan2((next.y - vertex.y), (next.x - vertex.x)) * (180 / PI);

				if(cmp(_lineCap, "butt") != 0)
				{
					Shape cap = _getLineCap();

					cap.position = vertex;
					cap.origin = Vector2f(_lineWidth / 2.0f, _lineWidth / 2.0f);
					cap.rotation = angle;

					_sfmlWindow.draw(cap);
				}
			}
		}
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