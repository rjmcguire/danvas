## danvas
An emulation of HTML5's [Canvas API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API) for [DSFML](https://github.com/Jebbs/DSFML/)

#### Prerequisites  

The only external requirement is [DSFML](http://jebbs.github.io/DSFML/downloads.html).  
Note: I've only tested this on Windows 10.

#### Why?

I'm personally a fan of the Canvas API and how easy it is to build little graphical projects. However, I'm not much of a fan of some of the things that JavaScript does. So, I decided to write a wrapper for DSFML (D being a fun and easy to use language) which works similarly to the Canvas API. Here's a basic example of the library at work: 

```D
import danvas;

Canvas canvas;
RenderingContext context;

void update()
{
    // Update stuff
}

void render()
{
    // Clear the screen
    context.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw a red rectangle
    context.fillStyle = "rgb(255, 0, 0)";
    context.fillRect(50, 50, 100, 100);
}

void tick()
{
    // Handle close and resize events, send events to their handlers
    canvas.dispatchEvents();
    
    update();
    render();
    
    if(!canvas.shouldClose())
    {
        // Display the SFML window and inform the canvas 
        // That it should call "tick" on the next frame
        canvas.display(&tick);
    }
}

void main()
{
    // Initialize the SFML window and Canvas object
    canvas = new Canvas(800, 600, "My Canvas");
    
    // Grab the canvas's RenderingContext
    context = canvas.getContext();
    
    tick();
}
```