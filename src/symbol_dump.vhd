----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: symbol_dump - Behavioral
--
-- Description: Create a trace of HDMI symbols - a 1024 word memory block is filled 
--              and then transmitted over rs232. Then refilled again, but this time
--              waiting an extra 1024 cycles from when symbol_sync is asserted.
--              
--             If the video source is paused, then the entire frame can be capbured
--             (excluding ADP data periods, which might get broken on the boundary.
--
--             The captured data can then be analysed by hand or used to drive 
--             simulations.
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

entity symbol_dump is
    Port ( clk : in STD_LOGIC;
           clk100 : in STD_LOGIC;
           symbol_sync : in STD_LOGIC;
           symbol_ch0 : in STD_LOGIC_VECTOR (9 downto 0);
           symbol_ch1 : in STD_LOGIC_VECTOR (9 downto 0);
           symbol_ch2 : in STD_LOGIC_VECTOR (9 downto 0);
           rs232_tx : out STD_LOGIC);
end symbol_dump;

architecture Behavioral of symbol_dump is
    type array_hex is array(0 to 15) of std_logic_vector(9 downto 0);
    signal hex : array_hex := (
            "1001100000", "1001100010", "1001100100", "1001100110",
            "1001101000", "1001101010", "1001101100", "1001101110",
            "1001110000", "1001110010", "1010000010", "1010000100",
            "1010000110", "1010001000", "1010001010", "1010001100");

    type array_memory is array(0 to 1023) of std_logic_vector(29 downto 0);
    signal memory : array_memory := (others => (others =>'0')); 
    signal position      : unsigned(23 downto 0) := (others => '0');
    signal capture_point : unsigned(23 downto 0) := (others => '0');
    signal write_address : unsigned(9 downto 0)  := (others => '0');
    signal write_enable  : std_logic := '0';
    signal write_data    : std_logic_vector(29 downto 0) := (others => '0');
    
    ---  For signaling into the 100MHz domain
    signal ready_to_send        : std_logic := '0';
    signal ready_to_send_meta   : std_logic := '0';
    signal ready_to_send_synced : std_logic := '0';
    ---  For signaling into the pixel clock domain
    signal sending_data : std_logic := '0';
    signal sending_data_meta   : std_logic := '0';
    signal sending_data_synced : std_logic := '0';

    signal rd_address   : unsigned(9 downto 0)  := (others => '0');
    signal rd_data      : std_logic_vector(29 downto 0) := (others => '0');
    signal tx_data      : std_logic_vector(89 downto 0)     := (others => '1');
    signal tx_count     : unsigned(7 downto 0)      := (others => '0');
    signal baud_counter : unsigned(12 downto 0)     := (others => '0');
    signal baud_counter_max : unsigned(12 downto 0) := to_unsigned(100000000/115200,13);
begin

process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                memory(to_integer(write_address)) <= symbol_ch2 & symbol_ch1 & symbol_ch0;
            end if;
            -- track where we are in the frame.
            if symbol_sync = '1' then
                position <= (others => '0');
            else
                position <= position+1;
            end if;
            
            -- If we are capturing remember where we have got up to
            -- and see if we have captured our full amount.
            if write_enable = '1' then
                capture_point <= position;
                write_data <= symbol_ch2 & symbol_ch1 & symbol_ch0;
                write_data <= symbol_ch2 & symbol_ch1 & symbol_ch0;
                if write_address = 1023 then
                    write_enable <= '0';
                    ready_to_send <= '1';
                end if;
                write_address <= write_address+1;
            end if;

            -- Do we start capturing at this point? 
            -- (write address resets itself to 0, so we don't
            -- have to do it here) 
            if position = capture_point and ready_to_send = '0' and sending_data_synced = '0' then
                write_enable <= '1';
            end if;
            
            -- Do we need to re-arm ready for the next capture
            if sending_data_synced = '1' then
               ready_to_send <= '0';
            end if;
            
            
            -- Bring data_sent into this clock domain
            sending_data_synced <= sending_data_meta; 
            sending_data_meta   <= sending_data; 

        end if;
    end process;
    
process(clk100)
    begin
        if rising_edge(clk100) then
            
            if baud_counter = 0 then
                rs232_tx <= tx_data(0);
                tx_data <= '1' & tx_data(89 downto 1);
                baud_counter <= baud_counter_max;
                if(tx_count > 0) then
                  tx_count <= tx_count-1;
                end if;
            else
                baud_counter <= baud_counter -1;    
            end if;
            
            if sending_data = '1' or ready_to_send_synced = '1' then            
                if tx_count = 0 then
                    tx_data(89 downto 80) <= hex(to_integer(unsigned(rd_data( 3 downto  0))));
                    tx_data(79 downto 70) <= hex(to_integer(unsigned(rd_data( 7 downto  4))));
                    tx_data(69 downto 60) <= hex(to_integer(unsigned(rd_data(11 downto  8))));
                    tx_data(59 downto 50) <= hex(to_integer(unsigned(rd_data(15 downto 12))));
                    tx_data(49 downto 40) <= hex(to_integer(unsigned(rd_data(19 downto 16))));
                    tx_data(39 downto 30) <= hex(to_integer(unsigned(rd_data(23 downto 20))));
                    tx_data(29 downto 20) <= hex(to_integer(unsigned(rd_data(27 downto 24))));
                    tx_data(19 downto 10) <= hex(to_integer(unsigned(rd_data(29 downto 28))));
                    tx_data( 9 downto  0) <= "1000010100"; -- New line
                    tx_count <= to_unsigned(90,8);

                    rd_data <= memory(to_integer(rd_address));
                    rd_address <= rd_address+1;
                    if rd_address = 1023 then
                        sending_data <= '0';
                    else
                        sending_data <= '1';
                    end if;
                end if;
            end if;
            
            -- Bring the ready to send signal into this clock domain    
            ready_to_send_synced <= ready_to_send_meta; 
            ready_to_send_meta   <= ready_to_send; 
        end if;
    end process;
end Behavioral;
