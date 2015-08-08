----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz<
-- 
-- Description: A minimal set of TMDS symbols - just enough to send a valid 
--              HDMI stream
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

entity minimal_hdmi_symbols is
    Port ( clk : in  STD_LOGIC;
           hsync, vsync,  blank : in  STD_LOGIC;
           red,   green,  blue  : in  STD_LOGIC;
           c0,    c1,     c2    : out STD_LOGIC_VECTOR (9 downto 0));
end minimal_hdmi_symbols;

architecture Behavioral of minimal_hdmi_symbols is
   type a_symbol_queue is array (0 to 10) of STD_LOGIC_VECTOR (4 downto 0);
   
   signal symbol_queue : a_symbol_queue                  := (others => (others => '0'));
   signal symbols      :  STD_LOGIC_VECTOR (29 downto 0) := (others => '0');
   
   signal last_blank : std_logic := '0';
   signal last_vsync : std_logic := '0';
   signal last_hsync : std_logic := '0';
   
   signal data_island_armed : std_logic := '0';
   signal data_island_index : unsigned(5 downto 0) := (others => '1');
begin
   c0 <= symbols(29 downto 20);
   c1 <= symbols(19 downto 10);
   c2 <= symbols( 9 downto  0);

process(clk) 
   begin
      if rising_edge(clk) then
         case symbol_queue(0) is  
            ---------------------------------------------------------------
            -- Eight TMDS encoded colours for testing
            ---------------------------------------------------------------
            when "00000" => symbols <= "0111110000" & "0111110000" & "0111110000"; -- RGB 0x101010 - Black
            when "00001" => symbols <= "0111110000" & "0111110000" & "1011110000"; -- RGB 0xEF1010 - Red
            when "00010" => symbols <= "0111110000" & "1011110000" & "0111110000"; -- RGB 0x10EF10 - Green
            when "00011" => symbols <= "0111110000" & "1011110000" & "1011110000"; -- RGB 0xEFEF10 - Cyan
            when "00100" => symbols <= "1011110000" & "0111110000" & "0111110000"; -- RGB 0x1010EF - Blue
            when "00101" => symbols <= "1011110000" & "0111110000" & "1011110000"; -- RGB 0xEF10EF - Magenta
            when "00110" => symbols <= "1011110000" & "1011110000" & "0111110000"; -- RGB 0x10EFEF - Yellow
            when "00111" => symbols <= "1011110000" & "1011110000" & "1011110000"; -- RGB 0xEFEFEF - White
            ---------------------------------------------------------------
            -- control symbols from 5.4.2 - part of the DVI-D standard
            ---------------------------------------------------------------
            when "01000" => symbols <= "1101010100" & "1101010100" & "1101010100"; -- CTL periods
            when "01001" => symbols <= "0010101011" & "1101010100" & "1101010100"; -- Hsync
            when "01010" => symbols <= "0101010100" & "1101010100" & "1101010100"; -- vSync
            when "01011" => symbols <= "1010101011" & "1101010100" & "1101010100"; -- vSync+hSync
            ---------------------------------------------------------------
            -- Symbols to signal the start of a HDMI feature 
            ---------------------------------------------------------------
            when "01100" => symbols <= "0101010100" & "0010101011" & "0010101011"; -- DataIslandPeamble, with VSYNC - 5.2.1.1
            when "01101" => symbols <= "0101100011" & "0100110011" & "0100110011"; -- DataIslandGuardBand, with VSYNC - 5.2.3.3	
            when "01110" => symbols <= "1101010100" & "0010101011" & "1101010100"; -- VideoPramble 5.2.1.1
            when "01111" => symbols <= "1011001100" & "0100110011" & "1011001100"; -- VideoGuardBand 5.2.2.1

            ---------------------------------------------------------------
            -- From TERC4 codes in 5.4.3, and data data layout from 5.2.3.1
            --
            -- First nibble  is used for the nFirstWordOfPacket (MSB) Header Bit, VSYNC, HSYNC (LSB).
            -- The packet is sent where VSYNC = '1' and HSYNC = '0', so we are left with 4 options            
            -- Second nibble is used for the odd bits the four data sub-packets
            -- Third nibble  is used for the even bits the four data sub-packets
            --
            -- These can be used to contruct a data island with any header
            -- and any data in subpacket 0, but all other subpackets 
            -- must be 0s.
            ---------------------------------------------------------------
            when "10000" => symbols <= "1011100100" & "1010011100" & "1010011100"; -- 0010 0000 0000, TERC4 coded
            when "10001" => symbols <= "1011100100" & "1010011100" & "1001100011"; -- 0010 0000 0001, TERC4 coded
            when "10010" => symbols <= "1011100100" & "1001100011" & "1010011100"; -- 0010 0000 0000, TERC4 coded
            when "10011" => symbols <= "1011100100" & "1001100011" & "1001100011"; -- 0010 0001 0001, TERC4 coded
            when "10100" => symbols <= "0110001110" & "1010011100" & "1010011100"; -- 0110 0000 0000, TERC4 coded
            when "10101" => symbols <= "0110001110" & "1010011100" & "1001100011"; -- 0110 0000 0001, TERC4 coded
            when "10110" => symbols <= "0110001110" & "1001100011" & "1010011100"; -- 0110 0001 0000, TERC4 coded
            when "10111" => symbols <= "0110001110" & "1001100011" & "1001100011"; -- 0110 0001 0001, TERC4 coded
            when "11000" => symbols <= "0110011100" & "1010011100" & "1010011100"; -- 1010 0000 0000, TERC4 coded
            when "11001" => symbols <= "0110011100" & "1010011100" & "1001100011"; -- 1010 0000 0001, TERC4 coded
            when "11010" => symbols <= "0110011100" & "1001100011" & "1010011100"; -- 1010 0001 0000, TERC4 coded
            when "11011" => symbols <= "0110011100" & "1001100011" & "1001100011"; -- 1010 0001 0001, TERC4 coded
            when "11100" => symbols <= "0101100011" & "1010011100" & "1010011100"; -- 1110 0000 0000, TERC4 coded
            when "11101" => symbols <= "0101100011" & "1010011100" & "1001100011"; -- 1110 0000 0001, TERC4 coded
            when "11110" => symbols <= "0101100011" & "1001100011" & "1010011100"; -- 1110 0001 0000, TERC4 coded
            when "11111" => symbols <= "0101100011" & "1001100011" & "1001100011"; -- 1110 0001 0001, TERC4 coded

            when others => symbols <= (others => '0');
         end case;
   
         if blank = '0' then
            -- Are we being asked to send video data? If so we need to send a peramble
            if last_blank = '1' then
               symbol_queue(10) <= "00" & blue & green & red;
               symbol_queue(9) <= "01111";  -- Video Guard Band
               symbol_queue(8) <= "01111"; 
               symbol_queue(7) <= "01110";  -- Video Preamble
               symbol_queue(6) <= "01110";
               symbol_queue(5) <= "01110";
               symbol_queue(4) <= "01110";
               symbol_queue(3) <= "01110";
               symbol_queue(2) <= "01110";
               symbol_queue(1) <= "01110";
               symbol_queue(0) <= "01110";
            else
               symbol_queue(0 to 9) <= symbol_queue(1 to 10);
               symbol_queue(10) <= "00" & blue & green & red;
            end if;
         else
           -- Just merge in the syncs into the control period
           case data_island_index is
               when "000000" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000001" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000010" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000011" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000100" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000101" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000110" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "000111" => symbol_queue(10) <= "01100"; -- Data island preamble
               when "001000" => symbol_queue(10) <= "01101"; -- Data island Guard Band
               when "001001" => symbol_queue(10) <= "01101"; -- Data island Guard Band


               -------------------------
               -- For a YCC mode AVI Infoframe Data Island
               -------------------------
                  -- Data Island (0-7)
               when "001010" => symbol_queue(10) <= "10011"; -- First word 
               when "001011" => symbol_queue(10) <= "11111";
               when "001100" => symbol_queue(10) <= "11001";
               when "001101" => symbol_queue(10) <= "11000";
               when "001110" => symbol_queue(10) <= "11000";
               when "001111" => symbol_queue(10) <= "11000";
               when "010000" => symbol_queue(10) <= "11000";
               when "010001" => symbol_queue(10) <= "11110";
                  -- Data Island (8-15)
               when "010010" => symbol_queue(10) <= "11000";
               when "010011" => symbol_queue(10) <= "11100";
               when "010100" => symbol_queue(10) <= "11000";
               when "010101" => symbol_queue(10) <= "11000";
               when "010110" => symbol_queue(10) <= "11000";
               when "010111" => symbol_queue(10) <= "11000";
               when "011000" => symbol_queue(10) <= "11000";
               when "011001" => symbol_queue(10) <= "11000";
                 -- Data Island (16-23)
               when "011010" => symbol_queue(10) <= "11100";
               when "011011" => symbol_queue(10) <= "11000";
               when "011100" => symbol_queue(10) <= "11100";
               when "011101" => symbol_queue(10) <= "11100";
               when "011110" => symbol_queue(10) <= "11000";
               when "011111" => symbol_queue(10) <= "11000";
               when "100000" => symbol_queue(10) <= "11000";
               when "100001" => symbol_queue(10) <= "11000";
                  -- Data Island (24-31)
               when "100010" => symbol_queue(10) <= "11000";
               when "100011" => symbol_queue(10) <= "11000";
               when "100100" => symbol_queue(10) <= "11100";
               when "100101" => symbol_queue(10) <= "11000";
               when "100110" => symbol_queue(10) <= "11010";
               when "100111" => symbol_queue(10) <= "11100";
               when "101000" => symbol_queue(10) <= "11111";
               when "101001" => symbol_queue(10) <= "11110";

               -------------------------
               -- For a NULL Data Island
               -------------------------
               -- Data Island (0-7)
