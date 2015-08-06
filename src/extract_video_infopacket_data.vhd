----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: extract_video_infopacket_data - Behavioral
--
-- Description: Extract a couple of fields from the video infopacket, allowin use
--              to correctly convert the incoming pixels into RGB 444 for internal
--              processing.  
-- 
--              Bits 14:13 indicate the colour space and 444 vs 422.
--              Bits 27:26 indicate if the pixels are studio level (16-240) 
--              or full range (0-255)  
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

entity extract_video_infopacket_data is
    Port ( clk                 : in STD_LOGIC;
           adp_data_valid      : in STD_LOGIC;
           adp_header_bit      : in STD_LOGIC;
           adp_frame_bit       : in STD_LOGIC;
           adp_subpacket0_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket1_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket2_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket3_bits : in STD_LOGIC_VECTOR (1 downto 0);
           input_is_YCbCr      : out STD_LOGIC;
           input_is_422        : out STD_LOGIC;
           input_is_sRGB       : out STD_LOGIC);
end extract_video_infopacket_data;

architecture Behavioral of extract_video_infopacket_data is
    -- For this usage, we are only interested in four bits that are all in the first
    -- 16 transfers of the 32-bit packets
    signal header_bits     : STD_LOGIC_VECTOR (15 downto 0);
    signal frame_bits      : STD_LOGIC_VECTOR (15 downto 0);
    signal subpacket0_bits : STD_LOGIC_VECTOR (31 downto 0);
    signal updated         : std_logic := '0';
begin

process(clk)
    begin
        if rising_edge(clk) then
            if adp_data_valid = '1' then
                -----------------------------------------------
                -- Move the incoming bits into a shift register
                -----------------------------------------------
                header_bits     <= adp_header_bit      & header_bits(header_bits'high downto 1);
                frame_bits      <= adp_frame_bit       & frame_bits(frame_bits'high   downto 1);
                subpacket0_bits <= adp_subpacket0_bits & subpacket0_bits(subpacket0_bits'high downto 2);
                updated         <= '1';  
            end if;

            ----------------------------------------------------
            -- The 0 in frame bits indicates the start of packet
            ----------------------------------------------------
            if updated = '1' and frame_bits = x"FFFE" then
                -- 82 is the type of packet, 02 is the version
                if header_bits = x"0282" then
                    case subpacket0_bits(14 downto 13) is
                        when "00"   => input_is_YCbCr <= '0'; input_is_422 <= '0';
                        when "01"   => input_is_YCbCr <= '1'; input_is_422 <= '1';
                        when "10"   => input_is_YCbCr <= '1'; input_is_422 <= '0';
                        when others => NULL;
                    end case; 

                    case subpacket0_bits(27 downto 26) is
                        when "01"   => input_is_sRGB <= '1';
                        when others => input_is_sRGB <= '0';
                    end case; 

                end if;
            end if; 
        end if;
    end process;

end Behavioral;
