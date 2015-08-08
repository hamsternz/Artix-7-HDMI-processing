----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz<
-- 
-- Description: Generate a 40Mhz Pixel clock from the 50Mhz input
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
library UNISIM;
use UNISIM.VComponents.all;

entity vga_clocking is
    Port ( clk50           : in  STD_LOGIC;
           pixel_clock     : out STD_LOGIC);
end vga_clocking;

architecture Behavioral of vga_clocking is
   signal clock_x1             : std_logic;
   signal clock_x1_unbuffered  : std_logic;
   signal clk_feedback         : std_logic;
   signal clk50_buffered       : std_logic;
   signal pll_locked           : std_logic;
begin
   pixel_clock     <= clock_x1;
   
   -- Multiply clk50m by 15, then divide by 10 for the 75 MHz pixel clock
   -- Because the all come from the same PLL the will all be in phase 
   PLL_BASE_inst : PLL_BASE
   generic map (
      CLKFBOUT_MULT => 16,                  
      CLKOUT0_DIVIDE => 20,       CLKOUT0_PHASE => 0.0,  -- Output pixel clock, 1.5x original frequency
      CLK_FEEDBACK => "CLKFBOUT",                        -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      CLKIN_PERIOD => 20.0,                              -- IMPORTANT! 20.00 => 50MHz
      DIVCLK_DIVIDE => 1                                 -- Division value for all output clocks (1-52)
   )
      port map (
      CLKFBOUT => clk_feedback, 
      CLKOUT0  => clock_x1_unbuffered,
      CLKOUT1  => open,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => pll_locked,      
      CLKFBIN  => clk_feedback,    
      CLKIN    => clk50_buffered, 
      RST      => '0'              -- 1-bit input: Reset input
   );

BUFG_clk    : BUFG port map ( I => clk50,                O => clk50_buffered);
BUFG_pclock : BUFG port map ( I => clock_x1_unbuffered,  O => clock_x1);

end Behavioral;