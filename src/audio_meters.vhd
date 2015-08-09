----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: audio_meters - Behavioral
--
-- Description: Insert audio level meters on a video stream. 
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

entity audio_meters is
    Port ( clk : in STD_LOGIC;
           -------------------------------
           -- VGA data recovered from HDMI
           -------------------------------
           in_blank  : in std_logic;
           in_hsync  : in std_logic;
           in_vsync  : in std_logic;
           in_red    : in std_logic_vector(7 downto 0);
           in_green  : in std_logic_vector(7 downto 0);
           in_blue   : in std_logic_vector(7 downto 0);
           is_interlaced   : in std_logic;
           is_second_field : in std_logic;
            
           -----------------------------------
           -- VGA data to be converted to HDMI
           -----------------------------------
           out_blank : out std_logic;
           out_hsync : out std_logic;
           out_vsync : out std_logic;
           out_red   : out std_logic_vector(7 downto 0);
           out_green : out std_logic_vector(7 downto 0);
           out_blue  : out std_logic_vector(7 downto 0);
           
           -------------------------------------
           -- Audio Levels
           -------------------------------------
           signal audio_channel : in std_logic_vector(2 downto 0);
           signal audio_de      : in std_logic;
           signal audio_level   : in std_logic_vector(5 downto 0)
     );
end audio_meters;

architecture Behavioral of audio_meters is
    signal col_count  : unsigned(11 downto 0);
    signal line_count : unsigned(11 downto 0);
    signal last_hsync : std_logic := '0';
    signal last_vsync : std_logic := '0';
    signal last_blank : std_logic := '0';

    signal mid_blank : std_logic;
    signal mid_hsync : std_logic;
    signal mid_vsync : std_logic;
    signal mid_red   : std_logic_vector(7 downto 0);
    signal mid_green : std_logic_vector(7 downto 0);
    signal mid_blue  : std_logic_vector(7 downto 0);
    signal bar_draw : std_logic;
    signal bar_col  : unsigned(6 downto 0); -- 0-127
    signal bar_line : unsigned(5 downto 0); -- 0-63
   
    type a_level is array (0 to 7) of unsigned(5 downto 0);
    signal levels : a_level;

    type a_peak is array (0 to 7) of unsigned(7 downto 0);
    signal peaks : a_peak;

    signal pending_drop : std_logic := '0';
	signal drop_index   : unsigned(2 downto 0) := (others => '0');

    signal u_sample     : unsigned(5 downto 0) := (others => '0');
    signal level        : unsigned(5 downto 0);
    signal peak         : unsigned(5 downto 0);

begin
    
