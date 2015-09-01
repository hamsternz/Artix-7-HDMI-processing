----------------------------------------------------------------------------------
-- Engineer: Mike Field <hasmter@snap.net.nz> 
-- 
-- Module Name: edge_enhance - Behavioral
--
-- Description: Video edge enhancement 
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

entity edge_enhance is
    Port (  clk            : in STD_LOGIC;
            enable_feature : in std_logic;
            -------------------------------
            -- VGA data recovered from HDMI
            -------------------------------
            in_blank  : in std_logic;
            in_hsync  : in std_logic;
            in_vsync  : in std_logic;
            in_red    : in std_logic_vector(7 downto 0);
            in_green  : in std_logic_vector(7 downto 0);
            in_blue   : in std_logic_vector(7 downto 0);
            
            -----------------------------------
            -- VGA data to be converted to HDMI
            -----------------------------------
            out_blank : out std_logic;
            out_hsync : out std_logic;
            out_vsync : out std_logic;
            out_red   : out std_logic_vector(7 downto 0);
            out_green : out std_logic_vector(7 downto 0);
            out_blue  : out std_logic_vector(7 downto 0));
end edge_enhance;

architecture Behavioral of edge_enhance is
    component line_delay is
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
     
           -----------------------------------
           -- VGA data to be converted to HDMI
           -----------------------------------
           out_blank : out std_logic;
           out_hsync : out std_logic;
           out_vsync : out std_logic;
           out_red   : out std_logic_vector(7 downto 0);
           out_green : out std_logic_vector(7 downto 0);
           out_blue  : out std_logic_vector(7 downto 0));
    end component;
    type a_bits is array(0 to 8) of std_logic;
    type a_component is array(0 to 8) of std_logic_vector(7 downto 0);
    signal blanks : a_bits;
    signal hsyncs : a_bits;
    signal vsyncs : a_bits;
    signal reds   : a_component;
    signal greens : a_component;
    signal blues  : a_component;

    signal bypass_1_blank : std_logic := '0';
    signal bypass_1_hsync : std_logic := '0';
    signal bypass_1_vsync : std_logic := '0';
    signal bypass_1_red   : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_1_blue  : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_1_green : std_logic_vector(7 downto 0) := (others => '0');

    signal bypass_2_blank : std_logic := '0';
    signal bypass_2_hsync : std_logic := '0';
    signal bypass_2_vsync : std_logic := '0';
    signal bypass_2_red   : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_2_blue  : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_2_green : std_logic_vector(7 downto 0) := (others => '0');
    
    signal bypass_3_blank : std_logic := '0';
    signal bypass_3_hsync : std_logic := '0';
    signal bypass_3_vsync : std_logic := '0';
    signal bypass_3_red   : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_3_blue  : std_logic_vector(7 downto 0) := (others => '0');
    signal bypass_3_green : std_logic_vector(7 downto 0) := (others => '0');

    signal sobel_3_hsync  : std_logic := '0';
    signal sobel_3_blank  : std_logic := '0';
    signal sobel_3_vsync  : std_logic := '0';
    signal sobel_3_red    : unsigned(12 downto 0) := (others => '0');
    signal sobel_3_green  : unsigned(12 downto 0) := (others => '0');
    signal sobel_3_blue   : unsigned(12 downto 0) := (others => '0');
    
    signal sobel_2_hsync   : std_logic := '0';
    signal sobel_2_blank   : std_logic := '0';
    signal sobel_2_vsync   : std_logic := '0';
    signal sobel_2_red_x   : unsigned(11 downto 0) := (others => '0');
    signal sobel_2_red_y   : unsigned(11 downto 0) := (others => '0');
    signal sobel_2_green_x : unsigned(11 downto 0) := (others => '0');
    signal sobel_2_green_y : unsigned(11 downto 0) := (others => '0');
    signal sobel_2_blue_x  : unsigned(11 downto 0) := (others => '0');
    signal sobel_2_blue_y  : unsigned(11 downto 0) := (others => '0');

    signal sobel_1_hsync        : std_logic := '0';
    signal sobel_1_blank        : std_logic := '0';
    signal sobel_1_vsync        : std_logic := '0';
    signal sobel_1_red_left     : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_red_right    : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_red_top      : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_red_bottom   : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_green_left   : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_green_right  : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_green_top    : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_green_bottom : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_blue_left    : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_blue_right   : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_blue_top     : unsigned(11 downto 0) := (others => '0');
    signal sobel_1_blue_bottom  : unsigned(11 downto 0) := (others => '0');
