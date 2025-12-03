library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
    port (
        CLK_I   : in  std_logic;
        RESET_I : in  std_logic;
        HSYNC_O   : out std_logic;
        VSYNC_O   : out std_logic;
        HACTIVE_O : out std_logic;
        VACTIVE_O : out std_logic;
        H_COUNT_O : out integer range 0 to 799;
        V_COUNT_O : out integer range 0 to 524
    );
end entity vga_sync;

architecture rtl of vga_sync is

    constant H_ACTIVE : integer := 640;
    constant H_FP     : integer := 16;
    constant H_SYNC   : integer := 96;
    constant H_BP     : integer := 48;
    constant H_TOTAL  : integer := 800;

    constant V_ACTIVE : integer := 480;
    constant V_FP     : integer := 10;
    constant V_SYNC   : integer := 2;
    constant V_BP     : integer := 33;
    constant V_TOTAL  : integer := 525;

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

begin

    process(CLK_I, RESET_I)
    begin
        if (RESET_I = '1') then
            h_count <= 0;
            v_count <= 0;
            
        elsif (rising_edge(CLK_I)) then
            if (h_count = H_TOTAL - 1) then
                h_count <= 0; 
                
                if (v_count = V_TOTAL - 1) then
                    v_count <= 0; 
                else
                    v_count <= v_count + 1; 
                end if;
                
            else
                h_count <= h_count + 1; 
            end if;
        end if;
    end process;

    HSYNC_O <= '0' when (h_count >= H_ACTIVE + H_FP) and (h_count < H_ACTIVE + H_FP + H_SYNC) 
                 else '1';

    VSYNC_O <= '0' when (v_count >= V_ACTIVE + V_FP) and (v_count < V_ACTIVE + V_FP + V_SYNC) 
                 else '1';
                 
    HACTIVE_O <= '1' when (h_count < H_ACTIVE) 
                   else '0';
                   
    VACTIVE_O <= '1' when (v_count < V_ACTIVE) 
                   else '0';
                   
    H_COUNT_O <= h_count;
    V_COUNT_O <= v_count;

end architecture rtl;