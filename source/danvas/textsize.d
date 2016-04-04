module danvas.textsize;

/*
 * This is a utility class returned by RenderingContext.measureText()
 */
class TextSize
{
	int width, height;

	this(int width, int height)
	{
		this.width = width;
		this.height = height;
	}
}