# VGA
For this project, I will be using VGA to output from the Basys3 to an LCD monitor. I will be using UART to communicate pan left, pan right, pan up, pan down, zoom in, zoom out from a laptop using Portu which is available in my repositories, it is a simple and lightweight asynchronous serial port interface that allows simplex transmission from a Windows computer with access to a powershell terminal.  
  
I will be outputting the mandelbrot render to a 640x480 display at 60 Hz. I get the following VGA timing parameters from the VESA DMT (Display Monitor Timings) Version 1.13 for this VGA resolution.  

<img width="662" height="835" alt="Screenshot 2026-03-17 204236" src="https://github.com/user-attachments/assets/bb0dedbd-e53f-4be0-8e76-edef0becc3c7" />  
  
## Timing Parameters
### Horizontal Parameters
Visible pixels = 640  
Front Porch = HorSyncStart - HorAddrTime = 656 - 640 = 16  
Sync Pulse = HorSyncTime = 96  
Back Porch = HBackPorch + HBottomBorder = 48  
Total = 800  
  
### Vertical Parameters
Visible pixels = 480  
Front Porch = VerSyncStart - VerAddrTime = 490 - 480 = 10  
Sync Pulse = VerSyncTime = 2  
Back Porch = VBackPorch + VBottomBorder = 25 + 8 = 33  
Total = 525  

### Pixel Clock
There isnt a particular performance reason to use a clocking wizard that im aware of for this, but for my own education I will. The pixel clock would work fine at 25 MHz since modern LCD monitors have better tolerance than the monitors used when the standard was written.  
Pixel clock = 25.125 MHz  

### Parameter meanings
VGA is based on old CRT technology, but modern LCD monitors still expect the different time regions listed, even though theres no physical beam that requires them.  

Hsync is the signal that tells the monitor the end of the line has been reached, and a new line needs to be started. Lines are output left to right, from top to bottom. It pulses low to do this.  
Vsync is the signal that indicates to the monitor the end of the frame has been reached, and to move back to the top. It also pulses low to do this.  

Front Porch is a guard period between the last visible pixel and the sync pulse, it gives the monitor a brief moment after after the last pixel before it responds to the sync pulse. During the front porch period the output is black and hsync stays high.  
Sync pulse is the synchronisation signal used by the monitor to lock its internal timing, it indicates where a line ends and so hsync is pulled low for this period.  
Back Porch is a guard period after the sync pulse and before visible pixels begin again, originally its use was to give the CRT beam time to stabalise after repositioning, hsync is high during this period and the output is black.  
  
# Complex Plane in VHDL
The region of interest within the mandelbrot set is Re [-2.5, 1.0] and Im [-1.2, 1.2]. VHDL obviously cannot directly use these values to perform mandelbrot iteration, so they need to be scaled to signed values that can be used. Using Q format, with 4 bits representing a signed integer, and 28 bits representing the floating point (Q4.28), VHDL can use these scaed values instead for the real and imaginary part of c in the mandelbrot set iterator.  
  
The iterator looks at each pixel (0,0) to (639,479) in order, maps the coordinates to a range in the complex plane described above, performs mandelbrot iteration and writes the iteration for that pixel to the framebuffer. When all pixels are done, or when the Basys3 is powered on, or when a UART command is received requiring a rerendering to occur, it starts again from (0,0).  

Since there is no way to synthesise complex number arithmetic, it has to be done using large Q format values. For signed values of Qm.n, a Qm.n added to another Qm.n will result in a Qm.n number. The multiplication of two Qm.n numbers results in a Q2m.2n number. 

# Iterations
The maximum number of iterations determines how far you can zoom in before the whole thing breaks, how much detail the output has but also unfortunately how long it takes to render. My initial approach naturally was to implement the mandelbrot renderer iteratively, that is, iterating pixel by pixel using a single core. An alternative and 'better' approach that would result in faster rendering although more hardware cost would be using pipelining and or multiple cores to achieve true parallel rendering. That is the next goal, to achieve faster rendering using pipelining, and to also implement multiple cores and achieve true parallel rendering.  

# Pipelining
Pipelining in this case would not work on the Basys3. There simply is not enough logic cells to be able to produce a recognisable mandelbrot render using pipelining, so you either end up with an error saying 'This design requires more LUT as logic cells than are available in the target device', I unfortunately found this out the hard way after implementing a pipelined version of the previous mandelbrot iterator and was only able to get an 8 stage pipeline working. This, as you can guess, produced a very blocky and barely reckognisable render. 
