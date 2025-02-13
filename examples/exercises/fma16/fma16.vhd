-- System on Chip Design Final Project - Spring 2025
-- 16 Bit Floating Point FMA
-- Written: Corey Hickson chickson@hmc.edu

library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD_UNSIGNED.all;

entity fma16 is
    port(x, y, z:   in  STD_LOGIC_VECTOR(15 downto 0);
         mul:       in  STD_LOGIC;
         add:       in  STD_LOGIC;
         negp:      in  STD_LOGIC;
         negz:      in  STD_LOGIC;
         roundmode: in  STD_LOGIC_VECTOR( 2 downto 0);
         result:    out STD_LOGIC_VECTOR(15 downto 0);
         flags:     out STD_LOGIC_VECTOR( 3 downto 0));
    end;

    architecture synth of fma16 is
    
    begin
        process(all)
            -- unpacked signals
            variable Xs, Ys, Zs: STD_LOGIC;
            variable Xe, Ye, Ze: STD_LOGIC_VECTOR( 4 downto 0);
            variable Xm, Ym, Zm: STD_LOGIC_VECTOR(10 downto 0);
            -- intermediate signals
            variable P_s:        STD_LOGIC;
            variable Pe:         STD_LOGIC_VECTOR( 4 downto 0);
            variable Pm:         STD_LOGIC_VECTOR(21 downto 0);
        begin

            Xs := x(15);
            Ys := y(15);
            Zs := z(15);
            Xe := x(14 downto 10);
            Ye := y(14 downto 10);
            Ze := z(14 downto 10);
            Xm := '1' & x(9 downto 0);
            Ym := '1' & y(9 downto 0);
            Zm := '1' & z(9 downto 0);

            Pm  := Xm * Ym;
            Pe  := Xe + Ye - '01111' + Pm(21);
            P_s := Xs xor Xy;


        end process 
            

    end;