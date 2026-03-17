For this project, I will be using VGA to output from the Basys3 to a monitor. I will be using UART to communicate pan left, pan right, pan up, pan down, zoom in, zoom out from a laptop using Portu which is available in my repositories, it is a simple and lightweight asynchronous serial port interface that allows simplex transmission from a Windows computer with access to a powershell terminal.
  
I will be outputting the mandelbrot render to a 640x480 display at 60 Hz. I get the following VGA timing parameters from the VESA DMT (Display Monitor Timings) Version 1.13 for this VGA resolution.
<img width="662" height="835" alt="Screenshot 2026-03-17 204236" src="https://github.com/user-attachments/assets/bb0dedbd-e53f-4be0-8e76-edef0becc3c7" />
The important VGA timing parameters that will be used are as follows:
  
Pixel Clock = 25.175 MHz
  
# Horizontal
Visible pixels = 640
Front Porch = HorSyncStart - HorAddrTime = 656 - 640 = 16
Sync Pulse = HorSyncTime = 96
Back Porch = HBackPorch + HBottomBorder = 48
Total = 800
  
# Vertical
Visible pixels = 480
Front Porch = VerSyncStart - VerAddrTime = 490 - 480 = 10
Sync Pulse = VerSyncTime = 2
Back Porch = VBackPorch + VBottomBorder = 25 + 8 = 33
Total = 525
  
Front Porch is a guard period between the last visible pixel and the sync pulse, it gives the monitor a brief moment after after the last pixel before it responds to the sync pulse. During the front porch period the output is black and hsync stays high.
Sync pulse
Back Porch
  
VGA is based on old CRT technology