begin
    blanks(0)  <= in_blank;
    hsyncs(0)  <= in_hsync;
    vsyncs(0)  <= in_vsync;
    reds(0)    <= in_red;
    greens(0)  <= in_green;
    blues(0)   <= in_blue;

i_line_delay_1: line_delay  Port map ( 
        clk       => clk,
        in_blank  => blanks(0),
        in_hsync  => hsyncs(0),
        in_vsync  => vsyncs(0),
        in_red    => reds(0),
        in_green  => greens(0),
        in_blue   => blues(0),

        out_blank => blanks(3), 
        out_hsync => hsyncs(3),
        out_vsync => vsyncs(3), 
        out_red   => reds(3),
        out_green => greens(3), 
        out_blue  => blues(3)  
    );

i_line_delay_2: line_delay  Port map ( 
        clk       => clk,
        in_blank  => blanks(3),
        in_hsync  => hsyncs(3),
        in_vsync  => vsyncs(3),
        in_red    => reds(3),
        in_green  => greens(3),
        in_blue   => blues(3),

        out_blank => blanks(6), 
        out_hsync => hsyncs(6),
        out_vsync => vsyncs(6), 
        out_red   => reds(6),
        out_green => greens(6), 
        out_blue  => blues(6)  
    );

process(clk)
    begin
        if rising_edge(clk) then
            if enable_feature = '1' then
                out_hsync <= sobel_3_hsync;
                out_blank <= sobel_3_blank;
                out_vsync <= sobel_3_vsync;

                if sobel_3_red(12 downto 12) = "0" then
                    out_red   <= std_logic_vector(sobel_3_red(11 downto 4));
                else
                    out_red   <= (others => '1');
                end if;

                if sobel_3_green(12 downto 12) = "0" then
                    out_green   <= std_logic_vector(sobel_3_green(11 downto 4));
                else
                    out_green   <= (others => '1');
                end if;

                if sobel_3_blue(12 downto 12) = "0" then
                    out_blue   <= std_logic_vector(sobel_3_blue(11 downto 4));
                else
                    out_blue   <= (others => '1');
                end if;
            else
                out_hsync <= bypass_3_hsync;
                out_blank <= bypass_3_blank;
                out_vsync <= bypass_3_vsync;
                out_red   <= bypass_3_red;
                out_blue  <= bypass_3_blue;
                out_green <= bypass_3_green;
            end if;

            --------------------------------------
            -- For if we eed to bypass the feature
            --------------------------------------
            bypass_3_blank <= bypass_2_blank;
            bypass_3_hsync <= bypass_2_hsync;
            bypass_3_vsync <= bypass_2_vsync;
            bypass_3_red   <= bypass_2_red;
            bypass_3_blue  <= bypass_2_blue;
            bypass_3_green <= bypass_2_green;

            bypass_2_blank <= bypass_1_blank;
            bypass_2_hsync <= bypass_1_hsync;
            bypass_2_vsync <= bypass_1_vsync;
            bypass_2_red   <= bypass_1_red;
            bypass_2_blue  <= bypass_1_blue;
            bypass_2_green <= bypass_1_green;

            bypass_1_blank <= blanks(4);
            bypass_1_hsync <= hsyncs(4);
            bypass_1_vsync <= vsyncs(4);
            bypass_1_red   <= reds(4);
            bypass_1_blue  <= blues(4);
            bypass_1_green <= greens(4);

            ----------------------------------
            --- Calculating the Sobel operator
            ----------------------------------
            sobel_3_blank <= sobel_2_blank;
            sobel_3_hsync <= sobel_2_hsync;
            sobel_3_vsync <= sobel_2_vsync;
            sobel_3_red   <= ("0" & sobel_2_red_x)   +  sobel_2_red_y;
            sobel_3_green <= ("0" & sobel_2_green_x) +  sobel_2_green_y;
            sobel_3_blue  <= ("0" & sobel_2_blue_x)  +  sobel_2_blue_y;
             
            -- For the red channel
            sobel_2_blank <= sobel_1_blank;
            sobel_2_hsync <= sobel_1_hsync;
            sobel_2_vsync <= sobel_1_vsync;

            if sobel_1_red_left > sobel_1_red_right then
                sobel_2_red_x <= sobel_1_red_left - sobel_1_red_right;
            else
                sobel_2_red_x <= sobel_1_red_right - sobel_1_red_left;
            end if;            
            if sobel_1_red_top > sobel_1_red_bottom then
                sobel_2_red_y <= sobel_1_red_top - sobel_1_red_bottom;
            else
                sobel_2_red_y <= sobel_1_red_bottom - sobel_1_red_top;
            end if;
            
            -- For the green channel
            if sobel_1_green_left > sobel_1_green_right then
                sobel_2_green_x <= sobel_1_green_left - sobel_1_green_right;
            else
                sobel_2_green_x <= sobel_1_green_right - sobel_1_green_left;
            end if;
            if sobel_1_green_top > sobel_1_green_bottom then
                sobel_2_green_y <= sobel_1_green_top - sobel_1_green_bottom;
            else
                sobel_2_green_y <= sobel_1_green_bottom - sobel_1_green_top;
            end if;
            
            -- For the blue channel
            if sobel_1_blue_left > sobel_1_blue_right then
                sobel_2_blue_x <= sobel_1_blue_left - sobel_1_blue_right;
            else
                sobel_2_blue_x <= sobel_1_blue_right - sobel_1_blue_left;
            end if;            
            if sobel_1_blue_top > sobel_1_blue_bottom then
                sobel_2_blue_y <= sobel_1_blue_top - sobel_1_blue_bottom;
            else
                sobel_2_blue_y <= sobel_1_blue_bottom - sobel_1_blue_top;
            end if;

            -- Now for the first stage;            
            sobel_1_blank <= blanks(4);
            sobel_1_hsync <= hsyncs(4);
            sobel_1_vsync <= vsyncs(4);
            -- For the red channel
            sobel_1_red_left   <= ("000" & unsigned(reds(0)) & "0") + ("0000" & unsigned(reds(0))) 
                                + ("000" & unsigned(reds(3)) & "0") + ("0"    & unsigned(reds(3)) & "000")
                                + ("000" & unsigned(reds(6)) & "0") + ("0000" & unsigned(reds(6)));

            sobel_1_red_right  <= ("000" & unsigned(reds(2)) & "0") + ("0000" & unsigned(reds(2))) 
                                + ("000" & unsigned(reds(5)) & "0") + ("0"    & unsigned(reds(5)) & "000") 
                                + ("000" & unsigned(reds(8)) & "0") + ("0000" & unsigned(reds(8)));

            sobel_1_red_top    <= ("000" & unsigned(reds(2)) & "0") + ("0000" & unsigned(reds(2)))       
                                + ("000" & unsigned(reds(1)) & "0") + ("0"    & unsigned(reds(1)) & "000") 
                                + ("000" & unsigned(reds(0)) & "0") + ("0000" & unsigned(reds(0)));

            sobel_1_red_bottom <= ("000" & unsigned(reds(6)) & "0") + ("0000" & unsigned(reds(6)))
                                + ("000" & unsigned(reds(7)) & "0") + ("0"    & unsigned(reds(7)) & "000") 
                                + ("000" & unsigned(reds(8)) & "0") + ("0000" & unsigned(reds(8)));

            -- For the green channel
            sobel_1_green_left   <= ("000" & unsigned(greens(0)) & "0") + ("0000" & unsigned(greens(0))) 
                                  + ("000" & unsigned(greens(3)) & "0") + ("0"    & unsigned(greens(3)) & "000")
                                  + ("000" & unsigned(greens(6)) & "0") + ("0000" & unsigned(greens(6)));

            sobel_1_green_right  <= ("000" & unsigned(greens(2)) & "0") + ("0000" & unsigned(greens(2))) 
                                  + ("000" & unsigned(greens(5)) & "0") + ("0"    & unsigned(greens(5)) & "000") 
                                  + ("000" & unsigned(greens(8)) & "0") + ("0000" & unsigned(greens(8)));

            sobel_1_green_top    <= ("000" & unsigned(greens(2)) & "0") + ("0000" & unsigned(greens(2)))       
                                  + ("000" & unsigned(greens(1)) & "0") + ("0"    & unsigned(greens(1)) & "000") 
                                  + ("000" & unsigned(greens(0)) & "0") + ("0000" & unsigned(greens(0)));

            sobel_1_green_bottom <= ("000" & unsigned(greens(6)) & "0") + ("0000" & unsigned(greens(6)))
                                  + ("000" & unsigned(greens(7)) & "0") + ("0"    & unsigned(greens(7)) & "000") 
                                  + ("000" & unsigned(greens(8)) & "0") + ("0000" & unsigned(greens(8)));
                    
            -- For the blue channel
            sobel_1_blue_left   <= ("000" & unsigned(blues(0)) & "0") + ("0000" & unsigned(blues(0))) 
                                 + ("000" & unsigned(blues(3)) & "0") + ("0"    & unsigned(blues(3)) & "000")
                                 + ("000" & unsigned(blues(6)) & "0") + ("0000" & unsigned(blues(6)));

            sobel_1_blue_right  <= ("000" & unsigned(blues(2)) & "0") + ("0000" & unsigned(blues(2))) 
                                 + ("000" & unsigned(blues(5)) & "0") + ("0"    & unsigned(blues(5)) & "000") 
                                 + ("000" & unsigned(blues(8)) & "0") + ("0000" & unsigned(blues(8)));

            sobel_1_blue_top    <= ("000" & unsigned(blues(2)) & "0") + ("0000" & unsigned(blues(2)))       
                                 + ("000" & unsigned(blues(1)) & "0") + ("0"    & unsigned(blues(1)) & "000") 
                                 + ("000" & unsigned(blues(0)) & "0") + ("0000" & unsigned(blues(0)));

            sobel_1_blue_bottom <= ("000" & unsigned(blues(6)) & "0") + ("0000" & unsigned(blues(6)))
                                 + ("000" & unsigned(blues(7)) & "0") + ("0"    & unsigned(blues(7)) & "000") 
                                 + ("000" & unsigned(blues(8)) & "0") + ("0000" & unsigned(blues(8)));
                    
            --------------------------------------------------------------------
            -- Copy over the short chains that gives us a 3x3 matrix to work with
            ---------------------------------------------------------------------
            -- The bottom row
            blanks(1) <= blanks(0);
            hsyncs(1) <= hsyncs(0);
            vsyncs(1) <= vsyncs(0);
            reds(1)   <= reds(0);
            greens(1) <= greens(0);
            blues(1)  <= blues(0);
        
            blanks(2) <= blanks(1);
            hsyncs(2) <= hsyncs(1);
            vsyncs(2) <= vsyncs(1);
            reds(2)   <= reds(1);
            greens(2) <= greens(1);
            blues(2)  <= blues(1);
            -- The middle row
            blanks(4) <= blanks(3);
            hsyncs(4) <= hsyncs(3);
            vsyncs(4) <= vsyncs(3);
            reds(4)   <= reds(3);
            greens(4) <= greens(3);
            blues(4)  <= blues(3);
        
            blanks(5) <= blanks(4);
            hsyncs(5) <= hsyncs(4);
            vsyncs(5) <= vsyncs(4);
            reds(5)   <= reds(4);
            greens(5) <= greens(4);
            blues(5)  <= blues(4);
        
            -- The top row
            blanks(7) <= blanks(6);
            hsyncs(7) <= hsyncs(6);
            vsyncs(7) <= vsyncs(6);
            reds(7)   <= reds(6);
            greens(7) <= greens(6);
            blues(7)  <= blues(6);
        
            blanks(8) <= blanks(7);
            hsyncs(8) <= hsyncs(7);
            vsyncs(8) <= vsyncs(7);
            reds(8)   <= reds(7);
            greens(8) <= greens(7);
            blues(8)  <= blues(7);
        end if;
    end process;

end Behavioral;
