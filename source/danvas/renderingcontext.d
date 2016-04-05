module danvas.renderingcontext;

import std.regex;
import std.string;
import std.stdio;
import std.conv;
import std.math;

import dsfml.graphics: 
	RenderWindow, 
	Color, 
	Vector2f, 
	Shape, 
	CircleShape, 
	RectangleShape, 
	Text,
	Sprite,
	FloatRect,
	IntRect
;

import danvas.canvas;
import danvas.image;
import danvas.textsize;

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

	Color[string] _colorCache;

	// Converts a CSS color string to an SFML color.
	Color _parseColor(string cssColor) 
	{
		cssColor = strip(cssColor);

		if(cssColor in _colorCache)
		{
			return _colorCache[cssColor];
		}

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

			_colorCache[cssColor] = Color(r, g, b);

			return _colorCache[cssColor];
		}
		else if (!rgbMatch.empty)
		{
			float a = 255;

			if(rgbMatch[4].length > 0)
			{
				// CSS RGBA alpha values are from 0.0 to 1.0, whereas SFML uses 0-255.
				// For this reason, the given alpha is bounds checks and multiplied by 255.

				a = to!float(rgbMatch[4]);

				if(a < 0) 
				{
					a = 0.0f;
				}

				if(a > 1)
				{
					a = 1.0f;
				}

				a *= 255.0f;
			}

			_colorCache[cssColor] = Color(
				to!ubyte(rgbMatch[1]),
				to!ubyte(rgbMatch[2]),
				to!ubyte(rgbMatch[3]),
				to!ubyte(a)
			);

			return _colorCache[cssColor];
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
	TextSize measureText(string value)
	{
		if(_fontString is null)
		{
			writeln("RenderingContext has no font.");
			return new TextSize(-1, -1);
		}

		Text text = new Text;

		text.setFont(_parent.getFont(_fontName));
		text.setCharacterSize(_fontSize);
		text.setString(value);

		return new TextSize(
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

	/*
	 * Renders an Image at the given location.
	 */
	void drawImage(Image image, float x, float y)
	{
		Sprite sprite = new Sprite(image._sfmlTexture);
		sprite.position = Vector2f(x, y);
		_sfmlWindow.draw(sprite);
	}

	/*
	 * Renders an Image at the given location with the given dimensions.
	 */
	void drawImage(Image image, float x, float y, float width, float height)
	{
		Sprite sprite = new Sprite(image._sfmlTexture);
		FloatRect spriteRect = sprite.getLocalBounds();

		// Calculate a float from 0.0-1.0 that describes how much to scale the sprite.
		float scaleX = width / spriteRect.width;
		float scaleY = height / spriteRect.height;

		sprite.position = Vector2f(x, y);
		sprite.scale = Vector2f(scaleX, scaleY);

		_sfmlWindow.draw(sprite);
	}

	/*
	 * Renders an Image at the given location, withe the given dimensions and with the given cropping.
	 */
	void drawImage(Image image, float sourceX, float sourceY, float sourceWidth, float sourceHeight, float x, float y, float width, float height)
	{
		Sprite sprite = new Sprite(image._sfmlTexture);

		sprite.textureRect = IntRect(
			cast(int) sourceX, 
			cast(int) sourceY, 
			cast(int) sourceWidth, 
			cast(int) sourceHeight
		);

		FloatRect spriteRect = sprite.getLocalBounds();
		
		// Calculate a float from 0.0-1.0 that describes how much to scale the sprite.
		float scaleX = width / spriteRect.width;
		float scaleY = height / spriteRect.height;

		sprite.position = Vector2f(x, y);
		sprite.scale = Vector2f(scaleX, scaleY);

		_sfmlWindow.draw(sprite);
	}
}
