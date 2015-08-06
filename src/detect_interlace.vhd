----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: detect_interlace - Behavioral
--
-- Description: Detect if the source is interlaced, and report what field is 
--              being processed
-- 
-- Will need to make allowances for interlaced sources!
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

entity detect_interlace is
    Port ( clk             : in STD_LOGIC;
           hsync           : in std_logic;
           vsync           : in std_logic;
    	   is_interlaced   : out std_logic;
	   	   is_second_field : out std_logic);
end entity;

architecture Behavioral of detect_interlace is
	signal last_vsync     : std_logic := '0';
	signal last_hsync     : std_logic := '0';
	signal first_quarter  : unsigned(11 downto 0) := (others => '0');
	signal last_quarter   : unsigned(11 downto 0) := (others => '0');
	signal hcount         : unsigned(11 downto 0) := (others => '0');
	signal last_vsync_pos : unsigned(11 downto 0) := (others => '0');
	signal second_field   : std_logic := '0';
begin
clk_proc: process(clk)
	begin
		if rising_edge(clk) then
			if last_vsync = '0' and vsync = '1' then
				is_second_field <= '0';
				if hcount > first_quarter and hcount < last_quarter then
					-- The second field of an interlaced 
                           -- frame is indicated when the vsync is
	                      -- asserted in the middle of the scan line.
					--
					-- Also add a little check for a misbehaving source
					if last_vsync_pos /= hcount then
						is_interlaced   <= '1';
						is_second_field <= '1';
						second_field    <= '1';
					else
						is_interlaced   <= '1';
						is_second_field <= '1';
						second_field    <= '1';
					end if;

				else
					-- If we see two 'field 1's in a row we 
					-- switch back to indicating an 
                    -- uninterlaced source
					if second_field = '0' then
						is_interlaced <= '0';
					end if;									
					is_second_field <= '0';
					second_field    <= '0';
				end if;
				last_vsync_pos <= hcount;
			else
			end if;

			if last_hsync = '0' and hsync = '1' then
				hcount <= (others => '0');
				first_quarter <= "00" & hcount(11 downto 2);
				last_quarter <= hcount+1-hcount(11 downto 2);
			else
				hcount <= hcount +1;
			end if;
			last_vsync <= vsync;
			last_hsync <= hsync;
		end if;
	end process;
end architecture;
		