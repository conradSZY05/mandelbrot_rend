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
  
