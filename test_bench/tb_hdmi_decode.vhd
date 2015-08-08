----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tb_hdmi_decode - Behavioral
--
-- Description: A testbench for testing HDMI decoding 
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
----------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_hdmi_decode is
end tb_hdmi_decode;

architecture Behavioral of tb_hdmi_decode is
    component hdmi_design is
    Port ( 
        clk100    : in STD_LOGIC;
        -- Control signals
        led           : out   std_logic_vector(7 downto 0);
        sw            : in    std_logic_vector(7 downto 0) :=(others => '0');
        debug_pmod    : out   std_logic_vector(7 downto 0) :=(others => '0');

        --HDMI input signals
        hdmi_rx_cec   : inout std_logic;
        hdmi_rx_hpa   : out   std_logic;
        hdmi_rx_scl   : in    std_logic;
        hdmi_rx_sda   : inout std_logic;
        hdmi_rx_txen  : out   std_logic;
        hdmi_rx_clk_n : in    std_logic;
        hdmi_rx_clk_p : in    std_logic;
        hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        hdmi_rx_p     : in    std_logic_vector(2 downto 0);

        --- HDMI out
        hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
        hdmi_tx_hpd   : in    std_logic;
        hdmi_tx_rscl  : inout std_logic;
        hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0);
        -- For dumping symbols
        rs232_tx     : out std_logic      
    );
    end component;
    
    component hdmi_output_test is
        Port ( clk50         : in  STD_LOGIC;
    
               hdmi_out_p : out  STD_LOGIC_VECTOR(3 downto 0);
               hdmi_out_n : out  STD_LOGIC_VECTOR(3 downto 0);
                          
               leds       : out std_logic_vector(7 downto 0));
    end component;
    
    
    signal clk           : std_logic := '0';
    signal clk50         : std_logic := '1';
    signal led           : std_logic_vector(7 downto 0);
    signal hdmi_rx_cec   : std_logic;
    signal hdmi_rx_hpa   : std_logic;
    signal hdmi_rx_scl   : std_logic;
    signal hdmi_rx_sda   : std_logic;
    signal hdmi_rx_txen  : std_logic;
    signal hdmi_rx_clk_n : std_logic;
    signal hdmi_rx_clk_p : std_logic;
    signal hdmi2_rx_clk_n : std_logic := '1';
    signal hdmi2_rx_clk_p : std_logic := '0';
    signal hdmi_out_n    : std_logic_vector(3 downto 0);
    signal hdmi_out_p    : std_logic_vector(3 downto 0);
    signal hdmi_rx_n     : std_logic_vector(2 downto 0);
    signal hdmi_rx_p     : std_logic_vector(2 downto 0);
    signal hdmi_tx_cec   : std_logic;
    signal hdmi_tx_clk_n : std_logic;
    signal hdmi_tx_clk_p : std_logic;
    signal hdmi_tx_hpd   : std_logic;
    signal hdmi_tx_rscl  : std_logic;
    signal hdmi_tx_rsda  : std_logic;
    signal hdmi_tx_p     : std_logic_vector(2 downto 0);
    signal hdmi_tx_n     : std_logic_vector(2 downto 0);
    
    signal sdat_drive : std_logic := '1';
    signal rs232_tx : std_logic := '1';
begin
hdmi_rx_sda <= '0' when sdat_drive = '0' else 'H';

  hdmi_rx_p <= transport hdmi_out_p(2 downto 0) after 5.00 ns;
  hdmi_rx_n <= transport hdmi_out_n(2 downto 0) after 5.00 ns;
  hdmi_rx_clk_p <= transport hdmi_out_p(3) after 1.25 ns;
  hdmi_rx_clk_n <= transport hdmi_out_n(3) after 1.25 ns;

clk_proc: process
begin
    wait for 7.0 ns;
    while 1 = 1 loop
        wait for 5.0 ns;
        clk <= not clk;
    end loop;
end process;

clk50_proc: process
begin
    wait for 7.0 ns;
    while 1 = 1 loop
        wait for 5.0 ns;
        clk50 <= not clk50;
    end loop;
end process;

i_gen_signal: hdmi_output_test port map (
    clk50         => clk50,
    hdmi_out_p    => hdmi_out_p,
    hdmi_out_n    => hdmi_out_n,
    leds          => open);

uut: hdmi_design Port map (
    clk100        => clk,
    led           => open,
    sw            => (others => '0'),
    debug_pmod    => open,
    --HDMI in
    hdmi_rx_cec   => hdmi_rx_cec,
    hdmi_rx_hpa   => hdmi_rx_hpa, 
    hdmi_rx_scl   => hdmi_rx_scl,
    hdmi_rx_sda   => hdmi_rx_sda,
    hdmi_rx_txen  => hdmi_rx_txen, 
    hdmi_rx_clk_n => hdmi_rx_clk_n,
    hdmi_rx_clk_p => hdmi_rx_clk_p,
    hdmi_rx_n     => hdmi_rx_n,
    hdmi_rx_p     => hdmi_rx_p,

    --- HDMI out
    hdmi_tx_cec   => hdmi_tx_cec,
    hdmi_tx_clk_n => hdmi_tx_clk_n,
    hdmi_tx_clk_p => hdmi_tx_clk_p,
    hdmi_tx_hpd   => hdmi_tx_hpd,
    hdmi_tx_rscl  => hdmi_tx_rscl,
    hdmi_tx_rsda  => hdmi_tx_rsda,
    hdmi_tx_p     => hdmi_tx_p,
    hdmi_tx_n     => hdmi_tx_n,
    
    rs232_tx      => rs232_tx
);

edid_test_proc: process
begin
       hdmi_rx_scl <= '1';
   wait for 1 us;
-- START condition
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- DEVICE ADDRESS FOR WRITE
-- dev bit 7
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 6
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 6
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 4
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 3
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 2
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 1
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 0
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- Slave ACK
-- Device to ack
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- SEND WRITE ADDRESS
-- addr bit 7
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 6
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 6
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 4
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 3
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 2
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 1
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- addr bit 0
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- Slave ACK
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- repeated START condition
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; 
   wait for 400 ns; sdat_drive  <= '0'; wait for 200 ns; hdmi_rx_scl <= '0'; wait for 200 ns; 
-- DEVICE ADDRESS / READ - 
-- dev bit 7
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 6
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 6
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 4
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 3
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 2
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 1
   sdat_drive <= '0'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- dev bit 0  - READ!
   sdat_drive <= '1'; wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;

-- ACK????
-- Device to ack
   sdat_drive <= '1';
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;

for i in 1 to 127 loop
-- READ First byte
-- read bit 7
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 6
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 6
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 4
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 3
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 2
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 1
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 0
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
   sdat_drive <= '1';

-- Host to ack
   sdat_drive <= '0';
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
   sdat_drive <= '1';
end loop;
-- READ Second
-- read bit 7
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 6
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 6
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 4
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 3
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 2
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 1
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
-- read bit 0
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
   sdat_drive <= '1';

-- Master NACK
   sdat_drive <= '1';
       wait for 200 ns; hdmi_rx_scl <= '1'; wait for 400 ns; hdmi_rx_scl <= '0'; wait for 200 ns;
   sdat_drive <= '1';

-- STOP
   sdat_drive <= '1';
   wait for 200 ns;
       hdmi_rx_scl <= '1';
   wait for 200 ns;

   wait;
end process;

end Behavioral;
