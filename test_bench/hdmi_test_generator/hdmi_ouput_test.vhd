----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Top level design for my minimal HDMI output project
--
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hdmi_output_test is
    Port ( clk50         : in  STD_LOGIC;

           hdmi_out_p : out  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_out_n : out  STD_LOGIC_VECTOR(3 downto 0);
                      
           leds       : out std_logic_vector(7 downto 0));
end hdmi_output_test;

architecture Behavioral of hdmi_output_test is

   COMPONENT vga_gen
   PORT(
      clk50           : IN std_logic;          
      pixel_clock     : OUT std_logic;
      red_p           : OUT std_logic_vector(7 downto 0);
      green_p         : OUT std_logic_vector(7 downto 0);
      blue_p          : OUT std_logic_vector(7 downto 0);
      blank           : OUT std_logic;
      hsync           : OUT std_logic;
      vsync           : OUT std_logic
      );
   END COMPONENT;

   COMPONENT Minimal_hdmi_symbols
   PORT(
      clk : IN std_logic;
      blank : IN std_logic;
      hsync : IN std_logic;
      vsync : IN std_logic;
      red   : IN std_logic;
      green : IN std_logic;
      blue  : IN std_logic;          
      c0    : OUT std_logic_vector(9 downto 0);          
      c1    : OUT std_logic_vector(9 downto 0);          
      c2    : OUT std_logic_vector(9 downto 0)         
      );
   END COMPONENT;
 
	COMPONENT serializers
	PORT(
		clk : IN std_logic;
		c0 : IN std_logic_vector(9 downto 0);
		c1 : IN std_logic_vector(9 downto 0);
		c2 : IN std_logic_vector(9 downto 0);          
		hdmi_p : OUT std_logic_vector(3 downto 0);
		hdmi_n : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;
 
   signal pixel_clock     : std_logic;

   signal red_p   : std_logic_vector(7 downto 0);
   signal green_p : std_logic_vector(7 downto 0);
   signal blue_p  : std_logic_vector(7 downto 0);
   signal blank   : std_logic;
   signal hsync   : std_logic;
   signal vsync   : std_logic;          

   signal c0, c1, c2 : std_logic_vector(9 downto 0);
begin
   leds <= x"AA";
   
---------------------------------------
-- Generate a 1280x720 VGA test pattern
---------------------------------------
Inst_vga_gen: vga_gen PORT MAP(
      clk50 => clk50,
      pixel_clock     => pixel_clock,      
      red_p           => red_p,
      green_p         => green_p,
      blue_p          => blue_p,
      blank           => blank,
      hsync           => hsync,
      vsync           => vsync
   );

---------------------------------------------------
-- Convert 9 bits of the VGA signals to the DVI-D/TMDS output 
---------------------------------------------------
i_Minimal_hdmi_symbols: Minimal_hdmi_symbols PORT MAP(
      clk    => pixel_clock,
      blank  => blank,
      hsync  => hsync,
      vsync  => vsync,
      red    => red_p(7),
      green  => green_p(7),
      blue   => blue_p(7),
      c0     => c0,
      c1     => c1,
      c2     => c2
   );

i_serializers : serializers PORT MAP (
      clk    => pixel_clock,
      c0     => c0,
      c1     => c1,
      c2     => c2,
      hdmi_p => hdmi_out_p,
      hdmi_n => hdmi_out_n);
      
end Behavioral;

