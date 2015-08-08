----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: Generates a test 1280x720 signal 
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
use IEEE.NUMERIC_STD.ALL;

entity vga_gen is
    Port ( clk50           : in  STD_LOGIC;
		     pixel_clock     : out std_logic;

           red_p   : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           green_p : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           blue_p  : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           blank   : out STD_LOGIC := '0';
           hsync   : out STD_LOGIC := '0';
           vsync   : out STD_LOGIC := '0');
end vga_gen;

architecture Behavioral of vga_gen is
	COMPONENT vga_clocking
	PORT( clk50           : IN  std_logic;          
         pixel_clock     : OUT std_logic);
	END COMPONENT;

   constant h_rez        : natural := 800;
   constant h_sync_start : natural := 800+40;
   constant h_sync_end   : natural := 800+40+128;
   constant h_max        : natural := 1056;
   signal   h_count      : unsigned(11 downto 0) := (others => '0');
   signal   h_offset     : unsigned(7 downto 0) := (others => '0');

   constant v_rez        : natural := 600;
   constant v_sync_start : natural := 600+1;
   constant v_sync_end   : natural := 600+1+4;
   constant v_max        : natural := 628;
   signal   v_count      : unsigned(11 downto 0) := x"250";
   signal   v_offset     : unsigned(7 downto 0) := (others => '0');
   signal clk40 : std_logic;
begin

Inst_clocking: vga_clocking PORT MAP(
		clk50           => clk50,
		pixel_clock     => clk40
	);
   pixel_clock <= clk40;

   
process(clk40)
   begin
      if rising_edge(clk40) then
         if h_count < h_rez and v_count < v_rez then
            red_p   <= std_logic_vector(h_count(7 downto 0)+h_offset);
            green_p <= std_logic_vector(v_count(7 downto 0)+v_offset);
            blue_p  <= std_logic_vector(h_count(7 downto 0)+v_count(7 downto 0));
            blank   <= '0';
            if h_count = 0 or h_count = h_rez-1 then
               red_p   <= (others => '1');
               green_p <= (others => '1');
               blue_p  <= (others => '1');
            end if;
            if v_count = 0 or v_count = v_rez-1 then
               red_p   <= (others => '1');
               green_p <= (others => '0');
               blue_p  <= (others => '0');
            end if;
         else
            red_p   <= (others => '0');
            green_p <= (others => '0');
            blue_p  <= (others => '0');
            blank   <= '1';
         end if;

         if h_count >= h_sync_start and h_count < h_sync_end then
            hsync <= '1';
         else
            hsync <= '0';
         end if;
         
         if v_count >= v_sync_start and v_count < v_sync_end then
            vsync <= '1';
         else
            vsync <= '0';
         end if;
         
         if h_count = h_max then
            h_count <= (others => '0');
            if v_count = v_max then
               h_offset <= h_offset + 1;
               v_offset <= v_offset + 1;
               v_count <= (others => '0');
            else
               v_count <= v_count+1;
            end if;
         else
            h_count <= h_count+1;
         end if;

      end if;
   end process;

end Behavioral;

