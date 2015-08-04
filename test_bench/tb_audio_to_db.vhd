----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tb_audio_to_db - Behavioral
--
-- Description: A testbench for the audio sample to db level calculation
-- 
----------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
----- Want to say thanks? --------------------------------------------------------
----------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_audio_to_db is
end tb_audio_to_db;

architecture Behavioral of tb_audio_to_db is
    component audio_to_db is
    Port ( clk           : in  STD_LOGIC;

           in_channel    : in  STD_LOGIC_VECTOR (2 downto 0);
           in_de         : in  STD_LOGIC;
           in_sample     : in  STD_LOGIC_VECTOR (23 downto 0);

           out_channel   : out STD_LOGIC_VECTOR (2 downto 0);
           out_de        : out STD_LOGIC;
           out_level     : out STD_LOGIC_VECTOR (5 downto 0));
    end component;

    signal clk           : STD_LOGIC := '0';

    signal in_channel    : STD_LOGIC_VECTOR (2 downto 0)  := (others => '0');
    signal in_de         : STD_LOGIC                      := '1';
    signal in_sample     : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');

    signal out_channel   : STD_LOGIC_VECTOR (2 downto 0);
    signal out_de        : STD_LOGIC;
    signal out_level     : STD_LOGIC_VECTOR (5 downto 0);

begin

process
    begin
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
    end process;

process
    begin
        wait until rising_edge(clk);
        in_de <= '1';
        in_sample <= in_sample(in_sample'high-1 downto 0) & not in_sample(in_sample'high);
        wait until rising_edge(clk);
        in_de <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
    end process;

uut: audio_to_db port map (
        clk         => clk,
        in_channel  => in_channel,
        in_de       => in_de,
        in_sample   => in_sample,

        out_channel => out_channel,
        out_de      => out_de,
        out_level   => out_level);

end Behavioral;
