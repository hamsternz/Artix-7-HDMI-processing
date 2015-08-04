----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Convert 3x 10-bit symbols to three serial channels and the clock channel.
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

entity serializers is
    Port ( clk : in  STD_LOGIC;
           c0 : in  STD_LOGIC_VECTOR (9 downto 0);
           c1 : in  STD_LOGIC_VECTOR (9 downto 0);
           c2 : in  STD_LOGIC_VECTOR (9 downto 0);
           hdmi_p : out  STD_LOGIC_VECTOR (3 downto 0);
           hdmi_n : out  STD_LOGIC_VECTOR (3 downto 0));
end serializers;

architecture Behavioral of serializers is
   -- For holding the outward bound TMDS symbols in the slow and fast domain
   signal c0_high_speed   : std_logic_vector(9 downto 0) := (others => '0');
   signal c1_high_speed   : std_logic_vector(9 downto 0) := (others => '0');
   signal c2_high_speed   : std_logic_vector(9 downto 0) := (others => '0');   
   signal clk_high_speed  : std_logic_vector(9 downto 0) := (others => '0');
   signal c2_output_bits  : std_logic_vector(1 downto 0) := "00";
   signal c1_output_bits  : std_logic_vector(1 downto 0) := "00";
   signal c0_output_bits  : std_logic_vector(1 downto 0) := "00";
   signal clk_output_bits : std_logic_vector(1 downto 0) := "00";

   -- Controlling the transfers into the high speed domain
   signal latch_high_speed : std_logic_vector(4 downto 0) := "00001";
   
   -- From the DDR outputs to the output buffers
   signal c0_serial, c1_serial, c2_serial, clk_serial : std_logic;

   -- For generating the x5 clocks
   signal clk_x5,  clk_x5_n, clk_x5_unbuffered  : std_logic;
   signal clk_feedback    : std_logic;

   -- To glue the HSYNC and VSYNC into the control character.
   signal syncs           : std_logic_vector(1 downto 0);
begin

process(clk_x5)
   begin
      ---------------------------------------------------------------
      -- Now take the 10-bit words and take it into the high-speed
      -- clock domain once every five cycles. 
      -- 
      -- Then send out two bits every clock cycle using DDR output
      -- registers.
      ---------------------------------------------------------------   
      if rising_edge(clk_x5) then
         c0_output_bits  <= c0_high_speed(1 downto 0);
         c1_output_bits  <= c1_high_speed(1 downto 0);
         c2_output_bits  <= c2_high_speed(1 downto 0);
         clk_output_bits <= clk_high_speed(1 downto 0);

         if latch_high_speed(0) = '1' then
            c0_high_speed   <= c0;
            c1_high_speed   <= c1;
            c2_high_speed   <= c2;
            clk_high_speed  <= "0000011111";
         else
            c0_high_speed   <= "00" & c0_high_speed(9 downto 2);
            c1_high_speed   <= "00" & c1_high_speed(9 downto 2);
            c2_high_speed   <= "00" & c2_high_speed(9 downto 2);
            clk_high_speed  <= "00" & clk_high_speed(9 downto 2);
         end if;
         latch_high_speed <= latch_high_speed(0) & latch_high_speed(4 downto 1);
      end if;
   end process;

   ------------------------------------------------------------------
   -- Convert the TMDS codes into a serial stream, two bits at a time
   ------------------------------------------------------------------
   clk_x5_n <= not clk_x5;
c0_to_serial: ODDR2
   generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") 
   port map (C0 => clk_x5,  C1 => clk_x5_n, CE => '1', R => '0', S => '0',
             D0 => C0_output_bits(0), D1 => C0_output_bits(1), Q => c0_serial);
OBUFDS_c0  : OBUFDS port map ( O  => hdmi_p(0), OB => hdmi_n(0), I => c0_serial);

c1_to_serial: ODDR2
   generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") 
   port map (C0 => clk_x5,  C1 => clk_x5_n, CE => '1', R => '0', S => '0',
             D0 => C1_output_bits(0), D1 => C1_output_bits(1), Q  => c1_serial);
OBUFDS_c1  : OBUFDS port map ( O  => hdmi_p(1), OB => hdmi_n(1), I => c1_serial);
   
c2_to_serial: ODDR2
   generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") 
   port map (C0 => clk_x5,  C1 => clk_x5_n, CE => '1', R => '0', S => '0',
             D0 => C2_output_bits(0), D1 => C2_output_bits(1), Q  => c2_serial);
OBUFDS_c2  : OBUFDS port map ( O  => hdmi_p(2), OB => hdmi_n(2), I => c2_serial);

clk_to_serial: ODDR2
   generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC") 
   port map (C0 => clk_x5,  C1 => clk_x5_n, CE => '1', R => '0', S => '0',
             D0 => Clk_output_bits(0), D1 => Clk_output_bits(1), Q  => clk_serial);
OBUFDS_clk : OBUFDS port map ( O  => hdmi_p(3), OB => hdmi_n(3), I => clk_serial);
   
   ------------------------------------------------------------------
   -- Use a PLL to generate a x5 clock, which is used to drive 
   -- the DDR registers.This allows 10 bits to be sent for every 
   -- pixel clock
   ------------------------------------------------------------------
PLL_BASE_inst : PLL_BASE
   generic map (
      CLKFBOUT_MULT => 10,                  
      CLKOUT0_DIVIDE => 2,       CLKOUT0_PHASE => 0.0,   -- Output 5x original frequency
      CLK_FEEDBACK => "CLKFBOUT",
      CLKIN_PERIOD => 13.33,
      DIVCLK_DIVIDE => 1
   )
      port map (
      CLKFBOUT => clk_feedback, 
      CLKOUT0  => clk_x5_unbuffered,
      CLKFBIN  => clk_feedback,    
      CLKIN    => clk, 
      RST      => '0'
   );

BUFG_pclkx5  : BUFG port map ( I => clk_x5_unbuffered,  O => clk_x5);

end Behavioral;

