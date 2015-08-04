README file for Artix 7 HDMI processing
=======================================
Hi! 

This is my design for receiving HDMI input, then extracting the video data, the
Video Inforframe and audio samples, then using that to display audio db meters 
on the top corner of the screen. Currently for simplicity the output is only DVID.

Features
--------
Supports HDMI formats:
  -720p@50
 - 720p@60, 
 - 1080i (with a bug)
 - 1080p@50
 - 1080p@60
 and others....

Colourspaces / formats:
 - RGB 444
 - YCbCr 444
 - YCbCr 422

Supported Boards
----------------
 - Digilent Nexys Video 

Sources tested with:
 - Western Digital HD Live
 - HP Laptop

Sinks tested with:
 - Viewsonic Monitor
 - AOC Monitor
 - Vivo TV
 
Known issues:
 - Currently extracts only two channels of audio 
 - Does not adjust PLL settings for input clock, so the PLL is run slightly out
   of spec.
 - Image may re-sync after a few seconds if it receives errors.
 - The audio meters are drawn twice as tall in interlaced modes
 - A false VSYNC pulse is causing the meters to be displayed more than once.

------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - with the industry metric of 30 lines
-- per day, it is equivalent to about 6 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
-- 
-- If you what to say thanks for this design how about trying PayPal?
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--
----------------------------------------------------------------------------------
