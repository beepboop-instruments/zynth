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
    clk          : in  std_logic;
    rst          : in  std_logic;
    -- Synth controls
    note_amps       : out t_note_amp;
    ph_inc_table    : out t_ph_inc_lut;
    wfrm_amps       : out t_wfrm_amp;
    wfrm_phs        : out t_wfrm_ph;
    out_amp         : out unsigned(WIDTH_OUT_GAIN-1 downto 0);
    out_shift       : out unsigned(WIDTH_OUT_SHIFT-1 downto 0);
    pulse_width     : out unsigned(WIDTH_PULSE_WIDTH-1 downto 0);
    attack_length   : out unsigned(WIDTH_ADSR_COUNT-1 downto 0);
    decay_length    : out unsigned(WIDTH_ADSR_COUNT-1 downto 0);
    sustain_amt     : out unsigned(WIDTH_ADSR_COUNT-1 downto 0);
    release_length  : out unsigned(WIDTH_ADSR_COUNT-1 downto 0);
    attack_steps    : out t_adsr;
    decay_steps     : out t_adsr;
    release_steps   : out t_adsr;

    -- Global Clock Signal
    S_AXI_ACLK  : in std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN  : in std_logic;
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

  component axi_clock_converter
    port (
      s_axi_aclk    : in  std_logic;
      s_axi_aresetn : in  std_logic;
      s_axi_awaddr  : in  std_logic_vector(30 downto 0);
      s_axi_awprot  : in  std_logic_vector(2 downto 0);
      s_axi_awvalid : in  std_logic;
      s_axi_awready : out std_logic;
      s_axi_wdata   : in  std_logic_vector(31 downto 0);
      s_axi_wstrb   : in  std_logic_vector(3 downto 0);
      s_axi_wvalid  : in  std_logic;
      s_axi_wready  : out std_logic;
      s_axi_bresp   : out std_logic_vector(1 downto 0);
      s_axi_bvalid  : out std_logic;
      s_axi_bready  : in  std_logic;
      s_axi_araddr  : in  std_logic_vector(30 downto 0);
      s_axi_arprot  : in  std_logic_vector(2 downto 0);
      s_axi_arvalid : in  std_logic;
      s_axi_arready : out std_logic;
      s_axi_rdata   : out std_logic_vector(31 downto 0);
      s_axi_rresp   : out std_logic_vector(1 downto 0);
      s_axi_rvalid  : out std_logic;
      s_axi_rready  : in  std_logic;
      m_axi_aclk    : in  std_logic;
      m_axi_aresetn : in  std_logic;
      m_axi_awaddr  : out std_logic_vector(30 downto 0);
      m_axi_awprot  : out std_logic_vector(2 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in  std_logic;
      m_axi_wdata   : out std_logic_vector(31 downto 0);
      m_axi_wstrb   : out std_logic_vector(3 downto 0);
      m_axi_wvalid  : out std_logic;
      m_axi_wready  : in  std_logic;
      m_axi_bresp   : in  std_logic_vector(1 downto 0);
      m_axi_bvalid  : in  std_logic;
      m_axi_bready  : out std_logic;
      m_axi_araddr  : out std_logic_vector(30 downto 0);
      m_axi_arprot  : out std_logic_vector(2 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in  std_logic;
      m_axi_rdata   : in  std_logic_vector(31 downto 0);
      m_axi_rresp   : in  std_logic_vector(1 downto 0);
      m_axi_rvalid  : in  std_logic;
      m_axi_rready  : out std_logic 
    );
  end component;

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

  -- clock conversion axi bus
  signal m_axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal m_axi_awprot  : std_logic_vector( 2 downto 0);
  signal m_axi_awvalid : std_logic;
  signal m_axi_awready : std_logic;
  signal m_axi_wdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal m_axi_wstrb   : std_logic_vector( 3 downto 0);
  signal m_axi_wvalid  : std_logic;
  signal m_axi_wready  : std_logic;
  signal m_axi_bresp   : std_logic_vector( 1 downto 0);
  signal m_axi_bvalid  : std_logic;
  signal m_axi_bready  : std_logic;
  signal m_axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal m_axi_arprot  : std_logic_vector( 2 downto 0);
  signal m_axi_arvalid : std_logic;
  signal m_axi_arready : std_logic;
  signal m_axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal m_axi_rresp   : std_logic_vector( 1 downto 0);
  signal m_axi_rvalid  : std_logic;
  signal m_axi_rready  : std_logic;

  -- constants
  constant ADDR_LSB : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := 8;

  -- note amplitudes array
  signal note_amps_int : t_note_amp;

  -- phase increment table array
  signal ph_inc_table_int : t_ph_inc_lut;

  -- adsr arrays
  signal  attack_steps_int,
          decay_steps_int,
          release_steps_int  : t_adsr;

  -- memory-mapped registers
  signal  pulse_width_reg,
          pulse_reg,
          ramp_reg,
          saw_reg,
          tri_reg,
          sine_reg,
          out_amp_reg,
          out_shift_reg,
          wrapback_reg,
          attack_length_reg,
          decay_length_reg,
          sustain_amt_reg,
          release_length_reg  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

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
  note_amps     <= note_amps_int;
  ph_inc_table  <= ph_inc_table_int;
  attack_steps  <= attack_steps_int;
  decay_steps   <= decay_steps_int;
  release_steps <= release_steps_int;

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

  out_amp   <= unsigned(out_amp_reg(WIDTH_OUT_GAIN-1 downto 0));
  out_shift <= unsigned(out_shift_reg(WIDTH_OUT_SHIFT-1 downto 0));

  attack_length   <= unsigned(attack_length_reg(WIDTH_ADSR_COUNT-1 downto 0));
  decay_length    <= unsigned(decay_length_reg(WIDTH_ADSR_COUNT-1 downto 0));
  sustain_amt     <= unsigned(sustain_amt_reg(WIDTH_ADSR_COUNT-1 downto 0));
  release_length  <= unsigned(release_length_reg(WIDTH_ADSR_COUNT-1 downto 0));

  m_axi_awready <= axi_awready;
  m_axi_wready  <= axi_wready;
  m_axi_bresp   <= axi_bresp;
  m_axi_bvalid  <= axi_bvalid;
  m_axi_arready <= axi_arready;
  m_axi_rresp   <= axi_rresp;
  m_axi_rvalid  <= axi_rvalid;
  mem_logic     <= m_axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) when (m_axi_awvalid = '1')
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
              if (m_axi_awvalid = '1' and axi_awready = '1') then                                       
                axi_awaddr <= m_axi_awaddr;                                       
                if (m_axi_wvalid = '1') then                                       
                  axi_awready <= '1';                                       
                  state_write <= Waddr;                                       
                  axi_bvalid  <= '1';                                       
                else                                       
                  axi_awready <= '0';                                       
                  state_write <= Wdata;                                       
                  if (m_axi_bready = '1' and axi_bvalid = '1') then                                       
                    axi_bvalid <= '0';                                       
                  end if;                                       
                end if;                                       
              else                                        
                state_write <= state_write;                                       
                if (m_axi_bready = '1' and axi_bvalid = '1') then                                       
                  axi_bvalid <= '0';                                       
                end if;                                       
              end if;

            when Wdata =>
            -- At this state, slave is ready to receive the data packets until the number 
            -- of transfers is equal to burst length                                       
              if (m_axi_wvalid = '1') then                                       
                state_write <= Waddr;                                       
                axi_bvalid  <= '1';                                       
                axi_awready <= '1';                                       
              else                                       
                state_write <= state_write;                                       
                if (m_axi_bready ='1' and axi_bvalid = '1') then                                       
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
        attack_length_reg  <= (others => '0');
        decay_length_reg   <= (others => '0');
        sustain_amt_reg    <= (others => '0');
        release_length_reg <= (others => '0');
        wrapback_reg       <= (others => '0');
        note_amps_int      <= (others => (others => '0'));
        ph_inc_table_int   <= ph_inc_lut;
        attack_steps_int   <= (others => (others => '0'));
        decay_steps_int    <= (others => (others => '0'));
        release_steps_int  <= (others => (others => '0'));
      else
        if (m_axi_wvalid = '1') then
          case(mem_logic(mem_logic'high downto mem_logic'high-1)) is

            when "00" =>
              write_strobe_array(temp, m_axi_wdata, m_axi_wstrb);
              note_amps_int(array_addr) <= unsigned(temp(WIDTH_NOTE_GAIN-1 downto 0));

            when "01" =>
              -- Registers for synth settings
              case(mem_logic(mem_logic'high-2 downto ADDR_LSB)) is
                when OFFSET_PULSE_WIDTH_REG  => write_strobe(pulse_width_reg,    m_axi_wdata, m_axi_wstrb);
                when OFFSET_PULSE_REG        => write_strobe(pulse_reg,          m_axi_wdata, m_axi_wstrb);
                when OFFSET_RAMP_REG         => write_strobe(ramp_reg,           m_axi_wdata, m_axi_wstrb);
                when OFFSET_SAW_REG          => write_strobe(saw_reg,            m_axi_wdata, m_axi_wstrb);
                when OFFSET_TRI_REG          => write_strobe(tri_reg,            m_axi_wdata, m_axi_wstrb);
                when OFFSET_SINE_REG         => write_strobe(sine_reg,           m_axi_wdata, m_axi_wstrb);
                when OFFSET_GAIN_SCALE_REG   => write_strobe(out_amp_reg,        m_axi_wdata, m_axi_wstrb);
                when OFFSET_GAIN_SHIFT_REG   => write_strobe(out_shift_reg,      m_axi_wdata, m_axi_wstrb);
                when OFFSET_ATTACK_LENGTH    => write_strobe(attack_length_reg,  m_axi_wdata, m_axi_wstrb);
                when OFFSET_DECAY_LENGTH     => write_strobe(decay_length_reg,   m_axi_wdata, m_axi_wstrb);
                when OFFSET_SUSTAIN_AMT      => write_strobe(sustain_amt_reg,    m_axi_wdata, m_axi_wstrb);
                when OFFSET_RELEASE_LENGTH   => write_strobe(release_length_reg, m_axi_wdata, m_axi_wstrb);
                when OFFSET_WRAPBACK_REG     => write_strobe(wrapback_reg,       m_axi_wdata, m_axi_wstrb);
                
                when others =>

                  pulse_width_reg    <= pulse_width_reg;
                  pulse_reg          <= pulse_reg;
                  ramp_reg           <= ramp_reg;
                  saw_reg            <= saw_reg;
                  tri_reg            <= tri_reg;
                  sine_reg           <= sine_reg;
                  out_amp_reg        <= out_amp_reg;
                  out_shift_reg      <= out_shift_reg;
                  attack_length_reg  <= attack_length_reg;
                  decay_length_reg   <= decay_length_reg;
                  sustain_amt_reg    <= sustain_amt_reg;
                  release_length_reg <= release_length_reg;
                  wrapback_reg       <= wrapback_reg;

                  if (mem_logic(mem_logic'high-2 downto ADDR_LSB) >= OFFSET_ATTACK_STEP
                      and mem_logic(mem_logic'high-2 downto ADDR_LSB) < OFFSET_DECAY_STEP) then
                    write_strobe_array(temp, m_axi_wdata, m_axi_wstrb);
                    attack_steps_int(array_addr-to_integer(unsigned(OFFSET_ATTACK_STEP))) <= unsigned(temp(WIDTH_ADSR_COUNT-1 downto 0));
                  
                  elsif (mem_logic(mem_logic'high-2 downto ADDR_LSB) >= OFFSET_DECAY_STEP
                      and mem_logic(mem_logic'high-2 downto ADDR_LSB) < OFFSET_RELEASE_STEP) then
                    write_strobe_array(temp, m_axi_wdata, m_axi_wstrb);
                    decay_steps_int(array_addr-to_integer(unsigned(OFFSET_DECAY_STEP))) <= unsigned(temp(WIDTH_ADSR_COUNT-1 downto 0));
                
                  elsif (mem_logic(mem_logic'high-2 downto ADDR_LSB) >= OFFSET_RELEASE_STEP
                      and mem_logic(mem_logic'high-2 downto ADDR_LSB) < OFFSET_ATTACK_LENGTH) then
                    write_strobe_array(temp, m_axi_wdata, m_axi_wstrb);
                    release_steps_int(array_addr-to_integer(unsigned(OFFSET_RELEASE_STEP))) <= unsigned(temp(WIDTH_ADSR_COUNT-1 downto 0));
                  
                  end if;
              
              end case;
            
            when "10" =>
            -- Registers for note frequency words
              write_strobe_array(temp, m_axi_wdata, m_axi_wstrb);
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
                  if (m_axi_arvalid = '1' and axi_arready = '1') then                                          
                    state_read <= Rdata;                                          
                    axi_rvalid <= '1';                                          
                    axi_arready <= '0';                                          
                    axi_araddr <= m_axi_araddr;                                          
                  else                                          
                    state_read <= state_read;                                          
                  end if;                                          
              when Rdata =>    --At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                          
                  if (axi_rvalid = '1' and m_axi_rready = '1') then                                          
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
  m_axi_rdata <= 
    -- read note amplitude
    x"000000" & '0' & std_logic_vector(note_amps_int(to_integer(unsigned(axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB))))) when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB+OPT_MEM_ADDR_BITS-1) = "00" ) else
    -- read from note phase increment table
    std_logic_vector(ph_inc_table_int(to_integer(unsigned(axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB))))) when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB+OPT_MEM_ADDR_BITS-1) = "10" ) else
    -- read from synth settings
    pulse_width_reg    when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_PULSE_WIDTH_REG   ) else 
    pulse_reg          when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_PULSE_REG         ) else 
    ramp_reg           when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_RAMP_REG          ) else 
    saw_reg            when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_SAW_REG           ) else 
    tri_reg            when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_TRI_REG           ) else 
    sine_reg           when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_SINE_REG          ) else 
    out_amp_reg        when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_GAIN_SCALE_REG    ) else
    out_shift_reg      when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_GAIN_SHIFT_REG    ) else
    -- read from adsr settings
    attack_length_reg  when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_ATTACK_LENGTH     ) else 
    decay_length_reg   when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_DECAY_LENGTH      ) else 
    sustain_amt_reg    when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_SUSTAIN_AMT       ) else 
    release_length_reg when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_RELEASE_LENGTH    ) else 
    -- read from info registers
    SYNTH_ENG_REV      when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_REV_REG           ) else 
    SYNTH_ENG_DATE     when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_DATE_REG          ) else 
    wrapback_reg       when (axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS-2 downto ADDR_LSB) = OFFSET_WRAPBACK_REG      ) else 
    -- default
    (others => '0');

  u_axi_converter: axi_clock_converter
    port map (
      s_axi_aclk    => S_AXI_ACLK,
      s_axi_aresetn => S_AXI_ARESETN,
      s_axi_awaddr  => S_AXI_AWADDR,
      s_axi_awprot  => S_AXI_AWPROT,
      s_axi_awvalid => S_AXI_AWVALID,
      s_axi_awready => S_AXI_AWREADY,
      s_axi_wdata   => S_AXI_WDATA,
      s_axi_wstrb   => S_AXI_WSTRB,
      s_axi_wvalid  => S_AXI_WVALID,
      s_axi_wready  => S_AXI_WREADY,
      s_axi_bresp   => S_AXI_BRESP,
      s_axi_bvalid  => S_AXI_BVALID,
      s_axi_bready  => S_AXI_BREADY,
      s_axi_araddr  => S_AXI_ARADDR,
      s_axi_arprot  => S_AXI_ARPROT,
      s_axi_arvalid => S_AXI_ARVALID,
      s_axi_arready => S_AXI_ARREADY,
      s_axi_rdata   => S_AXI_RDATA,
      s_axi_rresp   => S_AXI_RRESP,
      s_axi_rvalid  => S_AXI_RVALID,
      s_axi_rready  => S_AXI_RREADY,
      m_axi_aclk    => clk,
      m_axi_aresetn => rst_n,
      m_axi_awaddr  => m_axi_awaddr,
      m_axi_awprot  => m_axi_awprot,
      m_axi_awvalid => m_axi_awvalid,
      m_axi_awready => m_axi_awready,
      m_axi_wdata   => m_axi_wdata,
      m_axi_wstrb   => m_axi_wstrb,
      m_axi_wvalid  => m_axi_wvalid,
      m_axi_wready  => m_axi_wready,
      m_axi_bresp   => m_axi_bresp,
      m_axi_bvalid  => m_axi_bvalid,
      m_axi_bready  => m_axi_bready,
      m_axi_araddr  => m_axi_araddr,
      m_axi_arprot  => m_axi_arprot,
      m_axi_arvalid => m_axi_arvalid,
      m_axi_arready => m_axi_arready,
      m_axi_rdata   => m_axi_rdata,
      m_axi_rresp   => m_axi_rresp,
      m_axi_rvalid  => m_axi_rvalid,
      m_axi_rready  => m_axi_rready
    );

end arch_imp;
