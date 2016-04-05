module danvas.gradient;

import dsfml.graphics: Image, Color;

import danvas.canvas;

class CanvasGradient
{
private:
	Color[int] _colorStops;

public:
	/*
	 * Adds a color at the given index to the color stops map.
	 */
	void addColorStop(uint index, string cssColor)
	{
		Color color = Canvas.parseColor(cssColor);
	}
}