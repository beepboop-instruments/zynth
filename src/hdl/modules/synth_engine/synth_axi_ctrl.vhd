----------------------------------------------------------------------------------
-- Company: beepboop
-- Engineer: Tyler Huddleston
-- 
-- Create Date: 03/08/2025
-- Design Name: Synthesizer Engine
-- Module Name: Synthesizer AXI controller
-- Description: 
--   Provides an AXI-4 LITE interface to set controls to the synthesizer engine.
-- 
-- Note: This file was originally generated in Vivado 2024.2 as a AXI peripheral.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use xil_defaultlib.synth_pkg.all;
  use xil_defaultlib.music_note_pkg.all;

entity synth_axi_ctrl is
  generic (
    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH : integer  := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH : integer  := 31
  );
  port (
    -- user clock domain
    clk                : in  std_logic;
    rst                : in  std_logic;
    -- synth controls
    note_amps          : out t_note_amp;
    ph_inc_table       : out t_ph_inc_lut;
    wfrm_amps          : out t_wfrm_amp;
    wfrm_phs           : out t_wfrm_ph;
    out_amp            : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
    out_shift          : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
    pulse_width        : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
    adsr_attack_amt    : out unsigned(WIDTH_ADSR_CC-1 downto 0);
    adsr_decay_amt     : out unsigned(WIDTH_ADSR_CC-1 downto 0);
    adsr_sustain_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
    adsr_release_amt   : out unsigned(WIDTH_ADSR_CC-1 downto 0);
    -- compressor controls
    comp_attack_amt    : out integer;
    comp_release_amt   : out integer;
    comp_threshold     : out unsigned(WIDTH_WAVE_DATA+7 downto 0);
    comp_knee_width    : out unsigned(WIDTH_WAVE_DATA+7 downto 0);
    comp_knee_slope    : out unsigned(WIDTH_WAVE_GAIN-1 downto 0);
    
    -- Write address (issued by master, accepted by Slave)
    S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Write channel Protection type. This signal indicates the
        -- privilege and security level of the transaction, and whether
        -- the transaction is a data access or an instruction access.
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that the master signaling
        -- valid write address and control information.
    S_AXI_AWVALID  : in std_logic;
    -- Write address ready. This signal indicates that the slave is ready
        -- to accept an address and associated control signals.
    S_AXI_AWREADY  : out std_logic;
    -- Write data (issued by master, acceped by Slave) 
    S_AXI_WDATA  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Write strobes. This signal indicates which byte lanes hold
        -- valid data. There is one write strobe bit for each eight
        -- bits of the write data bus.    
    S_AXI_WSTRB  : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    -- Write valid. This signal indicates that valid write
        -- data and strobes are available.
    S_AXI_WVALID  : in std_logic;
    -- Write ready. This signal indicates that the slave
        -- can accept the write data.
    S_AXI_WREADY  : out std_logic;
    -- Write response. This signal indicates the status
        -- of the write transaction.
    S_AXI_BRESP  : out std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the channel
        -- is signaling a valid write response.
    S_AXI_BVALID  : out std_logic;
    -- Response ready. This signal indicates that the master
        -- can accept a write response.
    S_AXI_BREADY  : in std_logic;
    -- Read address (issued by master, acceped by Slave)
    S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Protection type. This signal indicates the privilege
        -- and security level of the transaction, and whether the
        -- transaction is a data access or an instruction access.
    S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
    -- Read address valid. This signal indicates that the channel
        -- is signaling valid read address and control information.
    S_AXI_ARVALID  : in std_logic;
    -- Read address ready. This signal indicates that the slave is
        -- ready to accept an address and associated control signals.
    S_AXI_ARREADY  : out std_logic;
    -- Read data (issued by slave)
    S_AXI_RDATA  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Read response. This signal indicates the status of the
        -- read transfer.
    S_AXI_RRESP  : out std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel is
        -- signaling the required read data.
    S_AXI_RVALID  : out std_logic;
    -- Read ready. This signal indicates that the master can
        -- accept the read data and response information.
    S_AXI_RREADY  : in std_logic
  );
