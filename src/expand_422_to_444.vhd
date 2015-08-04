----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: expand_422_to_444 - Behavioral
--
-- Description: Convert incoming 422 data to 444 
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

entity expand_422_to_444 is
    Port ( clk : in STD_LOGIC;
        input_is_422 : in std_logic;
        ------------------
        -- Incoming pixels
        ------------------
        in_blank  : in std_logic;
        in_hsync  : in std_logic;
        in_vsync  : in std_logic;
        in_ch2    : in std_logic_vector(7 downto 0);
        in_ch1    : in std_logic_vector(7 downto 0);
        in_ch0    : in std_logic_vector(7 downto 0);
    
        -------------------
        -- Processed pixels
        -------------------
        out_blank : out std_logic;
        out_hsync : out std_logic;
        out_vsync : out std_logic;
        out_U     : out std_logic_vector(11 downto 0);  -- B or Cb
        out_V     : out std_logic_vector(11 downto 0);  -- G or Y
        out_W     : out std_logic_vector(11 downto 0)   -- R or Cr
    );
end expand_422_to_444;

architecture Behavioral of expand_422_to_444 is

    signal in_blank_1 : std_logic := '0';
    signal in_hsync_1 : std_logic := '0';
    signal in_vsync_1 : std_logic := '0';
    signal in_ch0_1   : std_logic_vector(7 downto 0) := (others => '0');
    signal in_ch1_1   : std_logic_vector(7 downto 0) := (others => '0');
    signal in_ch2_1   : std_logic_vector(7 downto 0) := (others => '0');

    signal in_blank_2 : std_logic := '0';
    signal in_hsync_2 : std_logic := '0';
    signal in_vsync_2 : std_logic := '0';
    signal in_ch0_2   : std_logic_vector(7 downto 0) := (others => '0');
    signal in_ch1_2   : std_logic_vector(7 downto 0) := (others => '0');
    signal in_ch2_2   : std_logic_vector(7 downto 0) := (others => '0');

    signal first_of_pair : std_logic := '0';
begin

process(clk) 
    begin
        if rising_edge(clk) then
            if input_is_422 = '1' then
                ------------------------------------------------------
                -- For 422, copy the chroma values between pixel pairs 
                ------------------------------------------------------                
                out_blank <= in_blank_1;
                out_hsync <= in_hsync_1;
                out_vsync <= in_vsync_1;
                if in_blank_1 = '1' then
                    first_of_pair <= '1';
                    out_U     <= in_ch2_1 & in_ch0_1(7 downto 4); -- Cb
                    out_V     <= in_ch1_1 & in_ch0_1(3 downto 0); -- Y
                    out_W     <= in_ch2_1 & in_ch0_1(7 downto 4); -- Cr
                else
                    if first_of_pair = '1' then
                        -- Take Cr from the next pixel
                        first_of_pair <= '0';
                        out_U     <= in_ch2_1 & in_ch0_1(7 downto 4); -- Cb
                        out_V     <= in_ch1_1 & in_ch0_1(3 downto 0); -- Y
                        out_W     <= in_ch2   & in_ch0  (7 downto 4); -- Cr
                    else
                        -- Take Cb from the prior pixel
                        first_of_pair <= '1';
                        out_U     <= in_ch2_2 & in_ch0_2(7 downto 4); -- Cb
                        out_V     <= in_ch1_1 & in_ch0_1(3 downto 0); -- Y
                        out_W     <= in_ch2_1 & in_ch0_1(7 downto 4); -- Cr
                    end if;
                end if;
            else
                ------------------------------------------------------
                -- Minimal processing for 422 (either RGB or YCbCr)
                ------------------------------------------------------
                out_blank <= in_blank_1;
                out_hsync <= in_hsync_1;
                out_vsync <= in_vsync_1;
                out_U     <= in_ch0_1 & "0000";  -- B or Cb  
                out_V     <= in_ch1_1 & "0000";  -- G or Y
                out_W     <= in_ch2_1 & "0000";  -- R or Cr
            end if;
            
            -- Remember the pixel for two cycles
            in_blank_1 <= in_blank;
            in_hsync_1 <= in_hsync;
            in_vsync_1 <= in_vsync;
            in_ch0_1   <= in_ch0;
            in_ch1_1   <= in_ch1;
            in_ch2_1   <= in_ch2;
            
            in_blank_2 <= in_blank_1;
            in_hsync_2 <= in_hsync_1;
            in_vsync_2 <= in_vsync_1;
            in_ch0_2   <= in_ch0_1;
            in_ch1_2   <= in_ch1_1;
            in_ch2_2   <= in_ch2_1;
        end if;    
    end process;
end Behavioral;