--               when "001010" => symbol_queue(10) <= "10000"; -- First word 
--               when "001011" => symbol_queue(10) <= "11000";
--               when "001100" => symbol_queue(10) <= "11000";
--               when "001101" => symbol_queue(10) <= "11000";
--               when "001110" => symbol_queue(10) <= "11000";
--               when "001111" => symbol_queue(10) <= "11000";
--               when "010000" => symbol_queue(10) <= "11000";
--               when "010001" => symbol_queue(10) <= "11000";
                  -- Data Island (8-15)
--               when "010010" => symbol_queue(10) <= "11000";
--               when "010011" => symbol_queue(10) <= "11000";
--               when "010100" => symbol_queue(10) <= "11000";
--               when "010101" => symbol_queue(10) <= "11000";
--               when "010110" => symbol_queue(10) <= "11000";
--               when "010111" => symbol_queue(10) <= "11000";
--               when "011000" => symbol_queue(10) <= "11000";
--               when "011001" => symbol_queue(10) <= "11000";
                 -- Data Island (16-23)
--               when "011010" => symbol_queue(10) <= "11000";
--               when "011011" => symbol_queue(10) <= "11000";
--               when "011100" => symbol_queue(10) <= "11000";
--               when "011101" => symbol_queue(10) <= "11000";
--               when "011110" => symbol_queue(10) <= "11000";
--               when "011111" => symbol_queue(10) <= "11000";
--               when "100000" => symbol_queue(10) <= "11000";
--               when "100001" => symbol_queue(10) <= "11000";
                  -- Data Island (24-31)
