----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: DVID_output - Behavioral
--
-- Description: Convert a stream of pixels into a DVID output 
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

library UNISIM;
use UNISIM.VComponents.all;

entity DVID_output is
    Port ( 
        pixel_clk       : in std_logic;  -- Driven by BUFG
        pixel_io_clk_x1 : in std_logic;  -- Driven by BUFIO
        pixel_io_clk_x5 : in std_logic;  -- Driven by BUFIO
        
        -- VGA Signals
        vga_blank    : in  std_logic;
        vga_hsync    : in  std_logic;
        vga_vsync    : in  std_logic;
        vga_red      : in  std_logic_vector(7 downto 0);
        vga_blue     : in  std_logic_vector(7 downto 0);
        vga_green    : in  std_logic_vector(7 downto 0);
        data_valid   : in  std_logic;
        
        --- DVI-D out
        tmds_out_clk    : out   std_logic;
        tmds_out_ch0    : out   std_logic;
        tmds_out_ch1    : out   std_logic;
        tmds_out_ch2    : out   std_logic
    );
end DVID_output;

architecture Behavioral of DVID_output is

   component tmds_encoder is
   Port ( clk     : in  std_logic;
          data    : in  std_logic_vector (7 downto 0);
          c       : in  std_logic_vector (1 downto 0);
          blank   : in  std_logic;
          encoded : out std_logic_vector (9 downto 0));
    end component;

    component serialiser_10_to_1 is
    Port ( clk    : in  std_logic;
           clk_x5 : in  std_logic;
           reset  : in  std_logic;
           data   : in  std_logic_vector (9 downto 0);
           serial : out std_logic);
    end component;

    signal c0_tmds_symbol : std_logic_vector (9 downto 0);
    signal c1_tmds_symbol : std_logic_vector (9 downto 0);
    signal c2_tmds_symbol : std_logic_vector (9 downto 0);

    signal reset_sr       : std_logic_vector (2 downto 0) := (others => '1');
    signal reset          : std_logic := '1';
    
begin
    reset <= reset_sr(0);
    
process(pixel_clk, data_valid)
    begin
        if data_valid = '0' then
           reset_sr <= (others => '1');
        elsif rising_edge(pixel_clk) then
            reset_sr <= '0' & reset_sr(reset_sr'high downto 1); 
        end if;
    end process;
    ---------------------
    -- TMDS Encoders
    ---------------------
c0_tmds: tmds_encoder port map (
        clk     => pixel_clk,
        data    => vga_blue,
        c(1)    => vga_vsync,
        c(0)    => vga_hsync,
        blank   => vga_blank,
        encoded => c0_tmds_symbol);

c1_tmds: tmds_encoder port map (
        clk     => pixel_clk,
        data    => vga_green,
        c       => (others => '0'),
        blank   => vga_blank,
        encoded => c1_tmds_symbol);
        
c2_tmds: tmds_encoder port map (
        clk     => pixel_clk,
        data    => vga_red,
        c       => (others => '0'),
        blank   => vga_blank,
        encoded => c2_tmds_symbol);
    ---------------------
    -- Output serializers
    ---------------------
ser_ch0: serialiser_10_to_1 port map ( 
        clk    => pixel_io_clk_x1,
        clk_x5 => pixel_io_clk_x5,
        reset  => reset,
        data   => c0_tmds_symbol,
        serial => tmds_out_ch0);
        
ser_ch1: serialiser_10_to_1 port map ( 
        clk    => pixel_io_clk_x1,
        clk_x5 => pixel_io_clk_x5,
        reset  => reset,
        data   => c1_tmds_symbol,
        serial => tmds_out_ch1);

ser_ch2: serialiser_10_to_1 port map (
        clk    => pixel_io_clk_x1,
        clk_x5 => pixel_io_clk_x5,
        reset  => reset,
        data   => c2_tmds_symbol,
        serial => tmds_out_ch2);

ser_clk: serialiser_10_to_1 Port map (
        clk    => pixel_io_clk_x1,
        clk_x5 => pixel_io_clk_x5,
        reset  => reset,
        data   => "0000011111",
        serial => tmds_out_clk);

end Behavioral;
