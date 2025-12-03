library ieee;
use ieee.std_logic_1164.all;

entity top1 is
    port (
        MAX10_CLK1_50 : in  std_logic;
        SW            : in  std_logic_vector(9 downto 0);
        KEY           : in  std_logic_vector(1 downto 0);
        
        -- Afficheurs 7 segments
        HEX0          : out std_logic_vector(6 downto 0); -- Score J1
        HEX1          : out std_logic_vector(6 downto 0); 
        HEX2          : out std_logic_vector(6 downto 0); 
        HEX3          : out std_logic_vector(6 downto 0); 
        HEX4          : out std_logic_vector(6 downto 0); 
        HEX5          : out std_logic_vector(6 downto 0); -- Score J2

        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic;
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0)
    );
end entity top1;

architecture Behavioral of top1 is

    component clk_divider is
        port (clk_in : in std_logic; reset : in std_logic; clk_out : out std_logic);
    end component;
    
    -- CORRECTION 1 : Ajout des "range" dans la déclaration du composant vga_sync
    component vga_sync is
        port (
            CLK_I     : in  std_logic;
            RESET_I   : in  std_logic;
            HSYNC_O   : out std_logic;
            VSYNC_O   : out std_logic;
            HACTIVE_O : out std_logic;
            VACTIVE_O : out std_logic;
            H_COUNT_O : out integer range 0 to 799; -- ICI
            V_COUNT_O : out integer range 0 to 524  -- ET ICI
        );
    end component;

    -- CORRECTION 2 : Ajout des "range" dans la déclaration du composant image_gen
    component image_gen is
        port (
            PIXEL_CLK_I : in  std_logic;
            RESET_I     : in  std_logic;
            HACTIVE_I   : in  std_logic;
            VACTIVE_I   : in  std_logic;
            VSYNC_I     : in  std_logic;
            H_COUNT_I   : in  integer range 0 to 799; -- ICI
            V_COUNT_I   : in  integer range 0 to 524; -- ICI
            P1_UP_I     : in  std_logic;
            P1_DOWN_I   : in  std_logic;
            P2_UP_I     : in  std_logic;
            P2_DOWN_I   : in  std_logic;
            SCORE1_O    : out integer range 0 to 9;   -- ICI (4 bits)
            SCORE2_O    : out integer range 0 to 9;   -- ICI (4 bits)
            R_O, G_O, B_O : out std_logic_vector(3 downto 0)
        );
    end component;
    
    component segment_decoder is
        port (digit_i : in integer range 0 to 9; seg_o : out std_logic_vector(6 downto 0));
    end component;

    signal pixel_clk : std_logic;
    signal hsync_int, vsync_int, hactive, vactive : std_logic;
    
    -- CORRECTION 3 : Les signaux internes doivent aussi avoir la bonne taille !
    signal h_count   : integer range 0 to 799;
    signal v_count   : integer range 0 to 524;
    signal s_score1  : integer range 0 to 9;
    signal s_score2  : integer range 0 to 9;

begin
    -- Reset sur SW(0)
    inst_clk_divider : clk_divider port map (MAX10_CLK1_50, SW(0), pixel_clk);
    
    inst_vga_sync : vga_sync 
    port map (
        CLK_I => pixel_clk, 
        RESET_I => SW(0), 
        HSYNC_O => hsync_int, 
        VSYNC_O => vsync_int, 
        HACTIVE_O => hactive, 
        VACTIVE_O => vactive, 
        H_COUNT_O => h_count, 
        V_COUNT_O => v_count
    );

    inst_image_gen : image_gen
    port map (
        PIXEL_CLK_I => pixel_clk, 
        RESET_I => SW(0),
        HACTIVE_I => hactive, 
        VACTIVE_I => vactive, 
        VSYNC_I => vsync_int,
        H_COUNT_I => h_count, 
        V_COUNT_I => v_count,
        
        -- Joueur 1 (Droite) : Boutons KEY (actifs bas)
        P1_UP_I => KEY(0), 
        P1_DOWN_I => KEY(1),
        
        -- Joueur 2 (Gauche) : Switchs SW9 et SW8 (actifs hauts)
        P2_UP_I => SW(9), 
        P2_DOWN_I => SW(8),
        
        -- Scores
        SCORE1_O => s_score1, 
        SCORE2_O => s_score2,
        
        R_O => VGA_R, G_O => VGA_G, B_O => VGA_B 
    );
    
    -- Afficheurs scores
    inst_hex0 : segment_decoder port map (s_score1, HEX0); -- Score J1 à droite
    inst_hex5 : segment_decoder port map (s_score2, HEX5); -- Score J2 à gauche
    
    -- Eteindre les autres
    HEX1 <= "1111111"; 
    HEX2 <= "1111111"; 
    HEX3 <= "1111111"; 
    HEX4 <= "1111111";

    VGA_HS <= hsync_int; 
    VGA_VS <= vsync_int;

end architecture Behavioral;