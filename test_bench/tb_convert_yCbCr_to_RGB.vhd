----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: A testbench for YCbCr to RGB decoding 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_convert_yCbCr_to_RGB is
end tb_convert_yCbCr_to_RGB;

architecture Behavioral of tb_convert_yCbCr_to_RGB is
    component conversion_YCbCr_to_RGB is
    port ( clk      : in std_Logic;
           input_is_YCbCr : in std_Logic;

           ------------------------
           in_blank : in std_logic;
           in_hsync : in std_logic;
           in_vsync : in std_logic;
           in_U     : in std_logic_vector(11 downto 0);  -- B or Cb
           in_V     : in std_logic_vector(11 downto 0);  -- G or Y
           in_W     : in std_logic_vector(11 downto 0);  -- R or Cr

           ------------------------
           out_blank : out std_logic;
           out_hsync : out std_logic;
           out_vsync : out std_logic;
           out_R     : out std_logic_vector(11 downto 0);
           out_G     : out std_logic_vector(11 downto 0);
           out_B     : out std_logic_vector(11 downto 0));
    end component;

    signal clk            : std_Logic := '0';
    signal input_is_YCbCr : std_Logic := '0';
    signal in_blank       : std_logic := '0';
    signal in_hsync       : std_logic := '0';
    signal in_vsync       : std_logic := '0';
    signal in_U           : std_logic_vector(11 downto 0) := x"800";  -- B or Cb
    signal in_V           : std_logic_vector(11 downto 0) := x"800";  -- G or Y
    signal in_W           : std_logic_vector(11 downto 0) := x"800";  -- R or Cr
    signal out_blank      : std_logic := '0';
    signal out_hsync      : std_logic := '0';
    signal out_vsync      : std_logic := '0';
    signal out_R          : std_logic_vector(11 downto 0);
    signal out_G          : std_logic_vector(11 downto 0);
    signal out_B          : std_logic_vector(11 downto 0);

begin

process
    begin
        wait for 5 ns;
        clk <= not clk;
    end process;

stim: process
    begin
        wait for 100 ns;
        in_U <= x"100";
        wait for 100 ns;
        in_U <= x"EFF";
        wait for 100 ns;
        in_U <= x"800";

        wait for 100 ns;
        in_V <= x"100";
        wait for 100 ns;
        in_V <= x"EFF";
        wait for 100 ns;
        in_V <= x"800";

        wait for 100 ns;
        in_W <= x"100";
        wait for 100 ns;
        in_W <= x"EFF";
        wait for 100 ns;
        in_W <= x"800";

    end process;
uut: conversion_YCbCr_to_RGB port map (
        clk => clk,
        input_is_YCbCr => '1',
        ------------------------
        in_blank => in_blank,
        in_hsync => in_hsync,
        in_vsync => in_vsync, 
        in_U     => in_U,
        in_V     => in_V,
        in_W     => in_W,
        ------------------------
        out_blank => out_blank, 
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_R     => out_R,
        out_G     => out_G,
        out_B     => out_B);

end Behavioral;
