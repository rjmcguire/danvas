module danvas.all;

public import danvas.canvas;
public import danvas.events;

public void requestFrame(void function() callback)
{
	callback();
}