end synth_axi_ctrl;

architecture arch_imp of synth_axi_ctrl is

  signal rst_n : std_logic;

  -- AXI4LITE signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- constants
  constant ADDR_LSB : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := 8;

  -- note amplitudes array
  signal note_amps_int : t_note_amp;

  -- phase increment table array
  signal ph_inc_table_int : t_ph_inc_lut;

  -- memory-mapped registers
  signal  pulse_width_reg,
          pulse_reg,
          ramp_reg,
          saw_reg,
          tri_reg,
          sine_reg,
          adsr_attack_reg,
          adsr_decay_reg,
          adsr_sustain_reg,
          adsr_release_reg,
          comp_attack_reg,
          comp_release_reg,
          comp_threshold_reg,
          comp_knee_width_reg,
          comp_knee_slope_reg,
          out_amp_reg,
          out_shift_reg,
          wrapback_reg   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

  -- address indexing signals
  signal byte_index  : integer;
  signal mem_logic   : std_logic_vector(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

   -- State machine local parameters
  constant Idle : std_logic_vector(1 downto 0) := "00";
  constant Raddr: std_logic_vector(1 downto 0) := "10";
  constant Rdata: std_logic_vector(1 downto 0) := "11";
  constant Waddr: std_logic_vector(1 downto 0) := "10";
  constant Wdata: std_logic_vector(1 downto 0) := "11";

   -- State machine variables
  signal state_read : std_logic_vector(1 downto 0);
  signal state_write: std_logic_vector(1 downto 0); 

  -- array address
  signal array_addr : integer range ADDR_LSB to 2**(ADDR_LSB + OPT_MEM_ADDR_BITS);

begin

  rst_n <= not(rst);
  -- output port assignements
  note_amps      <= note_amps_int;
  ph_inc_table   <= ph_inc_table_int;

  wfrm_amps(I_PULSE) <= unsigned(pulse_reg(WIDTH_WAVE_GAIN-1 downto 0));
  wfrm_amps(I_RAMP)  <= unsigned(ramp_reg(WIDTH_WAVE_GAIN-1 downto 0));
  wfrm_amps(I_SAW)   <= unsigned(saw_reg(WIDTH_WAVE_GAIN-1 downto 0));
  wfrm_amps(I_TRI)   <= unsigned(tri_reg(WIDTH_WAVE_GAIN-1 downto 0));
  wfrm_amps(I_SINE)  <= unsigned(sine_reg(WIDTH_WAVE_GAIN-1 downto 0));
  
  wfrm_phs(I_PULSE)  <= unsigned(pulse_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH/2));
  wfrm_phs(I_RAMP)   <= unsigned(ramp_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH/2));
  wfrm_phs(I_SAW)    <= unsigned(saw_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH/2));
  wfrm_phs(I_TRI)    <= unsigned(tri_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH/2));
  wfrm_phs(I_SINE)   <= unsigned(sine_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH/2));

  pulse_width <= unsigned(pulse_width_reg(WIDTH_PULSE_WIDTH-1 downto 0));

  adsr_attack_amt  <= unsigned(adsr_attack_reg(WIDTH_ADSR_CC-1 downto 0));
  adsr_decay_amt   <= unsigned(adsr_decay_reg(WIDTH_ADSR_CC-1 downto 0));
  adsr_sustain_amt <= unsigned(adsr_sustain_reg(WIDTH_ADSR_CC-1 downto 0));
  adsr_release_amt <= unsigned(adsr_release_reg(WIDTH_ADSR_CC-1 downto 0));

  comp_attack_amt  <= to_integer(unsigned(comp_attack_reg));
  comp_release_amt <= to_integer(unsigned(comp_release_reg));
  comp_threshold   <= unsigned(comp_threshold_reg(WIDTH_WAVE_DATA+7 downto 0));
  comp_knee_width  <= unsigned(comp_knee_width_reg(WIDTH_WAVE_DATA+7 downto 0));
  comp_knee_slope  <= unsigned(comp_knee_slope_reg(WIDTH_WAVE_GAIN-1 downto 0));

  out_amp   <= unsigned(out_amp_reg(WIDTH_OUT_GAIN-1 downto 0));
  out_shift <= unsigned(out_shift_reg(WIDTH_OUT_SHIFT-1 downto 0));

  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP   <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RRESP   <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;
  mem_logic     <= S_AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) when (S_AXI_AWVALID = '1')
                  else axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

  -- array address logic
  array_addr <= to_integer(unsigned(mem_logic(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB)));

  -- Implement Write state machine
  -- Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
   process (clk)                                       
    begin                                       
      if rising_edge(clk) then
        if rst_n = '0' then
          --asserting initial values to all 0's during reset
          axi_awready <= '0';                                       
          axi_wready  <= '0';                                       
          axi_bvalid  <= '0';                                       
          axi_bresp   <= (others => '0');                                       
          state_write <= Idle;
        else
          case (state_write) is

            when Idle =>
            -- Initial state indicating reset is done and ready to receive read/write transactions                                        
              if (rst_n = '1') then                                       
                axi_awready    <= '1';                                       
                axi_wready     <= '1';                                       
                state_write    <= Waddr;                                       
              else
                state_write    <= state_write;                                       
              end if;

            when Waddr =>
            -- At this state, slave is ready to receive address along with corresponding control
            -- signals and first data packet. Response valid is also handled at this state                                       
              if (S_AXI_AWVALID = '1' and axi_awready = '1') then                                       
                axi_awaddr <= S_AXI_AWADDR;                                       
                if (S_AXI_WVALID = '1') then                                       
                  axi_awready <= '1';                                       
                  state_write <= Waddr;                                       
                  axi_bvalid  <= '1';                                       
                else                                       
                  axi_awready <= '0';                                       
                  state_write <= Wdata;                                       
                  if (S_AXI_BREADY = '1' and axi_bvalid = '1') then                                       
                    axi_bvalid <= '0';                                       
                  end if;                                       
                end if;                                       
              else                                        
                state_write <= state_write;                                       
                if (S_AXI_BREADY = '1' and axi_bvalid = '1') then                                       
                  axi_bvalid <= '0';                                       
                end if;                                       
              end if;

            when Wdata =>
            -- At this state, slave is ready to receive the data packets until the number 
            -- of transfers is equal to burst length                                       
              if (S_AXI_WVALID = '1') then                                       
                state_write <= Waddr;                                       
                axi_bvalid  <= '1';                                       
                axi_awready <= '1';                                       
              else                                       
                state_write <= state_write;                                       
                if (S_AXI_BREADY ='1' and axi_bvalid = '1') then                                       
                  axi_bvalid <= '0';                                       
                end if;                                       
              end if;

            when others =>
            -- reserved                                       
              axi_awready <= '0';                                       
              axi_wready  <= '0';                                       
              axi_bvalid  <= '0';

          end case;                                       
        end if;                                       
      end if;                                                
   end process;

  -- Implement memory mapped register select and write logic generation
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  -- select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  process (clk)
    
    variable temp : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

    -- procedure to simplify write logic with signal input
    procedure write_strobe(
     signal reg   : inout std_logic_vector;
     signal wdata : in    std_logic_vector;
     signal wstrb : in    std_logic_vector
   ) is
   begin
     for byte_index in 0 to (wdata'length/8 - 1) loop
       if wstrb(byte_index) = '1' then
         reg(byte_index*8 + 7 downto byte_index*8) <= wdata(byte_index*8 + 7 downto byte_index*8);
       end if;
     end loop;
   end procedure;
   -- procedure to simplify write logic with variable input
   procedure write_strobe_array(
    variable reg   : inout std_logic_vector;
    signal   wdata : in    std_logic_vector;
    signal   wstrb : in    std_logic_vector
  ) is
  begin
    for byte_index in 0 to (wdata'length/8 - 1) loop
      if wstrb(byte_index) = '1' then
        reg(byte_index*8 + 7 downto byte_index*8) := wdata(byte_index*8 + 7 downto byte_index*8);
      end if;
    end loop;
  end procedure;

  begin
    if rising_edge(clk) then 
      if rst_n = '0' then
        pulse_width_reg    <= (others => '0');
        pulse_reg          <= (others => '0');
        ramp_reg           <= (others => '0');
        saw_reg            <= (others => '0');
        tri_reg            <= (others => '0');
        sine_reg           <= (others => '0');
        out_amp_reg        <= (others => '0');
        out_shift_reg      <= (others => '0');
        wrapback_reg       <= (others => '0');
        note_amps_int      <= (others => (others => '0'));
        ph_inc_table_int   <= ph_inc_lut;
      else
        if (S_AXI_WVALID = '1') then
          case(mem_logic(mem_logic'high downto mem_logic'high-1)) is

            when "00" =>
              write_strobe_array(temp, S_AXI_WDATA, S_AXI_WSTRB);
              note_amps_int(array_addr) <= unsigned(temp(WIDTH_NOTE_GAIN-1 downto 0));

            when "01" =>
              -- Registers for synth settings
              case(mem_logic(mem_logic'high-2 downto ADDR_LSB)) is
                when OFFSET_PULSE_WIDTH_REG  => write_strobe(pulse_width_reg,     S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_PULSE_REG        => write_strobe(pulse_reg,           S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_RAMP_REG         => write_strobe(ramp_reg,            S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_SAW_REG          => write_strobe(saw_reg,             S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_TRI_REG          => write_strobe(tri_reg,             S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_SINE_REG         => write_strobe(sine_reg,            S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_ADSR_ATTACK_AMT  => write_strobe(adsr_attack_reg,     S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_ADSR_DECAY_AMT   => write_strobe(adsr_decay_reg,      S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_ADSR_SUSTAIN_AMT => write_strobe(adsr_sustain_reg,    S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_ADSR_RELEASE_AMT => write_strobe(adsr_release_reg,    S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_COMP_ATTACK_AMT  => write_strobe(comp_attack_reg,     S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_COMP_RELEASE_AMT => write_strobe(comp_release_reg,    S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_COMP_THRESHOLD   => write_strobe(comp_threshold_reg,  S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_COMP_KNEE_WIDTH  => write_strobe(comp_knee_width_reg, S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_COMP_KNEE_SLOPE  => write_strobe(comp_knee_slope_reg, S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_GAIN_SCALE_REG   => write_strobe(out_amp_reg,         S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_GAIN_SHIFT_REG   => write_strobe(out_shift_reg,       S_AXI_WDATA, S_AXI_WSTRB);
                when OFFSET_WRAPBACK_REG     => write_strobe(wrapback_reg,        S_AXI_WDATA, S_AXI_WSTRB);
                
                when others =>

                  pulse_width_reg     <= pulse_width_reg;
                  pulse_reg           <= pulse_reg;
                  ramp_reg            <= ramp_reg;
                  saw_reg             <= saw_reg;
                  tri_reg             <= tri_reg;
                  sine_reg            <= sine_reg;
                  adsr_attack_reg     <= adsr_attack_reg;
                  adsr_decay_reg      <= adsr_decay_reg;
                  adsr_sustain_reg    <= adsr_sustain_reg;
                  adsr_release_reg    <= adsr_release_reg;
                  comp_attack_reg     <= comp_attack_reg;
                  comp_release_reg    <= comp_release_reg;
                  comp_threshold_reg  <= comp_threshold_reg;
                  comp_knee_slope_reg <= comp_knee_slope_reg;
                  comp_knee_width_reg <= comp_knee_width_reg;
                  out_amp_reg         <= out_amp_reg;
                  out_shift_reg       <= out_shift_reg;
                  wrapback_reg        <= wrapback_reg;
              
              end case;
            
            when "10" =>
            -- Registers for note frequency words
              write_strobe_array(temp, S_AXI_WDATA, S_AXI_WSTRB);
              ph_inc_table_int(array_addr) <= unsigned(temp);
            
            when others =>
              note_amps_int    <= note_amps_int;
              ph_inc_table_int <= ph_inc_table_int;

          end case;
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement read state machine
   process (clk)                                          
     begin                                          
       if rising_edge(clk) then                                           
          if rst_n = '0' then                                          
            --asserting initial values to all 0's during reset                                          
            axi_arready <= '0';                                          
            axi_rvalid <= '0';                                          
            axi_rresp <= (others => '0');                                          
            state_read <= Idle;                                          
          else                                          
            case (state_read) is                                          
              when Idle =>    --Initial state inidicating reset is done and ready to receive read/write transactions                                          
                  if (rst_n = '1') then                                          
                    axi_arready <= '1';                                          
                    state_read <= Raddr;                                          
                  else state_read <= state_read;                                          
                  end if;                                          
              when Raddr =>    --At this state, slave is ready to receive address along with corresponding control signals                                          
                  if (S_AXI_ARVALID = '1' and axi_arready = '1') then                                          
                    state_read <= Rdata;                                          
                    axi_rvalid <= '1';                                          
                    axi_arready <= '0';                                          
                    axi_araddr <= S_AXI_ARADDR;                                          
                  else                                          
                    state_read <= state_read;                                          
                  end if;                                          
              when Rdata =>    --At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                          
                  if (axi_rvalid = '1' and S_AXI_RREADY = '1') then                                          
                    axi_rvalid <= '0';                                          
                    axi_arready <= '1';                                          
                    state_read <= Raddr;                                          
                  else                                          
                    state_read <= state_read;                                          
                  end if;                                          
              when others =>      --reserved                                          
                  axi_arready <= '0';                                          
                  axi_rvalid <= '0';                                          
             end case;                                          
           end if;                                          
         end if;                                                   
    end process;             

  -- Implement memory mapped register select and read logic generation
  S_AXI_RDATA <= 
    -- read note amplitude
    x"000000" & '0' & std_logic_vector(note_amps_int(to_integer(unsigned(axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB))))) when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB+OPT_MEM_ADDR_BITS-1) = "00" ) else
    -- read from note phase increment table
    std_logic_vector(ph_inc_table_int(to_integer(unsigned(axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB))))) when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB+OPT_MEM_ADDR_BITS-1) = "10" ) else
    -- read from synth settings
    pulse_width_reg     when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_PULSE_WIDTH_REG   ) else 
    pulse_reg           when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_PULSE_REG         ) else 
    ramp_reg            when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_RAMP_REG          ) else 
    saw_reg             when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_SAW_REG           ) else 
    tri_reg             when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_TRI_REG           ) else 
    sine_reg            when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_SINE_REG          ) else 
    out_amp_reg         when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_GAIN_SCALE_REG    ) else
    out_shift_reg       when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_GAIN_SHIFT_REG    ) else
    -- read from adsr settings
    adsr_attack_reg     when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_ADSR_ATTACK_AMT   ) else
    adsr_decay_reg      when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_ADSR_DECAY_AMT    ) else
    adsr_sustain_reg    when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_ADSR_SUSTAIN_AMT  ) else
    adsr_release_reg    when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_ADSR_RELEASE_AMT  ) else
    -- read from compressor settings
    comp_attack_reg     when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_COMP_ATTACK_AMT   ) else
    comp_release_reg    when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_COMP_RELEASE_AMT  ) else
    comp_threshold_reg  when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_COMP_THRESHOLD    ) else
    comp_knee_width_reg when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_COMP_KNEE_WIDTH   ) else
    comp_knee_slope_reg when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_COMP_KNEE_SLOPE   ) else
    -- read from info registers
    SYNTH_ENG_REV       when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_REV_REG           ) else 
    SYNTH_ENG_DATE      when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_DATE_REG          ) else 
    wrapback_reg        when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_WRAPBACK_REG      ) else 
    -- default
    (others => '0');


end arch_imp;