level_proc: process(clk)
    begin
        if rising_edge(clk) then
            -------------------------------------------------
            -- Update the peak level, or if pending_drop is 
            -- set then drop the peak and level by 1 every
			-- frame.
			--
		    -- This causes 'peak' to fall at 1/4th the speed
		    -- of 'level', but makes for inconsistent
			-- behaviour depending on frame rate :-(
            -------------------------------------------------
            if audio_de = '1' then 
                if levels(to_integer(unsigned(audio_channel))) < unsigned(audio_level) then
                    levels(to_integer(unsigned(audio_channel))) <= unsigned(audio_level);
                end if;     
                if peaks(to_integer(unsigned(audio_channel))) < unsigned(audio_level &"00") then
                    peaks(to_integer(unsigned(audio_channel))) <= unsigned(audio_level & "00");
                end if;
            else
                if pending_drop = '1' then
                    if levels(to_integer(drop_index)) > 0 then
                        levels(to_integer(drop_index)) <= levels(to_integer(drop_index))-1;
                    end if;
                    if peaks(to_integer(drop_index)) > 0 then
                        peaks(to_integer(drop_index))  <= peaks(to_integer(drop_index))-1;
                    end if;
                    if drop_index = "000" then
                       pending_drop <= '0';    
                    end if;
                    drop_index <= drop_index-1;
                end if;
            end if;

            -- Signal to reduce (drop' the levels of the meters once each frame (of field for interlaced sources
            if last_vsync = '0'  and in_vsync = '1' then
                pending_drop <= '1';
                drop_index <= (others => '1');
            end if;
        end if;
    end process;

video_proc: process(clk)
    begin
        if rising_edge(clk) then
            out_blank <= mid_blank;
            out_hsync <= mid_hsync;
            out_vsync <= mid_vsync;
            out_red   <= mid_red;
            out_green <= mid_green;
            out_blue  <= mid_blue;

            if bar_draw = '1' then
                if bar_col(3 downto 1) /= "000" and bar_col(3 downto 1) /= "111" then
                    if peak > bar_line then
                        if peak > 60 then
                            out_red(out_red'high) <= '1';
                        else
                            out_green(out_green'high) <= '1';
                        end if;
                    end if;
                    
                    if level = bar_line then
                        out_red   <= (others => '1');
                        out_green <= (others => '1');
                        out_blue  <= (others => '1');
                    end if;
                end if; 
            end if;

            -----------------------------------------------------------------------------
            -- the mid_* signals contain the video with the box drawn to house the meters
            -----------------------------------------------------------------------------
            mid_blank <= in_blank;
            mid_hsync <= in_hsync;
            mid_vsync <= in_vsync;
            mid_red   <= in_red;
            mid_green <= in_green;
            mid_blue  <= in_blue;
            --------------------------------------------------
            -- For working out if we need to draw colour bars
            --------------------------------------------------
            bar_draw <= '0';
            bar_col   <= unsigned(col_count(6 downto 0))-1;
            bar_line  <= to_unsigned(64,6)-unsigned(line_count(5 downto 0));
            
            -----------------------------------------------------------------------------
            -- Retreive the levels for the bar. There is an 
            -- off-by-one error hidden by the bar boarder.
            -----------------------------------------------------------------------------
            level <= levels(to_integer(col_count(6 downto 4)));
            peak  <= peaks(to_integer(col_count(6 downto 4)))(7 downto 2);
            
            -------------------------------------------------------
            -- Halve the intensity of the area where the meters are.
            -------------------------------------------------------
            if col_count > 0 and  col_count < 129 and line_count > 0 and line_count < 65 then
                bar_draw <= '1';
            end if;   

            if col_count > 0 and col_count < 129 and line_count > 0 and line_count < 65 then
                mid_red   <= "0" & in_red(in_red'high downto 1);
                mid_green <= "0" & in_green(in_green'high downto 1);
                mid_blue  <= "0" & in_blue(in_blue'high downto 1);
            end if;

            -- Draw bounding box left/right sides
            if (col_count = 0 or col_count = 129) and line_count < 66 then
                mid_red   <= (others => '1');
                mid_green <= (others => '1');
                mid_blue  <= (others => '1');
            end if; 
            -- Draw bounding box top/bottom sides
            if (line_count = 0 or line_count = 65) and col_count < 130 then
                mid_red   <= (others => '1');
                mid_green <= (others => '1');
                mid_blue  <= (others => '1');
            end if; 
            

            -- Increment the column count on when active pixels are seen 
            if in_blank = '0' then
                col_count <= col_count + 1;
            end if;

            -- The end of active video is used to increment the line count           
            if last_blank = '0' and in_blank = '1' then
                if is_interlaced = '1' then
                    line_count <= line_count + 2;
                else
                    line_count <= line_count + 1;
                end if;
                col_count <= (others => '0');
            end if; 
                        
            -- Reset the line count on falling vsync
            if last_vsync = '1'  and in_vsync = '0' then
                if is_interlaced = '1' and is_second_field = '1' then
                    line_count <= (0 => '1', others => '0');
                else
                    line_count <= (others => '0');
                end if;
            end if;
            -- remember the hsync and vsync values
            last_vsync <= in_vsync;
            last_hsync <= in_hsync;
            last_blank <= in_blank;
        end if;
    end process;
end Behavioral;
