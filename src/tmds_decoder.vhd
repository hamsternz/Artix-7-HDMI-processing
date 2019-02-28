----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date: 10.07.2015 20:06:49
-- Design Name: 
-- Module Name: TMDS_decoder - Behavioral
--
-- Description: Decoding for TMDS encoded symbols. This performs the conversion
--              using a table lookup for simplicity
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
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TMDS_decoder is
    Port ( clk              : in  std_logic;
           symbol           : in  std_logic_vector (9 downto 0);
           invalid_symbol   : out std_logic;
           
           ctl_valid        : out std_logic;
           ctl              : out std_logic_vector (1 downto 0);

           terc4_valid      : out std_logic;
           terc4            : out std_logic_vector (3 downto 0);

           guardband_valid  : out std_logic;
           guardband        : out std_logic_vector (0 downto 0);

           data_valid       : out std_logic;
           data             : out std_logic_vector (7 downto 0));
end TMDS_decoder;

architecture Behavioral of TMDS_decoder is
    signal lookup : std_logic_vector (8 downto 0);
begin

decode_ctl:  process(clk)
   begin
      if rising_edge(clk) then
            ------------------
            -- TMDS data bytes
            if lookup(8) = '1' then
                data_valid <= '1'; 
                data       <= lookup(7 downto 0);
            else
                data_valid <= '0';
            end if;
                        
            ------------
            -- CTL codes
            if lookup(8 downto 7) = "01" then
                ctl_valid <= '1';
                ctl       <= lookup(1 downto 0);
            else 
                ctl_valid <= '0';
            end if;

            ------------------------------
            -- All other codes are invalid 
            ------------------------------
            if lookup(8 downto 7) = "00" then
                invalid_symbol <= '1';
            else
                invalid_symbol <= '0';
            end if;

            terc4_valid     <= '0';
            guardband_valid <= '0';
            if lookup(8) = '1' then
                -------------------------
                -- Decode the guard bands
                -------------------------
                case lookup(7 downto 0) is 
                    when x"55"  => guardband_valid <= '1'; guardband <= "0";
                    when x"AB"  => guardband_valid <= '1'; guardband <= "1";
                    when others => null;
                end case;

                -------------------------
                -- Decode TERC4 data
                -------------------------
                case lookup(7 downto 0) is 
                    when x"5B"  => terc4_valid <= '1'; terc4 <= "0000";-- "1010011100" TERC4 0000
                    when x"5A"  => terc4_valid <= '1'; terc4 <= "0001"; -- "1001100011" TERC4 0001
                    when x"D3"  => terc4_valid <= '1'; terc4 <= "0010"; -- "1011100100" TERC4 0010
                    when x"D9"  => terc4_valid <= '1'; terc4 <= "0011"; -- "1011100010" TERC4 0011
                    when x"93"  => terc4_valid <= '1'; terc4 <= "0100"; -- "0101110001" TERC4 0100
                    when x"22"  => terc4_valid <= '1'; terc4 <= "0101"; -- "0100011110" TERC4 0101
                    when x"92"  => terc4_valid <= '1'; terc4 <= "0110"; -- "0110001110" TERC4 0110
                    when x"44"  => terc4_valid <= '1'; terc4 <= "0111"; -- "0100111100" TERC4 0111
                    when x"AB"  => terc4_valid <= '1'; terc4 <= "1000"; -- "1011001100" TERC4 1000 & HDMI Guard band (video C0 and Video C2) 
                    when x"4B"  => terc4_valid <= '1'; terc4 <= "1001"; -- "0100111001" TERC4 1001
                    when x"A4"  => terc4_valid <= '1'; terc4 <= "1010"; -- "0110011100" TERC4 1010
                    when x"B5"  => terc4_valid <= '1'; terc4 <= "1011"; -- "1011000110" TERC4 1011
                    when x"6D"  => terc4_valid <= '1'; terc4 <= "1100"; -- "1010001110" TERC4 1100
                    when x"6C"  => terc4_valid <= '1'; terc4 <= "1101"; -- "1001110001" TERC4 1101
                    when x"A5"  => terc4_valid <= '1'; terc4 <= "1110"; -- "0101100011" TERC4 1110
                    when x"BA"  => terc4_valid <= '1'; terc4 <= "1111"; -- "1011000011" TERC4 1111
                    when others => null;
                end case;
            end if;

            -------------------------------------------------------------
            -- Convert the incoming signal to something we can decode
            --
            -- For data symbols 
            -- ----------------
            -- bit 8    - 1 -- Data word flage
            -- bits 7:0 - xxxxxxxx - Data value
            --
            -- For CTL symbols
            -- --------------- 
            -- bit 8    - 0 - Data word flage
            -- bit 7    - 1 - CTL Indicator
            -- bits 6:2 - X - Ignored
            -- bits 1:0 - xx - CTL value
            --
            -- For Invalid symbols
            -- ------------------- 
            -- bit 8    - 0 - Data word flage
            -- bit 7    - 0 - TERC4 Inicated
            -- bit 6    - 0 - CTL Indicator
            -- bit 5    - 0 - Guard band indicator
            -- bits 4:0 - X - Unused 
            --
            ------------------------------------------------------------- 
            case symbol is
                -- DVI-D Data sybmols
                -- Data 00
                when "1111111111" => lookup <= "100000000";
                when "0100000000" => lookup <= "100000000";
                -- Data 01
                when "0111111111" => lookup <= "100000001";
                when "1100000000" => lookup <= "100000001";
                -- Data 02
                when "0111111110" => lookup <= "100000010";
                when "1100000001" => lookup <= "100000010";
                -- Data 03
                when "1111111110" => lookup <= "100000011";
                when "0100000001" => lookup <= "100000011";
                -- Data 04
                when "0111111100" => lookup <= "100000100";
                when "1100000011" => lookup <= "100000100";
                -- Data 05
                when "1111111100" => lookup <= "100000101";
                when "0100000011" => lookup <= "100000101";
                -- Data 06
                when "1111111101" => lookup <= "100000110";
                when "0100000010" => lookup <= "100000110";
                -- Data 07
                when "0111111101" => lookup <= "100000111";
                when "1100000010" => lookup <= "100000111";
                -- Data 08
                when "0111111000" => lookup <= "100001000";
                when "1100000111" => lookup <= "100001000";
                -- Data 09
                when "1111111000" => lookup <= "100001001";
                when "0100000111" => lookup <= "100001001";
                -- Data 0a
                when "1111111001" => lookup <= "100001010";
                when "0100000110" => lookup <= "100001010";
                -- Data 0b
                when "0111111001" => lookup <= "100001011";
                when "1100000110" => lookup <= "100001011";
                -- Data 0c
                when "1111111011" => lookup <= "100001100";
                when "0100000100" => lookup <= "100001100";
                -- Data 0d
                when "0111111011" => lookup <= "100001101";
                when "1100000100" => lookup <= "100001101";
                -- Data 0e
                when "0111111010" => lookup <= "100001110";
                when "1100000101" => lookup <= "100001110";
                -- Data 0f
                when "1111111010" => lookup <= "100001111";
                when "0100000101" => lookup <= "100001111";
                -- Data 10
                when "0111110000" => lookup <= "100010000";
                -- Data 11
                when "0100001111" => lookup <= "100010001";
                -- Data 12
                when "1111110001" => lookup <= "100010010";
                when "0100001110" => lookup <= "100010010";
                -- Data 13
                when "0111110001" => lookup <= "100010011";
                when "1100001110" => lookup <= "100010011";
                -- Data 14
                when "1111110011" => lookup <= "100010100";
                when "0100001100" => lookup <= "100010100";
                -- Data 15
                when "0111110011" => lookup <= "100010101";
                when "1100001100" => lookup <= "100010101";
                -- Data 16
                when "0111110010" => lookup <= "100010110";
                when "1100001101" => lookup <= "100010110";
                -- Data 17
                when "1111110010" => lookup <= "100010111";
                when "0100001101" => lookup <= "100010111";
                -- Data 18
                when "1111110111" => lookup <= "100011000";
                when "0100001000" => lookup <= "100011000";
                -- Data 19
                when "0111110111" => lookup <= "100011001";
                when "1100001000" => lookup <= "100011001";
                -- Data 1a
                when "0111110110" => lookup <= "100011010";
                when "1100001001" => lookup <= "100011010";
                -- Data 1b
                when "1111110110" => lookup <= "100011011";
                when "0100001001" => lookup <= "100011011";
                -- Data 1c
                when "0111110100" => lookup <= "100011100";
                when "1100001011" => lookup <= "100011100";
                -- Data 1d
                when "1111110100" => lookup <= "100011101";
                when "0100001011" => lookup <= "100011101";
                -- Data 1e
                when "1001011111" => lookup <= "100011110";
                when "0010100000" => lookup <= "100011110";
                -- Data 1f
                when "0001011111" => lookup <= "100011111";
                when "1010100000" => lookup <= "100011111";
                -- Data 20
                when "1100011111" => lookup <= "100100000";
                when "0111100000" => lookup <= "100100000";
                -- Data 21
                when "0100011111" => lookup <= "100100001";
                when "1111100000" => lookup <= "100100001";
                -- Data 22
                when "0100011110" => lookup <= "100100010"; -- TERC4 0101
                -- Data 23
                when "0111100001" => lookup <= "100100011";
                -- Data 24
                when "1111100011" => lookup <= "100100100";
                when "0100011100" => lookup <= "100100100";
                -- Data 25
                when "0111100011" => lookup <= "100100101";
                when "1100011100" => lookup <= "100100101";
                -- Data 26
                when "0111100010" => lookup <= "100100110";
                -- Data 27
                when "0100011101" => lookup <= "100100111";
                -- Data 28
                when "1111100111" => lookup <= "100101000";
                when "0100011000" => lookup <= "100101000";
                -- Data 29
                when "0111100111" => lookup <= "100101001";
                when "1100011000" => lookup <= "100101001";
                -- Data 2a
                when "0111100110" => lookup <= "100101010";
                when "1100011001" => lookup <= "100101010";
                -- Data 2b
                when "1111100110" => lookup <= "100101011";
                when "0100011001" => lookup <= "100101011";
                -- Data 2c
                when "0111100100" => lookup <= "100101100";
                -- Data 2d
                when "0100011011" => lookup <= "100101101";
                -- Data 2e
                when "1001001111" => lookup <= "100101110";
                when "0010110000" => lookup <= "100101110";
                -- Data 2f
                when "0001001111" => lookup <= "100101111";
                when "1010110000" => lookup <= "100101111";
                -- Data 30
                when "1111101111" => lookup <= "100110000";
                when "0100010000" => lookup <= "100110000";
                -- Data 31
                when "0111101111" => lookup <= "100110001";
                when "1100010000" => lookup <= "100110001";
                -- Data 32
                when "0111101110" => lookup <= "100110010";
                when "1100010001" => lookup <= "100110010";
                -- Data 33
                when "1111101110" => lookup <= "100110011";
                when "0100010001" => lookup <= "100110011";
                -- Data 34
                when "0111101100" => lookup <= "100110100";
                when "1100010011" => lookup <= "100110100";
                -- Data 35
                when "1111101100" => lookup <= "100110101";
                when "0100010011" => lookup <= "100110101";
                -- Data 36
                when "1001000111" => lookup <= "100110110";
                -- Data 37
                when "1010111000" => lookup <= "100110111";
                -- Data 38
                when "0111101000" => lookup <= "100111000";
                -- Data 39
                when "0100010111" => lookup <= "100111001";
                -- Data 3a
                when "0010111100" => lookup <= "100111010";
                when "1001000011" => lookup <= "100111010";
                -- Data 3b
                when "1010111100" => lookup <= "100111011";
                when "0001000011" => lookup <= "100111011";
                -- Data 3c
                when "0010111110" => lookup <= "100111100";
                when "1001000001" => lookup <= "100111100";
                -- Data 3d
                when "1010111110" => lookup <= "100111101";
                when "0001000001" => lookup <= "100111101";
                -- Data 3e
                when "1010111111" => lookup <= "100111110";
                when "0001000000" => lookup <= "100111110";
                -- Data 3f
                when "0010111111" => lookup <= "100111111";
                when "1001000000" => lookup <= "100111111";
                -- Data 40
                when "1100111111" => lookup <= "101000000";
                when "0111000000" => lookup <= "101000000";
                -- Data 41
                when "0100111111" => lookup <= "101000001";
                when "1111000000" => lookup <= "101000001";
                -- Data 42
                when "0100111110" => lookup <= "101000010";
                when "1111000001" => lookup <= "101000010";
                -- Data 43
                when "1100111110" => lookup <= "101000011";
                when "0111000001" => lookup <= "101000011";
                -- Data 44
                when "0100111100" => lookup <= "101000100"; -- TERC4 0111
                -- Data 45
                when "0111000011" => lookup <= "101000101";
                -- Data 46
                when "1100111101" => lookup <= "101000110";
                when "0111000010" => lookup <= "101000110";
                -- Data 47
                when "0100111101" => lookup <= "101000111";
                when "1111000010" => lookup <= "101000111";
                -- Data 48
                when "1111000111" => lookup <= "101001000";
                when "0100111000" => lookup <= "101001000";
                -- Data 49
                when "0111000111" => lookup <= "101001001";
                when "1100111000" => lookup <= "101001001";
                -- Data 4a
                when "0111000110" => lookup <= "101001010";
                -- Data 4b
                when "0100111001" => lookup <= "101001011";  -- TERC4 1001
                -- Data 4c
                when "1100111011" => lookup <= "101001100";
                when "0111000100" => lookup <= "101001100";
                -- Data 4d
                when "0100111011" => lookup <= "101001101";
                when "1111000100" => lookup <= "101001101";
                -- Data 4e
                when "1001101111" => lookup <= "101001110";
                when "0010010000" => lookup <= "101001110";
                -- Data 4f
                when "0001101111" => lookup <= "101001111";
                when "1010010000" => lookup <= "101001111";
                -- Data 50
                when "1111001111" => lookup <= "101010000";
                when "0100110000" => lookup <= "101010000";
                -- Data 51
                when "0111001111" => lookup <= "101010001";
                when "1100110000" => lookup <= "101010001";
                -- Data 52
                when "0111001110" => lookup <= "101010010";
                when "1100110001" => lookup <= "101010010";
                -- Data 53
                when "1111001110" => lookup <= "101010011";
                when "0100110001" => lookup <= "101010011";
                -- Data 54
                when "0111001100" => lookup <= "101010100";
                -- Data 55
                when "0100110011" => lookup <= "101010101"; -- HDMI Guard band (video C1, data C1 & C2)
                -- Data 56
                when "1001100111" => lookup <= "101010110";
                when "0010011000" => lookup <= "101010110";
                -- Data 57
                when "0001100111" => lookup <= "101010111";
                when "1010011000" => lookup <= "101010111";
                -- Data 58
                when "1100110111" => lookup <= "101011000";
                when "0111001000" => lookup <= "101011000";
                -- Data 59
                when "0100110111" => lookup <= "101011001";
                when "1111001000" => lookup <= "101011001";
                -- Data 5a
                when "1001100011" => lookup <= "101011010"; -- TERC4 0001
                -- Data 5b
                when "1010011100" => lookup <= "101011011"; -- TERC4 0000
                -- Data 5c
                when "0010011110" => lookup <= "101011100";
                when "1001100001" => lookup <= "101011100";
                -- Data 5d
                when "1010011110" => lookup <= "101011101";
                when "0001100001" => lookup <= "101011101";
                -- Data 5e
                when "1010011111" => lookup <= "101011110";
                when "0001100000" => lookup <= "101011110";
                -- Data 5f
                when "0010011111" => lookup <= "101011111";
                when "1001100000" => lookup <= "101011111";
                -- Data 60
                when "1111011111" => lookup <= "101100000";
                when "0100100000" => lookup <= "101100000";
                -- Data 61
                when "0111011111" => lookup <= "101100001";
                when "1100100000" => lookup <= "101100001";
                -- Data 62
                when "0111011110" => lookup <= "101100010";
                when "1100100001" => lookup <= "101100010";
                -- Data 63
                when "1111011110" => lookup <= "101100011";
                when "0100100001" => lookup <= "101100011";
                -- Data 64
                when "0111011100" => lookup <= "101100100";
                when "1100100011" => lookup <= "101100100";
                -- Data 65
                when "1111011100" => lookup <= "101100101";
                when "0100100011" => lookup <= "101100101";
                -- Data 66
                when "1001110111" => lookup <= "101100110";
                when "0010001000" => lookup <= "101100110";
                -- Data 67
                when "0001110111" => lookup <= "101100111";
                when "1010001000" => lookup <= "101100111";
                -- Data 68
                when "0111011000" => lookup <= "101101000";
                -- Data 69
                when "0100100111" => lookup <= "101101001";
                -- Data 6a
                when "1001110011" => lookup <= "101101010";
                when "0010001100" => lookup <= "101101010";
                -- Data 6b
                when "0001110011" => lookup <= "101101011";
                when "1010001100" => lookup <= "101101011";
                -- Data 6c
                when "1001110001" => lookup <= "101101100"; -- TERC4 1101
                -- Data 6d
                when "1010001110" => lookup <= "101101101"; -- TERC4 1100
                -- Data 6e
                when "1010001111" => lookup <= "101101110";
                when "0001110000" => lookup <= "101101110";
                -- Data 6f
                when "0010001111" => lookup <= "101101111";
                when "1001110000" => lookup <= "101101111";
                -- Data 70
                when "1100101111" => lookup <= "101110000";
                when "0111010000" => lookup <= "101110000";
                -- Data 71
                when "0100101111" => lookup <= "101110001";
                when "1111010000" => lookup <= "101110001";
                -- Data 72
                when "1001111011" => lookup <= "101110010";
                when "0010000100" => lookup <= "101110010";
                -- Data 73
                when "0001111011" => lookup <= "101110011";
                when "1010000100" => lookup <= "101110011";
                -- Data 74
                when "1001111001" => lookup <= "101110100";
                when "0010000110" => lookup <= "101110100";
                -- Data 75
                when "0001111001" => lookup <= "101110101";
                when "1010000110" => lookup <= "101110101";
                -- Data 76
                when "1010000111" => lookup <= "101110110";
                -- Data 77
                when "1001111000" => lookup <= "101110111";
                -- Data 78
                when "1001111101" => lookup <= "101111000";
                when "0010000010" => lookup <= "101111000";
                -- Data 79
                when "0001111101" => lookup <= "101111001";
                when "1010000010" => lookup <= "101111001";
                -- Data 7a
                when "0001111100" => lookup <= "101111010";
                when "1010000011" => lookup <= "101111010";
                -- Data 7b
                when "1001111100" => lookup <= "101111011";
                when "0010000011" => lookup <= "101111011";
                -- Data 7c
                when "0001111110" => lookup <= "101111100";
                when "1010000001" => lookup <= "101111100";
                -- Data 7d
                when "1001111110" => lookup <= "101111101";
                when "0010000001" => lookup <= "101111101";
                -- Data 7e
                when "1001111111" => lookup <= "101111110";
                when "0010000000" => lookup <= "101111110";
                -- Data 7f
                when "0001111111" => lookup <= "101111111";
                when "1010000000" => lookup <= "101111111";
                -- Data 80
                when "1101111111" => lookup <= "110000000";
                when "0110000000" => lookup <= "110000000";
                -- Data 81
                when "0101111111" => lookup <= "110000001";
                when "1110000000" => lookup <= "110000001";
                -- Data 82
                when "0101111110" => lookup <= "110000010";
                when "1110000001" => lookup <= "110000010";
                -- Data 83
                when "1101111110" => lookup <= "110000011";
                when "0110000001" => lookup <= "110000011";
                -- Data 84
                when "0101111100" => lookup <= "110000100";
                when "1110000011" => lookup <= "110000100";
                -- Data 85
                when "1101111100" => lookup <= "110000101";
                when "0110000011" => lookup <= "110000101";
                -- Data 86
                when "1101111101" => lookup <= "110000110";
                when "0110000010" => lookup <= "110000110";
                -- Data 87
                when "0101111101" => lookup <= "110000111";
                when "1110000010" => lookup <= "110000111";
                -- Data 88
                when "0101111000" => lookup <= "110001000";
                -- Data 89
                when "0110000111" => lookup <= "110001001";
                -- Data 8a
                when "1101111001" => lookup <= "110001010";
                when "0110000110" => lookup <= "110001010";
                -- Data 8b
                when "0101111001" => lookup <= "110001011";
                when "1110000110" => lookup <= "110001011";
                -- Data 8c
                when "1101111011" => lookup <= "110001100";
                when "0110000100" => lookup <= "110001100";
                -- Data 8d
                when "0101111011" => lookup <= "110001101";
                when "1110000100" => lookup <= "110001101";
                -- Data 8e
                when "1000101111" => lookup <= "110001110";
                when "0011010000" => lookup <= "110001110";
                -- Data 8f
                when "0000101111" => lookup <= "110001111";
                when "1011010000" => lookup <= "110001111";
                -- Data 90
                when "1110001111" => lookup <= "110010000";
                when "0101110000" => lookup <= "110010000";
                -- Data 91
                when "0110001111" => lookup <= "110010001";
                when "1101110000" => lookup <= "110010001";
                -- Data 92
                when "0110001110" => lookup <= "110010010"; -- TERC4 0110
                -- Data 93
                when "0101110001" => lookup <= "110010011"; -- TERC4 0100
                -- Data 94
                when "1101110011" => lookup <= "110010100";
                when "0110001100" => lookup <= "110010100";
                -- Data 95
                when "0101110011" => lookup <= "110010101";
                when "1110001100" => lookup <= "110010101";
                -- Data 96
                when "1000100111" => lookup <= "110010110";
                -- Data 97
                when "1011011000" => lookup <= "110010111";
                -- Data 98
                when "1101110111" => lookup <= "110011000";
                when "0110001000" => lookup <= "110011000";
                -- Data 99
                when "0101110111" => lookup <= "110011001";
                when "1110001000" => lookup <= "110011001";
                -- Data 9a
                when "0011011100" => lookup <= "110011010";
                when "1000100011" => lookup <= "110011010";
                -- Data 9b
                when "1011011100" => lookup <= "110011011";
                when "0000100011" => lookup <= "110011011";
                -- Data 9c
                when "0011011110" => lookup <= "110011100";
                when "1000100001" => lookup <= "110011100";
                -- Data 9d
                when "1011011110" => lookup <= "110011101";
                when "0000100001" => lookup <= "110011101";
                -- Data 9e
                when "1011011111" => lookup <= "110011110";
                when "0000100000" => lookup <= "110011110";
                -- Data 9f
                when "0011011111" => lookup <= "110011111";
                when "1000100000" => lookup <= "110011111";
                -- Data a0
                when "1110011111" => lookup <= "110100000";
                when "0101100000" => lookup <= "110100000";
                -- Data a1
                when "0110011111" => lookup <= "110100001";
                when "1101100000" => lookup <= "110100001";
                -- Data a2
                when "0110011110" => lookup <= "110100010";
                when "1101100001" => lookup <= "110100010";
                -- Data a3
                when "1110011110" => lookup <= "110100011";
                when "0101100001" => lookup <= "110100011";
                -- Data a4
                when "0110011100" => lookup <= "110100100"; -- TERC4 1010
                -- Data a5
                when "0101100011" => lookup <= "110100101"; -- TERC4 1110
                -- Data a6
                when "1000110111" => lookup <= "110100110";
                when "0011001000" => lookup <= "110100110";
                -- Data a7
                when "0000110111" => lookup <= "110100111";
                when "1011001000" => lookup <= "110100111";
                -- Data a8
                when "1101100111" => lookup <= "110101000";
                when "0110011000" => lookup <= "110101000";
                -- Data a9
                when "0101100111" => lookup <= "110101001";
                when "1110011000" => lookup <= "110101001";
                -- Data aa
                when "1000110011" => lookup <= "110101010";
                -- Data ab
                when "1011001100" => lookup <= "110101011"; -- TERC4 1000 & HDMI Guard band (video C0 and Video C2) 
                -- Data ac
                when "0011001110" => lookup <= "110101100";
                when "1000110001" => lookup <= "110101100";
                -- Data ad
                when "1011001110" => lookup <= "110101101";
                when "0000110001" => lookup <= "110101101";
                -- Data ae
                when "1011001111" => lookup <= "110101110";
                when "0000110000" => lookup <= "110101110";
                -- Data af
                when "0011001111" => lookup <= "110101111";
                when "1000110000" => lookup <= "110101111";
                -- Data b0
                when "1101101111" => lookup <= "110110000";
                when "0110010000" => lookup <= "110110000";
                -- Data b1
                when "0101101111" => lookup <= "110110001";
                when "1110010000" => lookup <= "110110001";
                -- Data b2
                when "1000111011" => lookup <= "110110010";
                when "0011000100" => lookup <= "110110010";
                -- Data b3
                when "0000111011" => lookup <= "110110011";
                when "1011000100" => lookup <= "110110011";
                -- Data b4
                when "1000111001" => lookup <= "110110100";
                -- Data b5
                when "1011000110" => lookup <= "110110101"; -- TERC4 1011
                -- Data b6
                when "1011000111" => lookup <= "110110110";
                when "0000111000" => lookup <= "110110110";
                -- Data b7
                when "0011000111" => lookup <= "110110111";
                when "1000111000" => lookup <= "110110111";
                -- Data b8
                when "1000111101" => lookup <= "110111000";
                when "0011000010" => lookup <= "110111000";
                -- Data b9
                when "0000111101" => lookup <= "110111001";
                when "1011000010" => lookup <= "110111001";
                -- Data ba
                when "1011000011" => lookup <= "110111010"; -- TERC4 1111
                -- Data bb
                when "1000111100" => lookup <= "110111011";
                -- Data bc
                when "0000111110" => lookup <= "110111100";
                when "1011000001" => lookup <= "110111100";
                -- Data bd
                when "1000111110" => lookup <= "110111101";
                when "0011000001" => lookup <= "110111101";
                -- Data be
                when "1000111111" => lookup <= "110111110";
                when "0011000000" => lookup <= "110111110";
                -- Data bf
                when "0000111111" => lookup <= "110111111";
                when "1011000000" => lookup <= "110111111";
                -- Data c0
                when "1110111111" => lookup <= "111000000";
                when "0101000000" => lookup <= "111000000";
                -- Data c1
                when "0110111111" => lookup <= "111000001";
                when "1101000000" => lookup <= "111000001";
                -- Data c2
                when "0110111110" => lookup <= "111000010";
                when "1101000001" => lookup <= "111000010";
                -- Data c3
                when "1110111110" => lookup <= "111000011";
                when "0101000001" => lookup <= "111000011";
                -- Data c4
                when "0110111100" => lookup <= "111000100";
                when "1101000011" => lookup <= "111000100";
                -- Data c5
                when "1110111100" => lookup <= "111000101";
                when "0101000011" => lookup <= "111000101";
                -- Data c6
                when "1000010111" => lookup <= "111000110";
                -- Data c7
                when "1011101000" => lookup <= "111000111";
                -- Data c8
                when "0110111000" => lookup <= "111001000";
                -- Data c9
                when "0101000111" => lookup <= "111001001";
                -- Data ca
                when "0011101100" => lookup <= "111001010";
                when "1000010011" => lookup <= "111001010";
                -- Data cb
                when "1011101100" => lookup <= "111001011";
                when "0000010011" => lookup <= "111001011";
                -- Data cc
                when "0011101110" => lookup <= "111001100";
                when "1000010001" => lookup <= "111001100";
                -- Data cd
                when "1011101110" => lookup <= "111001101";
                when "0000010001" => lookup <= "111001101";
                -- Data ce
                when "1011101111" => lookup <= "111001110";
                when "0000010000" => lookup <= "111001110";
                -- Data cf
                when "0011101111" => lookup <= "111001111";
                when "1000010000" => lookup <= "111001111";
                -- Data d0
                when "1101001111" => lookup <= "111010000";
                when "0110110000" => lookup <= "111010000";
                -- Data d1
                when "0101001111" => lookup <= "111010001";
                when "1110110000" => lookup <= "111010001";
                -- Data d2
                when "1000011011" => lookup <= "111010010";
                -- Data d3
                when "1011100100" => lookup <= "111010011"; -- TERC4 0010
                -- Data d4
                when "0011100110" => lookup <= "111010100";
                when "1000011001" => lookup <= "111010100";
                -- Data d5
                when "1011100110" => lookup <= "111010101";
                when "0000011001" => lookup <= "111010101";
                -- Data d6
                when "1011100111" => lookup <= "111010110";
                when "0000011000" => lookup <= "111010110";
                -- Data d7
                when "0011100111" => lookup <= "111010111";
                when "1000011000" => lookup <= "111010111";
                -- Data d8
                when "1000011101" => lookup <= "111011000";
                -- Data d9
                when "1011100010" => lookup <= "111011001"; -- TERC4 0011
                -- Data da
                when "1011100011" => lookup <= "111011010";
                when "0000011100" => lookup <= "111011010";
                -- Data db
                when "0011100011" => lookup <= "111011011";
                when "1000011100" => lookup <= "111011011";
                -- Data dc
                when "1011100001" => lookup <= "111011100";
                -- Data dd
                when "1000011110" => lookup <= "111011101";
                -- Data de
                when "1000011111" => lookup <= "111011110";
                when "0011100000" => lookup <= "111011110";
                -- Data df
                when "0000011111" => lookup <= "111011111";
                when "1011100000" => lookup <= "111011111";
                -- Data e0
                when "1101011111" => lookup <= "111100000";
                when "0110100000" => lookup <= "111100000";
                -- Data e1
                when "0101011111" => lookup <= "111100001";
                when "1110100000" => lookup <= "111100001";
                -- Data e2
                when "0011110100" => lookup <= "111100010";
                when "1000001011" => lookup <= "111100010";
                -- Data e3
                when "1011110100" => lookup <= "111100011";
                when "0000001011" => lookup <= "111100011";
                -- Data e4
                when "0011110110" => lookup <= "111100100";
                when "1000001001" => lookup <= "111100100";
                -- Data e5
                when "1011110110" => lookup <= "111100101";
                when "0000001001" => lookup <= "111100101";
                -- Data e6
                when "1011110111" => lookup <= "111100110";
                when "0000001000" => lookup <= "111100110";
                -- Data e7
                when "0011110111" => lookup <= "111100111";
                when "1000001000" => lookup <= "111100111";
                -- Data e8
                when "0011110010" => lookup <= "111101000";
                when "1000001101" => lookup <= "111101000";
                -- Data e9
                when "1011110010" => lookup <= "111101001";
                when "0000001101" => lookup <= "111101001";
                -- Data ea
                when "1011110011" => lookup <= "111101010";
                when "0000001100" => lookup <= "111101010";
                -- Data eb
                when "0011110011" => lookup <= "111101011";
                when "1000001100" => lookup <= "111101011";
                -- Data ec
                when "1011110001" => lookup <= "111101100";
                when "0000001110" => lookup <= "111101100";
                -- Data ed
                when "0011110001" => lookup <= "111101101";
                when "1000001110" => lookup <= "111101101";
                -- Data ee
                when "1000001111" => lookup <= "111101110";
                -- Data ef
                when "1011110000" => lookup <= "111101111";
                -- Data f0
                when "0011111010" => lookup <= "111110000";
                when "1000000101" => lookup <= "111110000";
                -- Data f1
                when "1011111010" => lookup <= "111110001";
                when "0000000101" => lookup <= "111110001";
                -- Data f2
                when "1011111011" => lookup <= "111110010";
                when "0000000100" => lookup <= "111110010";
                -- Data f3
                when "0011111011" => lookup <= "111110011";
                when "1000000100" => lookup <= "111110011";
                -- Data f4
                when "1011111001" => lookup <= "111110100";
                when "0000000110" => lookup <= "111110100";
                -- Data f5
                when "0011111001" => lookup <= "111110101";
                when "1000000110" => lookup <= "111110101";
                -- Data f6
                when "0011111000" => lookup <= "111110110";
                when "1000000111" => lookup <= "111110110";
                -- Data f7
                when "1011111000" => lookup <= "111110111";
                when "0000000111" => lookup <= "111110111";
                -- Data f8
                when "1011111101" => lookup <= "111111000";
                when "0000000010" => lookup <= "111111000";
                -- Data f9
                when "0011111101" => lookup <= "111111001";
                when "1000000010" => lookup <= "111111001";
                -- Data fa
                when "0011111100" => lookup <= "111111010";
                when "1000000011" => lookup <= "111111010";
                -- Data fb
                when "1011111100" => lookup <= "111111011";
                when "0000000011" => lookup <= "111111011";
                -- Data fc
                when "0011111110" => lookup <= "111111100";
                when "1000000001" => lookup <= "111111100";
                -- Data fd
                when "1011111110" => lookup <= "111111101";
                when "0000000001" => lookup <= "111111101";
                -- Data fe
                when "1011111111" => lookup <= "111111110";
                when "0000000000" => lookup <= "111111110";
                -- Data ff
                when "0011111111" => lookup <= "111111111";
                when "1000000000" => lookup <= "111111111";
                
                -- DVI-D CTL symbols        
                when "0010101011" => lookup <= "01" & "00000" &  "01";  -- CTL1
                when "0101010100" => lookup <= "01" & "00000" &  "10";  -- CTL2
                when "1010101011" => lookup <= "01" & "00000" &  "11";  -- CTL3
                when "1101010100" => lookup <= "01" & "00000" &  "00";  -- CTL0
                
                -- Invalid symbols
                when others       => lookup <= "0000" & "00000"; 
            end case;
        end if;
    end process;
end Behavioral;

-- For Guard band and TERC4 decoding (to be done later!) 
-- when x"55" => -- "0100110011" HDMI Guard band (video C1, data C1 & C2)
-- when x"5B" => -- "1010011100" TERC4 0000
-- when x"5A" => -- "1001100011" TERC4 0001
-- when x"D3" => -- "1011100100" TERC4 0010
-- when x"D9" => -- "1011100010" TERC4 0011
-- when x"93" => -- "0101110001" TERC4 0100
-- when x"22" => -- "0100011110" TERC4 0101
-- when x"92" => -- "0110001110" TERC4 0110
-- when x"44" => -- "0100111100" TERC4 0111
-- when x"AB" => -- "1011001100" TERC4 1000 & HDMI Guard band (video C0 and Video C2) 
-- when x"4B" => -- "0100111001" TERC4 1001
-- when x"A4" => -- "0110011100" TERC4 1010
-- when x"B5" => -- "1011000110" TERC4 1011
-- when x"6D" => -- "1010001110" TERC4 1100
-- when x"6C" => -- "1001110001" TERC4 1101
-- when x"A5" => -- "0101100011" TERC4 1110
-- when x"BA" => -- "1011000011" TERC4 1111