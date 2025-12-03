library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity image_gen is
    port (
        PIXEL_CLK_I : in  std_logic;
        RESET_I     : in  std_logic;
        HACTIVE_I   : in  std_logic;
        VACTIVE_I   : in  std_logic;
        VSYNC_I     : in  std_logic;
        H_COUNT_I   : in  integer range 0 to 799;
        V_COUNT_I   : in  integer range 0 to 524;
        
        -- Contrôles
        P1_UP_I     : in  std_logic; 
        P1_DOWN_I   : in  std_logic;
        P2_UP_I     : in  std_logic; 
        P2_DOWN_I   : in  std_logic;
        
        -- Scores
        SCORE1_O    : out integer range 0 to 9;
        SCORE2_O    : out integer range 0 to 9;
        
        -- Couleurs
        R_O, G_O, B_O : out std_logic_vector(3 downto 0)
    );
end entity image_gen;

architecture rtl of image_gen is

    -- Constantes Écran
    constant H_ACTIVE : integer := 640;
    constant V_ACTIVE : integer := 480;
    constant H_CENTER : integer := 320;
    
    -- CONFIGURATION DU JEU
    constant MAX_SCORE        : integer := 9; 
    constant RAQUETTE_LARGEUR : integer := 10;
    constant RAQUETTE_HAUTEUR : integer := 80;
    constant BALLE_TAILLE     : integer := 10;
    constant VITESSE_RAQUETTE : integer := 6;
    
    -- Gestion de la vitesse
    constant VITESSE_INIT     : integer := 3;  
    constant MAX_SPEED        : integer := 8; 
    
    constant P1_X_POS : integer := H_ACTIVE - 20 - RAQUETTE_LARGEUR; 
    constant P2_X_POS : integer := 20;                               
    
    -- =============================================================
    -- DEFINITION DES SPRITES
    -- =============================================================
    type sprite_type is array (0 to 15) of std_logic_vector(15 downto 0);
    
    constant ROM_V : sprite_type := (
        "1100000000000011", "1100000000000011", "0110000000000110", "0110000000000110",
        "0011000000001100", "0011000000001100", "0001100000011000", "0001100000011000",
        "0000110000110000", "0000110000110000", "0000011001100000", "0000011001100000",
        "0000001111000000", "0000001111000000", "0000000110000000", "0000000000000000"
    );
    
    constant ROM_L : sprite_type := (
        "1100000000000000", "1100000000000000", "1100000000000000", "1100000000000000",
        "1100000000000000", "1100000000000000", "1100000000000000", "1100000000000000",
        "1100000000000000", "1100000000000000", "1100000000000000", "1100000000000000",
        "1111111111111000", "1111111111111000", "0000000000000000", "0000000000000000"
    );

    -- Signaux de jeu
    signal balle_x  : integer range -20 to H_ACTIVE + 20 := 320;
    signal balle_y  : integer range 0 to V_ACTIVE - 1 := 240;
    signal balle_vx : integer := VITESSE_INIT;
    signal balle_vy : integer := VITESSE_INIT;
    
    signal p1_y : integer range 0 to V_ACTIVE := 200;
    signal p2_y : integer range 0 to V_ACTIVE := 200;
    
    signal score1 : integer range 0 to 9 := 0;
    signal score2 : integer range 0 to 9 := 0;
    
    signal game_over : std_logic := '0';
    signal winner    : integer range 0 to 2 := 0; 
    
    -- Signaux de dessin
    signal dessine_balle    : std_logic;
    signal dessine_p1       : std_logic;
    signal dessine_p2       : std_logic;
    signal dessine_filet    : std_logic;
    signal dessine_symbole  : std_logic; 
    signal couleur_symbole  : std_logic_vector(1 downto 0); 

