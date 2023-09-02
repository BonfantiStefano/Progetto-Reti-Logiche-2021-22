----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Bonfanti Stefano 10670135 935228
-- 
-- Create Date: 13.02.2022 18:19:24
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    component fsm is
        port(
            clk : in std_logic;
            rst : in std_logic;
            en : in std_logic;
            i : in std_logic;
            o :  out std_logic_vector(1 downto 0));
    end component;
    
    signal  ifsm_rst, ifsm_data, ifsm_en : std_logic;
    type S is (RESET, START, FETCH_W, FETCH_VAL, CALC_FSM, CALC_OUT_VAL, PRINT_VAL_1, PRINT_VAL_2, CHECK_END, DONE);
    signal cur_state, next_state : S;
    signal idx, next_idx, address, next_address, output_val, next_output_val : std_logic_vector(15 downto 0);
    signal num_parole, next_num_parole : std_logic_vector(7 downto 0);
    signal count, next_count : std_logic_vector(3 downto 0);
    signal o_fsm : std_logic_vector(1 downto 0);
    
begin
    state_reg : process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            cur_state <= RESET;
        elsif i_clk'event and i_clk = '1' then
            cur_state <= next_state;
            idx <= next_idx;
            address <= next_address;
            num_parole <= next_num_parole;
            output_val <= next_output_val;
            count <= next_count;
        end if;
    end process;

    delta_function : process(cur_state, i_start, i_rst, i_data, idx, address, num_parole, count, output_val)
    begin
        ifsm_rst <= '0';
        ifsm_en <= '0';
        ifsm_data <= '0';
        next_state <= cur_state;
        next_idx <= idx;
        next_address <= address;
        next_num_parole <= num_parole;
        next_output_val <= output_val;
        next_count <= count;        
        o_en <= '0';
        o_we <= '0';
        o_address <= "0000000000000000";
        o_data <= "00000000";
        o_done <= '0';
        case cur_state is
            when RESET => 
                if i_rst = '0' then 
                    ifsm_rst <= '1';
                    next_state <= START;
                end if;
            when START =>
                if i_start = '1' then
                    o_en <= '1';
                    next_state <= FETCH_W;
                else
                    next_state <= START;
                end if;
            when FETCH_W =>
                o_en <= '1';
                o_address <= "0000000000000001";
                next_num_parole <= i_data;
                if i_data = "00000000" then
                    next_state <= DONE;
                else
                    next_address <= "0000001111101000";
                    next_idx <= "0000000000000001";
                    next_state <= FETCH_VAL;
                end if;
            when FETCH_VAL =>
                next_count <= "0000";
                next_output_val <= "0000000000000000";
                next_idx <= idx + "0000000000000001";           
                next_state <= CALC_FSM;
            when CALC_FSM =>
                if count < "1000" then
                    ifsm_data <= i_data(7 - conv_integer(count));
                    ifsm_en <= '1';
                    next_count <= count + "0001";
                    next_state <= CALC_OUT_VAL;
                else
                    next_state <= PRINT_VAL_1;
                end if;
             when CALC_OUT_VAL => 
                for i in 0 to 13 loop
                    next_output_val(i+2) <= output_val(i);
                end loop;
                next_output_val(0) <= o_fsm(0);
                next_output_val(1) <= o_fsm(1);
                next_state <= CALC_FSM;                
             when PRINT_VAL_1 =>
                o_en <= '1';
                o_we <= '1';
                o_address <= address;
                o_data <= output_val(15 downto 8);
                next_address <= address + "0000000000000001";
                next_state <= PRINT_VAL_2;
             when PRINT_VAL_2 =>
                o_en <= '1';
                o_we <= '1';
                o_address <= address;
                o_data <= output_val(7 downto 0);
                next_address <= address + "0000000000000001";
                next_state <= CHECK_END;
             when CHECK_END =>
                if unsigned(idx - "0000000000000001") = unsigned(("00000000" & num_parole)) then
                    o_done <= '1';
                    next_state <= DONE;
                    ifsm_rst <= '1';
                 else
                    o_en <= '1';
                    o_address <= idx;
                    next_state <= FETCH_VAL;
                 end if;
              when DONE =>
                o_done <= '1';
                if i_start = '0' then 
                    next_state <= START;
                end if; 
        end case;
    end process;
    
    convolutore: fsm port map(
            i_clk,
            ifsm_rst,
            ifsm_en,
            ifsm_data,
            o_fsm
        );        
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm is
  port(
      clk : in std_logic;
      rst : in std_logic;
      en : in std_logic;
      i : in std_logic;
      o :  out std_logic_vector(1 downto 0)
  );
end fsm;

architecture arch_fsm of fsm is
  type state_type is (S0, S1, S2, S3);
  signal next_state, current_state: state_type;
  
begin
  state_reg_fsm : process(clk, rst)
  begin
    if rst = '1' then
      current_state <= S0;
    elsif rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process;

  delta_function_fsm : process(current_state, i, clk)
  begin
  next_state <= current_state;
  if falling_edge(clk) then
  if en = '1' then
    case current_state is
      when S0 =>
        if i='0' then
          next_state <= S0;
          o <= "00";
        else
          next_state <= S2;
          o <= "11";
        end if;
      when S1 =>
        if i = '0' then
          next_state <= S0;
          o <= "11";
        else
          next_state <= S2;
          o <= "00";
        end if;
      when S2 =>
        if i='0' then
          next_state <= S1;
          o <= "01";
        else
          next_state <= S3;
          o <= "10";
        end if;
      when S3 =>
        if i='0' then
          next_state <= S1;
          o <= "10";
        else
          next_state <= S3;
          o <= "01";
        end if;
    end case;
   end if;
   end if;
  end process;
end arch_fsm;