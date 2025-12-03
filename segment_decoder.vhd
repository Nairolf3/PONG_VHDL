library ieee;
use ieee.std_logic_1164.all;

entity segment_decoder is
    port (
        digit_i : in  integer range 0 to 9;
        seg_o   : out std_logic_vector(6 downto 0) -- Segments A à G
    );
end entity segment_decoder;

architecture Behavioral of segment_decoder is
begin
    process(digit_i)
    begin
        -- Rappel : 0 = Allumé, 1 = Éteint (Logique inversée sur DE10)
        case digit_i is
            when 0 => seg_o <= "1000000"; -- 0
            when 1 => seg_o <= "1111001"; -- 1
            when 2 => seg_o <= "0100100"; -- 2
            when 3 => seg_o <= "0110000"; -- 3
            when 4 => seg_o <= "0011001"; -- 4
            when 5 => seg_o <= "0010010"; -- 5
            when 6 => seg_o <= "0000010"; -- 6
            when 7 => seg_o <= "1111000"; -- 7
            when 8 => seg_o <= "0000000"; -- 8
            when 9 => seg_o <= "0010000"; -- 9
            when others => seg_o <= "1111111"; -- Eteint
        end case;
    end process;
end architecture Behavioral;