begin

    process(PIXEL_CLK_I, RESET_I)
        variable v_sync_prev : std_logic := '0';
    begin
        if (RESET_I = '1') then
            balle_x  <= 320; balle_y <= 240;
            balle_vx <= VITESSE_INIT;   
            balle_vy <= VITESSE_INIT;
            p1_y <= 200; p2_y <= 200;
            score1 <= 0; score2 <= 0;
            game_over <= '0';
            winner <= 0;
            
        elsif (rising_edge(PIXEL_CLK_I)) then
            if (VSYNC_I = '1' and v_sync_prev = '0') then
                if (game_over = '0') then 
                    -- === 1. RAQUETTES ===
                    -- J1 (Droite)
                    if (P1_UP_I = '0') then
                        if p1_y > VITESSE_RAQUETTE then p1_y <= p1_y - VITESSE_RAQUETTE; else p1_y <= 0; end if;
                    elsif (P1_DOWN_I = '0') then
                        if p1_y < V_ACTIVE - RAQUETTE_HAUTEUR - VITESSE_RAQUETTE then p1_y <= p1_y + VITESSE_RAQUETTE; else p1_y <= V_ACTIVE - RAQUETTE_HAUTEUR; end if;
                    end if;
                    -- J2 (Gauche)
                    if (P2_UP_I = '1') then 
                        if p2_y > VITESSE_RAQUETTE then p2_y <= p2_y - VITESSE_RAQUETTE; else p2_y <= 0; end if;
                    elsif (P2_DOWN_I = '1') then
                        if p2_y < V_ACTIVE - RAQUETTE_HAUTEUR - VITESSE_RAQUETTE then p2_y <= p2_y + VITESSE_RAQUETTE; else p2_y <= V_ACTIVE - RAQUETTE_HAUTEUR; end if;
                    end if;

                    -- === 2. BALLE & COLLISION ===
                    -- BUT GAUCHE (Point pour J1)
                    if (balle_x <= 0) then
                        score1 <= score1 + 1;
                        if (score1 + 1 >= MAX_SCORE) then 
                            game_over <= '1'; winner <= 1;
                        else 
                            balle_x <= 320; balle_y <= 240; 
                            balle_vx <= VITESSE_INIT; -- Reset vitesse
                            balle_vy <= VITESSE_INIT; -- Reset angle aussi
                        end if;
                        
                    -- BUT DROIT (Point pour J2)
                    elsif (balle_x >= H_ACTIVE - BALLE_TAILLE) then
                        score2 <= score2 + 1;
                        if (score2 + 1 >= MAX_SCORE) then 
                            game_over <= '1'; winner <= 2;
                        else 
                            balle_x <= 320; balle_y <= 240; 
                            balle_vx <= -VITESSE_INIT; -- Reset vitesse
                            balle_vy <= VITESSE_INIT;  -- Reset angle aussi
                        end if;
                        
                    else
                        -- Rebond Mur Haut/Bas
                        if (balle_y + balle_vy <= 0) then balle_y <= 0; balle_vy <= abs(balle_vy);
                        elsif (balle_y + BALLE_TAILLE + balle_vy >= V_ACTIVE) then balle_y <= V_ACTIVE - BALLE_TAILLE; balle_vy <= -abs(balle_vy);
                        else balle_y <= balle_y + balle_vy; end if;
                        
                        balle_x <= balle_x + balle_vx;
                        
                        
                        -- Rebond Raquette J1 (Droite)
                        if (balle_x + BALLE_TAILLE + balle_vx >= P1_X_POS) and (balle_x + balle_vx <= P1_X_POS + RAQUETTE_LARGEUR) and
                           (balle_y + BALLE_TAILLE >= p1_y) and (balle_y <= p1_y + RAQUETTE_HAUTEUR) then
                           
                           -- 1. Accélération horizontale
                           if (abs(balle_vx) < MAX_SPEED) then balle_vx <= -(abs(balle_vx) + 1);
                           else balle_vx <= -abs(balle_vx); end if;
                           
                           -- 2. Effet d'Angle (Physique)
                           if (balle_y < p1_y + 27) then          
                               balle_vy <= -4;                    -- Rebond vers le HAUT
                           elsif (balle_y > p1_y + 53) then       
                               balle_vy <= 4;                     -- Rebond vers le BAS
                           else                                   
                               balle_vy <= 0;                     -- Tir tout droit
                           end if;
                        end if;
                        
                        -- Rebond Raquette J2 (Gauche)
                        if (balle_x + balle_vx <= P2_X_POS + RAQUETTE_LARGEUR) and (balle_x + BALLE_TAILLE + balle_vx >= P2_X_POS) and
                           (balle_y + BALLE_TAILLE >= p2_y) and (balle_y <= p2_y + RAQUETTE_HAUTEUR) then
                           
                           -- 1. Accélération horizontale
                           if (abs(balle_vx) < MAX_SPEED) then balle_vx <= abs(balle_vx) + 1;
                           else balle_vx <= abs(balle_vx); end if;
                           
                           -- 2. Effet d'Angle (Physique)
                           if (balle_y < p2_y + 27) then          -- Tiers HAUT
                               balle_vy <= -4;                    
                           elsif (balle_y > p2_y + 53) then       -- Tiers BAS
                               balle_vy <= 4;                     
                           else                                   -- CENTRE
                               balle_vy <= 0;                     
                           end if;
                        end if;
                        -- =========================================================================

                    end if;
                end if; 
            end if;
            v_sync_prev := VSYNC_I;
        end if;
    end process;
    
    SCORE1_O <= score1; SCORE2_O <= score2;

    -- =============================================================
    -- LOGIQUE DE DESSIN
    -- =============================================================
    
    dessine_filet <= '1' when (abs(H_COUNT_I - H_CENTER) < 2) and ((V_COUNT_I / 16) mod 2 = 0) else '0';

    dessine_p1 <= '1' when (H_COUNT_I >= P1_X_POS) and (H_COUNT_I < P1_X_POS + RAQUETTE_LARGEUR) and
                           (V_COUNT_I >= p1_y) and (V_COUNT_I < p1_y + RAQUETTE_HAUTEUR) else '0';
                           
    dessine_p2 <= '1' when (H_COUNT_I >= P2_X_POS) and (H_COUNT_I < P2_X_POS + RAQUETTE_LARGEUR) and
                           (V_COUNT_I >= p2_y) and (V_COUNT_I < p2_y + RAQUETTE_HAUTEUR) else '0';

    dessine_balle <= '1' when (H_COUNT_I >= balle_x) and (H_COUNT_I < balle_x + BALLE_TAILLE) and
                              (V_COUNT_I >= balle_y) and (V_COUNT_I < balle_y + BALLE_TAILLE) else '0';

    -- AFFICHEUR SPRITES (V et L)
    process(game_over, winner, H_COUNT_I, V_COUNT_I)
        variable rel_x_p1, rel_x_p2, rel_y : integer;
        variable rom_col, rom_row : integer;
        constant ZOOM : integer := 4; 
        constant Y_POS_SYMBOLE : integer := 20; 
        constant X_POS_P2 : integer := 140; 
        constant X_POS_P1 : integer := 460; 
    begin
        dessine_symbole <= '0';
        couleur_symbole <= "00";
        if (game_over = '1') then
            rel_y := V_COUNT_I - Y_POS_SYMBOLE;
            if (rel_y >= 0 and rel_y < 16 * ZOOM) then
                rom_row := rel_y / ZOOM; 
                -- J2 (Gauche)
                rel_x_p2 := H_COUNT_I - X_POS_P2;
                if (rel_x_p2 >= 0 and rel_x_p2 < 16 * ZOOM) then
                    rom_col := rel_x_p2 / ZOOM; 
                    if (winner = 2) then 
                        if (ROM_V(rom_row)(15 - rom_col) = '1') then dessine_symbole <= '1'; couleur_symbole <= "01"; end if;
                    else 
                        if (ROM_L(rom_row)(15 - rom_col) = '1') then dessine_symbole <= '1'; couleur_symbole <= "10"; end if;
                    end if;
                end if;
                -- J1 (Droite)
                rel_x_p1 := H_COUNT_I - X_POS_P1;
                if (rel_x_p1 >= 0 and rel_x_p1 < 16 * ZOOM) then
                    rom_col := rel_x_p1 / ZOOM;
                    if (winner = 1) then 
                        if (ROM_V(rom_row)(15 - rom_col) = '1') then dessine_symbole <= '1'; couleur_symbole <= "01"; end if;
                    else 
                        if (ROM_L(rom_row)(15 - rom_col) = '1') then dessine_symbole <= '1'; couleur_symbole <= "10"; end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- MIXER COULEURS
    process(HACTIVE_I, VACTIVE_I, dessine_balle, dessine_p1, dessine_p2, dessine_filet, dessine_symbole, couleur_symbole)
    begin
        if (HACTIVE_I = '0' or VACTIVE_I = '0') then
            R_O <= "0000"; G_O <= "0000"; B_O <= "0000";
        elsif (dessine_balle = '1') then
            R_O <= "1111"; G_O <= "1111"; B_O <= "1111"; 
        elsif (dessine_symbole = '1') then
            if (couleur_symbole = "01") then R_O <= "0000"; G_O <= "1111"; B_O <= "0000"; -- Vert
            else R_O <= "1111"; G_O <= "0000"; B_O <= "0000"; end if; -- Rouge
        elsif (dessine_p1 = '1') then
            R_O <= "0000"; G_O <= "0000"; B_O <= "1111"; -- J1 Bleu
        elsif (dessine_p2 = '1') then
            R_O <= "0000"; G_O <= "0000"; B_O <= "1111"; -- J2 Bleu
        elsif (dessine_filet = '1') then
            R_O <= "1000"; G_O <= "1000"; B_O <= "1000"; 
        else
            R_O <= "0000"; G_O <= "0000"; B_O <= "0000";
        end if;
    end process;

end architecture rtl;