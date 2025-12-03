library ieee;
use ieee.std_logic_1164.all;

entity clk_divider is
    port (
        clk_in   : in std_logic;
        reset : in std_logic;
        clk_out  : out std_logic
    );
end entity;

architecture Behavorial of clk_divider is
    signal tmp_clk : std_logic := '0';
begin
    process(clk_in,reset)
    begin
        if reset = '1' then
            tmp_clk<='0';
        elsif rising_edge(clk_in) then
            tmp_clk <= not tmp_clk;
        end if;
    end process;
     
     clk_out<= tmp_clk;

end architecture;