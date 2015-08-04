----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: audio_to_db - Behavioral
--
-- Description: Calcuate the approximate DB level of an audio signal, with a 
--              return of 63 indicating 0db, (e.g. 3 = -60fb)
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

entity audio_to_db is
    Port ( clk           : in  STD_LOGIC;

           in_channel    : in  STD_LOGIC_VECTOR (2 downto 0);
           in_de         : in  STD_LOGIC;
           in_sample     : in  STD_LOGIC_VECTOR (23 downto 0);

           out_channel   : out STD_LOGIC_VECTOR (2 downto 0);
           out_de        : out STD_LOGIC;
           out_level     : out STD_LOGIC_VECTOR (5 downto 0));
end audio_to_db;

architecture Behavioral of audio_to_db is

    signal s7_sample  : unsigned (23 downto 0);
    signal s7_de      : STD_LOGIC;
    signal s7_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s7_level   : unsigned( 7 downto 0);

    signal s6_sample  : unsigned (23 downto 0);
    signal s6_de      : STD_LOGIC;
    signal s6_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s6_level   : unsigned( 7 downto 0);

    signal s5_sample  : unsigned (23 downto 0);
    signal s5_de      : STD_LOGIC;
    signal s5_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s5_level   : unsigned( 7 downto 0);

    signal s4_sample  : unsigned (23 downto 0);
    signal s4_de      : STD_LOGIC;
    signal s4_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s4_level   : unsigned( 7 downto 0);

    signal s3_sample  : unsigned (23 downto 0);
    signal s3_de      : STD_LOGIC;
    signal s3_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s3_level   : unsigned( 7 downto 0);

    signal s2_sample  : unsigned (23 downto 0);
    signal s2_de      : STD_LOGIC;
    signal s2_channel : STD_LOGIC_VECTOR (2 downto 0);
    signal s2_level   : unsigned( 7 downto 0);

    signal s1_sample  : unsigned (23 downto 0);
    signal s1_de      : STD_LOGIC;
    signal s1_channel : STD_LOGIC_VECTOR (2 downto 0);
begin

process(clk)
    begin
        if rising_edge(clk) then
            out_channel <= s7_channel;
            out_de      <= s7_de;
            if s7_level(7 downto 6) = "00" then
                out_level <= std_logic_vector(to_unsigned(63,6)-s7_level(5 downto 0));
            else
                out_level <= (others => '0');
            end if;
            
            -- Finally the last stage to get a db level
            s7_channel <= s6_channel;
            s7_de      <= s6_de;
            if s6_sample(22 downto 15) < 72 then
                s7_level <= s6_level + 5;
            elsif s6_sample(22 downto 15) < 81 then
                s7_level <= s6_level + 4;
            elsif s6_sample(22 downto 15) < 91 then
                s7_level <= s6_level + 3;
            elsif s6_sample(22 downto 15) < 102 then
                s7_level <= s6_level + 2;
            elsif s6_sample(22 downto 15) < 114 then
                s7_level <= s6_level + 1;
            else
                s7_level <= s6_level + 1;
            end if;
                        
            -- Stage 5 - shift up 2 bits if needed(bit 23 of sample will be 0)
            s6_channel <= s5_channel;
            s6_de      <= s5_de;
            if s5_sample(23 downto 22) = "00" then
                s6_sample <= s5_sample(22 downto 0) & "0";
                s6_level  <= s5_level + to_unsigned(6,8);
            else
                s6_sample <= s5_sample;
                s6_level  <= s5_level;
            end if; 
    
            -- Stage 5 - shift up 2 bits if needed(bit 23 of sample will be 0)
            s5_channel <= s4_channel;
            s5_de      <= s4_de;
            if s4_sample(23 downto 21) = "000" then
                s5_sample <= s4_sample(21 downto 0) & "00";
                s5_level  <= s4_level + to_unsigned(12,8);
            else
                s5_sample <= s4_sample;
                s5_level  <= s4_level;
            end if; 
        
            -- Stage 4 - shift up 4 bits if needed(bit 23 of sample will be 0)
            s4_channel <= s3_channel;
            s4_de      <= s3_de;
            if s3_sample(23 downto 19) = "00000" then
                s4_sample <= s3_sample(19 downto 0) & "0000";
                s4_level  <= s3_level + to_unsigned(24,8);
            else
                s4_sample <= s3_sample;
                s4_level  <= s3_level;
            end if; 

            -- Stage 3 - shift up 4 bits if needed(bit 23 of sample will be 0)
            s3_channel <= s2_channel;
            s3_de      <= s2_de;
            if s2_sample(23 downto 19) = "00000" then
                s3_sample <= s2_sample(19 downto 0) & "0000";
                s3_level  <= s2_level + to_unsigned(24,8);
            else
                s3_sample <= s2_sample;
                s3_level  <= s2_level;
            end if; 

            -- Stage 2 - shift up 4 bits if needed(bit 23 of sample will be 0)
            s2_channel <= s1_channel;
            s2_de      <= s1_de;
            if s1_sample(23 downto 19) = "00000" then
                s2_sample <= s1_sample(19 downto 0) & "0000";
                s2_level  <= to_unsigned(24,8);
            else
                s2_sample <= s1_sample;
                s2_level  <= to_unsigned(0,8);
            end if; 
             
            --- Stage 1 - remove any sign.
            s1_channel <= in_channel;
            s1_de      <= in_de;
            if in_sample(23) = '1' then
                s1_sample  <= to_unsigned(0,24) - unsigned(in_sample);
            else
                s1_sample  <= unsigned(in_sample);
            end if;
        end if;
    end process;

end Behavioral;