--               when "100010" => symbol_queue(10) <= "11000";
--               when "100011" => symbol_queue(10) <= "11000";
--               when "100100" => symbol_queue(10) <= "11000";
--               when "100101" => symbol_queue(10) <= "11000";
--               when "100110" => symbol_queue(10) <= "11000";
--               when "100111" => symbol_queue(10) <= "11000";
--               when "101000" => symbol_queue(10) <= "11000";
--               when "101001" => symbol_queue(10) <= "11000";

                  -- Trailing guard band
               when "101010" => symbol_queue(10) <= "01101"; -- Data island Guard Band
               when "101011" => symbol_queue(10) <= "01101"; -- Data island Guard Band
                  -- There has to be four CTL symbols before the next block of video our data,
                  -- But that won't be a problem for us, we will have the rest of the vertical 
                  -- Blanking interval
               when others   => symbol_queue(10) <= "010" & Vsync & Hsync;
           end case;
           
           symbol_queue(0 to 9) <= symbol_queue(1 to 10);
         end if;

         if data_island_index /= "111111" then
            data_island_index  <= data_island_index  + 1;
         end if;
         
         -- If we see the rising edge of vsync we need to send 
         -- a data island the next time we see the hsync signal
         -- drop.
         if last_vsync = '0' and vsync = '1' then
            data_island_armed <= '1';
         end if;

         if data_island_armed = '1' and last_hsync = '1' and hsync = '0' then
            data_island_index <= (others => '0');
            data_island_armed <= '0';
         end if;
         
         last_blank <= blank;
         last_hsync <= hsync;
         last_vsync <= vsync;
      end if;
   end process;

end Behavioral;

