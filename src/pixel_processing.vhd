----------------------------------------------------------------------------------
-- Engineer: Mike Field <hasmter@snap.net.nz> 
-- 
-- Module Name: pixel_processing - Behavioral
--
-- Description: Where you can do processing on the raw pixel data
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

entity pixel_processing is
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
            ------------------------------------
            -- Audio only comes in..
            ------------------------------------
            audio_channel : in std_logic_vector(2 downto 0);
            audio_de      : in std_logic;
            audio_sample  : in std_logic_vector(23 downto 0);
      
            ----------------------------------
            -- Controls
            ----------------------------------   
            switches : in std_logic_vector(7 downto 0)
    );
end pixel_processing;

architecture Behavioral of pixel_processing is
    component audio_to_db is
    Port ( clk           : in STD_LOGIC;
           in_channel    : in STD_LOGIC_VECTOR (2 downto 0);
           in_de         : in STD_LOGIC;
           in_sample     : in STD_LOGIC_VECTOR (23 downto 0);
           out_channel   : out STD_LOGIC_VECTOR (2 downto 0);
           out_de        : out STD_LOGIC;
           out_level     : out STD_LOGIC_VECTOR (5 downto 0));
    end component;

    signal level_channel  : std_logic_vector(2 downto 0);
    signal level_de       : std_logic;
    signal level          : std_logic_vector(5 downto 0);

    component audio_meters is
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
    end component;

    component edge_enhance is
    Port ( clk : in STD_LOGIC;
           enable_feature   : in std_logic;
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
           out_blue  : out std_logic_vector(7 downto 0)
    );
    end component;

    component guidelines is
    Port ( clk : in STD_LOGIC;
           enable_feature   : in std_logic;
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
           out_blue  : out std_logic_vector(7 downto 0)
    );
    end component;
    
    signal b_blank : std_logic;
    signal b_hsync : std_logic;
    signal b_vsync : std_logic;
    signal b_red   : std_logic_vector(7 downto 0);
    signal b_green : std_logic_vector(7 downto 0);
    signal b_blue  : std_logic_vector(7 downto 0);

    signal c_blank : std_logic;
    signal c_hsync : std_logic;
    signal c_vsync : std_logic;
    signal c_red   : std_logic_vector(7 downto 0);
    signal c_green : std_logic_vector(7 downto 0);
    signal c_blue  : std_logic_vector(7 downto 0);

begin

i_audio_to_db: audio_to_db port map (
        clk            => clk,

        in_channel     => audio_channel,
        in_de          => audio_de,
        in_sample      => audio_sample,
 
        out_channel    => level_channel,
        out_de         => level_de,
        out_level      => level
    );

i_edge_enhance: edge_enhance Port map ( 
        clk       => clk,
        
        enable_feature => switches(0),

        in_blank  => in_blank,
        in_hsync  => in_hsync,
        in_vsync  => in_vsync,
        in_red    => in_red,
        in_green  => in_green,
        in_blue   => in_blue,
       
        out_blank => b_blank,
        out_hsync => b_hsync,
        out_vsync => b_vsync,
        out_red   => b_red,
        out_green => b_green,
        out_blue  => b_blue
    );

i_audio_meters: audio_meters Port map ( 
        clk       => clk,
        in_blank  => b_blank,
        in_hsync  => b_hsync,
        in_vsync  => b_vsync,
        in_red    => b_red,
        in_green  => b_green,
        in_blue   => b_blue,
        is_interlaced => is_interlaced,
        is_second_field => is_second_field,
       
        out_blank => c_blank,
        out_hsync => c_hsync,
        out_vsync => c_vsync,
        out_red   => c_red,
        out_green => c_green,
        out_blue  => c_blue,
        
        audio_channel => level_channel,
        audio_de      => level_de,
        audio_level   => level
    );


i_guidelines: guidelines Port map ( 
        clk       => clk,
        
        enable_feature => switches(1),

        in_blank  => c_blank,
        in_hsync  => c_hsync,
        in_vsync  => c_vsync,
        in_red    => c_red,
        in_green  => c_green,
        in_blue   => c_blue,
        is_interlaced => is_interlaced,
        is_second_field => is_second_field,
       
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue
    );

 end Behavioral;