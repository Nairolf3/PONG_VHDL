library ieee;
use ieee.std_logic_1164.all;

entity clk_divider_tb is
end entity;

architecture tb of clk_divider_tb is

    -- Signaux de test
    signal clk_in  : std_logic := '0';
    signal reset   : std_logic := '0';
    signal clk_out : std_logic;

    -- Constante : période de l’horloge d’entrée
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz

begin

    -- Instanciation du module à tester
    uut: entity work.clk_divider
        port map (
            clk_in  => clk_in,
            reset   => reset,
            clk_out => clk_out
        );

    -----------------------------------------------------------------
    -- Génération de l’horloge 50 MHz
    -----------------------------------------------------------------
    clk_process: process
    begin
        clk_in <= '0';
        wait for CLK_PERIOD / 2;
        clk_in <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -----------------------------------------------------------------
    -- Séquence de test
    -----------------------------------------------------------------
    stim_proc: process
    begin
        -- Étape 1 : Reset actif
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- Étape 2 : Laisse tourner la simulation
        wait for 2000 ns;

        -- Étape 3 : Fin de simulation
        wait;
    end process;

end architecture;
