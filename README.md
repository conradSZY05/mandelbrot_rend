# UART
The first component I implemented was the UART interface. In order for the render to be interactive, the Basys 3 needs to receive commands either from the USB - JTAG/UART port (J4) which is just the same port that is used for power and programming the FPGA, or it can receive commands from the dedicated USB - HID port (J2) which can directly interface with peripherals such as keyboard and mice. The Basys 3 needs to act as a UART Rx receiver, receiving commands pan up/down/left/right and zoom in/out.

I chose to write my own UART interface terminal in C++ called portu, the github repo for this is [here](https://github.com/conradSZY05/portu). It is a Windows only program as it uses Windows libraries to read open COM ports, and send key strokes as single characters to the Basys 3 over the J4 port. There is no particular reason I wrote and used a custom program for this other than pure curiosity, there are plenty of alternatives that are compatible with whatever operating system you use (PuTTY, Tera Term, Coolterm). The method for sending commands to the Basys 3 really does not matter, so long as UART is sent at 115200 baud and the character map listed below that is also hardcoded into the coord_mapper.vhd module is followed.
‘U’ - pan up | ‘D’ - pan down | ‘L’ - pan left | ‘R’ - pan right | ‘i’ - zoom in | ‘o’ - zoom out  

<img width="1692" height="702" alt="image" src="https://github.com/user-attachments/assets/a0090d53-9626-4bca-ba07-e3a763a155dd" />  

On the physical FPGA, you can see if the UART commands are being received by looking at the bottom LEDs (LD7 - LD0), these will represent the binary representation of the character that was last sent. For exaample this is the Basys 3 after I press the right arrow key which sends the character 'R' or 01010010 in binary to the Basys 3.  
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/98e88927-b837-4058-b24a-157b7a4696f0" />

# VGA
For this project, I will be using VGA to output from the Basys3 to an LCD monitor. I will be using UART as described above for interacting with the VGA display, sending zooming and panning commands from my laptop keyboard with portu running. 
  
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
VGA is based on old CRT technology, but modern LCD monitors still expect the different time regions listed, even though theres no physical beam that requires them like there is in a CRT.  

Hsync is the signal that tells the monitor the end of the line has been reached, and a new line needs to be started. Lines are output left to right, from top to bottom. It pulses low to do this.  
Vsync is the signal that indicates to the monitor the end of the frame has been reached, and to move back to the top. It also pulses low to do this.  

Front Porch is a guard period between the last visible pixel and the sync pulse, it gives the monitor a brief moment after after the last pixel before it responds to the sync pulse. During the front porch period the output is black and hsync stays high.  
Sync pulse is the synchronisation signal used by the monitor to lock its internal timing, it indicates where a line ends and so hsync is pulled low for this period.  
Back Porch is a guard period after the sync pulse and before visible pixels begin again, originally its use was to give the CRT beam time to stabalise after repositioning, hsync is high during this period and the output is black.  

Details and explanations of these timing variables are available in VESA DMT Version 1.13, the location of these are listed at the bottom of the image above. I recommend really understanding what these core paramters do before implementing anything using VGA, implementation of the VGA display will go a lot smoother if you do. As a test before I really start implementing any iteration logic, I can confirm if the VGA timing parameters I implemented in the VGA_controller.vhd module are working by looking at the display settings directly on my monitor using the on monitor buttons (not all monitors will have easy to access display settings like this, especially older models).  

<img width="1355" height="1520" alt="image" src="https://github.com/user-attachments/assets/de99850c-c9c0-4b15-ace3-985e9f42c2cd" />  
  
# Complex Plane in VHDL
The region of interest within the mandelbrot set is Re [-2.5, 1.0] and Im [-1.2, 1.2]. VHDL obviously cannot directly use these values to perform mandelbrot iteration, so they need to be scaled to signed values that can be used. Using Q format, with 4 bits representing a signed integer, and 28 bits representing the floating point (Q4.28 in Q format), VHDL can use these scaled values instead for the real and imaginary part of c in the mandelbrot set iterator. The Q format addition operation on two signed values Qm.n + Qm.n, where m is the number of bits representing the signed integer and n is the number of bits representing the fixed point results in a Q format number of Qm.n. The Q format multiplication operation on two signed values Qm.n * Qm.n results in a Q format number Q(m+m).(n+n) or Q(m+m+1).(n+n), the reason for the +1 is that since we are dealing with signed numbers, a resulting number in Q(m+m).(n+n) with a MSB of 1 will be interpreted as negative in signed format, so it is best to be on the safe side and use Q(m+m+1).(n+n) for this signed multiplication. I found [this website](https://hardwaredescriptions.com/elementor-fixed-point-arithmetic-in-synthesizable-vhdl/) particularly helpful for understanding fixed point arithmetic, and [this website](https://chummersone.github.io/qformat.html#converter) very useful for calculating Q format numbers that I could use.  

For some examples of Q format numbers, take the mandelbrot set range Re [-2.5, 1.0] and Im [-1.2, 1.2]. This range can simply be converted to Q4.28 format by multiplying each number by 2^28, resulting in a range that will be used in the coord_mapper.vhd of Re [-671088640, 268435456] and Im [-322122547, 322122547]. 
  
Panning and zooming using UART commands is where most of the complexity of the coord_mapper.vhd lies. For panning, I chose to make it so that one pan in any direction would move the render 1/16 in that direction, meaning 16 pans in one direction is one full screen. The pan amount uses the range of coordinates on tha axis that is being panned, take for example a pan right command: coord_mapper.vhd will get the range of the x coordinates in Q4.28 format using x_max and x_min signals (x_max and x_min represent the current complex coordinates scaled to Q4.28 format being rendered in the set), the amount being panned will be calculated using this range by shifting the range 4 times to the right, effectively dividing it by 16, that way when a pan right is needed the pan amount just calculated will be added to the x_min and x_max. This operation works the same for panning left, up and down, only for left it subtracts the pan amount, and for panning up and down the y axis is used. You can think of this panning operation as just shifting the range of coordinates that are currently being rendered in the mandelbrot set.   
Zooming is similar to panning, in that it calculates a new range of max and min values for the x and y axis but it focuses around a centre point. For each zooming operation, the sum is calculated using the current max and min values for both axis, the centre is then determined by shifting the sum right once, effectively halving it and getting the middle value. For zooming in, x_min becomes equal to the centre of the x axis minus the new range (the current x range shifted twice to the right), x_max becomes equal to the centre of the x axis plus the new range (it works the same way for the y axis). The amount zoomed in is determined by the step in each axis direction, the x axis step is initialised to 3.5 / 640 (range/pixels) or 1468006 in Q4.28 format, and the y step is initialised to 2 / 480 or 1342177 in Q4.28 format. Every time a zoom in operation occurs both of these axis steps are shifted right once and effectively halved, this is one of the main limiting factors in my approach to the mandelbrot set render, as after 21 zooming in operations the y step value becomes 0.64. 0.64 cannot be accurately represented as an integer, and so any zooming in operation after this effectively breaks the render resulting in a blank coloured screen. This is something I may wish to improve upon by using larger Q format values.  

# Colour mapping and iteration
The iterator looks at each pixel (0,0) to (639,479) in order, maps the coordinates to a range in the complex plane described above, performs mandelbrot iteration and writes the iteration for that pixel to the framebuffer. When all pixels are done, or when the Basys3 is powered on, or when a UART command is received requiring a rerendering to occur (i.e. on a UART command), it starts again from (0,0). The basic iterative mandelbrot set uses the function z[n+1] = z[n]^2 + c, starting with z[0] = 0, where c is the current pixel coordinates mapped to the real plane $c=Re+i*Im$, scaled to Q format as described above. Every time an iteration of this function occurs on the current set of pixels an iteration count for the current pixels is incremented, the function iterates until an escape condition is true, this escape condition is true when the current iteration count exceeds the maximum iterations I chose as 255 as I found this had a good performance to detail trade off, or when the magnitude of z exceeds the escape magnitude of 4. You can read more about escape time algorithms for the mandelbrot set [here ](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set), I found this resource very useful.  
Colour mapping is simply just taking the bottom 4 bits of the iteration count for the current pixel, and using a lookup table in colour_mapper.vhd to determine what colour should represent these 4 bits. My original renderer only contained one set of 16 colours available, since then I have expanded the sets of colours to 7 different colour sets which can be cycled through on the Basys 3 using the right push button. The reason for the selection of 4 bits for colour mapping can be seen in the next Framebuffer section.  
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/3a3d2d3a-939f-4794-81aa-38117b3f285f" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/f42cae23-3ac2-4eb3-884d-c1fcf11906ef" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/7252ff7b-689b-449b-8886-7e04da9e6767" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/eac1f753-54df-4cc5-87be-cc0335659848" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/1b7c7d32-163e-4629-adea-7688a8ab0511" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/3eac9a80-e5b5-4d29-a8dc-305141991a25" />
<img width="2880" height="2160" alt="image" src="https://github.com/user-attachments/assets/7a082334-591d-43d5-ba0c-d2a851fa4900" />

# Framebuffer
The framebuffer is by far the most important aspect of the mandelbrot renderer as it is responsible for storing the rendered mandelbrot image, as well as being the main factor in hardware limitation. Using a single core iteration (see more on this in the next section), the hardware utilisation was really getting pushed with 80% of the BRAM being used. The Basys 3 contains 1.8 Mb of BRAM available, at 640x480 resolution, thats 307200 pixels in total, with 4 bits per pixel thats 1228800 pixels in total needed to be stored on the framebuffer at any one time. Any more than 4 bits will exceed the framebuffer limit, that is why I chose only 4 bits to represent the colour of each pixel. This is the hardware utilisation for the single core iteration version. 
<img width="1280" height="149" alt="image" src="https://github.com/user-attachments/assets/ac6ea389-dbe9-4d81-9d8e-04dead40802a" />
The framebuffer is a simple dual port framebuffer, in that it is written to at 100 MHz (the Basys 3 clock), and read at 25.125 MHz (the pixel clock). 

# Multi core acceleration
In my first iterative renderer, I only implemented a single core iterating over all pixels in order. This, as you can imagine, resulted in a very slow and tedious rendering time every time a UART command is sent. I originally thought that I could implement pipelining in order to speed this process up, I quickly realised that the Basys 3 simply does not have enough LUT storage for pipelining in this way to work and so I was only actually able to get 16 maximum iterations and display probably the least complex mandelbrot set ever and so I abondoned this approach although I still uploaded my attempt at the pipeline approach here. You can see the result of implementing a pipelined iteration process below. 
<img width="1324" height="861" alt="image" src="https://github.com/user-attachments/assets/d6a13c3d-699c-49d0-96f1-6069f0f9d99d" />
After this 'improvement' didn't exactly go to plan, I began looking at using multiple worker cores to iterate over pixels simultaneously. I originally got this suggestion from somebody in r/FPGA, and am very thankful as it led to an increase in time taken to render of up to 5 times depending on the location of the set that was currently being rendered. N iterator cores are assigned their own pixels all in parallel, when all cores are finished with their pixels then the result of each is written in order to the framebuffer and then the next batch of N pixels begins. With the single iteration approach, each pixel had to wait for the previous one to finish iterating in order to be worked on, and so with N cores, N pixels can be worked on simultaneously resulting in approximately an N times speed up in rendering. I say approximate because each pixel may take a different amount of time to iterate and reach the escape condition, this is where I encountered challenges in the multi core implementation.

Single core iteration was simple because each pixel could be worked on straight after the last, but with say 5 worker cores working on 5 pixels at the same time, one pixel may reach the escape sequence sooner than the rest, or one later than the rest (interior points take the full 255 iterations while boundary points escape quickly). The hardest part was this synchronisation, ensuring that all cores had finished before writing them to the framebuffer.
With 255 max iterations, roughly 4 cycles per iteration state and 307200 pixels in total, thats 313344000 cycles or around 3.1 seconds per frame at 100 MHz. However, with 5 cores its more like 3.1 / 5 seconds or 0.62 seconds per frame, a very noticable change in render time. Below is the resource utilisation of the multi core approach, using 255 maximum iterations and 5 worker iteration cores.  
<img width="1576" height="610" alt="image" src="https://github.com/user-attachments/assets/3b788664-c0ae-421f-b852-7e9c6fad93e8" />
A clear increase in hardware utilisation for the multi core approach, although a very reasonable tradeoff given the massive improvement in rendering speed achieved. Below you can see a side by side comparison of the rendering speed of the single core approach and the multi core approach. 

https://github.com/user-attachments/assets/a66d5afe-9b41-42b7-9561-b191f3eae7e7
https://github.com/user-attachments/assets/1056ed31-3373-4c8f-b64f-e27f1ece5e87
