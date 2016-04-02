module danvas.events;

import dsfml.window;

class EventHandler
{
private:
	void function(Event)[string] _methods;

public:
	void registerEvent(string name, void function(Event) method)
	{
		_methods[name] = method;
	}

	void callMethod(string name, Event event)
	{
		if(name in _methods)
		{
			_methods[name](event);
		}
	}
}