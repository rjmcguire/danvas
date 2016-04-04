module danvas.image;

import std.stdio;

import dsfml.graphics;

class Image
{
private:
	string _source;

public:
	Texture _sfmlTexture;

	this()
	{
		_source = null;
	}

	this(string source)
	{
		src = source;
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
