----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: extract_audio_samples - Behavioral
--
-- Description: Extract audio data from the HDMI ADP data stream
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

entity extract_audio_samples is
    Port ( clk                 : in STD_LOGIC;
           adp_data_valid      : in STD_LOGIC;
           adp_header_bit      : in STD_LOGIC;
           adp_frame_bit       : in STD_LOGIC;
           adp_subpacket0_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket1_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket2_bits : in STD_LOGIC_VECTOR (1 downto 0);
           adp_subpacket3_bits : in STD_LOGIC_VECTOR (1 downto 0);
           audio_de            : out STD_LOGIC;
           audio_channel       : out STD_LOGIC_VECTOR (2 downto 0);
           audio_sample        : out STD_LOGIC_VECTOR (23 downto 0)
    );
end extract_audio_samples;

architecture Behavioral of extract_audio_samples is
    signal header_bits        : STD_LOGIC_VECTOR (31 downto 0);
    signal frame_bits         : STD_LOGIC_VECTOR (31 downto 0);
    signal subpacket0_bits    : STD_LOGIC_VECTOR (63 downto 0);
    signal subpacket1_bits    : STD_LOGIC_VECTOR (63 downto 0);
    signal subpacket2_bits    : STD_LOGIC_VECTOR (63 downto 0);
    signal subpacket3_bits    : STD_LOGIC_VECTOR (63 downto 0);
    signal grab_other_channel : std_logic := '0';
begin

process(clk)
    begin
        if rising_edge(clk) then
            -----------------------------------------------
            -- Move the incoming bits into a shift register
            -----------------------------------------------
            header_bits     <= adp_header_bit      & header_bits(header_bits'high downto 1);
            frame_bits      <= (adp_frame_bit and adp_data_valid) & frame_bits(frame_bits'high   downto 1);
            subpacket0_bits <= adp_subpacket0_bits & subpacket0_bits(subpacket0_bits'high downto 2);
            subpacket1_bits <= adp_subpacket1_bits & subpacket1_bits(subpacket1_bits'high downto 2);
            subpacket2_bits <= adp_subpacket2_bits & subpacket2_bits(subpacket2_bits'high downto 2);
            subpacket3_bits <= adp_subpacket3_bits & subpacket3_bits(subpacket3_bits'high downto 2);
            
            audio_de      <= '0';

            if grab_other_channel = '1' then
                audio_de           <= header_bits(7);
                audio_channel      <= "001";
                audio_sample       <= subpacket0_bits(45 downto 22);
                grab_other_channel <= '0';
            end if;
            if frame_bits = x"FFFFFFFE" then
                ------------------------------------------------
                -- Check the packet type as being audio samples
                ------------------------------------------------
                if header_bits(7 downto 0) = x"02" then
                    audio_de      <= header_bits(8);
                    audio_channel <= "000";
                    audio_sample  <= subpacket0_bits(23 downto 0);
                    grab_other_channel <= '1';                      
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
