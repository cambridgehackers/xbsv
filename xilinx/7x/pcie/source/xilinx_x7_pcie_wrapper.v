// Copyright (c) 2012  Bluespec, Inc.  ALL RIGHTS RESERVED

`ifdef BSV_ASSIGNMENT_DELAY
`else
 `define BSV_ASSIGNMENT_DELAY
`endif

module xilinx_x7_pcie_wrapper #(
// These are the parameters that we are overriding:
// configured gen1 x8 with msix etc
				parameter         CFG_VEND_ID        = 16'h1BE7,
				parameter         CFG_DEV_ID         = 16'hB100,
				parameter         CFG_REV_ID         = 8'h00,
				parameter         CFG_SUBSYS_VEND_ID = 16'h1BE7,
				parameter         CFG_SUBSYS_ID      = 16'hA705,
				parameter         C_DATA_WIDTH = 64,
				parameter         PL_FAST_TRAIN = "FALSE",
				parameter         PCIE_EXT_CLK  = "TRUE",
				parameter         PIPE_PIPELINE_STAGES = 1,
				parameter [23:0]  CLASS_CODE = 24'h050000,
				parameter [11:0]  DSN_CAP_NEXTPTR =  12'hffc ,
				parameter         LINK_CAP_ASPM_OPTIONALITY = "TRUE",
				parameter         LINK_CAP_ASPM_SUPPORT = 0,
				parameter [5:0]   LINK_CAP_MAX_LINK_WIDTH = 6'h8,
				parameter [5:0]   LTSSM_MAX_LINK_WIDTH = 6'h8,
				parameter         MSIX_CAP_ON = "TRUE",
				parameter [28:0]  MSIX_CAP_PBA_OFFSET = 29'ha00,
				parameter [28:0]  MSIX_CAP_TABLE_OFFSET = 29'h800,
				parameter [10:0]  MSIX_CAP_TABLE_SIZE = 11'h003,
				parameter [7:0]   PCIE_CAP_NEXTPTR = 8'h9c,
				parameter         USER_CLK_FREQ = 3,
				parameter USER_CLK2_DIV2 = "FALSE",
				// add 26 to replay timeout
				parameter [14:0]  LL_REPLAY_TIMEOUT = 15'h001a,
				parameter         LL_REPLAY_TIMEOUT_EN = "TRUE",
				// AER
				parameter AER_CAP_ON = "FALSE",
				
				parameter         C_FAMILY = "7X",
				parameter         C_ROOT_PORT = "FALSE",
				parameter         C_PM_PRIORITY = "FALSE",
				parameter         IMPL_TARGET = "HARD",
				parameter         TLM_TX_OVERHEAD = 24, // overhead bytes for packets (transmit)
				
// xbsv
				parameter [31:0]  BAR0 = 32'hFFFF8000,
				parameter [31:0]  BAR1 = 32'h00000000,
				parameter [31:0]  BAR2 = 32'h00000000,
				parameter [31:0]  BAR3 = 32'h00000000,
				parameter [31:0]  BAR4 = 32'h00000000,
				parameter [31:0]  BAR5 = 32'h00000000
// xbsv
                                )
(
 
 //----------------------------------------------------------------------------------------------------------------//
 // 1. PCI Express (pci_exp) Interface                                                                             //
 //----------------------------------------------------------------------------------------------------------------//
 
 // Tx
 output [7:0]                                pci_exp_txn,
 output [7:0]                                pci_exp_txp,

 // Rx
 input  [7:0]                                pci_exp_rxn,
 input  [7:0]                                pci_exp_rxp,
 
 //----------------------------------------------------------------------------------------------------------------//
 // 2. Clock Inputs                                                                                                //
 //----------------------------------------------------------------------------------------------------------------//

 //----------------------------------------------------------------------------------------------------------------//
 // 3. AXI-S Interface                                                                                             //
 //----------------------------------------------------------------------------------------------------------------//
 
 // Common
 output                                     user_clk_out,
 output reg                                 user_reset_out,
 output wire                                user_lnk_up,
 output wire                                user_app_rdy,

 // Tx
 output  [5:0]                              tx_buf_av,
 output                                     tx_err_drop,
 output                                     tx_cfg_req,
 output                                     s_axis_tx_tready,
 input   [63:0]                             s_axis_tx_tdata,
 input   [7:0]                              s_axis_tx_tkeep,
 input   [3:0]                              s_axis_tx_tuser,
 input                                      s_axis_tx_tlast,
 input                                      s_axis_tx_tvalid,
 input                                      tx_cfg_gnt,

 // Rx
 output reg [63:0]                          m_axis_rx_tdata,
 output  [7:0]                              m_axis_rx_tkeep,
 output                                     m_axis_rx_tlast,
 output reg                                 m_axis_rx_tvalid,
 input                                      m_axis_rx_tready,
 output reg [21:0]                          m_axis_rx_tuser,
 input                                      rx_np_ok,
 input                                      rx_np_req,

 // Flow Control
 output  [11:0]                             fc_cpld,
 output  [7:0]                              fc_cplh,
 output  [11:0]                             fc_npd,
 output  [7:0]                              fc_nph,
 output  [11:0]                             fc_pd,
 output  [7:0]                              fc_ph,
 input   [2:0]                              fc_sel,
 
 
 //----------------------------------------------------------------------------------------------------------------//
 // 4. Configuration (CFG) Interface                                                                               //
 //----------------------------------------------------------------------------------------------------------------//
 
 //------------------------------------------------//
 // EP and RP                                      //
 //------------------------------------------------//
 output wire  [31:0]  cfg_mgmt_do,
 output wire          cfg_mgmt_rd_wr_done,
 
 output wire  [15:0]  cfg_status,
 output wire  [15:0]  cfg_command,
 output wire  [15:0]  cfg_dstatus,
 output wire  [15:0]  cfg_dcommand,
 output wire  [15:0]  cfg_lstatus,
 output wire  [15:0]  cfg_lcommand,
 output wire  [15:0]  cfg_dcommand2,
 output       [2:0]   cfg_pcie_link_state,
 
 output wire          cfg_pmcsr_pme_en,
 output wire  [1:0]   cfg_pmcsr_powerstate,
 output wire          cfg_pmcsr_pme_status,
 output wire          cfg_received_func_lvl_rst,
 
 // Management Interface
 input wire   [31:0]  cfg_mgmt_di,
 input wire   [3:0]   cfg_mgmt_byte_en,
 input wire   [9:0]   cfg_mgmt_dwaddr,
 input wire           cfg_mgmt_wr_en,
 input wire           cfg_mgmt_rd_en,
 input wire           cfg_mgmt_wr_readonly,
 
 // Error Reporting Interface
 input wire           cfg_err_ecrc,
 input wire           cfg_err_ur,
 input wire           cfg_err_cpl_timeout,
 input wire           cfg_err_cpl_unexpect,
 input wire           cfg_err_cpl_abort,
 input wire           cfg_err_posted,
 input wire           cfg_err_cor,
 input wire           cfg_err_atomic_egress_blocked,
 input wire           cfg_err_internal_cor,
 input wire           cfg_err_malformed,
 input wire           cfg_err_mc_blocked,
 input wire           cfg_err_poisoned,
 input wire           cfg_err_norecovery,
 input wire  [47:0]   cfg_err_tlp_cpl_header,
 output wire          cfg_err_cpl_rdy,
 input wire           cfg_err_locked,
 input wire           cfg_err_acs,
 input wire           cfg_err_internal_uncor,
 
 input wire           cfg_trn_pending,
 input wire           cfg_pm_halt_aspm_l0s,
 input wire           cfg_pm_halt_aspm_l1,
 input wire           cfg_pm_force_state_en,
 input wire   [1:0]   cfg_pm_force_state,
 
 input wire  [63:0]   cfg_dsn,
 
 //------------------------------------------------//
 // EP Only                                        //
 //------------------------------------------------//
 
 // Interrupt Interface Signals
 input wire           cfg_interrupt,
 output wire          cfg_interrupt_rdy,
 input wire           cfg_interrupt_assert,
 input wire   [7:0]   cfg_interrupt_di,
 output wire  [7:0]   cfg_interrupt_do,
 output wire  [2:0]   cfg_interrupt_mmenable,
 output wire          cfg_interrupt_msienable,
 output wire          cfg_interrupt_msixenable,
 output wire          cfg_interrupt_msixfm,
 input wire           cfg_interrupt_stat,
 input wire   [4:0]   cfg_pciecap_interrupt_msgnum,
 
 
 output               cfg_to_turnoff,
 input wire           cfg_turnoff_ok,
 output wire  [7:0]   cfg_bus_number,
 output wire  [4:0]   cfg_device_number,
 output wire  [2:0]   cfg_function_number,
 input wire           cfg_pm_wake,
 
 //----------------------------------------------------------------------------------------------------------------//
 // 5. Physical Layer Control and Status (PL) Interface                                                            //
 //----------------------------------------------------------------------------------------------------------------//
 
 //------------------------------------------------//
 // EP and RP                                      //
 //------------------------------------------------//
 input wire   [1:0]   pl_directed_link_change,
 input wire   [1:0]   pl_directed_link_width,
 input wire           pl_directed_link_speed,
 input wire           pl_directed_link_auton,
 input wire           pl_upstream_prefer_deemph,
 
 
 
 output wire          pl_sel_lnk_rate,
 output wire  [1:0]   pl_sel_lnk_width,
 output wire  [5:0]   pl_ltssm_state,
 output wire  [1:0]   pl_lane_reversal_mode,
 
 output wire          pl_phy_lnk_up,
 output wire  [2:0]   pl_tx_pm_state,
 output wire  [1:0]   pl_rx_pm_state,
 
 output wire          pl_link_upcfg_cap,
 output wire          pl_link_gen2_cap,
 output wire          pl_link_partner_gen2_supported,
 output wire  [2:0]   pl_initial_link_width,
 
 output wire          pl_directed_change_done,
 
 //------------------------------------------------//
 // EP Only                                        //
 //------------------------------------------------//
 output wire          pl_received_hot_rst,
 
 //----------------------------------------------------------------------------------------------------------------//
 // 6. AER interface                                                                                               //
 //----------------------------------------------------------------------------------------------------------------//
 
 input wire [127:0]   cfg_err_aer_headerlog,
 input wire   [4:0]   cfg_aer_interrupt_msgnum,
 output wire          cfg_err_aer_headerlog_set,
 output wire          cfg_aer_ecrc_check_en,
 output wire          cfg_aer_ecrc_gen_en,
 
 //----------------------------------------------------------------------------------------------------------------//
 // 7. VC interface                                                                                                //
 //----------------------------------------------------------------------------------------------------------------//
 
 output wire [6:0]    cfg_vc_tcvc_map,
 
 //----------------------------------------------------------------------------------------------------------------//
 // 8. System(SYS) Interface                                                                                       //
 //----------------------------------------------------------------------------------------------------------------//
 
 
 
 input wire           sys_clk,
 input wire           sys_reset_n
 );
   
   // Wires used for external clocking connectivity
   wire                pipe_pclk_in;
   wire                pipe_rxusrclk_in;
   wire [7:0]          pipe_rxoutclk_in;
   wire                pipe_dclk_in;
   wire                pipe_userclk1_in;
   wire                pipe_userclk2_in;
   wire                pipe_mmcm_lock_in;
   
   wire                pipe_txoutclk_out;
   wire [7:0]          pipe_rxoutclk_out;
   wire [7:0]          pipe_pclk_sel_out;
   wire                pipe_gen3_out;
   wire                pipe_oobclk_in;

   localparam USERCLK2_FREQ = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ
                                                                                    : USER_CLK_FREQ;
   wire pipe_clk_rst_n = 1'b1 ;
   
   generate
      if (PCIE_EXT_CLK == "TRUE") begin: ext_clk
         pcie_7x_0_pipe_clock #(
                                   .PCIE_ASYNC_EN                  ( "FALSE" ),     // PCIe async enable
                                   .PCIE_TXBUF_EN                  ( "FALSE" ),     // PCIe TX buffer enable for Gen1/Gen2 only
                                   .PCIE_LANE                      ( 6'h08 ),     // PCIe number of lanes
                                   .PCIE_LINK_SPEED                ( 3 ),
                                   .PCIE_REFCLK_FREQ               ( 0 ),     // PCIe reference clock frequency
                                   .PCIE_USERCLK1_FREQ             ( USER_CLK_FREQ +1 ),     // PCIe user clock 1 frequency
                                   .PCIE_USERCLK2_FREQ             ( USERCLK2_FREQ +1 ),     // PCIe user clock 2 frequency
                                   .PCIE_DEBUG_MODE                ( 0 )
                                   )
         pipe_clock_i
           (
            
            //---------- Input -------------------------------------
            .CLK_CLK                        ( sys_clk ),
            .CLK_TXOUTCLK                   ( pipe_txoutclk_out ),     // Reference clock from lane 0
            .CLK_RXOUTCLK_IN                ( pipe_rxoutclk_out ),
            .CLK_RST_N                      ( pipe_clk_rst_n ),
            .CLK_PCLK_SEL                   ( pipe_pclk_sel_out ),
            .CLK_GEN3                       ( pipe_gen3_out ),
            
            //---------- Output ------------------------------------
            .CLK_PCLK                       ( pipe_pclk_in ),
            .CLK_RXUSRCLK                   ( pipe_rxusrclk_in ),
            .CLK_RXOUTCLK_OUT               ( pipe_rxoutclk_in ),
            .CLK_DCLK                       ( pipe_dclk_in ),
            .CLK_OOBCLK                     ( pipe_oobclk_in ),
            .CLK_USERCLK1                   ( pipe_userclk1_in ),
            .CLK_USERCLK2                   ( pipe_userclk2_in ),
            .CLK_MMCM_LOCK                  ( pipe_mmcm_lock_in )
            
            );
      end
   endgenerate
   
   
//begin pcie_7x_v2_1_core_top {
// bluenoc vend/dev id			  
//   pcie_7x_v2_1_i
      
   // localparam         CFG_VEND_ID        = 16'h1be7;
   // localparam         CFG_DEV_ID         = 16'hb100;
   // localparam         CFG_REV_ID         =  8'h00;
   // localparam         CFG_SUBSYS_VEND_ID = 16'h1be7;
   // localparam         CFG_SUBSYS_ID      = 16'ha705;


   localparam         ALLOW_X8_GEN2 = "FALSE";
   // localparam         PIPE_PIPELINE_STAGES = 1;
   localparam [11:0]  AER_BASE_PTR = 12'h000;
   localparam         AER_CAP_ECRC_CHECK_CAPABLE = "FALSE";
   localparam         AER_CAP_ECRC_GEN_CAPABLE = "FALSE";
   localparam         AER_CAP_MULTIHEADER = "FALSE";
   localparam [11:0]  AER_CAP_NEXTPTR = 12'h000;
   localparam [23:0]  AER_CAP_OPTIONAL_ERR_SUPPORT = 24'h000000;
   // localparam         AER_CAP_ON = "FALSE";
   localparam         AER_CAP_PERMIT_ROOTERR_UPDATE = "FALSE";

   // localparam [31:0]  BAR0 = 32'hFFF00004;
   // localparam [31:0]  BAR1 = 32'hFFFFFFFF;
   // localparam [31:0]  BAR2 = 32'hFF000004;
   // localparam [31:0]  BAR3 = 32'hFFFFFFFF;
   // localparam [31:0]  BAR4 = 32'hFFFFF800;
   // localparam [31:0]  BAR5 = 32'hFFFFF800;

   // localparam         C_DATA_WIDTH = 64;
   localparam [31:0]  CARDBUS_CIS_POINTER = 32'h00000000;
   // localparam [23:0]  CLASS_CODE = 24'h050000;
   localparam         CMD_INTX_IMPLEMENTED = "TRUE";
   localparam         CPL_TIMEOUT_DISABLE_SUPPORTED = "FALSE";
   localparam [3:0]   CPL_TIMEOUT_RANGES_SUPPORTED = 4'h2;

   localparam integer DEV_CAP_ENDPOINT_L0S_LATENCY = 0;
   localparam integer  DEV_CAP_ENDPOINT_L1_LATENCY = 7;
   localparam         DEV_CAP_EXT_TAG_SUPPORTED = "FALSE";
   localparam integer   DEV_CAP_MAX_PAYLOAD_SUPPORTED = 2;
   localparam integer 	DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT = 0;

   localparam         DEV_CAP2_ARI_FORWARDING_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_ATOMICOP32_COMPLETER_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_ATOMICOP64_COMPLETER_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_ATOMICOP_ROUTING_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_CAS128_COMPLETER_SUPPORTED = "FALSE";
   localparam [1:0]   DEV_CAP2_TPH_COMPLETER_SUPPORTED = 2'b00;
   localparam         DEV_CONTROL_EXT_TAG_DEFAULT = "FALSE";

   localparam         DISABLE_LANE_REVERSAL = "TRUE";
   localparam         DISABLE_RX_POISONED_RESP = "FALSE";
   localparam         DISABLE_SCRAMBLING = "FALSE";
   localparam [11:0]  DSN_BASE_PTR = 12'h100;
   // localparam [11:0]  DSN_CAP_NEXTPTR = 12'hffc;
   localparam         DSN_CAP_ON = "TRUE";

   localparam [10:0]  ENABLE_MSG_ROUTE = 11'b00000000000;
   localparam         ENABLE_RX_TD_ECRC_TRIM = "TRUE";
   localparam [31:0]  EXPANSION_ROM = 32'h00000000;
   localparam [5:0]   EXT_CFG_CAP_PTR = 6'h3F;
   localparam [9:0]   EXT_CFG_XP_CAP_PTR = 10'h3FF;
   localparam [7:0]   HEADER_TYPE = 8'h00;
   localparam [7:0]   INTERRUPT_PIN = 8'h1;
   
   localparam [9:0]   LAST_CONFIG_DWORD = 10'h3FF;
   // localparam         LINK_CAP_ASPM_OPTIONALITY = "TRUE";
   localparam         LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP = "FALSE";
   localparam         LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP = "FALSE";
   localparam [3:0]   LINK_CAP_MAX_LINK_SPEED = 4'h1;
   // localparam [5:0]   LINK_CAP_MAX_LINK_WIDTH = 6'h8;

   localparam         LINK_CTRL2_DEEMPHASIS = "FALSE";
   localparam         LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE = "FALSE";
   localparam [3:0]   LINK_CTRL2_TARGET_LINK_SPEED = 4'h0;
   localparam         LINK_STATUS_SLOT_CLOCK_CONFIG = "TRUE";

   localparam [14:0]  LL_ACK_TIMEOUT = 15'h0000;
   localparam         LL_ACK_TIMEOUT_EN = "FALSE";
   localparam integer 	LL_ACK_TIMEOUT_FUNC = 0;
   // localparam [14:0]  LL_REPLAY_TIMEOUT = 15'h0000;
   // localparam         LL_REPLAY_TIMEOUT_EN = "FALSE";
   localparam integer 	LL_REPLAY_TIMEOUT_FUNC = 1;

   // localparam [5:0]   LTSSM_MAX_LINK_WIDTH = 6'h8;
   localparam         MSI_CAP_MULTIMSGCAP = 0;
   localparam         MSI_CAP_MULTIMSG_EXTENSION = 0;
   localparam         MSI_CAP_ON = "TRUE";
   localparam         MSI_CAP_PER_VECTOR_MASKING_CAPABLE = "FALSE";
   localparam         MSI_CAP_64_BIT_ADDR_CAPABLE = "TRUE";

   // localparam         MSIX_CAP_ON = "TRUE";
   localparam         MSIX_CAP_PBA_BIR = 0;
   // localparam [28:0]  MSIX_CAP_PBA_OFFSET = 29'ha00;
   localparam         MSIX_CAP_TABLE_BIR = 0;
   // localparam [28:0]  MSIX_CAP_TABLE_OFFSET = 29'h800;
   // localparam [10:0]  MSIX_CAP_TABLE_SIZE = 11'h003;

   localparam [3:0]   PCIE_CAP_DEVICE_PORT_TYPE = 4'h0;
   // localparam [7:0]   PCIE_CAP_NEXTPTR = 8'h9C;

   localparam         PM_CAP_DSI = "FALSE";
   localparam         PM_CAP_D1SUPPORT = "FALSE";
   localparam         PM_CAP_D2SUPPORT = "FALSE";
   localparam [7:0]   PM_CAP_NEXTPTR = 8'h48;
   localparam [4:0]   PM_CAP_PMESUPPORT = 5'h0F;
   localparam         PM_CSR_NOSOFTRST = "TRUE";

   localparam [1:0]   PM_DATA_SCALE0 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE1 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE2 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE3 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE4 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE5 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE6 = 2'h0;
   localparam [1:0]   PM_DATA_SCALE7 = 2'h0;

   localparam [7:0]   PM_DATA0 = 8'h00;
   localparam [7:0]   PM_DATA1 = 8'h00;
   localparam [7:0]   PM_DATA2 = 8'h00;
   localparam [7:0]   PM_DATA3 = 8'h00;
   localparam [7:0]   PM_DATA4 = 8'h00;
   localparam [7:0]   PM_DATA5 = 8'h00;
   localparam [7:0]   PM_DATA6 = 8'h00;
   localparam [7:0]   PM_DATA7 = 8'h00;

   localparam [11:0]  RBAR_BASE_PTR = 12'h000;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR0 = 5'h00;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR1 = 5'h00;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR2 = 5'h00;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR3 = 5'h00;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR4 = 5'h00;
   localparam [4:0]   RBAR_CAP_CONTROL_ENCODEDBAR5 = 5'h00;
   localparam [2:0]   RBAR_CAP_INDEX0 = 3'h0;
   localparam [2:0]   RBAR_CAP_INDEX1 = 3'h0;
   localparam [2:0]   RBAR_CAP_INDEX2 = 3'h0;
   localparam [2:0]   RBAR_CAP_INDEX3 = 3'h0;
   localparam [2:0]   RBAR_CAP_INDEX4 = 3'h0;
   localparam [2:0]   RBAR_CAP_INDEX5 = 3'h0;
   localparam         RBAR_CAP_ON = "FALSE";
   localparam [31:0]  RBAR_CAP_SUP0 = 32'h00001;
   localparam [31:0]  RBAR_CAP_SUP1 = 32'h00001;
   localparam [31:0]  RBAR_CAP_SUP2 = 32'h00001;
   localparam [31:0]  RBAR_CAP_SUP3 = 32'h00001;
   localparam [31:0]  RBAR_CAP_SUP4 = 32'h00001;
   localparam [31:0]  RBAR_CAP_SUP5 = 32'h00001;
   localparam [2:0]   RBAR_NUM = 3'h0;

   localparam         RECRC_CHK = 0;
   localparam         RECRC_CHK_TRIM = "FALSE";
   localparam         REF_CLK_FREQ = 0;     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
   localparam         REM_WIDTH  = (C_DATA_WIDTH == 128) ? 2 : 1;
   localparam         KEEP_WIDTH = C_DATA_WIDTH / 8;

   localparam         TL_RX_RAM_RADDR_LATENCY = 0;
   localparam         TL_RX_RAM_RDATA_LATENCY = 2;
   localparam         TL_RX_RAM_WRITE_LATENCY = 0;
   localparam         TL_TX_RAM_RADDR_LATENCY = 0;
   localparam         TL_TX_RAM_RDATA_LATENCY = 2;
   localparam         TL_TX_RAM_WRITE_LATENCY = 0;
   localparam         TRN_NP_FC = "TRUE";
   localparam         TRN_DW = "FALSE";

   localparam         UPCONFIG_CAPABLE = "TRUE";
   localparam         UPSTREAM_FACING = "TRUE";
   localparam         UR_ATOMIC = "FALSE";
   localparam         UR_INV_REQ = "TRUE";
   localparam         UR_PRS_RESPONSE = "TRUE";
   // localparam         USER_CLK_FREQ = 3;
   // localparam         USER_CLK2_DIV2 = "FALSE";

   localparam [11:0]  VC_BASE_PTR = 12'h000;
   localparam [11:0]  VC_CAP_NEXTPTR = 12'h000;
   localparam         VC_CAP_ON = "FALSE";
   localparam         VC_CAP_REJECT_SNOOP_TRANSACTIONS = "FALSE";

   localparam         VC0_CPL_INFINITE = "TRUE";
   localparam [12:0]  VC0_RX_RAM_LIMIT = 13'h7FF;
   localparam         VC0_TOTAL_CREDITS_CD = 461;
   localparam         VC0_TOTAL_CREDITS_CH = 36;
   localparam         VC0_TOTAL_CREDITS_NPH = 12;
   localparam         VC0_TOTAL_CREDITS_NPD = 24;
   localparam         VC0_TOTAL_CREDITS_PD = 437;
   localparam         VC0_TOTAL_CREDITS_PH = 32;
   localparam         VC0_TX_LASTPACKET = 29;

   localparam [11:0]  VSEC_BASE_PTR = 12'h000;
   localparam [11:0]  VSEC_CAP_NEXTPTR = 12'h000;
   localparam         VSEC_CAP_ON = "FALSE";

   localparam         DISABLE_ASPM_L1_TIMER = "FALSE";
   localparam         DISABLE_BAR_FILTERING = "FALSE";
   localparam         DISABLE_ID_CHECK = "FALSE";
   localparam         DISABLE_RX_TC_FILTER = "FALSE";
   localparam [7:0]   DNSTREAM_LINK_NUM = 8'h00;

   localparam [15:0]  DSN_CAP_ID = 16'h0003;
   localparam [3:0]   DSN_CAP_VERSION = 4'h1;
   localparam         ENTER_RVRY_EI_L0 = "TRUE";
   localparam [4:0]   INFER_EI = 5'h00;
   localparam         IS_SWITCH = "FALSE";

   // localparam         LINK_CAP_ASPM_SUPPORT = 1;
   localparam         LINK_CAP_CLOCK_POWER_MANAGEMENT = "FALSE";
   localparam         LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1 = 7;
   localparam         LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2 = 7;
   localparam         LINK_CAP_L0S_EXIT_LATENCY_GEN1 = 7;
   localparam         LINK_CAP_L0S_EXIT_LATENCY_GEN2 = 7;
   localparam         LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1 = 7;
   localparam         LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2 = 7;
   localparam         LINK_CAP_L1_EXIT_LATENCY_GEN1 = 7;
   localparam         LINK_CAP_L1_EXIT_LATENCY_GEN2 = 7;
   localparam         LINK_CAP_RSVD_23 = 0;
   localparam         LINK_CONTROL_RCB = 0;

   localparam [7:0]   MSI_BASE_PTR = 8'h48;
   localparam [7:0]   MSI_CAP_ID = 8'h05;
   localparam [7:0]   MSI_CAP_NEXTPTR = 8'h60;
   localparam [7:0]   MSIX_BASE_PTR = 8'h9C;
   localparam [7:0]   MSIX_CAP_ID = 8'h11;
   localparam [7:0]   MSIX_CAP_NEXTPTR =8'h00;

   localparam         N_FTS_COMCLK_GEN1 = 255;
   localparam         N_FTS_COMCLK_GEN2 = 255;
   localparam         N_FTS_GEN1 = 255;
   localparam         N_FTS_GEN2 = 255;

   localparam [7:0]   PCIE_BASE_PTR = 8'h60;
   localparam [7:0]   PCIE_CAP_CAPABILITY_ID = 8'h10;
   localparam [3:0]   PCIE_CAP_CAPABILITY_VERSION = 4'h2;
   localparam         PCIE_CAP_ON = "TRUE";
   localparam         PCIE_CAP_RSVD_15_14 = 0;
   localparam         PCIE_CAP_SLOT_IMPLEMENTED = "FALSE";
   localparam         PCIE_REVISION = 2;

   localparam         PL_AUTO_CONFIG = 0;
   // localparam         PL_FAST_TRAIN = "FALSE";
   // localparam         PCIE_EXT_CLK = "TRUE";

   localparam [7:0]   PM_BASE_PTR = 8'h40;
   localparam         PM_CAP_AUXCURRENT = 0;
   localparam [7:0]   PM_CAP_ID = 8'h01;
   localparam         PM_CAP_ON = "TRUE";
   localparam         PM_CAP_PME_CLOCK = "FALSE";
   localparam         PM_CAP_RSVD_04 = 0;
   localparam         PM_CAP_VERSION = 3;
   localparam         PM_CSR_BPCCEN = "FALSE";
   localparam         PM_CSR_B2B3 = "FALSE";

   localparam         ROOT_CAP_CRS_SW_VISIBILITY = "FALSE";
   localparam         SELECT_DLL_IF = "FALSE";
   localparam         SLOT_CAP_ATT_BUTTON_PRESENT = "FALSE";
   localparam         SLOT_CAP_ATT_INDICATOR_PRESENT = "FALSE";
   localparam         SLOT_CAP_ELEC_INTERLOCK_PRESENT = "FALSE";
   localparam         SLOT_CAP_HOTPLUG_CAPABLE = "FALSE";
   localparam         SLOT_CAP_HOTPLUG_SURPRISE = "FALSE";
   localparam         SLOT_CAP_MRL_SENSOR_PRESENT = "FALSE";
   localparam         SLOT_CAP_NO_CMD_COMPLETED_SUPPORT = "FALSE";
   localparam [12:0]  SLOT_CAP_PHYSICAL_SLOT_NUM = 13'h0000;
   localparam         SLOT_CAP_POWER_CONTROLLER_PRESENT = "FALSE";
   localparam         SLOT_CAP_POWER_INDICATOR_PRESENT = "FALSE";
   localparam         SLOT_CAP_SLOT_POWER_LIMIT_SCALE = 0;
   localparam [7:0]   SLOT_CAP_SLOT_POWER_LIMIT_VALUE = 8'h00;

   localparam integer 	SPARE_BIT0 = 0;

   localparam integer 	SPARE_BIT1 = 0;
   localparam integer 	SPARE_BIT2 = 0;
   localparam integer 	SPARE_BIT3 = 0;
   localparam integer 	SPARE_BIT4 = 0;
   localparam integer 	SPARE_BIT5 = 0;
   localparam integer 	SPARE_BIT6 = 0;
   localparam integer 	SPARE_BIT7 = 0;
   localparam integer 	SPARE_BIT8 = 0;
   localparam [7:0]   SPARE_BYTE0 = 8'h00;
   localparam [7:0]   SPARE_BYTE1 = 8'h00;
   localparam [7:0]   SPARE_BYTE2 = 8'h00;
   localparam [7:0]   SPARE_BYTE3 = 8'h00;
   localparam [31:0]  SPARE_WORD0 = 32'h00000000;
   localparam [31:0]  SPARE_WORD1 = 32'h00000000;
   localparam [31:0]  SPARE_WORD2 = 32'h00000000;
   localparam [31:0]  SPARE_WORD3 = 32'h00000000;

   localparam         TL_RBYPASS = "FALSE";
   localparam         TL_TFC_DISABLE = "FALSE";
   localparam         TL_TX_CHECKS_DISABLE = "FALSE";
   localparam         EXIT_LOOPBACK_ON_EI = "TRUE";

   localparam         CFG_ECRC_ERR_CPLSTAT = 0;
   localparam [7:0]   CAPABILITIES_PTR = 8'h40;
   localparam [6:0]   CRM_MODULE_RSTS = 7'h00;
   localparam         DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE = "TRUE";
   localparam         DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE = "TRUE";
   localparam         DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE = "FALSE";
   localparam         DEV_CAP_ROLE_BASED_ERROR = "TRUE";
   localparam         DEV_CAP_RSVD_14_12 = 0;
   localparam         DEV_CAP_RSVD_17_16 = 0;
   localparam         DEV_CAP_RSVD_31_29 = 0;
   localparam         DEV_CONTROL_AUX_POWER_SUPPORTED = "FALSE";

   localparam [15:0]  VC_CAP_ID = 16'h0002;
   localparam [3:0]   VC_CAP_VERSION = 4'h1;
   localparam [15:0]  VSEC_CAP_HDR_ID = 16'h1234;
   localparam [11:0]  VSEC_CAP_HDR_LENGTH = 12'h018;
   localparam [3:0]   VSEC_CAP_HDR_REVISION = 4'h1;
   localparam [15:0]  VSEC_CAP_ID = 16'h000B;
   localparam         VSEC_CAP_IS_LINK_VISIBLE = "TRUE";
   localparam [3:0]   VSEC_CAP_VERSION = 4'h1;

   localparam         DISABLE_ERR_MSG = "FALSE";
   localparam         DISABLE_LOCKED_FILTER = "FALSE";
   localparam         DISABLE_PPM_FILTER = "FALSE";
   localparam         ENDEND_TLP_PREFIX_FORWARDING_SUPPORTED = "FALSE";
   localparam         INTERRUPT_STAT_AUTO = "TRUE";
   localparam         MPS_FORCE = "FALSE";
   localparam [14:0]  PM_ASPML0S_TIMEOUT = 15'h0000;
   localparam         PM_ASPML0S_TIMEOUT_EN = "FALSE";
   localparam         PM_ASPML0S_TIMEOUT_FUNC = 0;
   localparam         PM_ASPM_FASTEXIT = "FALSE";
   localparam         PM_MF = "FALSE";

   localparam [1:0]   RP_AUTO_SPD = 2'h1;
   localparam [4:0]   RP_AUTO_SPD_LOOPCNT = 5'h1f;
   localparam         SIM_VERSION = "1.0";
   localparam         SSL_MESSAGE_AUTO = "FALSE";
   localparam         TECRC_EP_INV = "FALSE";
   localparam         UR_CFG1 = "TRUE";
   localparam         USE_RID_PINS = "FALSE";

// New Parameters
   localparam         DEV_CAP2_ENDEND_TLP_PREFIX_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_EXTENDED_FMT_FIELD_SUPPORTED = "FALSE";
   localparam         DEV_CAP2_LTR_MECHANISM_SUPPORTED = "FALSE";
   localparam [1:0]   DEV_CAP2_MAX_ENDEND_TLP_PREFIXES = 2'h0;
   localparam         DEV_CAP2_NO_RO_ENABLED_PRPR_PASSING = "FALSE";

   localparam         LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE = "FALSE";

   localparam [15:0]  AER_CAP_ID = 16'h0001;
   localparam [3:0]   AER_CAP_VERSION = 4'h1;

   localparam [15:0]  RBAR_CAP_ID = 16'h0015;
   localparam [11:0]  RBAR_CAP_NEXTPTR = 12'h000;
   localparam [3:0]   RBAR_CAP_VERSION = 4'h1;
   localparam         PCIE_USE_MODE = "3.0";
   localparam         PCIE_GT_DEVICE = "GTX";
   localparam         PCIE_CHAN_BOND = 0;
   localparam         PCIE_PLL_SEL   = "CPLL";
   localparam         PCIE_ASYNC_EN  = "FALSE";
   localparam         PCIE_TXBUF_EN  = "FALSE";
   

      //------------------------------------------------//
      // RP Only                                        //
      //------------------------------------------------//
   wire cfg_pm_send_pme_to = 1'b0 ;
   wire [7:0] cfg_ds_bus_number = 8'b0 ;
   wire [4:0] cfg_ds_device_number = 5'b0 ;
   wire [2:0] cfg_ds_function_number = 3'b0 ;
   wire cfg_mgmt_wr_rw1c_as_rw = 1'b0 ;
   wire cfg_msg_received ; // not connected
   wire [15:0] cfg_msg_data ; // not connected
   
   wire cfg_bridge_serr_en ; // not connected
   wire cfg_slot_control_electromech_il_ctl_pulse ; // not connected
   wire cfg_root_control_syserr_corr_err_en ; // not connected
   wire cfg_root_control_syserr_non_fatal_err_en ; // not connected
   wire cfg_root_control_syserr_fatal_err_en ; // not connected
   wire cfg_root_control_pme_int_en ; // not connected
   wire cfg_aer_rooterr_corr_err_reporting_en ; // not connected
   wire cfg_aer_rooterr_non_fatal_err_reporting_en ; // not connected
   wire cfg_aer_rooterr_fatal_err_reporting_en ; // not connected
   wire cfg_aer_rooterr_corr_err_received ; // not connected
   wire cfg_aer_rooterr_non_fatal_err_received ; // not connected
   wire cfg_aer_rooterr_fatal_err_received ; // not connected
   
   wire cfg_msg_received_err_cor ; // not connected
   wire cfg_msg_received_err_non_fatal ; // not connected
   wire cfg_msg_received_err_fatal ; // not connected
   wire cfg_msg_received_pm_as_nak ; // not connected
   wire cfg_msg_received_pme_to_ack ; // not connected
   wire cfg_msg_received_pm_pme; // not connected
   wire cfg_msg_received_setslotpowerlimit; // not connected
   wire cfg_msg_received_assert_int_a ; // not connected
   wire cfg_msg_received_assert_int_b ; // not connected
   wire cfg_msg_received_assert_int_c ; // not connected
   wire cfg_msg_received_assert_int_d ; // not connected
   wire cfg_msg_received_deassert_int_a ; // not connected
   wire cfg_msg_received_deassert_int_b ; // not connected
   wire cfg_msg_received_deassert_int_c ; // not connected
   wire cfg_msg_received_deassert_int_d ; // not connected
   wire pl_transmit_hot_rst = 1'b0 ;

   wire pl_downstream_deemph_source = 1'b0 ;

   wire sys_rst_n = sys_reset_n ;
   wire pipe_clk;


  wire                 user_clk;
  wire                 user_clk2;

  wire [15:0]          cfg_vend_id        = CFG_VEND_ID;
  wire [15:0]          cfg_dev_id         = CFG_DEV_ID;
  wire [7:0]           cfg_rev_id         = CFG_REV_ID;
  wire [15:0]          cfg_subsys_vend_id = CFG_SUBSYS_VEND_ID;
  wire [15:0]          cfg_subsys_id      = CFG_SUBSYS_ID;

  // PIPE Interface Wires
  wire                 phy_rdy_n;
  wire                 pipe_rx0_polarity_gt;
  wire                 pipe_rx1_polarity_gt;
  wire                 pipe_rx2_polarity_gt;
  wire                 pipe_rx3_polarity_gt;
  wire                 pipe_rx4_polarity_gt;
  wire                 pipe_rx5_polarity_gt;
  wire                 pipe_rx6_polarity_gt;
  wire                 pipe_rx7_polarity_gt;
  wire                 pipe_tx_deemph_gt;
  wire [2:0]           pipe_tx_margin_gt;
  wire                 pipe_tx_rate_gt;
  wire                 pipe_tx_rcvr_det_gt;
  wire [1:0]           pipe_tx0_char_is_k_gt;
  wire                 pipe_tx0_compliance_gt;
  wire [15:0]          pipe_tx0_data_gt;
  wire                 pipe_tx0_elec_idle_gt;
  wire [1:0]           pipe_tx0_powerdown_gt;
  wire [1:0]           pipe_tx1_char_is_k_gt;
  wire                 pipe_tx1_compliance_gt;
  wire [15:0]          pipe_tx1_data_gt;
  wire                 pipe_tx1_elec_idle_gt;
  wire [1:0]           pipe_tx1_powerdown_gt;
  wire [1:0]           pipe_tx2_char_is_k_gt;
  wire                 pipe_tx2_compliance_gt;
  wire [15:0]          pipe_tx2_data_gt;
  wire                 pipe_tx2_elec_idle_gt;
  wire [1:0]           pipe_tx2_powerdown_gt;
  wire [1:0]           pipe_tx3_char_is_k_gt;
  wire                 pipe_tx3_compliance_gt;
  wire [15:0]          pipe_tx3_data_gt;
  wire                 pipe_tx3_elec_idle_gt;
  wire [1:0]           pipe_tx3_powerdown_gt;
  wire [1:0]           pipe_tx4_char_is_k_gt;
  wire                 pipe_tx4_compliance_gt;
  wire [15:0]          pipe_tx4_data_gt;
  wire                 pipe_tx4_elec_idle_gt;
  wire [1:0]           pipe_tx4_powerdown_gt;
  wire [1:0]           pipe_tx5_char_is_k_gt;
  wire                 pipe_tx5_compliance_gt;
  wire [15:0]          pipe_tx5_data_gt;
  wire                 pipe_tx5_elec_idle_gt;
  wire [1:0]           pipe_tx5_powerdown_gt;
  wire [1:0]           pipe_tx6_char_is_k_gt;
  wire                 pipe_tx6_compliance_gt;
  wire [15:0]          pipe_tx6_data_gt;
  wire                 pipe_tx6_elec_idle_gt;
  wire [1:0]           pipe_tx6_powerdown_gt;
  wire [1:0]           pipe_tx7_char_is_k_gt;
  wire                 pipe_tx7_compliance_gt;
  wire [15:0]          pipe_tx7_data_gt;
  wire                 pipe_tx7_elec_idle_gt;
  wire [1:0]           pipe_tx7_powerdown_gt;

  wire                 pipe_rx0_chanisaligned_gt;
  wire  [1:0]          pipe_rx0_char_is_k_gt;
  wire  [15:0]         pipe_rx0_data_gt;
  wire                 pipe_rx0_elec_idle_gt;
  wire                 pipe_rx0_phy_status_gt;
  wire  [2:0]          pipe_rx0_status_gt;
  wire                 pipe_rx0_valid_gt;
  wire                 pipe_rx1_chanisaligned_gt;
  wire  [1:0]          pipe_rx1_char_is_k_gt;
  wire  [15:0]         pipe_rx1_data_gt;
  wire                 pipe_rx1_elec_idle_gt;
  wire                 pipe_rx1_phy_status_gt;
  wire  [2:0]          pipe_rx1_status_gt;
  wire                 pipe_rx1_valid_gt;
  wire                 pipe_rx2_chanisaligned_gt;
  wire  [1:0]          pipe_rx2_char_is_k_gt;
  wire  [15:0]         pipe_rx2_data_gt;
  wire                 pipe_rx2_elec_idle_gt;
  wire                 pipe_rx2_phy_status_gt;
  wire  [2:0]          pipe_rx2_status_gt;
  wire                 pipe_rx2_valid_gt;
  wire                 pipe_rx3_chanisaligned_gt;
  wire  [1:0]          pipe_rx3_char_is_k_gt;
  wire  [15:0]         pipe_rx3_data_gt;
  wire                 pipe_rx3_elec_idle_gt;
  wire                 pipe_rx3_phy_status_gt;
  wire  [2:0]          pipe_rx3_status_gt;
  wire                 pipe_rx3_valid_gt;
  wire                 pipe_rx4_chanisaligned_gt;
  wire  [1:0]          pipe_rx4_char_is_k_gt;
  wire  [15:0]         pipe_rx4_data_gt;
  wire                 pipe_rx4_elec_idle_gt;
  wire                 pipe_rx4_phy_status_gt;
  wire  [2:0]          pipe_rx4_status_gt;
  wire                 pipe_rx4_valid_gt;
  wire                 pipe_rx5_chanisaligned_gt;
  wire  [1:0]          pipe_rx5_char_is_k_gt;
  wire  [15:0]         pipe_rx5_data_gt;
  wire                 pipe_rx5_elec_idle_gt;
  wire                 pipe_rx5_phy_status_gt;
  wire  [2:0]          pipe_rx5_status_gt;
  wire                 pipe_rx5_valid_gt;
  wire                 pipe_rx6_chanisaligned_gt;
  wire  [1:0]          pipe_rx6_char_is_k_gt;
  wire  [15:0]         pipe_rx6_data_gt;
  wire                 pipe_rx6_elec_idle_gt;
  wire                 pipe_rx6_phy_status_gt;
  wire  [2:0]          pipe_rx6_status_gt;
  wire                 pipe_rx6_valid_gt;
  wire                 pipe_rx7_chanisaligned_gt;
  wire  [1:0]          pipe_rx7_char_is_k_gt;
  wire  [15:0]         pipe_rx7_data_gt;
  wire                 pipe_rx7_elec_idle_gt;
  wire                 pipe_rx7_phy_status_gt;
  wire  [2:0]          pipe_rx7_status_gt;
  wire                 pipe_rx7_valid_gt;

  reg                  user_lnk_up_int;
  reg                  user_reset_int;

  reg                  bridge_reset_int;
  reg                  bridge_reset_d;
  wire                 user_rst_n;
  reg                  pl_received_hot_rst_q;
  wire                 pl_received_hot_rst_wire;
  reg                  pl_phy_lnk_up_q;
  wire                 pl_phy_lnk_up_wire;
  wire                 sys_or_hot_rst;
  wire                 trn_lnk_up;

  wire [5:0]           pl_ltssm_state_int;
  wire                 user_app_rdy_req;
  wire                 sys_rst_n_int    = sys_rst_n;
  wire                 mmcm_lock_int    = pipe_mmcm_lock_in;
  reg                  user_lnk_up_mux;

  localparam        TCQ = 100;
  localparam        ENABLE_FAST_SIM_TRAINING   = "TRUE";


  assign user_lnk_up = user_lnk_up_int;



  assign user_app_rdy = 1'b1;
  assign pl_ltssm_state = pl_ltssm_state_int;
  assign pl_phy_lnk_up = pl_phy_lnk_up_q;
  assign pl_received_hot_rst = pl_received_hot_rst_q;

  // Register block outputs pl_received_hot_rst and phy_lnk_up to ease timing on block output
  assign sys_or_hot_rst = !sys_rst_n_int || pl_received_hot_rst_q;
  always @(posedge user_clk_out)
  begin
    if (!sys_rst_n_int) begin
      pl_received_hot_rst_q <= #TCQ 1'b0;
      pl_phy_lnk_up_q       <= #TCQ 1'b0;
    end else begin
      pl_received_hot_rst_q <= #TCQ pl_received_hot_rst_wire;
      pl_phy_lnk_up_q       <= #TCQ pl_phy_lnk_up_wire;
    end
  end
  // Generate user_lnk_up_mux
  always @(posedge user_clk_out)
  begin
    if (!sys_rst_n_int) begin
      user_lnk_up_mux <= #TCQ 1'b0;
    end else begin
      user_lnk_up_mux <= #TCQ user_lnk_up_int;
    end
  end

  always @(posedge user_clk_out)
  begin
    if (!sys_rst_n_int) begin
      user_lnk_up_int <= #TCQ 1'b0;
    end else begin
      user_lnk_up_int <= #TCQ trn_lnk_up;
    end
  end


  // Generate user_reset_out                                                                                          //
  // Once user reset output of PCIE and Phy Layer is active, de-assert reset                                          //
  // Only assert reset if system reset or hot reset is seen.  Keep AXI backend/user application alive otherwise       //
  //------------------------------------------------------------------------------------------------------------------//

 always @(posedge user_clk_out or posedge sys_or_hot_rst)
  begin
    if (sys_or_hot_rst) begin
      user_reset_int <= #TCQ 1'b1;
    end else if (user_rst_n && pl_phy_lnk_up_q) begin
      user_reset_int <= #TCQ 1'b0;
    end
  end

  // Invert active low reset to active high AXI reset
  always @(posedge user_clk_out or posedge sys_or_hot_rst)
  begin
    if (sys_or_hot_rst) begin
      user_reset_out <= #TCQ 1'b1;
    end else begin
      user_reset_out <= #TCQ user_reset_int;
    end
  end
  always @(posedge user_clk_out or posedge sys_or_hot_rst)
  begin
    if (sys_or_hot_rst) begin
      bridge_reset_int <= #TCQ 1'b1;
    end else if (user_rst_n && pl_phy_lnk_up_q) begin
      bridge_reset_int <= #TCQ 1'b0;
    end
  end

  // Invert active low reset to active high AXI reset
  always @(posedge user_clk_out or posedge sys_or_hot_rst)
  begin
    if (sys_or_hot_rst) begin
      bridge_reset_d <= #TCQ 1'b1;
    end else begin
      bridge_reset_d <= #TCQ bridge_reset_int;
    end
  end

  //------------------------------------------------------------------------------------------------------------------//
  // **** PCI Express Core Wrapper ****                                                                               //
  // The PCI Express Core Wrapper includes the following:                                                             //
  //   1) AXI Streaming Bridge                                                                                        //
  //   2) PCIE 2_1 Hard Block                                                                                         //
  //   3) PCIE PIPE Interface Pipeline                                                                                //
  //------------------------------------------------------------------------------------------------------------------//
//begin pcie_7x_0_pcie_top {

   //.PL_FAST_TRAIN                            ( ENABLE_FAST_SIM_TRAINING ),
   // pcie_top_i

   wire user_reset                                 = bridge_reset_d;
   wire cm_rst_n                                   = 1'b1;
   wire func_lvl_rst_n                             = 1'b1;
   wire lnk_clk_en;
   wire cfg_command_bus_master_enable;
   wire cfg_command_interrupt_disable;
   wire cfg_command_io_enable;
   wire cfg_command_mem_enable;
   wire cfg_command_serr_en;
   wire cfg_dev_control_aux_power_en;
   wire cfg_dev_control_corr_err_reporting_en;
   wire cfg_dev_control_enable_ro;
   wire cfg_dev_control_ext_tag_en;
   wire cfg_dev_control_fatal_err_reporting_en;
   wire [2:0] cfg_dev_control_max_payload;
   wire [2:0] cfg_dev_control_max_read_req;
   wire       cfg_dev_control_non_fatal_reporting_en;
   wire       cfg_dev_control_no_snoop_en;
   wire       cfg_dev_control_phantom_en;
   wire       cfg_dev_control_ur_err_reporting_en;
   wire       cfg_dev_control2_cpl_timeout_dis;
   wire [3:0] cfg_dev_control2_cpl_timeout_val;
   wire       cfg_dev_control2_ari_forward_en;
   wire       cfg_dev_control2_atomic_requester_en;
   wire       cfg_dev_control2_atomic_egress_block;
   wire       cfg_dev_control2_ido_req_en;
   wire       cfg_dev_control2_ido_cpl_en;
   wire       cfg_dev_control2_ltr_en;
   wire       cfg_dev_control2_tlp_prefix_block;
   wire       cfg_dev_status_corr_err_detected;
   wire       cfg_dev_status_fatal_err_detected;
   wire       cfg_dev_status_non_fatal_err_detected;
   wire       cfg_dev_status_ur_detected;
   wire       cfg_link_control_rcb;
   wire [1:0] cfg_link_control_aspm_control;
   wire       cfg_link_control_auto_bandwidth_int_en;
   wire       cfg_link_control_bandwidth_int_en;
   wire       cfg_link_control_clock_pm_en;
   wire       cfg_link_control_common_clock;
   wire       cfg_link_control_extended_sync;
   wire       cfg_link_control_hw_auto_width_dis;
   wire       cfg_link_control_link_disable;
   wire       cfg_link_control_retrain_link;
   wire       cfg_link_status_auto_bandwidth_status;
   wire       cfg_link_status_bandwidth_status;
   wire [1:0] cfg_link_status_current_speed;
   wire       cfg_link_status_dll_active;
   wire       cfg_link_status_link_training;
   wire [3:0] cfg_link_status_negotiated_width;
   wire       cfg_msg_received_pme_to;
   wire       cfg_msg_received_unlock;
   wire       cfg_pm_rcv_as_req_l1_n;
   wire       cfg_pm_rcv_enter_l1_n;
   wire       cfg_pm_rcv_enter_l23_n;
   wire       cfg_pm_rcv_req_ack_n;
   wire       cfg_transaction;
   wire [6:0] cfg_transaction_addr;
   wire       cfg_transaction_type;
   wire [3:0] cfg_mgmt_byte_en_n                         = ~cfg_mgmt_byte_en;
   wire       cfg_err_acs_n                              = 1'b1;
   wire       cfg_err_cor_n                              = ~cfg_err_cor;
   wire       cfg_err_cpl_abort_n                        = ~cfg_err_cpl_abort;
   wire       cfg_err_cpl_timeout_n                      = ~cfg_err_cpl_timeout;
   wire       cfg_err_cpl_unexpect_n                     = ~cfg_err_cpl_unexpect;
   wire       cfg_err_ecrc_n                             = ~cfg_err_ecrc;
   wire       cfg_err_locked_n                           = ~cfg_err_locked;
   wire       cfg_err_posted_n                           = ~cfg_err_posted;
   wire       cfg_err_ur_n                               = ~cfg_err_ur;
   wire       cfg_err_malformed_n                        = ~cfg_err_malformed;
   wire       cfg_err_poisoned_n                         = ~cfg_err_poisoned;
   wire       cfg_err_atomic_egress_blocked_n            = ~cfg_err_atomic_egress_blocked;
   wire       cfg_err_mc_blocked_n                       = ~cfg_err_mc_blocked;
   wire       cfg_err_internal_uncor_n                   = ~cfg_err_internal_uncor;
   wire       cfg_err_internal_cor_n                     = ~cfg_err_internal_cor;
   wire       cfg_err_norecovery_n                       = ~cfg_err_norecovery;

   wire       cfg_interrupt_assert_n                     = ~cfg_interrupt_assert;
   wire       cfg_interrupt_n                            = ~cfg_interrupt;
   wire       cfg_interrupt_stat_n                       = ~cfg_interrupt_stat;
   wire       cfg_pm_send_pme_to_n                       = 1'b1;
   wire       cfg_pm_wake_n                              = ~cfg_pm_wake;
   wire       cfg_pm_halt_aspm_l0s_n                     = ~cfg_pm_halt_aspm_l0s;
   wire       cfg_pm_halt_aspm_l1_n                      = ~cfg_pm_halt_aspm_l1;
   wire       cfg_pm_force_state_en_n                    = ~cfg_pm_force_state_en;
   wire [2:0] cfg_force_mps                        = 3'b0;
   wire       cfg_force_common_clock_off                 = 1'b0;
   wire       cfg_force_extended_sync_on                 = 1'b0;
   wire [7:0] cfg_port_number                      = 8'b0;
   wire       cfg_mgmt_rd_en_n                           = ~cfg_mgmt_rd_en;
   wire       cfg_mgmt_wr_en_n                           = ~cfg_mgmt_wr_en;
   wire       cfg_mgmt_wr_readonly_n                     = ~cfg_mgmt_wr_readonly;
   wire       cfg_mgmt_wr_rw1c_as_rw_n                   = ~cfg_mgmt_wr_rw1c_as_rw;

   wire       pcie_top_pl_phy_lnk_up;
   assign     pl_phy_lnk_up_wire                         = pcie_top_pl_phy_lnk_up;
   wire       pcie_top_pl_received_hot_rst;
   assign     pl_received_hot_rst_wire = pcie_top_pl_received_hot_rst;
   wire       pl_directed_ltssm_new_vld                  = 1'b0;
   wire [5:0] pl_directed_ltssm_new                = 6'b0;
   wire       pl_directed_ltssm_stall                    = 1'b0;
   wire       dbg_sclr_a;
   wire       dbg_sclr_b;
   wire       dbg_sclr_c;
   wire       dbg_sclr_d;
   wire       dbg_sclr_e;
   wire       dbg_sclr_f;
   wire       dbg_sclr_g;
   wire       dbg_sclr_h;
   wire       dbg_sclr_i;
   wire       dbg_sclr_j;
   wire       dbg_sclr_k;
   wire [63:0] dbg_vec_a;
   wire [63:0] dbg_vec_b;
   wire [11:0] dbg_vec_c;
   wire [11:0] pl_dbg_vec;
   wire [63:0] trn_rdllp_data;
   wire [1:0]  trn_rdllp_src_rdy;
   wire [1:0]  dbg_mode                             = 2'b0;
   wire        dbg_sub_mode                               = 1'b0;
   wire [2:0]  pl_dbg_mode                          = 3'b0;

   wire        drp_clk                                    = 1'b0;
   wire [15:0] drp_do;
   wire        drp_rdy;
   wire [8:0]  drp_addr                             = 9'b0;
   wire        drp_en                                     = 1'b0;
   wire [15:0] drp_di                              = 16'b0;
   wire        drp_we                                     = 1'b0;
   wire        pipe_mmcm_rst_n                            = 1'b1;
   //wire declaration

  // TRN Interface
  wire [C_DATA_WIDTH-1:0]  trn_td;
  wire [REM_WIDTH-1:0]     trn_trem;
  wire                     trn_tsof;
  wire                     trn_teof;
  wire                     trn_tsrc_rdy;
  wire                     trn_tsrc_dsc;
  wire                     trn_terrfwd;
  wire                     trn_tecrc_gen;
  wire                     trn_tstr;
  wire                     trn_tcfg_gnt;
  wire 		           trn_tdst_rdy;
  wire                     trn_recrc_err;

  wire [C_DATA_WIDTH-1:0]  trn_rd;
  wire [REM_WIDTH-1:0]     trn_rrem;
  reg                      trn_rdst_rdy;
  wire                     trn_rsof;
  wire                     trn_reof;
  wire                     trn_rsrc_rdy;
  wire                     trn_rsrc_dsc;
  wire                     trn_rerrfwd;
  wire [7:0]               trn_rbar_hit;

  wire                 sys_reset_n_d;
  wire [1:0]           pipe_rx0_char_is_k;
  wire [1:0]           pipe_rx1_char_is_k;
  wire [1:0]           pipe_rx2_char_is_k;
  wire [1:0]           pipe_rx3_char_is_k;
  wire [1:0]           pipe_rx4_char_is_k;
  wire [1:0]           pipe_rx5_char_is_k;
  wire [1:0]           pipe_rx6_char_is_k;
  wire [1:0]           pipe_rx7_char_is_k;
  wire                 pipe_rx0_valid;
  wire                 pipe_rx1_valid;
  wire                 pipe_rx2_valid;
  wire                 pipe_rx3_valid;
  wire                 pipe_rx4_valid;
  wire                 pipe_rx5_valid;
  wire                 pipe_rx6_valid;
  wire                 pipe_rx7_valid;
  wire [15:0]          pipe_rx0_data;
  wire [15:0]          pipe_rx1_data;
  wire [15:0]          pipe_rx2_data;
  wire [15:0]          pipe_rx3_data;
  wire [15:0]          pipe_rx4_data;
  wire [15:0]          pipe_rx5_data;
  wire [15:0]          pipe_rx6_data;
  wire [15:0]          pipe_rx7_data;
  wire                 pipe_rx0_chanisaligned;
  wire                 pipe_rx1_chanisaligned;
  wire                 pipe_rx2_chanisaligned;
  wire                 pipe_rx3_chanisaligned;
  wire                 pipe_rx4_chanisaligned;
  wire                 pipe_rx5_chanisaligned;
  wire                 pipe_rx6_chanisaligned;
  wire                 pipe_rx7_chanisaligned;
  wire [2:0]           pipe_rx0_status;
  wire [2:0]           pipe_rx1_status;
  wire [2:0]           pipe_rx2_status;
  wire [2:0]           pipe_rx3_status;
  wire [2:0]           pipe_rx4_status;
  wire [2:0]           pipe_rx5_status;
  wire [2:0]           pipe_rx6_status;
  wire [2:0]           pipe_rx7_status;
  wire                 pipe_rx0_phy_status;
  wire                 pipe_rx1_phy_status;
  wire                 pipe_rx2_phy_status;
  wire                 pipe_rx3_phy_status;
  wire                 pipe_rx4_phy_status;
  wire                 pipe_rx5_phy_status;
  wire                 pipe_rx6_phy_status;
  wire                 pipe_rx7_phy_status;

  wire                 pipe_rx0_elec_idle;
  wire                 pipe_rx1_elec_idle;
  wire                 pipe_rx2_elec_idle;
  wire                 pipe_rx3_elec_idle;
  wire                 pipe_rx4_elec_idle;
  wire                 pipe_rx5_elec_idle;
  wire                 pipe_rx6_elec_idle;
  wire                 pipe_rx7_elec_idle;


  wire                 pipe_tx_reset;
  wire                 pipe_tx_rate;
  wire                 pipe_tx_deemph;
  wire [2:0]           pipe_tx_margin;
  wire                 pipe_rx0_polarity;
  wire                 pipe_rx1_polarity;
  wire                 pipe_rx2_polarity;
  wire                 pipe_rx3_polarity;
  wire                 pipe_rx4_polarity;
  wire                 pipe_rx5_polarity;
  wire                 pipe_rx6_polarity;
  wire                 pipe_rx7_polarity;
  wire                 pipe_tx0_compliance;
  wire                 pipe_tx1_compliance;
  wire                 pipe_tx2_compliance;
  wire                 pipe_tx3_compliance;
  wire                 pipe_tx4_compliance;
  wire                 pipe_tx5_compliance;
  wire                 pipe_tx6_compliance;
  wire                 pipe_tx7_compliance;
  wire [1:0]           pipe_tx0_char_is_k;
  wire [1:0]           pipe_tx1_char_is_k;
  wire [1:0]           pipe_tx2_char_is_k;
  wire [1:0]           pipe_tx3_char_is_k;
  wire [1:0]           pipe_tx4_char_is_k;
  wire [1:0]           pipe_tx5_char_is_k;
  wire [1:0]           pipe_tx6_char_is_k;
  wire [1:0]           pipe_tx7_char_is_k;
  wire [15:0]          pipe_tx0_data;
  wire [15:0]          pipe_tx1_data;
  wire [15:0]          pipe_tx2_data;
  wire [15:0]          pipe_tx3_data;
  wire [15:0]          pipe_tx4_data;
  wire [15:0]          pipe_tx5_data;
  wire [15:0]          pipe_tx6_data;
  wire [15:0]          pipe_tx7_data;
  wire                 pipe_tx0_elec_idle;
  wire                 pipe_tx1_elec_idle;
  wire                 pipe_tx2_elec_idle;
  wire                 pipe_tx3_elec_idle;
  wire                 pipe_tx4_elec_idle;
  wire                 pipe_tx5_elec_idle;
  wire                 pipe_tx6_elec_idle;
  wire                 pipe_tx7_elec_idle;
  wire [1:0]           pipe_tx0_powerdown;
  wire [1:0]           pipe_tx1_powerdown;
  wire [1:0]           pipe_tx2_powerdown;
  wire [1:0]           pipe_tx3_powerdown;
  wire [1:0]           pipe_tx4_powerdown;
  wire [1:0]           pipe_tx5_powerdown;
  wire [1:0]           pipe_tx6_powerdown;
  wire [1:0]           pipe_tx7_powerdown;

  wire                 cfg_received_func_lvl_rst_n;
  wire                 cfg_err_cpl_rdy_n;
  wire                 cfg_interrupt_rdy_n;
  reg [7:0]            cfg_bus_number_d;
  reg [4:0]            cfg_device_number_d;
  reg [2:0]            cfg_function_number_d;

  wire                 cfg_mgmt_rd_wr_done_n;
  wire                 pl_phy_lnk_up_n;
  wire                 cfg_err_aer_headerlog_set_n;
  wire                 cfg_turnoff_ok_w;
   wire 	       pipe_tx_rcvr_det;

  assign        cfg_received_func_lvl_rst = ~cfg_received_func_lvl_rst_n;

  assign        cfg_err_cpl_rdy = ~cfg_err_cpl_rdy_n;

  assign        cfg_interrupt_rdy = ~cfg_interrupt_rdy_n;

  assign        cfg_mgmt_rd_wr_done = ~cfg_mgmt_rd_wr_done_n;

  assign        pcie_top_pl_phy_lnk_up = ~pl_phy_lnk_up_n;

  assign        cfg_err_aer_headerlog_set = ~cfg_err_aer_headerlog_set_n;

  assign        cfg_to_turnoff = cfg_msg_received_pme_to;

  assign        cfg_status   = {16'b0};

  assign        cfg_command  = {5'b0,
                                cfg_command_interrupt_disable,
                                1'b0,
                                cfg_command_serr_en,
                                5'b0,
                                cfg_command_bus_master_enable,
                                cfg_command_mem_enable,
                                cfg_command_io_enable};

  assign        cfg_dstatus  = {10'h0,
                                cfg_trn_pending,
                                1'b0,
                                cfg_dev_status_ur_detected,
                                cfg_dev_status_fatal_err_detected,
                                cfg_dev_status_non_fatal_err_detected,
                                cfg_dev_status_corr_err_detected};

  assign        cfg_dcommand = {1'b0,
                                cfg_dev_control_max_read_req,
                                cfg_dev_control_no_snoop_en,
                                cfg_dev_control_aux_power_en,
                                cfg_dev_control_phantom_en,
                                cfg_dev_control_ext_tag_en,
                                cfg_dev_control_max_payload,
                                cfg_dev_control_enable_ro,
                                cfg_dev_control_ur_err_reporting_en,
                                cfg_dev_control_fatal_err_reporting_en,
                                cfg_dev_control_non_fatal_reporting_en,
                                cfg_dev_control_corr_err_reporting_en };

  assign        cfg_lstatus  = {cfg_link_status_auto_bandwidth_status,
                                cfg_link_status_bandwidth_status,
                                cfg_link_status_dll_active,
                                (LINK_STATUS_SLOT_CLOCK_CONFIG == "TRUE") ? 1'b1 : 1'b0,
                                cfg_link_status_link_training,
                                1'b0,
                                {2'b00, cfg_link_status_negotiated_width},
                                {2'b00, cfg_link_status_current_speed} };

  assign        cfg_lcommand = {4'b0,
                                cfg_link_control_auto_bandwidth_int_en,
                                cfg_link_control_bandwidth_int_en,
                                cfg_link_control_hw_auto_width_dis,
                                cfg_link_control_clock_pm_en,
                                cfg_link_control_extended_sync,
                                cfg_link_control_common_clock,
                                cfg_link_control_retrain_link,
                                cfg_link_control_link_disable,
                                cfg_link_control_rcb,
                                1'b0,
                                cfg_link_control_aspm_control};

  assign       cfg_bus_number = cfg_bus_number_d;

  assign       cfg_device_number = cfg_device_number_d;

  assign       cfg_function_number =  cfg_function_number_d;

  assign       cfg_dcommand2 = {4'b0,
                                cfg_dev_control2_tlp_prefix_block,
                                cfg_dev_control2_ltr_en,
                                cfg_dev_control2_ido_cpl_en,
                                cfg_dev_control2_ido_req_en,
                                cfg_dev_control2_atomic_egress_block,
                                cfg_dev_control2_atomic_requester_en,
                                cfg_dev_control2_ari_forward_en,
                                cfg_dev_control2_cpl_timeout_dis,
                                cfg_dev_control2_cpl_timeout_val};

  // Capture Bus/Device/Function number

  always @(posedge user_clk_out) begin
    if (~user_lnk_up)
    begin
      cfg_bus_number_d <= 8'b0;
    end // if (~user_lnk_up)
    else if (~cfg_msg_received)
    begin
      cfg_bus_number_d <= cfg_msg_data[15:8];
    end // if (~cfg_msg_received)
  end

  always @(posedge user_clk_out) begin
    if (~user_lnk_up)
    begin
      cfg_device_number_d <= 5'b0;
    end // if (~user_lnk_up)
    else if (~cfg_msg_received)
    begin
      cfg_device_number_d <= cfg_msg_data[7:3];
    end // if (~cfg_msg_received)
  end

  always @(posedge user_clk_out) begin
    if (~user_lnk_up)
    begin
      cfg_function_number_d <= 3'b0;
    end // if (~user_lnk_up)
    else if (~cfg_msg_received)
    begin
      cfg_function_number_d <= cfg_msg_data[2:0];
    end // if (~cfg_msg_received)
  end

//begin pcie_7x_0_axi_basic_top {
// axi_basic_top
   wire user_turnoff_ok      = cfg_turnoff_ok;               //  input
   wire  user_tcfg_gnt            =tx_cfg_gnt;               //  input
   wire [5:0] trn_tbuf_av = tx_buf_av;
   wire  trn_tcfg_req             = tx_cfg_req ;             //  input
   wire  axi_top_trn_lnk_up               = user_lnk_up;     //  input
   wire  axi_top_cfg_pm_send_pme_to       =1'b0;             //  input  NOT USED FOR EP
   wire  [31:0] axi_top_trn_rdllp_data    =32'b0;            //  input - Not used in 7-series
   wire  axi_top_trn_rdllp_src_rdy        =1'b0;             //  input -- Not used in 7-series
   reg   axi_top_cfg_turnoff_ok;
   assign cfg_turnoff_ok_w = axi_top_cfg_turnoff_ok;         //  output
   wire [2:0] np_counter;                                    //  output

//---------------------------------------------//
// RX Data Pipeline                            //
//---------------------------------------------//

//begin pcie_7x_0_axi_basic_rx {
// rx_inst

// Wires
wire                  null_rx_tvalid;
wire                  null_rx_tlast;
wire [KEEP_WIDTH-1:0] null_rx_tkeep;
wire                  null_rdst_rdy;
reg             [4:0] null_is_eof;

//---------------------------------------------//
// RX Data Pipeline                            //
//---------------------------------------------//

//begin pcie_7x_0_axi_basic_rx_pipeline {
// rx_pipeline_inst 

// Wires and regs for creating AXI signals
wire              [4:0] is_sof;
wire              [4:0] is_sof_prev;

wire              [4:0] is_eof;
wire              [4:0] is_eof_prev;

reg    [KEEP_WIDTH-1:0] reg_tkeep;
wire   [KEEP_WIDTH-1:0] tkeep;
wire   [KEEP_WIDTH-1:0] tkeep_prev;

reg                     reg_tlast;
wire                    rsrc_rdy_filtered;

// Wires and regs for previous value buffer
wire [C_DATA_WIDTH-1:0] trn_rd_DW_swapped;
reg  [C_DATA_WIDTH-1:0] trn_rd_prev;

wire                    data_hold;
reg                     data_prev;

reg                     trn_reof_prev;
reg     [REM_WIDTH-1:0] trn_rrem_prev;
reg                     trn_rsrc_rdy_prev;
reg                     trn_rsrc_dsc_prev;
reg                     trn_rsof_prev;
reg               [6:0] trn_rbar_hit_prev;
reg                     trn_rerrfwd_prev;
reg                     trn_recrc_err_prev;

// Null packet handling signals
reg                     null_mux_sel;
reg                     trn_in_packet;
wire                    dsc_flag;
wire                    dsc_detect;
reg                     reg_dsc_detect;
reg                     trn_rsrc_dsc_d;


// Create "filtered" version of rsrc_rdy, where discontinued SOFs are removed.
assign rsrc_rdy_filtered = trn_rsrc_rdy &&
                                 (trn_in_packet || (trn_rsof && !trn_rsrc_dsc));

//----------------------------------------------------------------------------//
// Previous value buffer                                                      //
// ---------------------                                                      //
// We are inserting a pipeline stage in between TRN and AXI, which causes     //
// some issues with handshaking signals m_axis_rx_tready/trn_rdst_rdy. The    //
// added cycle of latency in the path causes the user design to fall behind   //
// the TRN interface whenever it throttles.                                   //
//                                                                            //
// To avoid loss of data, we must keep the previous value of all trn_r*       //
// signals in case the user throttles.                                        //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    trn_rd_prev        <= #TCQ {C_DATA_WIDTH{1'b0}};
    trn_rsof_prev      <= #TCQ 1'b0;
    trn_rrem_prev      <= #TCQ {REM_WIDTH{1'b0}};
    trn_rsrc_rdy_prev  <= #TCQ 1'b0;
    trn_rbar_hit_prev  <= #TCQ 7'h00;
    trn_rerrfwd_prev   <= #TCQ 1'b0;
    trn_recrc_err_prev <= #TCQ 1'b0;
    trn_reof_prev      <= #TCQ 1'b0;
    trn_rsrc_dsc_prev  <= #TCQ 1'b0;
  end
  else begin
    // prev buffer works by checking trn_rdst_rdy. When trn_rdst_rdy is
    // asserted, a new value is present on the interface.
    if(trn_rdst_rdy) begin
      trn_rd_prev        <= #TCQ trn_rd_DW_swapped;
      trn_rsof_prev      <= #TCQ trn_rsof;
      trn_rrem_prev      <= #TCQ trn_rrem;
      trn_rbar_hit_prev  <= #TCQ trn_rbar_hit[6:0];
      trn_rerrfwd_prev   <= #TCQ trn_rerrfwd;
      trn_recrc_err_prev <= #TCQ trn_recrc_err;
      trn_rsrc_rdy_prev  <= #TCQ rsrc_rdy_filtered;
      trn_reof_prev      <= #TCQ trn_reof;
      trn_rsrc_dsc_prev  <= #TCQ trn_rsrc_dsc || dsc_flag;
    end
  end
end


//----------------------------------------------------------------------------//
// Create TDATA                                                               //
//----------------------------------------------------------------------------//

// Convert TRN data format to AXI data format. AXI is DWORD swapped from TRN
// 128-bit:                 64-bit:                  32-bit:
// TRN DW0 maps to AXI DW3  TRN DW0 maps to AXI DW1  TNR DW0 maps to AXI DW0
// TRN DW1 maps to AXI DW2  TRN DW1 maps to AXI DW0
// TRN DW2 maps to AXI DW1
// TRN DW3 maps to AXI DW0
generate
  if(C_DATA_WIDTH == 128) begin : rd_DW_swap_128
    assign trn_rd_DW_swapped = {trn_rd[31:0],
                                trn_rd[63:32],
                                trn_rd[95:64],
                                trn_rd[127:96]};
  end
  else if(C_DATA_WIDTH == 64) begin : rd_DW_swap_64
    assign trn_rd_DW_swapped = {trn_rd[31:0], trn_rd[63:32]};
  end
  else begin : rd_DW_swap_32
    assign trn_rd_DW_swapped = trn_rd;
  end
endgenerate


// Create special buffer which locks in the proper value of TDATA depending
// on whether the user is throttling or not. This buffer has three states:
//
//       HOLD state: TDATA maintains its current value
//                   - the user has throttled the PCIe block
//   PREVIOUS state: the buffer provides the previous value on trn_rd
//                   - the user has finished throttling, and is a little behind
//                     the PCIe block
//    CURRENT state: the buffer passes the current value on trn_rd
//                   - the user is caught up and ready to receive the latest
//                     data from the PCIe block
always @(posedge user_clk_out) begin
  if(user_reset) begin
    m_axis_rx_tdata <= #TCQ {C_DATA_WIDTH{1'b0}};
  end
  else begin
    if(!data_hold) begin
      // PREVIOUS state
      if(data_prev) begin
        m_axis_rx_tdata <= #TCQ trn_rd_prev;
      end

      // CURRENT state
      else begin
        m_axis_rx_tdata <= #TCQ trn_rd_DW_swapped;
      end
    end
    // else HOLD state
  end
end

// Logic to instruct pipeline to hold its value
assign data_hold = (!m_axis_rx_tready && m_axis_rx_tvalid);

// Logic to instruct pipeline to use previous bus values. Always use previous
// value after holding a value.
always @(posedge user_clk_out) begin
  if(user_reset) begin
    data_prev <= #TCQ 1'b0;
  end
  else begin
    data_prev <= #TCQ data_hold;
  end
end


//----------------------------------------------------------------------------//
// Create TVALID, TLAST, tkeep, TUSER                                         //
// -----------------------------------                                        //
// Use the same strategy for these signals as for TDATA, except here we need  //
// an extra provision for null packets.                                       //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    m_axis_rx_tvalid <= #TCQ 1'b0;
    reg_tlast        <= #TCQ 1'b0;
    reg_tkeep        <= #TCQ {KEEP_WIDTH{1'b1}};
    m_axis_rx_tuser  <= #TCQ 22'h0;
  end
  else begin
    if(!data_hold) begin
      // If in a null packet, use null generated value
      if(null_mux_sel) begin
        m_axis_rx_tvalid <= #TCQ null_rx_tvalid;
        reg_tlast        <= #TCQ null_rx_tlast;
        reg_tkeep        <= #TCQ null_rx_tkeep;
        m_axis_rx_tuser  <= #TCQ {null_is_eof, 17'h0000};
      end

      // PREVIOUS state
      else if(data_prev) begin
        m_axis_rx_tvalid <= #TCQ (trn_rsrc_rdy_prev || dsc_flag);
        reg_tlast        <= #TCQ trn_reof_prev;
        reg_tkeep        <= #TCQ tkeep_prev;
        m_axis_rx_tuser  <= #TCQ {is_eof_prev,          // TUSER bits [21:17]
                                  2'b00,                // TUSER bits [16:15]
                                  is_sof_prev,          // TUSER bits [14:10]
                                  1'b0,                 // TUSER bit  [9]
                                  trn_rbar_hit_prev,    // TUSER bits [8:2]
                                  trn_rerrfwd_prev,     // TUSER bit  [1]
                                  trn_recrc_err_prev};  // TUSER bit  [0]
      end

      // CURRENT state
      else begin
        m_axis_rx_tvalid <= #TCQ (rsrc_rdy_filtered || dsc_flag);
        reg_tlast        <= #TCQ trn_reof;
        reg_tkeep        <= #TCQ tkeep;
        m_axis_rx_tuser  <= #TCQ {is_eof,               // TUSER bits [21:17]
                                  2'b00,                // TUSER bits [16:15]
                                  is_sof,               // TUSER bits [14:10]
                                  1'b0,                 // TUSER bit  [9]
                                  trn_rbar_hit[6:0],    // TUSER bits [8:2]
                                  trn_rerrfwd,          // TUSER bit  [1]
                                  trn_recrc_err};       // TUSER bit  [0]
      end
    end
    // else HOLD state
  end
end

// Hook up TLAST and tkeep depending on interface width
generate
  // For 128-bit interface, don't pass TLAST and tkeep to user (is_eof and
  // is_data passed to user instead). reg_tlast is still used internally.
  if(C_DATA_WIDTH == 128) begin : tlast_tkeep_hookup_128
    assign m_axis_rx_tlast = 1'b0;
    assign m_axis_rx_tkeep = {KEEP_WIDTH{1'b1}};
  end

  // For 64/32-bit interface, pass TLAST to user.
  else begin : tlast_tkeep_hookup_64_32
    assign m_axis_rx_tlast = reg_tlast;
    assign m_axis_rx_tkeep = reg_tkeep;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create tkeep                                                               //
// ------------                                                               //
// Convert RREM to STRB. Here, we are converting the encoding method for the  //
// location of the EOF from TRN flavor (rrem) to AXI (tkeep).                 //
//                                                                            //
// NOTE: for each configuration, we need two values of tkeep, the current and //
//       previous values. The need for these two values is described below.   //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : rrem_to_tkeep_128
    // TLAST and tkeep not used in 128-bit interface. is_sof and is_eof used
    // instead.
    assign tkeep      = 16'h0000;
    assign tkeep_prev = 16'h0000;
  end
  else if(C_DATA_WIDTH == 64) begin : rrem_to_tkeep_64
    // 64-bit interface: contains 2 DWORDs per cycle, for a total of 8 bytes
    //  - tkeep has only two possible values here, 0xFF or 0x0F
    assign tkeep      = trn_rrem      ? 8'hFF : 8'h0F;
    assign tkeep_prev = trn_rrem_prev ? 8'hFF : 8'h0F;
  end
  else begin : rrem_to_tkeep_32
    // 32-bit interface: contains 1 DWORD per cycle, for a total of 4 bytes
    //  - tkeep is always 0xF in this case, due to the nature of the PCIe block
    assign tkeep      = 4'hF;
    assign tkeep_prev = 4'hF;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create is_sof                                                              //
// -------------                                                              //
// is_sof is a signal to the user indicating the location of SOF in TDATA   . //
// Due to inherent 64-bit alignment of packets from the block, the only       //
// possible values are:                                                       //
//                      Value                      Valid data widths          //
//                      5'b11000 (sof @ byte 8)    128                        //
//                      5'b10000 (sof @ byte 0)    128, 64, 32                //
//                      5'b00000 (sof not present) 128, 64, 32                //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : is_sof_128
    assign is_sof      = {(trn_rsof && !trn_rsrc_dsc), // bit 4:   enable
                          (trn_rsof && !trn_rrem[1]),  // bit 3:   sof @ byte 8?
                          3'b000};                     // bit 2-0: hardwired 0

    assign is_sof_prev = {(trn_rsof_prev && !trn_rsrc_dsc_prev), // bit 4
                          (trn_rsof_prev && !trn_rrem_prev[1]),  // bit 3
                          3'b000};                               // bit 2-0
  end
  else begin : is_sof_64_32
    assign is_sof      = {(trn_rsof && !trn_rsrc_dsc), // bit 4:   enable
                          4'b0000};                    // bit 3-0: hardwired 0

    assign is_sof_prev = {(trn_rsof_prev && !trn_rsrc_dsc_prev), // bit 4
                          4'b0000};                              // bit 3-0
  end
endgenerate


//----------------------------------------------------------------------------//
// Create is_eof                                                              //
// -------------                                                              //
// is_eof is a signal to the user indicating the location of EOF in TDATA   . //
// Due to DWORD granularity of packets from the block, the only               //
// possible values are:                                                       //
//                      Value                      Valid data widths          //
//                      5'b11111 (eof @ byte 15)   128                        //
//                      5'b11011 (eof @ byte 11)   128                        //
//                      5'b10111 (eof @ byte 7)    128, 64                    //
//                      5'b10011 (eof @ byte 3)`   128, 64, 32                //
//                      5'b00011 (eof not present) 128, 64, 32                //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : is_eof_128
    assign is_eof      = {trn_reof,      // bit 4:   enable
                          trn_rrem,      // bit 3-2: encoded eof loc rom block
                          2'b11};        // bit 1-0: hardwired 1

    assign is_eof_prev = {trn_reof_prev, // bit 4:   enable
                          trn_rrem_prev, // bit 3-2: encoded eof loc from block
                          2'b11};        // bit 1-0: hardwired 1
  end
  else if(C_DATA_WIDTH == 64) begin : is_eof_64
    assign is_eof      = {trn_reof,      // bit 4:   enable
                          1'b0,          // bit 3:   hardwired 0
                          trn_rrem,      // bit 2:   encoded eof loc from block
                          2'b11};        // bit 1-0: hardwired 1

    assign is_eof_prev = {trn_reof_prev, // bit 4:   enable
                          1'b0,          // bit 3:   hardwired 0
                          trn_rrem_prev, // bit 2:   encoded eof loc from block
                          2'b11};        // bit 1-0: hardwired 1
  end
  else begin : is_eof_32
    assign is_eof      = {trn_reof,      // bit 4:   enable
                          4'b0011};      // bit 3-0: hardwired to byte 3

    assign is_eof_prev = {trn_reof_prev, // bit 4:   enable
                          4'b0011};      // bit 3-0: hardwired to byte 3
  end
endgenerate



//----------------------------------------------------------------------------//
// Create trn_rdst_rdy                                                        //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    trn_rdst_rdy <= #TCQ 1'b0;
  end
  else begin
    // If in a null packet, use null generated value
    if(null_mux_sel && m_axis_rx_tready) begin
      trn_rdst_rdy <= #TCQ null_rdst_rdy;
    end

    // If a discontinue needs to be serviced, throttle the block until we are
    // ready to pad out the packet.
    else if(dsc_flag) begin
      trn_rdst_rdy <= #TCQ 1'b0;
    end

    // If in a packet, pass user back-pressure directly to block
    else if(m_axis_rx_tvalid) begin
      trn_rdst_rdy <= #TCQ m_axis_rx_tready;
    end

    // If idle, default to no back-pressure. We need to default to the
    // "ready to accept data" state to make sure we catch the first
    // clock of data of a new packet.
    else begin
      trn_rdst_rdy <= #TCQ 1'b1;
    end
  end
end

//----------------------------------------------------------------------------//
// Create null_mux_sel                                                        //
// null_mux_sel is the signal used to detect a discontinue situation and      //
// mux in the null packet generated in rx_null_gen. Only mux in null data     //
// when not at the beginningof a packet. SOF discontinues do not require      //
// padding, as the whole packet is simply squashed instead.                   //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    null_mux_sel <= #TCQ 1'b0;
  end
  else begin
    // NULL packet done
    if(null_mux_sel && null_rx_tlast && m_axis_rx_tready)
    begin
      null_mux_sel <= #TCQ 1'b0;
    end

    // Discontinue detected and we're in packet, so switch to NULL packet
    else if(dsc_flag && !data_hold) begin
      null_mux_sel <= #TCQ 1'b1;
    end
  end
end


//----------------------------------------------------------------------------//
// Create discontinue tracking signals                                        //
//----------------------------------------------------------------------------//
// Create signal trn_in_packet, which is needed to validate trn_rsrc_dsc. We
// should ignore trn_rsrc_dsc when it's asserted out-of-packet.
always @(posedge user_clk_out) begin
  if(user_reset) begin
    trn_in_packet <= #TCQ 1'b0;
  end
  else begin
    if(trn_rsof && !trn_reof && rsrc_rdy_filtered && trn_rdst_rdy)
    begin
      trn_in_packet <= #TCQ 1'b1;
    end
    else if(trn_rsrc_dsc) begin
      trn_in_packet <= #TCQ 1'b0;
    end
    else if(trn_reof && !trn_rsof && trn_rsrc_rdy && trn_rdst_rdy) begin
      trn_in_packet <= #TCQ 1'b0;
    end
  end
end


// Create dsc_flag, which identifies and stores mid-packet discontinues that
// require null packet padding. This signal is edge sensitive to trn_rsrc_dsc,
// to make sure we don't service the same dsc twice in the event that
// trn_rsrc_dsc stays asserted for longer than it takes to pad out the packet.
assign dsc_detect = trn_rsrc_dsc && !trn_rsrc_dsc_d && trn_in_packet &&
                         (!trn_rsof || trn_reof) && !(trn_rdst_rdy && trn_reof);

always @(posedge user_clk_out) begin
  if(user_reset) begin
    reg_dsc_detect <= #TCQ 1'b0;
    trn_rsrc_dsc_d <= #TCQ 1'b0;
  end
  else begin
    if(dsc_detect) begin
      reg_dsc_detect <= #TCQ 1'b1;
    end
    else if(null_mux_sel) begin
      reg_dsc_detect <= #TCQ 1'b0;
    end

    trn_rsrc_dsc_d <= #TCQ trn_rsrc_dsc;
  end
end

assign dsc_flag = dsc_detect || reg_dsc_detect;



//----------------------------------------------------------------------------//
// Create np_counter (V6 128-bit only). This counter tells the V6 128-bit     //
// interface core how many NP packets have left the RX pipeline. The V6       //
// 128-bit interface uses this count to perform rnp_ok modulation.            //
//----------------------------------------------------------------------------//
generate
  if(C_FAMILY == "V6" && C_DATA_WIDTH == 128) begin : np_cntr_to_128_enabled
    reg [2:0] reg_np_counter;

    // Look for NP packets beginning on lower (i.e. unaligned) start
    wire mrd_lower      = (!(|m_axis_rx_tdata[92:88]) && !m_axis_rx_tdata[94]);
    wire mrd_lk_lower   = (m_axis_rx_tdata[92:88] == 5'b00001);
    wire io_rdwr_lower  = (m_axis_rx_tdata[92:88] == 5'b00010);
    wire cfg_rdwr_lower = (m_axis_rx_tdata[92:89] == 4'b0010);
    wire atomic_lower   = ((&m_axis_rx_tdata[91:90]) && m_axis_rx_tdata[94]);

    wire np_pkt_lower = (mrd_lower      ||
                         mrd_lk_lower   ||
                         io_rdwr_lower  ||
                         cfg_rdwr_lower ||
                         atomic_lower) && m_axis_rx_tuser[13];

    // Look for NP packets beginning on upper (i.e. aligned) start
    wire mrd_upper      = (!(|m_axis_rx_tdata[28:24]) && !m_axis_rx_tdata[30]);
    wire mrd_lk_upper   = (m_axis_rx_tdata[28:24] == 5'b00001);
    wire io_rdwr_upper  = (m_axis_rx_tdata[28:24] == 5'b00010);
    wire cfg_rdwr_upper = (m_axis_rx_tdata[28:25] == 4'b0010);
    wire atomic_upper   = ((&m_axis_rx_tdata[27:26]) && m_axis_rx_tdata[30]);

    wire np_pkt_upper = (mrd_upper      ||
                         mrd_lk_upper   ||
                         io_rdwr_upper  ||
                         cfg_rdwr_upper ||
                         atomic_upper) && !m_axis_rx_tuser[13];

    wire pkt_accepted =
                    m_axis_rx_tuser[14] && m_axis_rx_tready && m_axis_rx_tvalid;

    // Increment counter whenever an NP packet leaves the RX pipeline
    always @(posedge user_clk_out)  begin
      if (user_reset) begin
        reg_np_counter <= #TCQ 0;
      end
      else begin
        if((np_pkt_lower || np_pkt_upper) && pkt_accepted)
        begin
          reg_np_counter <= #TCQ reg_np_counter + 3'h1;
        end
      end
    end

    assign np_counter = reg_np_counter;
  end
  else begin : np_cntr_to_128_disabled
    assign np_counter = 3'h0;
  end
endgenerate

//end pcie_7x_0_axi_basic_rx_pipeline }



 //---------------------------------------------//
 // RX Null Packet Generator                    //
 //---------------------------------------------//

//begin pcie_7x_0_axi_basic_rx_null_gen {
// rx_null_gen_inst

localparam INTERFACE_WIDTH_DWORDS = (C_DATA_WIDTH == 128) ? 12'd4 :
                                           (C_DATA_WIDTH == 64) ? 12'd2 : 12'd1;

//----------------------------------------------------------------------------//
// NULL packet generator state machine                                        //
// This state machine shadows the AXI RX interface, tracking each packet as   //
// it's passed to the AXI user. When a multi-cycle packet is detected, the    //
// state machine automatically generates a "null" packet. In the event of a   //
// discontinue, the RX pipeline can switch over to this null packet as        //
// necessary.                                                                 //
//----------------------------------------------------------------------------//

// State machine variables and states
localparam            IDLE      = 0;
localparam            IN_PACKET = 1;
reg                   cur_state;
reg                   next_state;

// Signals for tracking a packet on the AXI interface
reg            [11:0] reg_pkt_len_counter;
reg            [11:0] pkt_len_counter;
wire           [11:0] pkt_len_counter_dec;
wire                  pkt_done;

// Calculate packet fields, which are needed to determine total packet length.
wire           [11:0] new_pkt_len;
wire            [9:0] payload_len;
wire            [1:0] packet_fmt;
wire                  packet_td;
reg             [3:0] packet_overhead;

// Misc.
wire [KEEP_WIDTH-1:0] eof_tkeep;
wire                  straddle_sof;
wire                  eof;


// Create signals to detect sof and eof situations. These signals vary depending
// on data width.
assign eof = m_axis_rx_tuser[21];
generate
  if(C_DATA_WIDTH == 128) begin : sof_eof_128
    assign straddle_sof = (m_axis_rx_tuser[14:13] == 2'b11);
  end
  else begin : sof_eof_64_32
    assign straddle_sof = 1'b0;
  end
endgenerate


//----------------------------------------------------------------------------//
// Calculate the length of the packet being presented on the RX interface. To //
// do so, we need the relevent packet fields that impact total packet length. //
// These are:                                                                 //
//   - Header length: obtained from bit 1 of FMT field in 1st DWORD of header //
//   - Payload length: obtained from LENGTH field in 1st DWORD of header      //
//   - TLP digest: obtained from TD field in 1st DWORD of header              //
//   - Current data: the number of bytes that have already been presented     //
//                   on the data interface                                    //
//                                                                            //
// packet length = header + payload + tlp digest - # of DWORDS already        //
//                 transmitted                                                //
//                                                                            //
// packet_overhead is where we calculate everything except payload.           //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : len_calc_128
    assign packet_fmt  = straddle_sof ?
                                m_axis_rx_tdata[94:93] : m_axis_rx_tdata[30:29];
    assign packet_td   = straddle_sof ?
                                      m_axis_rx_tdata[79] : m_axis_rx_tdata[15];
    assign payload_len = packet_fmt[1] ?
         (straddle_sof ? m_axis_rx_tdata[73:64] : m_axis_rx_tdata[9:0]) : 10'h0;

    always @(*) begin
      // In 128-bit mode, the amount of data currently on the interface
      // depends on whether we're straddling or not. If so, 2 DWORDs have been
      // seen. If not, 4 DWORDs.
      case({packet_fmt[0], packet_td, straddle_sof})
        //                        Header +  TD  - Data currently on interface
        3'b0_0_0: packet_overhead = 4'd3 + 4'd0 - 4'd4;
        3'b0_0_1: packet_overhead = 4'd3 + 4'd0 - 4'd2;
        3'b0_1_0: packet_overhead = 4'd3 + 4'd1 - 4'd4;
        3'b0_1_1: packet_overhead = 4'd3 + 4'd1 - 4'd2;
        3'b1_0_0: packet_overhead = 4'd4 + 4'd0 - 4'd4;
        3'b1_0_1: packet_overhead = 4'd4 + 4'd0 - 4'd2;
        3'b1_1_0: packet_overhead = 4'd4 + 4'd1 - 4'd4;
        3'b1_1_1: packet_overhead = 4'd4 + 4'd1 - 4'd2;
      endcase
    end
  end
  else if(C_DATA_WIDTH == 64) begin : len_calc_64
    assign packet_fmt  = m_axis_rx_tdata[30:29];
    assign packet_td   = m_axis_rx_tdata[15];
    assign payload_len = packet_fmt[1] ? m_axis_rx_tdata[9:0] : 10'h0;

    always @(*) begin
      // 64-bit mode: no straddling, so always 2 DWORDs
      case({packet_fmt[0], packet_td})
        //                      Header +  TD  - Data currently on interface
        2'b0_0: packet_overhead = 4'd3 + 4'd0 - 4'd2;
        2'b0_1: packet_overhead = 4'd3 + 4'd1 - 4'd2;
        2'b1_0: packet_overhead = 4'd4 + 4'd0 - 4'd2;
        2'b1_1: packet_overhead = 4'd4 + 4'd1 - 4'd2;
      endcase
    end
  end
  else begin : len_calc_32
    assign packet_fmt  = m_axis_rx_tdata[30:29];
    assign packet_td   = m_axis_rx_tdata[15];
    assign payload_len = packet_fmt[1] ? m_axis_rx_tdata[9:0] : 10'h0;

    always @(*) begin
      // 32-bit mode: no straddling, so always 1 DWORD
      case({packet_fmt[0], packet_td})
        //                      Header +  TD  - Data currently on interface
        2'b0_0: packet_overhead = 4'd3 + 4'd0 - 4'd1;
        2'b0_1: packet_overhead = 4'd3 + 4'd1 - 4'd1;
        2'b1_0: packet_overhead = 4'd4 + 4'd0 - 4'd1;
        2'b1_1: packet_overhead = 4'd4 + 4'd1 - 4'd1;
      endcase
    end
  end
endgenerate

// Now calculate actual packet length, adding the packet overhead and the
// payload length. This is signed math, so sign-extend packet_overhead.
// NOTE: a payload length of zero means 1024 DW in the PCIe spec, but this
//       behavior isn't supported in our block.
assign new_pkt_len =
         {{9{packet_overhead[3]}}, packet_overhead[2:0]} + {2'b0, payload_len};


// Math signals needed in the state machine below. These are seperate wires to
// help ensure synthesis tools sre smart about optimizing them.
assign pkt_len_counter_dec = reg_pkt_len_counter - INTERFACE_WIDTH_DWORDS;
assign pkt_done = (reg_pkt_len_counter <= INTERFACE_WIDTH_DWORDS);

//----------------------------------------------------------------------------//
// Null generator Mealy state machine. Determine outputs based on:            //
//   1) current st                                                            //
//   2) current inp                                                           //
//----------------------------------------------------------------------------//
always @(*) begin
  case (cur_state)

    // IDLE state: the interface is IDLE and we're waiting for a packet to
    // start. If a packet starts, move to state IN_PACKET and begin tracking
    // it as long as it's NOT a single cycle packet (indicated by assertion of
    // eof at packet start)
    IDLE: begin
      if(m_axis_rx_tvalid && m_axis_rx_tready && !eof) begin
        next_state = IN_PACKET;
      end
      else begin
        next_state = IDLE;
      end

      pkt_len_counter = new_pkt_len;
    end

    // IN_PACKET: a mutli-cycle packet is in progress and we're tracking it. We
    // are in lock-step with the AXI interface decrementing our packet length
    // tracking reg, and waiting for the packet to finish.
    //
    // * If packet finished and a new one starts, this is a straddle situation.
    //   Next state is IN_PACKET (128-bit only).
    // * If the current packet is done, next state is IDLE.
    // * Otherwise, next state is IN_PACKET.
    IN_PACKET: begin
      // Straddle packet
      if((C_DATA_WIDTH == 128) && straddle_sof && m_axis_rx_tvalid) begin
        pkt_len_counter = new_pkt_len;
        next_state = IN_PACKET;
      end

      // Current packet finished
      else if(m_axis_rx_tready && pkt_done)
      begin
        pkt_len_counter = new_pkt_len;
        next_state      = IDLE;
      end

      // Packet in progress
      else begin
        if(m_axis_rx_tready) begin
          // Not throttled
          pkt_len_counter = pkt_len_counter_dec;
        end
        else begin
          // Throttled
          pkt_len_counter = reg_pkt_len_counter;
        end

        next_state = IN_PACKET;
      end
    end

    default: begin
      pkt_len_counter = reg_pkt_len_counter;
      next_state      = IDLE;
    end
  endcase
end


// Synchronous NULL packet generator state machine logic
always @(posedge user_clk_out) begin
  if(user_reset) begin
    cur_state           <= #TCQ IDLE;
    reg_pkt_len_counter <= #TCQ 12'h0;
  end
  else begin
    cur_state           <= #TCQ next_state;
    reg_pkt_len_counter <= #TCQ pkt_len_counter;
  end
end


// Generate tkeep/is_eof for an end-of-packet situation.
generate
  if(C_DATA_WIDTH == 128) begin : strb_calc_128
    always @(*) begin
      // Assign null_is_eof depending on how many DWORDs are left in the
      // packet.
      case(pkt_len_counter)
        10'd1:   null_is_eof = 5'b10011;
        10'd2:   null_is_eof = 5'b10111;
        10'd3:   null_is_eof = 5'b11011;
        10'd4:   null_is_eof = 5'b11111;
        default: null_is_eof = 5'b00011;
      endcase
    end

    // tkeep not used in 128-bit interface
    assign eof_tkeep = {KEEP_WIDTH{1'b0}};
  end
  else if(C_DATA_WIDTH == 64) begin : strb_calc_64
    always @(*) begin
      // Assign null_is_eof depending on how many DWORDs are left in the
      // packet.
      case(pkt_len_counter)
        12'd1:   null_is_eof = 5'b10011;
        12'd2:   null_is_eof = 5'b10111;
        default: null_is_eof = 5'b00011;
      endcase
    end

    // Assign tkeep to 0xFF or 0x0F depending on how many DWORDs are left in
    // the current packet.
    assign eof_tkeep = { ((pkt_len_counter == 12'd2) ? 4'hF:4'h0), 4'hF };
  end
  else begin : strb_calc_32
    always @(*) begin
      // is_eof is either on or off for 32-bit
      if(pkt_len_counter == 12'd1) begin
        null_is_eof = 5'b10011;
      end
      else begin
        null_is_eof = 5'b00011;
      end
    end

    // The entire DWORD is always valid in 32-bit mode, so tkeep is always 0xF
    assign eof_tkeep = 4'hF;
  end
endgenerate


// Finally, use everything we've generated to calculate our NULL outputs
assign null_rx_tvalid = 1'b1;
assign null_rx_tlast  = (pkt_len_counter <= INTERFACE_WIDTH_DWORDS);
assign null_rx_tkeep  = null_rx_tlast ? eof_tkeep : {KEEP_WIDTH{1'b1}};
assign null_rdst_rdy  = null_rx_tlast;

//end pcie_7x_0_axi_basic_rx_null_gen }

//end pcie_7x_0_axi_basic_rx }




//---------------------------------------------//
// TX Data Pipeline                            //
//---------------------------------------------//

//begin pcie_7x_0_axi_basic_tx {
// tx_inst 

reg tready_thrtl;

//---------------------------------------------//
// TX Data Pipeline                            //
//---------------------------------------------//

//begin pcie_7x_0_axi_basic_tx_pipeline {
// tx_pipeline_inst 

// Input register stage
reg  [C_DATA_WIDTH-1:0] tx_pipe_reg_tdata;
reg                     tx_pipe_reg_tvalid;
reg    [KEEP_WIDTH-1:0] tx_pipe_reg_tkeep;
reg               [3:0] tx_pipe_reg_tuser;
reg                     tx_pipe_reg_tlast;
reg                     tx_pipe_reg_tready;

// Pipeline utility signals
reg                     tx_pipe_trn_in_packet;
reg                     tx_pipe_axi_in_packet;
reg                     flush_axi;
wire                    disable_trn;
reg                     reg_disable_trn;

wire                    axi_beat_live  = s_axis_tx_tvalid && s_axis_tx_tready;
wire                    axi_end_packet = axi_beat_live && s_axis_tx_tlast;


//----------------------------------------------------------------------------//
// Convert TRN data format to AXI data format. AXI is DWORD swapped from TRN. //
// 128-bit:                 64-bit:                  32-bit:                  //
// TRN DW0 maps to AXI DW3  TRN DW0 maps to AXI DW1  TNR DW0 maps to AXI DW0  //
// TRN DW1 maps to AXI DW2  TRN DW1 maps to AXI DW0                           //
// TRN DW2 maps to AXI DW1                                                    //
// TRN DW3 maps to AXI DW0                                                    //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : td_DW_swap_128
    assign trn_td = {tx_pipe_reg_tdata[31:0],
                     tx_pipe_reg_tdata[63:32],
                     tx_pipe_reg_tdata[95:64],
                     tx_pipe_reg_tdata[127:96]};
  end
  else if(C_DATA_WIDTH == 64) begin : td_DW_swap_64
    assign trn_td = {tx_pipe_reg_tdata[31:0], tx_pipe_reg_tdata[63:32]};
  end
  else begin : td_DW_swap_32
    assign trn_td = tx_pipe_reg_tdata;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create trn_tsof. If we're not currently in a packet and TVALID goes high,  //
// assert TSOF.                                                               //
//----------------------------------------------------------------------------//
assign trn_tsof = tx_pipe_reg_tvalid && !tx_pipe_trn_in_packet;


//----------------------------------------------------------------------------//
// Create tx_pipe_trn_in_packet. This signal tracks if the TRN interface is currently //
// in the middle of a packet, which is needed to generate trn_tsof            //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    tx_pipe_trn_in_packet <= #TCQ 1'b0;
  end
  else begin
    if(trn_tsof && trn_tsrc_rdy && trn_tdst_rdy && !trn_teof) begin
      tx_pipe_trn_in_packet <= #TCQ 1'b1;
    end
    else if((tx_pipe_trn_in_packet && trn_teof && trn_tsrc_rdy) || !axi_top_trn_lnk_up) begin
      tx_pipe_trn_in_packet <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// Create tx_pipe_axi_in_packet. This signal tracks if the AXI interface is currently //
// in the middle of a packet, which is needed in case the link goes down.     //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    tx_pipe_axi_in_packet <= #TCQ 1'b0;
  end
  else begin
    if(axi_beat_live && !s_axis_tx_tlast) begin
      tx_pipe_axi_in_packet <= #TCQ 1'b1;
    end
    else if(axi_beat_live) begin
      tx_pipe_axi_in_packet <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// Create disable_trn. This signal asserts when the link goes down and        //
// triggers the deassertiong of trn_tsrc_rdy. The deassertion of disable_trn  //
// depends on C_PM_PRIORITY, as described below.                              //
//----------------------------------------------------------------------------//
generate
  // In the C_PM_PRIORITY pipeline, we disable the TRN interfacefrom the time
  // the link goes down until the the AXI interface is ready to accept packets
  // again (via assertion of TREADY). By waiting for TREADY, we allow the
  // previous value buffer to fill, so we're ready for any throttling by the
  // user or the block.
  if(C_PM_PRIORITY == "TRUE") begin : pm_priority_trn_flush
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        reg_disable_trn    <= #TCQ 1'b1;
      end
      else begin
        // When the link goes down, disable the TRN interface.
        if(!axi_top_trn_lnk_up)
        begin
          reg_disable_trn  <= #TCQ 1'b1;
        end

        // When the link comes back up and the AXI interface is ready, we can
        // release the pipeline and return to normal operation.
        else if(!flush_axi && s_axis_tx_tready) begin
          reg_disable_trn <= #TCQ 1'b0;
        end
      end
    end

    assign disable_trn = reg_disable_trn;
  end

  // In the throttle-controlled pipeline, we don't have a previous value buffer.
  // The throttle control mechanism handles TREADY, so all we need to do is
  // detect when the link goes down and disable the TRN interface until the link
  // comes back up and the AXI interface is finished flushing any packets.
  else begin : thrtl_ctl_trn_flush
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        reg_disable_trn    <= #TCQ 1'b0;
      end
      else begin
        // If the link is down and AXI is in packet, disable TRN and look for
        // the end of the packet
        if(tx_pipe_axi_in_packet && !axi_top_trn_lnk_up && !axi_end_packet)
        begin
          reg_disable_trn  <= #TCQ 1'b1;
        end

        // AXI packet is ending, so we're done flushing
        else if(axi_end_packet) begin
          reg_disable_trn <= #TCQ 1'b0;
        end
      end
    end

    // Disable the TRN interface if link is down or we're still flushing the AXI
    // interface.
    assign disable_trn = reg_disable_trn || !axi_top_trn_lnk_up;
  end
endgenerate


//----------------------------------------------------------------------------//
// Convert STRB to RREM. Here, we are converting the encoding method for the  //
// location of the EOF from AXI (tkeep) to TRN flavor (rrem).                 //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : tkeep_to_trem_128
    //---------------------------------------//
    // Conversion table:                     //
    // trem    | tkeep                       //
    // [1] [0] | [15:12] [11:8] [7:4] [3:0]  //
    // ------------------------------------- //
    //  1   1  |   D3      D2    D1    D0    //
    //  1   0  |   --      D2    D1    D0    //
    //  0   1  |   --      --    D1    D0    //
    //  0   0  |   --      --    --    D0    //
    //---------------------------------------//

    wire   axi_DW_1    = tx_pipe_reg_tkeep[7];
    wire   axi_DW_2    = tx_pipe_reg_tkeep[11];
    wire   axi_DW_3    = tx_pipe_reg_tkeep[15];
    assign trn_trem[1] = axi_DW_2;
    assign trn_trem[0] = axi_DW_3 || (axi_DW_1 && !axi_DW_2);
  end
  else if(C_DATA_WIDTH == 64) begin : tkeep_to_trem_64
    assign trn_trem    = tx_pipe_reg_tkeep[7];
  end
  else begin : tkeep_to_trem_32
    assign trn_trem    = 1'b0;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create remaining TRN signals                                               //
//----------------------------------------------------------------------------//
assign trn_teof      = tx_pipe_reg_tlast;
assign trn_tecrc_gen = tx_pipe_reg_tuser[0];
assign trn_terrfwd   = tx_pipe_reg_tuser[1];
assign trn_tstr      = tx_pipe_reg_tuser[2];
assign trn_tsrc_dsc  = tx_pipe_reg_tuser[3];


//----------------------------------------------------------------------------//
// Pipeline stage                                                             //
//----------------------------------------------------------------------------//
// We need one of two approaches for the pipeline stage depending on the
// C_PM_PRIORITY parameter.
generate
  reg reg_tsrc_rdy;

  // If set to FALSE, that means the user wants to use the TX packet boundary
  // throttling feature. Since all Block throttling will now be predicted, we
  // can use a simple straight-through pipeline.
  if(C_PM_PRIORITY == "FALSE") begin : throttle_ctl_pipeline
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        tx_pipe_reg_tdata        <= #TCQ {C_DATA_WIDTH{1'b0}};
        tx_pipe_reg_tvalid       <= #TCQ 1'b0;
        tx_pipe_reg_tkeep        <= #TCQ {KEEP_WIDTH{1'b0}};
        tx_pipe_reg_tlast        <= #TCQ 1'b0;
        tx_pipe_reg_tuser        <= #TCQ 4'h0;
        reg_tsrc_rdy     <= #TCQ 1'b0;
      end
      else begin
        tx_pipe_reg_tdata        <= #TCQ s_axis_tx_tdata;
        tx_pipe_reg_tvalid       <= #TCQ s_axis_tx_tvalid;
        tx_pipe_reg_tkeep        <= #TCQ s_axis_tx_tkeep;
        tx_pipe_reg_tlast        <= #TCQ s_axis_tx_tlast;
        tx_pipe_reg_tuser        <= #TCQ s_axis_tx_tuser;

        // Hold trn_tsrc_rdy low when flushing a packet.
        reg_tsrc_rdy     <= #TCQ axi_beat_live && !disable_trn;
      end
    end

    assign trn_tsrc_rdy = reg_tsrc_rdy;

    // With TX packet boundary throttling, TREADY is pipelined in
    // axi_basic_tx_thrtl_ctl and wired through here.
    assign s_axis_tx_tready = tready_thrtl;
  end

  //**************************************************************************//

  // If C_PM_PRIORITY is set to TRUE, that means the user prefers to have all PM
  // functionality intact isntead of TX packet boundary throttling. Now the
  // Block could back-pressure at any time, which creates the standard problem
  // of potential data loss due to the handshaking latency. Here we need a
  // previous value buffer, just like the RX data path.
  else begin : pm_prioity_pipeline
    reg  [C_DATA_WIDTH-1:0] tdata_prev;
    reg                     tvalid_prev;
    reg    [KEEP_WIDTH-1:0] tkeep_prev;
    reg                     tlast_prev;
    reg               [3:0] tuser_prev;
    reg                     reg_tdst_rdy;

    wire                    data_hold;
    reg                     data_prev;


    //------------------------------------------------------------------------//
    // Previous value buffer                                                  //
    // ---------------------                                                  //
    // We are inserting a pipeline stage in between AXI and TRN, which causes //
    // some issues with handshaking signals trn_tsrc_rdy/s_axis_tx_tready.    //
    // The added cycle of latency in the path causes the Block to fall behind //
    // the AXI interface whenever it throttles.                               //
    //                                                                        //
    // To avoid loss of data, we must keep the previous value of all          //
    // s_axis_tx_* signals in case the Block throttles.                       //
    //------------------------------------------------------------------------//
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        tdata_prev   <= #TCQ {C_DATA_WIDTH{1'b0}};
        tvalid_prev  <= #TCQ 1'b0;
        tkeep_prev   <= #TCQ {KEEP_WIDTH{1'b0}};
        tlast_prev   <= #TCQ 1'b0;
        tuser_prev   <= #TCQ 4'h 0;
      end
      else begin
        // prev buffer works by checking s_axis_tx_tready. When
        // s_axis_tx_tready is asserted, a new value is present on the
        // interface.
        if(!s_axis_tx_tready) begin
          tdata_prev   <= #TCQ tdata_prev;
          tvalid_prev  <= #TCQ tvalid_prev;
          tkeep_prev   <= #TCQ tkeep_prev;
          tlast_prev   <= #TCQ tlast_prev;
          tuser_prev   <= #TCQ tuser_prev;
        end
        else begin
          tdata_prev   <= #TCQ s_axis_tx_tdata;
          tvalid_prev  <= #TCQ s_axis_tx_tvalid;
          tkeep_prev   <= #TCQ s_axis_tx_tkeep;
          tlast_prev   <= #TCQ s_axis_tx_tlast;
          tuser_prev   <= #TCQ s_axis_tx_tuser;
        end
      end
    end

    // Create special buffer which locks in the proper value of TDATA depending
    // on whether the user is throttling or not. This buffer has three states:
    //
    //       HOLD state: TDATA maintains its current value
    //                   - the Block has throttled the PCIe block
    //   PREVIOUS state: the buffer provides the previous value on TDATA
    //                   - the Block has finished throttling, and is a little
    //                     behind the user
    //    CURRENT state: the buffer passes the current value on TDATA
    //                   - the Block is caught up and ready to receive the
    //                     latest data from the user
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        tx_pipe_reg_tdata  <= #TCQ {C_DATA_WIDTH{1'b0}};
        tx_pipe_reg_tvalid <= #TCQ 1'b0;
        tx_pipe_reg_tkeep  <= #TCQ {KEEP_WIDTH{1'b0}};
        tx_pipe_reg_tlast  <= #TCQ 1'b0;
        tx_pipe_reg_tuser  <= #TCQ 4'h0;

        reg_tdst_rdy <= #TCQ 1'b0;
      end
      else begin
        reg_tdst_rdy <= #TCQ trn_tdst_rdy;

        if(!data_hold) begin
          // PREVIOUS state
          if(data_prev) begin
            tx_pipe_reg_tdata  <= #TCQ tdata_prev;
            tx_pipe_reg_tvalid <= #TCQ tvalid_prev;
            tx_pipe_reg_tkeep  <= #TCQ tkeep_prev;
            tx_pipe_reg_tlast  <= #TCQ tlast_prev;
            tx_pipe_reg_tuser  <= #TCQ tuser_prev;
          end

          // CURRENT state
          else begin
            tx_pipe_reg_tdata  <= #TCQ s_axis_tx_tdata;
            tx_pipe_reg_tvalid <= #TCQ s_axis_tx_tvalid;
            tx_pipe_reg_tkeep  <= #TCQ s_axis_tx_tkeep;
            tx_pipe_reg_tlast  <= #TCQ s_axis_tx_tlast;
            tx_pipe_reg_tuser  <= #TCQ s_axis_tx_tuser;
          end
        end
        // else HOLD state
      end
    end


    // Logic to instruct pipeline to hold its value
    assign data_hold = trn_tsrc_rdy && !trn_tdst_rdy;


    // Logic to instruct pipeline to use previous bus values. Always use
    // previous value after holding a value.
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        data_prev <= #TCQ 1'b0;
      end
      else begin
        data_prev <= #TCQ data_hold;
      end
    end


    //------------------------------------------------------------------------//
    // Create trn_tsrc_rdy. If we're flushing the TRN hold trn_tsrc_rdy low.  //
    //------------------------------------------------------------------------//
    assign trn_tsrc_rdy = tx_pipe_reg_tvalid && !disable_trn;


    //------------------------------------------------------------------------//
    // Create TREADY                                                          //
    //------------------------------------------------------------------------//
    always @(posedge user_clk_out) begin
      if(user_reset) begin
        tx_pipe_reg_tready <= #TCQ 1'b0;
      end
      else begin
        // If the link went down and we need to flush a packet in flight, hold
        // TREADY high
        if(flush_axi && !axi_end_packet) begin
          tx_pipe_reg_tready <= #TCQ 1'b1;
        end

        // If the link is up, TREADY is as follows:
        //   TREADY = 1 when trn_tsrc_rdy == 0
        //      - While idle, keep the pipeline primed and ready for the next
        //        packet
        //
        //   TREADY = trn_tdst_rdy when trn_tsrc_rdy == 1
        //      - While in packet, throttle pipeline based on state of TRN
        else if(axi_top_trn_lnk_up) begin
          tx_pipe_reg_tready <= #TCQ trn_tdst_rdy || !trn_tsrc_rdy;
        end

        // If the link is down and we're not flushing a packet, hold TREADY low
        // wait for link to come back up
        else begin
          tx_pipe_reg_tready <= #TCQ 1'b0;
        end
      end
    end

    assign s_axis_tx_tready = tx_pipe_reg_tready;
  end


  //--------------------------------------------------------------------------//
  // Create flush_axi. This signal detects if the link goes down while the    //
  // AXI interface is in packet. In this situation, we need to flush the      //
  // packet through the AXI interface and discard it.                         //
  //--------------------------------------------------------------------------//
  always @(posedge user_clk_out) begin
    if(user_reset) begin
      flush_axi    <= #TCQ 1'b0;
    end
    else begin
      // If the AXI interface is in packet and the link goes down, purge it.
      if(tx_pipe_axi_in_packet && !axi_top_trn_lnk_up && !axi_end_packet) begin
        flush_axi <= #TCQ 1'b1;
      end

      // The packet is finished, so we're done flushing.
      else if(axi_end_packet) begin
        flush_axi <= #TCQ 1'b0;
      end
    end
  end
endgenerate

//end pcie_7x_0_axi_basic_tx_pipeline }



//---------------------------------------------//
// TX Throttle Controller                      //
//---------------------------------------------//

//generate
//  if(C_PM_PRIORITY == "FALSE") begin : thrtl_ctl_enabled
//begin pcie_7x_0_axi_basic_tx_thrtl_ctl {
// tx_thrl_ctl_inst 

// Thrtl user when TBUF hits this val
localparam TBUF_AV_MIN = (C_DATA_WIDTH == 128) ? 5 :
                                                   (C_DATA_WIDTH == 64) ? 1 : 0;

// Pause user when TBUF hits this val
localparam TBUF_AV_GAP = TBUF_AV_MIN + 1;

// GAP pause time - the latency from the time a packet is accepted on the TRN
// interface to the time trn_tbuf_av from the Block will decrement.
localparam TBUF_GAP_TIME = (C_DATA_WIDTH == 128) ? 4 : 1;

// Latency time from when tcfg_gnt is asserted to when PCIe block will throttle
localparam TCFG_LATENCY_TIME = 2'd2;

// Number of pipeline stages to delay trn_tcfg_gnt. For V6 128-bit only
localparam TCFG_GNT_PIPE_STAGES = 3;

// Throttle condition registers and constants
reg        lnk_up_thrtl;
wire       lnk_up_trig;
wire       lnk_up_exit;

reg        tbuf_av_min_thrtl;
wire       tbuf_av_min_trig;

reg        tbuf_av_gap_thrtl;
reg  [2:0] tbuf_gap_cnt;
wire       tbuf_av_gap_trig;
wire       tbuf_av_gap_exit;
wire       gap_trig_tlast;
wire       gap_trig_decr;
reg  [5:0] tbuf_av_d;

reg        tcfg_req_thrtl;
reg  [1:0] tcfg_req_cnt;
reg        trn_tdst_rdy_d;
wire       tcfg_req_trig;
wire       tcfg_req_exit;
reg        tcfg_gnt_log;

wire       pre_throttle;
wire       reg_throttle;
wire       exit_crit;
reg        reg_tcfg_gnt;
reg        trn_tcfg_req_d;
reg        tcfg_gnt_pending;
wire       wire_to_turnoff;
reg        reg_turnoff_ok;

reg        tready_thrtl_mux;

localparam LINKSTATE_L0             = 3'b000;
localparam LINKSTATE_PPM_L1         = 3'b001;
localparam LINKSTATE_PPM_L1_TRANS   = 3'b101;
localparam LINKSTATE_PPM_L23R_TRANS = 3'b110;
localparam PM_ENTER_L1              = 8'h20;
localparam POWERSTATE_D0            = 2'b00;

reg        ppm_L1_thrtl;
wire       ppm_L1_trig;
wire       ppm_L1_exit;
reg  [2:0] cfg_pcie_link_state_d;
reg        trn_rdllp_src_rdy_d;

reg        ppm_L23_thrtl;
wire       ppm_L23_trig;
reg        cfg_turnoff_ok_pending;

reg        tx_thrtl_reg_tlast;

// Throttle control state machine states and registers
localparam TX_IDLE       = 0;
localparam TX_THROTTLE   = 1;
reg        tx_thrtl_cur_state;
reg        tx_thrtl_next_state;

reg        reg_axi_in_pkt;
wire       axi_in_pkt;
wire       axi_pkt_ending;
wire       axi_throttled;
wire       axi_thrtl_ok;
wire       tx_ecrc_pause;

//----------------------------------------------------------------------------//
// THROTTLE REASON: PCIe link is down                                         //
//   - When to throttle: axi_top_trn_lnk_up deasserted                                //
//   - When to stop: trn_tdst_rdy assesrted                                   //
//----------------------------------------------------------------------------//
assign lnk_up_trig = !axi_top_trn_lnk_up;
assign lnk_up_exit = trn_tdst_rdy;

always @(posedge user_clk_out) begin
  if(user_reset) begin
    lnk_up_thrtl <= #TCQ 1'b1;
  end
  else begin
    if(lnk_up_trig) begin
      lnk_up_thrtl <= #TCQ 1'b1;
    end
    else if(lnk_up_exit) begin
      lnk_up_thrtl <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// THROTTLE REASON: Transmit buffers depleted                                 //
//   - When to throttle: trn_tbuf_av falls to 0                               //
//   - When to stop: trn_tbuf_av rises above 0 again                          //
//----------------------------------------------------------------------------//
assign tbuf_av_min_trig = (trn_tbuf_av <= TBUF_AV_MIN);

always @(posedge user_clk_out) begin
  if(user_reset) begin
    tbuf_av_min_thrtl <= #TCQ 1'b0;
  end
  else begin
    if(tbuf_av_min_trig) begin
      tbuf_av_min_thrtl <= #TCQ 1'b1;
    end

    // The exit condition for tbuf_av_min_thrtl is !tbuf_av_min_trig
    else begin
      tbuf_av_min_thrtl <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// THROTTLE REASON: Transmit buffers getting low                              //
//   - When to throttle: trn_tbuf_av falls below "gap" threshold TBUF_AV_GAP  //
//   - When to stop: after TBUF_GAP_TIME cycles elapse                        //
//                                                                            //
// If we're about to run out of transmit buffers, throttle the user for a     //
// few clock cycles to give the PCIe block time to catch up. This is          //
// needed to compensate for latency in decrementing trn_tbuf_av in the PCIe   //
// Block transmit path.                                                       //
//----------------------------------------------------------------------------//

// Detect two different scenarios for buffers getting low:
// 1) If we see a TLAST. a new packet has been inserted into the buffer, and
//    we need to pause and let that packet "soak in"
assign gap_trig_tlast = (trn_tbuf_av <= TBUF_AV_GAP) &&
                            s_axis_tx_tvalid && tready_thrtl && s_axis_tx_tlast;

// 2) Any time tbug_avail decrements to the TBUF_AV_GAP threshold, we need to
//    pause and make sure no other packets are about to soak in and cause the
//    buffer availability to drop further.
assign gap_trig_decr  = (trn_tbuf_av == (TBUF_AV_GAP)) &&
                                                 (tbuf_av_d == (TBUF_AV_GAP+1));

assign gap_trig_tcfg  = (tcfg_req_thrtl && tcfg_req_exit);
assign tbuf_av_gap_trig = gap_trig_tlast || gap_trig_decr || gap_trig_tcfg;
assign tbuf_av_gap_exit = (tbuf_gap_cnt == 0);

always @(posedge user_clk_out) begin
  if(user_reset) begin
    tbuf_av_gap_thrtl <= #TCQ 1'b0;
    tbuf_gap_cnt      <= #TCQ 3'h0;
    tbuf_av_d         <= #TCQ 6'h00;
  end
  else begin
    if(tbuf_av_gap_trig) begin
      tbuf_av_gap_thrtl <= #TCQ 1'b1;
    end
    else if(tbuf_av_gap_exit) begin
      tbuf_av_gap_thrtl <= #TCQ 1'b0;
    end

    // tbuf gap counter:
    // This logic controls the length of the throttle condition when tbufs are
    // getting low.
    if(tbuf_av_gap_thrtl && (tx_thrtl_cur_state == TX_THROTTLE)) begin
      if(tbuf_gap_cnt > 0) begin
        tbuf_gap_cnt <= #TCQ tbuf_gap_cnt - 3'd1;
      end
    end
    else begin
      tbuf_gap_cnt <= #TCQ TBUF_GAP_TIME;
    end

    tbuf_av_d <= #TCQ trn_tbuf_av;
  end
end


//----------------------------------------------------------------------------//
// THROTTLE REASON: Block needs to send a CFG response                        //
//   - When to throttle: trn_tcfg_req and user_tcfg_gnt asserted              //
//   - When to stop: after trn_tdst_rdy transitions to unasserted             //
//                                                                            //
// If the block needs to send a response to a CFG packet, this will cause     //
// the subsequent deassertion of trn_tdst_rdy. When the user design permits,  //
// grant permission to the block to service request and throttle the user.    //
//----------------------------------------------------------------------------//
assign tcfg_req_trig = trn_tcfg_req && reg_tcfg_gnt;
assign tcfg_req_exit = (tcfg_req_cnt == 2'd0) && !trn_tdst_rdy_d &&
                                                                   trn_tdst_rdy;
always @(posedge user_clk_out) begin
  if(user_reset) begin
    tcfg_req_thrtl   <= #TCQ 1'b0;
    trn_tcfg_req_d   <= #TCQ 1'b0;
    trn_tdst_rdy_d   <= #TCQ 1'b1;
    reg_tcfg_gnt     <= #TCQ 1'b0;
    tcfg_req_cnt     <= #TCQ 2'd0;
    tcfg_gnt_pending <= #TCQ 1'b0;
  end
  else begin
    if(tcfg_req_trig) begin
      tcfg_req_thrtl <= #TCQ 1'b1;
    end
    else if(tcfg_req_exit) begin
      tcfg_req_thrtl <= #TCQ 1'b0;
    end

    // We need to wait the appropriate amount of time for the tcfg_gnt to
    // "sink in" to the PCIe block. After that, we know that the PCIe block will
    // not reassert trn_tdst_rdy until the CFG request has been serviced. If a
    // new request is being service (tcfg_gnt_log == 1), then reset the timer.
    if((trn_tcfg_req && !trn_tcfg_req_d) || tcfg_gnt_pending) begin
      tcfg_req_cnt <= #TCQ TCFG_LATENCY_TIME;
    end
    else begin
      if(tcfg_req_cnt > 0) begin
        tcfg_req_cnt <= #TCQ tcfg_req_cnt - 2'd1;
      end
    end

    // Make sure tcfg_gnt_log pulses once for one clock cycle for every
    // cfg packet request.
    if(trn_tcfg_req && !trn_tcfg_req_d) begin
      tcfg_gnt_pending <= #TCQ 1'b1;
    end
    else if(tcfg_gnt_log) begin
      tcfg_gnt_pending <= #TCQ 1'b0;
    end

    trn_tcfg_req_d <= #TCQ trn_tcfg_req;
    trn_tdst_rdy_d <= #TCQ trn_tdst_rdy;
    reg_tcfg_gnt   <= #TCQ user_tcfg_gnt;
  end
end


//----------------------------------------------------------------------------//
// THROTTLE REASON: Block needs to transition to low power state PPM L1       //
//   - When to throttle: appropriate low power state signal asserted          //
//     (architecture dependent)                                               //
//   - When to stop: cfg_pcie_link_state goes to proper value (C_ROOT_PORT    //
//     dependent)                                                             //
//                                                                            //
// If the block needs to transition to PM state PPM L1, we need to finish     //
// up what we're doing and throttle immediately.                              //
//----------------------------------------------------------------------------//
generate
  // PPM L1 signals for 7 Series in RC mode
  if((C_FAMILY == "X7") && (C_ROOT_PORT == "TRUE")) begin : x7_L1_thrtl_rp
    assign ppm_L1_trig = (cfg_pcie_link_state_d == LINKSTATE_L0) &&
                           (cfg_pcie_link_state == LINKSTATE_PPM_L1_TRANS);
    assign ppm_L1_exit = cfg_pcie_link_state == LINKSTATE_PPM_L1;
  end

  // PPM L1 signals for 7 Series in EP mode
  else if((C_FAMILY == "X7") && (C_ROOT_PORT == "FALSE")) begin : x7_L1_thrtl_ep
    assign ppm_L1_trig = (cfg_pcie_link_state_d == LINKSTATE_L0) &&
                           (cfg_pcie_link_state == LINKSTATE_PPM_L1_TRANS);
    assign ppm_L1_exit = cfg_pcie_link_state == LINKSTATE_L0;
  end

  // PPM L1 signals for V6 in RC mode
  else if((C_FAMILY == "V6") && (C_ROOT_PORT == "TRUE")) begin : v6_L1_thrtl_rp
    assign ppm_L1_trig = (axi_top_trn_rdllp_data[31:24] == PM_ENTER_L1) &&
                                      axi_top_trn_rdllp_src_rdy && !trn_rdllp_src_rdy_d;
    assign ppm_L1_exit = cfg_pcie_link_state == LINKSTATE_PPM_L1;
  end

  // PPM L1 signals for V6 in EP mode
  else if((C_FAMILY == "V6") && (C_ROOT_PORT == "FALSE")) begin : v6_L1_thrtl_ep
    assign ppm_L1_trig = (cfg_pmcsr_powerstate != POWERSTATE_D0);
    assign ppm_L1_exit = cfg_pcie_link_state == LINKSTATE_L0;
  end

  // PPM L1 detection not supported for S6
  else begin : s6_L1_thrtl
    assign ppm_L1_trig = 1'b0;
    assign ppm_L1_exit = 1'b1;
  end
endgenerate

always @(posedge user_clk_out) begin
  if(user_reset) begin
    ppm_L1_thrtl          <= #TCQ 1'b0;
    cfg_pcie_link_state_d <= #TCQ 3'b0;
    trn_rdllp_src_rdy_d   <= #TCQ 1'b0;
  end
  else begin
    if(ppm_L1_trig) begin
      ppm_L1_thrtl <= #TCQ 1'b1;
    end
    else if(ppm_L1_exit) begin
      ppm_L1_thrtl <= #TCQ 1'b0;
    end
    cfg_pcie_link_state_d <= #TCQ cfg_pcie_link_state;
    trn_rdllp_src_rdy_d   <= #TCQ axi_top_trn_rdllp_src_rdy;
  end
end


//----------------------------------------------------------------------------//
// THROTTLE REASON: Block needs to transition to low power state PPM L2/3     //
//   - When to throttle: appropriate PM signal indicates a transition to      //
//     L2/3 is pending or in progress (family and role dependent)             //
//   - When to stop: never (the only path out of L2/3 is a full reset)        //
//                                                                            //
// If the block needs to transition to PM state PPM L2/3, we need to finish   //
// up what we're doing and throttle when the user gives permission.           //
//----------------------------------------------------------------------------//
generate
  // PPM L2/3 signals for 7 Series in RC mode
  if((C_FAMILY == "X7") && (C_ROOT_PORT == "TRUE")) begin : x7_L23_thrtl_rp
    assign ppm_L23_trig = (cfg_pcie_link_state_d == LINKSTATE_PPM_L23R_TRANS);
    assign wire_to_turnoff = 1'b0;
  end

  // PPM L2/3 signals for V6 in RC mode
  else if((C_FAMILY == "V6") && (C_ROOT_PORT == "TRUE")) begin : v6_L23_thrtl_rp
    assign ppm_L23_trig = axi_top_cfg_pm_send_pme_to;
    assign wire_to_turnoff = 1'b0;
  end

  // PPM L2/3 signals in EP mode
  else begin : L23_thrtl_ep
    assign ppm_L23_trig = wire_to_turnoff && reg_turnoff_ok;

    // PPM L2/3 signals for 7 Series in EP mode
    // For 7 Series, cfg_to_turnoff pulses once when a turnoff request is
    // outstanding, so we need a "sticky" register that grabs the request.
    if(C_FAMILY == "X7") begin : x7_L23_thrtl_ep
      reg reg_to_turnoff;

      always @(posedge user_clk_out) begin
        if(user_reset) begin
          reg_to_turnoff <= #TCQ 1'b0;
        end
        else begin
          if(cfg_to_turnoff) begin
            reg_to_turnoff <= #TCQ 1'b1;
          end
        end
      end

      assign wire_to_turnoff = reg_to_turnoff;
    end

    // PPM L2/3 signals for V6/S6 in EP mode
    // In V6 and S6, the to_turnoff signal asserts and remains asserted until
    // turnoff_ok is asserted, so a sticky reg is not necessary.
    else begin : v6_s6_L23_thrtl_ep
      assign wire_to_turnoff = cfg_to_turnoff;
    end

    always @(posedge user_clk_out) begin
      if(user_reset) begin
        reg_turnoff_ok <= #TCQ 1'b0;
      end
      else begin
        reg_turnoff_ok <= #TCQ user_turnoff_ok;
      end
    end
  end
endgenerate

always @(posedge user_clk_out) begin
  if(user_reset) begin
    ppm_L23_thrtl   <= #TCQ 1'b0;
    cfg_turnoff_ok_pending <= #TCQ 1'b0;
  end
  else begin
    if(ppm_L23_trig) begin
      ppm_L23_thrtl <= #TCQ 1'b1;
    end

    // Make sure axi_top_cfg_turnoff_ok pulses once for one clock cycle for every
    // turnoff request.
    if(ppm_L23_trig && !ppm_L23_thrtl) begin
      cfg_turnoff_ok_pending <= #TCQ 1'b1;
    end
    else if(axi_top_cfg_turnoff_ok) begin
      cfg_turnoff_ok_pending <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// Create axi_thrtl_ok. This signal determines if it's OK to throttle the     //
// user design on the AXI interface. Since TREADY is registered, this signal  //
// needs to assert on the cycle ~before~ we actually intend to throttle.      //
// The only time it's OK to throttle when TVALID is asserted is on the first  //
// beat of a new packet. Therefore, assert axi_thrtl_ok if one of the         //
// is true:                                                                   //
//    1) The user is not in a packet and is not starting one                  //
//    2) The user is just finishing a packet                                  //
//    3) We're already throttled, so it's OK to continue throttling           //
//----------------------------------------------------------------------------//
always @(posedge user_clk_out) begin
  if(user_reset) begin
    reg_axi_in_pkt <= #TCQ 1'b0;
  end
  else begin
    if(s_axis_tx_tvalid && s_axis_tx_tlast) begin
      reg_axi_in_pkt <= #TCQ 1'b0;
    end
    else if(tready_thrtl && s_axis_tx_tvalid) begin
      reg_axi_in_pkt <= #TCQ 1'b1;
    end
  end
end

assign axi_in_pkt     = s_axis_tx_tvalid || reg_axi_in_pkt;
assign axi_pkt_ending = s_axis_tx_tvalid && s_axis_tx_tlast;
assign axi_throttled  = !tready_thrtl;
assign axi_thrtl_ok   = !axi_in_pkt || axi_pkt_ending || axi_throttled;


//----------------------------------------------------------------------------//
// Throttle CTL State Machine:                                                //
// Throttle user design when a throttle trigger (or triggers) occur.          //
// Keep user throttled until all exit criteria have been met.                 //
//----------------------------------------------------------------------------//

// Immediate throttle signal. Used to "pounce" on a throttle opportunity when
// we're seeking one
assign pre_throttle = tbuf_av_min_trig || tbuf_av_gap_trig || lnk_up_trig
                                || tcfg_req_trig || ppm_L1_trig || ppm_L23_trig;


// Registered throttle signals. Used to control throttle state machine
assign reg_throttle = tbuf_av_min_thrtl || tbuf_av_gap_thrtl || lnk_up_thrtl
                             || tcfg_req_thrtl || ppm_L1_thrtl || ppm_L23_thrtl;

assign exit_crit = !tbuf_av_min_thrtl && !tbuf_av_gap_thrtl && !lnk_up_thrtl
                          && !tcfg_req_thrtl && !ppm_L1_thrtl && !ppm_L23_thrtl;

always @(*) begin
  case(tx_thrtl_cur_state)
    // TX_IDLE: in this state we're waiting for a trigger event to occur. As
    // soon as an event occurs and the user isn't transmitting a packet, we
    // throttle the PCIe block and the user and next state is TX_THROTTLE.
    TX_IDLE: begin
      if(reg_throttle && axi_thrtl_ok) begin
        // Throttle user
        tready_thrtl_mux = 1'b0;
        tx_thrtl_next_state       = TX_THROTTLE;

        // Assert appropriate grant signal depending on the throttle type.
        if(tcfg_req_thrtl) begin
          tcfg_gnt_log   = 1'b1;   // For cfg request, grant the request
          axi_top_cfg_turnoff_ok = 1'b0;   //
        end
        else if(ppm_L23_thrtl) begin
          tcfg_gnt_log   = 1'b0;   //
          axi_top_cfg_turnoff_ok = 1'b1;   // For PM request, permit transition
        end
        else begin
          tcfg_gnt_log   = 1'b0;   // Otherwise do nothing
          axi_top_cfg_turnoff_ok = 1'b0;   //
        end
      end

      // If there's not throttle event, do nothing
      else begin
        // Throttle user as soon as possible
        tready_thrtl_mux = !(axi_thrtl_ok && pre_throttle);
        tx_thrtl_next_state       = TX_IDLE;

        tcfg_gnt_log     = 1'b0;
        axi_top_cfg_turnoff_ok   = 1'b0;
      end
    end

    // TX_THROTTLE: in this state the user is throttle and we're waiting for
    // exit criteria, which tells us that the throttle event is over. When
    // the exit criteria is satisfied, de-throttle the user and next state
    // is TX_IDLE.
    TX_THROTTLE: begin
      if(exit_crit) begin
        // Dethrottle user
        tready_thrtl_mux = !pre_throttle;
        tx_thrtl_next_state       = TX_IDLE;
      end
      else begin
        // Throttle user
        tready_thrtl_mux = 1'b0;
        tx_thrtl_next_state       = TX_THROTTLE;
      end

      // Assert appropriate grant signal depending on the throttle type.
      if(tcfg_req_thrtl && tcfg_gnt_pending) begin
        tcfg_gnt_log   = 1'b1;   // For cfg request, grant the request
        axi_top_cfg_turnoff_ok = 1'b0;   //
      end
      else if(cfg_turnoff_ok_pending) begin
        tcfg_gnt_log   = 1'b0;   //
        axi_top_cfg_turnoff_ok = 1'b1;   // For PM request, permit transition
      end
      else begin
        tcfg_gnt_log   = 1'b0;   // Otherwise do nothing
        axi_top_cfg_turnoff_ok = 1'b0;   //
      end
    end

    default: begin
      tready_thrtl_mux = 1'b0;
      tx_thrtl_next_state       = TX_IDLE;
      tcfg_gnt_log     = 1'b0;
      axi_top_cfg_turnoff_ok   = 1'b0;
    end
  endcase
end

// Synchronous logic
always @(posedge user_clk_out) begin
  if(user_reset) begin
    // Throttle user by default until link comes up
    tx_thrtl_cur_state        <= #TCQ TX_THROTTLE;

    tx_thrtl_reg_tlast        <= #TCQ 1'b0;

    tready_thrtl     <= #TCQ 1'b0;
  end
  else begin
    tx_thrtl_cur_state        <= #TCQ tx_thrtl_next_state;

    tready_thrtl     <= #TCQ tready_thrtl_mux && !tx_ecrc_pause;
    tx_thrtl_reg_tlast        <= #TCQ s_axis_tx_tlast;
  end
end

// For X7, the PCIe block will generate the ECRC for a packet if trn_tecrc_gen
// is asserted at SOF. In this case, the Block needs an extra data beat to
// calculate the ECRC, but only if the following conditions are met:
//  1) there is no empty DWORDS at the end of the packet
//     (i.e. packet length % C_DATA_WIDTH == 0)
//
//  2) There isn't a ECRC in the TLP already, as indicated by the TD bit in the
//     TLP header
//
// If both conditions are met, the Block will stall the TRN interface for one
// data beat after EOF. We need to predict this stall and preemptively stall the
// User for one beat.
generate
  if(C_FAMILY == "X7") begin : ecrc_pause_enabled
    wire        tx_ecrc_pkt;
    reg         reg_tx_ecrc_pkt;

    wire  [1:0] packet_fmt;
    wire        packet_td;
    wire  [2:0] header_len;
    wire  [9:0] payload_len;
    wire [13:0] packet_len;
    wire        pause_needed;

    // Grab necessary packet fields
    assign packet_fmt  = s_axis_tx_tdata[30:29];
    assign packet_td   = s_axis_tx_tdata[15];

    // Calculate total packet length
    assign header_len  = packet_fmt[0] ? 3'd4 : 3'd3;
    assign payload_len = packet_fmt[1] ? s_axis_tx_tdata[9:0] : 10'h0;
    assign packet_len  = {10'h000, header_len} + {4'h0, payload_len};


    // Determine if packet a ECRC pause is needed
    if(C_DATA_WIDTH == 128) begin : packet_len_check_128
      assign pause_needed = (packet_len[1:0] == 2'b00) && !packet_td;
    end
    else begin : packet_len_check_64
      assign pause_needed = (packet_len[0] == 1'b0) && !packet_td;
    end


    // Create flag to alert TX pipeline to insert a stall
    assign tx_ecrc_pkt = s_axis_tx_tuser[0] && pause_needed &&
                            tready_thrtl && s_axis_tx_tvalid && !reg_axi_in_pkt;

    always @(posedge user_clk_out) begin
      if(user_reset) begin
        reg_tx_ecrc_pkt <= #TCQ 1'b0;
      end
      else begin
        if(tx_ecrc_pkt && !s_axis_tx_tlast) begin
          reg_tx_ecrc_pkt <= #TCQ 1'b1;
        end
        else if(tready_thrtl && s_axis_tx_tvalid && s_axis_tx_tlast) begin
          reg_tx_ecrc_pkt <= #TCQ 1'b0;
        end
      end
    end


    // Insert the stall now
    assign tx_ecrc_pause = ((tx_ecrc_pkt || reg_tx_ecrc_pkt) &&
                           s_axis_tx_tlast && s_axis_tx_tvalid && tready_thrtl);

  end
  else begin : ecrc_pause_disabled
    assign tx_ecrc_pause = 1'b0;
  end
endgenerate


// Logic for 128-bit single cycle bug fix.
// This tcfg_gnt pipeline addresses an issue with 128-bit V6 designs where a
// single cycle packet transmitted simultaneously with an assertion of tcfg_gnt
// from AXI Basic causes the packet to be dropped. The packet drop occurs
// because the 128-bit shim doesn't know about the tcfg_req/gnt, and therefor
// isn't expecting trn_tdst_rdy to go low. Since the 128-bit shim does throttle
// prediction just as we do, it ignores the value of trn_tdst_rdy, and
// ultimately drops the packet when transmitting the packet to the block.
generate
  if(C_DATA_WIDTH == 128 && C_FAMILY == "V6") begin : tcfg_gnt_pipeline
    genvar stage;
    reg tcfg_gnt_pipe [TCFG_GNT_PIPE_STAGES:0];

    // Create a configurable depth FF delay pipeline
    for(stage = 0; stage < TCFG_GNT_PIPE_STAGES; stage = stage + 1)
    begin : tcfg_gnt_pipeline_stage

      always @(posedge user_clk_out) begin
        if(user_reset) begin
          tcfg_gnt_pipe[stage] <= #TCQ 1'b0;
        end
        else begin
          // For stage 0, insert the actual tcfg_gnt signal from logic
          if(stage == 0) begin
            tcfg_gnt_pipe[stage] <= #TCQ tcfg_gnt_log;
          end

          // For stages 1+, chain together
          else begin
            tcfg_gnt_pipe[stage] <= #TCQ tcfg_gnt_pipe[stage - 1];
          end
        end
      end

      // tcfg_gnt output to block assigned the last pipeline stage
      assign trn_tcfg_gnt = tcfg_gnt_pipe[TCFG_GNT_PIPE_STAGES-1];
    end
  end
  else begin : tcfg_gnt_no_pipeline

    // For all other architectures, no pipeline delay needed for tcfg_gnt
    assign trn_tcfg_gnt = tcfg_gnt_log;
  end
endgenerate

//end pcie_7x_0_axi_basic_tx_thrtl_ctl }

  // end
  // else begin : thrtl_ctl_disabled
  //   assign tready_thrtl   = 1'b0;

  //   assign axi_top_cfg_turnoff_ok = user_turnoff_ok;
  //   assign trn_tcfg_gnt   = user_tcfg_gnt;
  // end
//endgenerate

//end pcie_7x_0_axi_basic_tx }


//end pcie_7x_0_axi_basic_top }


 //-------------------------------------------------------
 // PCI Express Pipe Wrapper
 //-------------------------------------------------------
//begin pcie_7x_0_pcie_7x {
// pcie_7x_i 
   wire pcie_7x_sys_rst_n                         = (~phy_rdy_n);
   wire pl_rst_n                                  = ( 1'b1 );
   wire dl_rst_n                                  = ( 1'b1 );
   wire tl_rst_n                                  = ( 1'b1 );
   wire cm_sticky_rst_n                           = ( 1'b1 );
   wire trn_rfcp_ret                              = ( 1'b1 );
   wire trn_tdllp_dst_rdy;
   wire [31:0] trn_tdllp_data                     = ( 32'b0 );
   wire trn_tdllp_src_rdy                         = ( 1'b0 );
   //wire cfg_err_acs_n                             = ( 1'b1 ); // same as above
   wire cfg_trn_pending_n                         = ( ~cfg_trn_pending );

   wire ll2_tlp_rcv                               = ( 1'b0 );
   wire ll2_send_enter_l1                         = ( 1'b0 );
   wire ll2_send_enter_l23                        = ( 1'b0 );
   wire ll2_send_as_req_l1                        = ( 1'b0 );
   wire ll2_send_pm_ack                           = ( 1'b0 );
   wire ll2_suspend_now                           = ( 1'b0 );
   wire ll2_tfc_init1_seq;
   wire ll2_tfc_init2_seq;
   wire ll2_suspend_ok;
   wire ll2_tx_idle;
   wire ll2_link_status;
   wire ll2_receiver_err;
   wire ll2_protocol_err;
   wire ll2_bad_tlp_err;
   wire ll2_bad_dllp_err;
   wire ll2_replay_ro_err;
   wire ll2_replay_to_err;
   wire tl2_ppm_suspend_req                       = ( 1'b0 );
   wire tl2_aspm_suspend_credit_check             = ( 1'b0 );
   wire tl2_ppm_suspend_ok;
   wire tl2_aspm_suspend_req;
   wire tl2_aspm_suspend_credit_check_ok;
   wire tl2_err_hdr;
   wire tl2_err_malformed;
   wire tl2_err_rxoverflow;
   wire tl2_err_fcpe;
   wire [4:0] pl2_directed_lstate                 = ( 5'b0 );
   wire pl2_suspend_ok;
   wire pl2_recovery;
   wire pl2_rx_elec_idle;
   wire pl2_rx_pm_state;
   wire pl2_l0_req;
   wire pl2_link_up;
   wire pl2_receiver_err;
   wire user_clk_prebuf                           = ( 1'b0 );
   wire user_clk_prebuf_en                        = ( 1'b0 );


 // localparam        TCQ = 1;

  wire [3:0]        trn_tdst_rdy_bus;

  // Assignments to outputs
  assign            user_clk_out = user_clk2;
  assign            trn_tdst_rdy = trn_tdst_rdy_bus[0];

  //----------------------------------------------------------------------//
  // BRAM                                                                 //
  //----------------------------------------------------------------------//

  // transmit bram interface
  wire        mim_tx_wen;
  wire [12:0] mim_tx_waddr;
  wire [68:0] mim_tx_wdata;
  wire        mim_tx_ren;
  wire        mim_tx_rce;
  wire [12:0] mim_tx_raddr;
  wire [68:0] mim_tx_rdata;
  wire [2:0]  unused_mim_tx_rdata;

  // receive bram interface
  wire        mim_rx_wen;
  wire [12:0] mim_rx_waddr;
  wire [67:0] mim_rx_wdata;
  wire        mim_rx_ren;
  wire        mim_rx_rce;
  wire [12:0] mim_rx_raddr;
  wire [67:0] mim_rx_rdata;
  wire [3:0]  unused_mim_rx_rdata;

pcie_7x_0_pcie_bram_top_7x #(
    .LINK_CAP_MAX_LINK_SPEED       ( LINK_CAP_MAX_LINK_SPEED ),
    .LINK_CAP_MAX_LINK_WIDTH       ( LINK_CAP_MAX_LINK_WIDTH ),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED ( DEV_CAP_MAX_PAYLOAD_SUPPORTED ),
    .VC0_TX_LASTPACKET             ( VC0_TX_LASTPACKET ),
    .TL_TX_RAM_RADDR_LATENCY       ( TL_TX_RAM_RADDR_LATENCY ),
    .TL_TX_RAM_RDATA_LATENCY       ( TL_TX_RAM_RDATA_LATENCY ),
    .TL_TX_RAM_WRITE_LATENCY       ( TL_TX_RAM_WRITE_LATENCY ),
    .VC0_RX_RAM_LIMIT              ( VC0_RX_RAM_LIMIT ),
    .TL_RX_RAM_RADDR_LATENCY       ( TL_RX_RAM_RADDR_LATENCY ),
    .TL_RX_RAM_RDATA_LATENCY       ( TL_RX_RAM_RDATA_LATENCY ),
    .TL_RX_RAM_WRITE_LATENCY       ( TL_RX_RAM_WRITE_LATENCY )
  ) pcie_bram_top (
    .user_clk_i    ( user_clk ),
    .reset_i       ( 1'b0 ),

    .mim_tx_waddr  ( mim_tx_waddr ),
    .mim_tx_wen    ( mim_tx_wen ),
    .mim_tx_ren    ( mim_tx_ren ),
    .mim_tx_rce    ( 1'b1 ),
    .mim_tx_wdata  ( {3'b0, mim_tx_wdata} ),
    .mim_tx_raddr  ( mim_tx_raddr ),
    .mim_tx_rdata  ( {unused_mim_tx_rdata, mim_tx_rdata} ),

    .mim_rx_waddr  ( mim_rx_waddr ),
    .mim_rx_wen    ( mim_rx_wen ),
    .mim_rx_ren    ( mim_rx_ren ),
    .mim_rx_rce    ( 1'b1 ),
    .mim_rx_wdata  ( {4'b0, mim_rx_wdata} ),
    .mim_rx_raddr  ( mim_rx_raddr ),
    .mim_rx_rdata  ( {unused_mim_rx_rdata, mim_rx_rdata} )
 );

  //-------------------------------------------------------
  // Virtex7 PCI Express Block Module
  //-------------------------------------------------------

  PCIE_2_1 #(  // Verilog-2001
    .AER_BASE_PTR                             ( AER_BASE_PTR ),
    .AER_CAP_ECRC_CHECK_CAPABLE               ( AER_CAP_ECRC_CHECK_CAPABLE ),
    .AER_CAP_ECRC_GEN_CAPABLE                 ( AER_CAP_ECRC_GEN_CAPABLE ),
    .AER_CAP_ID                               ( AER_CAP_ID ),
    .AER_CAP_MULTIHEADER                      ( AER_CAP_MULTIHEADER ),
    .AER_CAP_NEXTPTR                          ( AER_CAP_NEXTPTR ),
    .AER_CAP_ON                               ( AER_CAP_ON ),
    .AER_CAP_OPTIONAL_ERR_SUPPORT             ( AER_CAP_OPTIONAL_ERR_SUPPORT ),
    .AER_CAP_PERMIT_ROOTERR_UPDATE            ( AER_CAP_PERMIT_ROOTERR_UPDATE ),
    .AER_CAP_VERSION                          ( AER_CAP_VERSION ),
    .ALLOW_X8_GEN2                            ( ALLOW_X8_GEN2 ),
    .BAR0                                     ( BAR0 ),
    .BAR1                                     ( BAR1 ),
    .BAR2                                     ( BAR2 ),
    .BAR3                                     ( BAR3 ),
    .BAR4                                     ( BAR4 ),
    .BAR5                                     ( BAR5 ),
    .CAPABILITIES_PTR                         ( CAPABILITIES_PTR ),
    .CARDBUS_CIS_POINTER                      ( CARDBUS_CIS_POINTER ),
    .CFG_ECRC_ERR_CPLSTAT                     ( CFG_ECRC_ERR_CPLSTAT ),
    .CLASS_CODE                               ( CLASS_CODE ),
    .CMD_INTX_IMPLEMENTED                     ( CMD_INTX_IMPLEMENTED ),
    .CPL_TIMEOUT_DISABLE_SUPPORTED            ( CPL_TIMEOUT_DISABLE_SUPPORTED ),
    .CPL_TIMEOUT_RANGES_SUPPORTED             ( CPL_TIMEOUT_RANGES_SUPPORTED ),
    .CRM_MODULE_RSTS                          ( CRM_MODULE_RSTS ),
    .DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE      ( DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE ),
    .DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE      ( DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE ),
    .DEV_CAP_ENDPOINT_L0S_LATENCY             ( DEV_CAP_ENDPOINT_L0S_LATENCY ),
    .DEV_CAP_ENDPOINT_L1_LATENCY              ( DEV_CAP_ENDPOINT_L1_LATENCY ),
    .DEV_CAP_EXT_TAG_SUPPORTED                ( DEV_CAP_EXT_TAG_SUPPORTED ),
    .DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE     ( DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE ),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED            ( DEV_CAP_MAX_PAYLOAD_SUPPORTED ),
    .DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT        ( DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT ),
    .DEV_CAP_ROLE_BASED_ERROR                 ( DEV_CAP_ROLE_BASED_ERROR ),
    .DEV_CAP_RSVD_14_12                       ( DEV_CAP_RSVD_14_12 ),
    .DEV_CAP_RSVD_17_16                       ( DEV_CAP_RSVD_17_16 ),
    .DEV_CAP_RSVD_31_29                       ( DEV_CAP_RSVD_31_29 ),
    .DEV_CAP2_ARI_FORWARDING_SUPPORTED        ( DEV_CAP2_ARI_FORWARDING_SUPPORTED ),
    .DEV_CAP2_ATOMICOP_ROUTING_SUPPORTED      ( DEV_CAP2_ATOMICOP_ROUTING_SUPPORTED ),
    .DEV_CAP2_ATOMICOP32_COMPLETER_SUPPORTED  ( DEV_CAP2_ATOMICOP32_COMPLETER_SUPPORTED ),
    .DEV_CAP2_ATOMICOP64_COMPLETER_SUPPORTED  ( DEV_CAP2_ATOMICOP64_COMPLETER_SUPPORTED ),
    .DEV_CAP2_CAS128_COMPLETER_SUPPORTED      ( DEV_CAP2_CAS128_COMPLETER_SUPPORTED ),
    .DEV_CAP2_ENDEND_TLP_PREFIX_SUPPORTED     ( DEV_CAP2_ENDEND_TLP_PREFIX_SUPPORTED ),
    .DEV_CAP2_EXTENDED_FMT_FIELD_SUPPORTED    ( DEV_CAP2_EXTENDED_FMT_FIELD_SUPPORTED ),
    .DEV_CAP2_LTR_MECHANISM_SUPPORTED         ( DEV_CAP2_LTR_MECHANISM_SUPPORTED ),
    .DEV_CAP2_MAX_ENDEND_TLP_PREFIXES         ( DEV_CAP2_MAX_ENDEND_TLP_PREFIXES ),
    .DEV_CAP2_NO_RO_ENABLED_PRPR_PASSING      ( DEV_CAP2_NO_RO_ENABLED_PRPR_PASSING ),
    .DEV_CAP2_TPH_COMPLETER_SUPPORTED         ( DEV_CAP2_TPH_COMPLETER_SUPPORTED ),
    .DEV_CONTROL_AUX_POWER_SUPPORTED          ( DEV_CONTROL_AUX_POWER_SUPPORTED ),
    .DEV_CONTROL_EXT_TAG_DEFAULT              ( DEV_CONTROL_EXT_TAG_DEFAULT ),
    .DISABLE_ASPM_L1_TIMER                    ( DISABLE_ASPM_L1_TIMER ),
    .DISABLE_BAR_FILTERING                    ( DISABLE_BAR_FILTERING ),
    .DISABLE_ERR_MSG                          ( DISABLE_ERR_MSG ),
    .DISABLE_ID_CHECK                         ( DISABLE_ID_CHECK ),
    .DISABLE_LANE_REVERSAL                    ( DISABLE_LANE_REVERSAL ),
    .DISABLE_LOCKED_FILTER                    ( DISABLE_LOCKED_FILTER ),
    .DISABLE_PPM_FILTER                       ( DISABLE_PPM_FILTER ),
    .DISABLE_RX_POISONED_RESP                 ( DISABLE_RX_POISONED_RESP ),
    .DISABLE_RX_TC_FILTER                     ( DISABLE_RX_TC_FILTER ),
    .DISABLE_SCRAMBLING                       ( DISABLE_SCRAMBLING ),
    .DNSTREAM_LINK_NUM                        ( DNSTREAM_LINK_NUM ),
    .DSN_BASE_PTR                             ( DSN_BASE_PTR ),
    .DSN_CAP_ID                               ( DSN_CAP_ID ),
    .DSN_CAP_NEXTPTR                          ( DSN_CAP_NEXTPTR ),
    .DSN_CAP_ON                               ( DSN_CAP_ON ),
    .DSN_CAP_VERSION                          ( DSN_CAP_VERSION ),
    .ENABLE_MSG_ROUTE                         ( ENABLE_MSG_ROUTE ),
    .ENABLE_RX_TD_ECRC_TRIM                   ( ENABLE_RX_TD_ECRC_TRIM ),
    .ENDEND_TLP_PREFIX_FORWARDING_SUPPORTED   ( ENDEND_TLP_PREFIX_FORWARDING_SUPPORTED ),
    .ENTER_RVRY_EI_L0                         ( ENTER_RVRY_EI_L0 ),
    .EXIT_LOOPBACK_ON_EI                      ( EXIT_LOOPBACK_ON_EI ),
    .EXPANSION_ROM                            ( EXPANSION_ROM ),
    .EXT_CFG_CAP_PTR                          ( EXT_CFG_CAP_PTR ),
    .EXT_CFG_XP_CAP_PTR                       ( EXT_CFG_XP_CAP_PTR ),
    .HEADER_TYPE                              ( HEADER_TYPE ),
    .INFER_EI                                 ( INFER_EI ),
    .INTERRUPT_PIN                            ( INTERRUPT_PIN ),
    .INTERRUPT_STAT_AUTO                      ( INTERRUPT_STAT_AUTO ),
    .IS_SWITCH                                ( IS_SWITCH ),
    .LAST_CONFIG_DWORD                        ( LAST_CONFIG_DWORD ),
    .LINK_CAP_ASPM_OPTIONALITY                ( LINK_CAP_ASPM_OPTIONALITY ),
    .LINK_CAP_ASPM_SUPPORT                    ( LINK_CAP_ASPM_SUPPORT ),
    .LINK_CAP_CLOCK_POWER_MANAGEMENT          ( LINK_CAP_CLOCK_POWER_MANAGEMENT ),
    .LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP   ( LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP ),
    .LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP ( LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP ),
    .LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1    ( LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1 ),
    .LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2    ( LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2 ),
    .LINK_CAP_L0S_EXIT_LATENCY_GEN1           ( LINK_CAP_L0S_EXIT_LATENCY_GEN1 ),
    .LINK_CAP_L0S_EXIT_LATENCY_GEN2           ( LINK_CAP_L0S_EXIT_LATENCY_GEN2 ),
    .LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1     ( LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1 ),
    .LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2     ( LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2 ),
    .LINK_CAP_L1_EXIT_LATENCY_GEN1            ( LINK_CAP_L1_EXIT_LATENCY_GEN1 ),
    .LINK_CAP_L1_EXIT_LATENCY_GEN2            ( LINK_CAP_L1_EXIT_LATENCY_GEN2 ),
    .LINK_CAP_MAX_LINK_SPEED                  ( LINK_CAP_MAX_LINK_SPEED ),
    .LINK_CAP_MAX_LINK_WIDTH                  ( LINK_CAP_MAX_LINK_WIDTH ),
    .LINK_CAP_RSVD_23                         ( LINK_CAP_RSVD_23 ),
    .LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE     ( LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE ),
    .LINK_CONTROL_RCB                         ( LINK_CONTROL_RCB ),
    .LINK_CTRL2_DEEMPHASIS                    ( LINK_CTRL2_DEEMPHASIS ),
    .LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE   ( LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE ),
    .LINK_CTRL2_TARGET_LINK_SPEED             ( LINK_CTRL2_TARGET_LINK_SPEED ),
    .LINK_STATUS_SLOT_CLOCK_CONFIG            ( LINK_STATUS_SLOT_CLOCK_CONFIG ),
    .LL_ACK_TIMEOUT                           ( LL_ACK_TIMEOUT ),
    .LL_ACK_TIMEOUT_EN                        ( LL_ACK_TIMEOUT_EN ),
    .LL_ACK_TIMEOUT_FUNC                      ( LL_ACK_TIMEOUT_FUNC ),
    .LL_REPLAY_TIMEOUT                        ( LL_REPLAY_TIMEOUT ),
    .LL_REPLAY_TIMEOUT_EN                     ( LL_REPLAY_TIMEOUT_EN ),
    .LL_REPLAY_TIMEOUT_FUNC                   ( LL_REPLAY_TIMEOUT_FUNC ),
    .LTSSM_MAX_LINK_WIDTH                     ( LTSSM_MAX_LINK_WIDTH ),
    .MPS_FORCE                                ( MPS_FORCE ),
    .MSI_BASE_PTR                             ( MSI_BASE_PTR ),
    .MSI_CAP_ID                               ( MSI_CAP_ID ),
    .MSI_CAP_MULTIMSG_EXTENSION               ( MSI_CAP_MULTIMSG_EXTENSION ),
    .MSI_CAP_MULTIMSGCAP                      ( MSI_CAP_MULTIMSGCAP ),
    .MSI_CAP_NEXTPTR                          ( MSI_CAP_NEXTPTR ),
    .MSI_CAP_ON                               ( MSI_CAP_ON ),
    .MSI_CAP_PER_VECTOR_MASKING_CAPABLE       ( MSI_CAP_PER_VECTOR_MASKING_CAPABLE ),
    .MSI_CAP_64_BIT_ADDR_CAPABLE              ( MSI_CAP_64_BIT_ADDR_CAPABLE ),
    .MSIX_BASE_PTR                            ( MSIX_BASE_PTR ),
    .MSIX_CAP_ID                              ( MSIX_CAP_ID ),
    .MSIX_CAP_NEXTPTR                         ( MSIX_CAP_NEXTPTR ),
    .MSIX_CAP_ON                              ( MSIX_CAP_ON ),
    .MSIX_CAP_PBA_BIR                         ( MSIX_CAP_PBA_BIR ),
    .MSIX_CAP_PBA_OFFSET                      ( MSIX_CAP_PBA_OFFSET ),
    .MSIX_CAP_TABLE_BIR                       ( MSIX_CAP_TABLE_BIR ),
    .MSIX_CAP_TABLE_OFFSET                    ( MSIX_CAP_TABLE_OFFSET ),
    .MSIX_CAP_TABLE_SIZE                      ( MSIX_CAP_TABLE_SIZE ),
    .N_FTS_COMCLK_GEN1                        ( N_FTS_COMCLK_GEN1 ),
    .N_FTS_COMCLK_GEN2                        ( N_FTS_COMCLK_GEN2 ),
    .N_FTS_GEN1                               ( N_FTS_GEN1 ),
    .N_FTS_GEN2                               ( N_FTS_GEN2 ),
    .PCIE_BASE_PTR                            ( PCIE_BASE_PTR ),
    .PCIE_CAP_CAPABILITY_ID                   ( PCIE_CAP_CAPABILITY_ID ),
    .PCIE_CAP_CAPABILITY_VERSION              ( PCIE_CAP_CAPABILITY_VERSION ),
    .PCIE_CAP_DEVICE_PORT_TYPE                ( PCIE_CAP_DEVICE_PORT_TYPE ),
    .PCIE_CAP_NEXTPTR                         ( PCIE_CAP_NEXTPTR ),
    .PCIE_CAP_ON                              ( PCIE_CAP_ON ),
    .PCIE_CAP_RSVD_15_14                      ( PCIE_CAP_RSVD_15_14 ),
    .PCIE_CAP_SLOT_IMPLEMENTED                ( PCIE_CAP_SLOT_IMPLEMENTED ),
    .PCIE_REVISION                            ( PCIE_REVISION ),
    .PL_AUTO_CONFIG                           ( PL_AUTO_CONFIG ),
    .PL_FAST_TRAIN                            ( PL_FAST_TRAIN ),
    .PM_ASPML0S_TIMEOUT                       ( PM_ASPML0S_TIMEOUT ),
    .PM_ASPML0S_TIMEOUT_EN                    ( PM_ASPML0S_TIMEOUT_EN ),
    .PM_ASPML0S_TIMEOUT_FUNC                  ( PM_ASPML0S_TIMEOUT_FUNC ),
    .PM_ASPM_FASTEXIT                         ( PM_ASPM_FASTEXIT ),
    .PM_BASE_PTR                              ( PM_BASE_PTR ),
    .PM_CAP_AUXCURRENT                        ( PM_CAP_AUXCURRENT ),
    .PM_CAP_DSI                               ( PM_CAP_DSI ),
    .PM_CAP_D1SUPPORT                         ( PM_CAP_D1SUPPORT ),
    .PM_CAP_D2SUPPORT                         ( PM_CAP_D2SUPPORT ),
    .PM_CAP_ID                                ( PM_CAP_ID ),
    .PM_CAP_NEXTPTR                           ( PM_CAP_NEXTPTR ),
    .PM_CAP_ON                                ( PM_CAP_ON ),
    .PM_CAP_PME_CLOCK                         ( PM_CAP_PME_CLOCK ),
    .PM_CAP_PMESUPPORT                        ( PM_CAP_PMESUPPORT ),
    .PM_CAP_RSVD_04                           ( PM_CAP_RSVD_04 ),
    .PM_CAP_VERSION                           ( PM_CAP_VERSION ),
    .PM_CSR_BPCCEN                            ( PM_CSR_BPCCEN ),
    .PM_CSR_B2B3                              ( PM_CSR_B2B3 ),
    .PM_CSR_NOSOFTRST                         ( PM_CSR_NOSOFTRST ),
    .PM_DATA_SCALE0                           ( PM_DATA_SCALE0 ),
    .PM_DATA_SCALE1                           ( PM_DATA_SCALE1 ),
    .PM_DATA_SCALE2                           ( PM_DATA_SCALE2 ),
    .PM_DATA_SCALE3                           ( PM_DATA_SCALE3 ),
    .PM_DATA_SCALE4                           ( PM_DATA_SCALE4 ),
    .PM_DATA_SCALE5                           ( PM_DATA_SCALE5 ),
    .PM_DATA_SCALE6                           ( PM_DATA_SCALE6 ),
    .PM_DATA_SCALE7                           ( PM_DATA_SCALE7 ),
    .PM_DATA0                                 ( PM_DATA0 ),
    .PM_DATA1                                 ( PM_DATA1 ),
    .PM_DATA2                                 ( PM_DATA2 ),
    .PM_DATA3                                 ( PM_DATA3 ),
    .PM_DATA4                                 ( PM_DATA4 ),
    .PM_DATA5                                 ( PM_DATA5 ),
    .PM_DATA6                                 ( PM_DATA6 ),
    .PM_DATA7                                 ( PM_DATA7 ),
    .PM_MF                                    ( PM_MF ),
    .RBAR_BASE_PTR                            ( RBAR_BASE_PTR ),
    .RBAR_CAP_CONTROL_ENCODEDBAR0             ( RBAR_CAP_CONTROL_ENCODEDBAR0 ),
    .RBAR_CAP_CONTROL_ENCODEDBAR1             ( RBAR_CAP_CONTROL_ENCODEDBAR1 ),
    .RBAR_CAP_CONTROL_ENCODEDBAR2             ( RBAR_CAP_CONTROL_ENCODEDBAR2 ),
    .RBAR_CAP_CONTROL_ENCODEDBAR3             ( RBAR_CAP_CONTROL_ENCODEDBAR3 ),
    .RBAR_CAP_CONTROL_ENCODEDBAR4             ( RBAR_CAP_CONTROL_ENCODEDBAR4 ),
    .RBAR_CAP_CONTROL_ENCODEDBAR5             ( RBAR_CAP_CONTROL_ENCODEDBAR5 ),
    .RBAR_CAP_ID                              ( RBAR_CAP_ID ),
    .RBAR_CAP_INDEX0                          ( RBAR_CAP_INDEX0 ),
    .RBAR_CAP_INDEX1                          ( RBAR_CAP_INDEX1 ),
    .RBAR_CAP_INDEX2                          ( RBAR_CAP_INDEX2 ),
    .RBAR_CAP_INDEX3                          ( RBAR_CAP_INDEX3 ),
    .RBAR_CAP_INDEX4                          ( RBAR_CAP_INDEX4 ),
    .RBAR_CAP_INDEX5                          ( RBAR_CAP_INDEX5 ),
    .RBAR_CAP_NEXTPTR                         ( RBAR_CAP_NEXTPTR ),
    .RBAR_CAP_ON                              ( RBAR_CAP_ON ),
    .RBAR_CAP_SUP0                            ( RBAR_CAP_SUP0 ),
    .RBAR_CAP_SUP1                            ( RBAR_CAP_SUP1 ),
    .RBAR_CAP_SUP2                            ( RBAR_CAP_SUP2 ),
    .RBAR_CAP_SUP3                            ( RBAR_CAP_SUP3 ),
    .RBAR_CAP_SUP4                            ( RBAR_CAP_SUP4 ),
    .RBAR_CAP_SUP5                            ( RBAR_CAP_SUP5 ),
    .RBAR_CAP_VERSION                         ( RBAR_CAP_VERSION ),
    .RBAR_NUM                                 ( RBAR_NUM ),
    .RECRC_CHK                                ( RECRC_CHK ),
    .RECRC_CHK_TRIM                           ( RECRC_CHK_TRIM ),
    .ROOT_CAP_CRS_SW_VISIBILITY               ( ROOT_CAP_CRS_SW_VISIBILITY ),
    .RP_AUTO_SPD                              ( RP_AUTO_SPD ),
    .RP_AUTO_SPD_LOOPCNT                      ( RP_AUTO_SPD_LOOPCNT ),
    .SELECT_DLL_IF                            ( SELECT_DLL_IF ),
    .SLOT_CAP_ATT_BUTTON_PRESENT              ( SLOT_CAP_ATT_BUTTON_PRESENT ),
    .SLOT_CAP_ATT_INDICATOR_PRESENT           ( SLOT_CAP_ATT_INDICATOR_PRESENT ),
    .SLOT_CAP_ELEC_INTERLOCK_PRESENT          ( SLOT_CAP_ELEC_INTERLOCK_PRESENT ),
    .SLOT_CAP_HOTPLUG_CAPABLE                 ( SLOT_CAP_HOTPLUG_CAPABLE ),
    .SLOT_CAP_HOTPLUG_SURPRISE                ( SLOT_CAP_HOTPLUG_SURPRISE ),
    .SLOT_CAP_MRL_SENSOR_PRESENT              ( SLOT_CAP_MRL_SENSOR_PRESENT ),
    .SLOT_CAP_NO_CMD_COMPLETED_SUPPORT        ( SLOT_CAP_NO_CMD_COMPLETED_SUPPORT ),
    .SLOT_CAP_PHYSICAL_SLOT_NUM               ( SLOT_CAP_PHYSICAL_SLOT_NUM ),
    .SLOT_CAP_POWER_CONTROLLER_PRESENT        ( SLOT_CAP_POWER_CONTROLLER_PRESENT ),
    .SLOT_CAP_POWER_INDICATOR_PRESENT         ( SLOT_CAP_POWER_INDICATOR_PRESENT ),
    .SLOT_CAP_SLOT_POWER_LIMIT_SCALE          ( SLOT_CAP_SLOT_POWER_LIMIT_SCALE ),
    .SLOT_CAP_SLOT_POWER_LIMIT_VALUE          ( SLOT_CAP_SLOT_POWER_LIMIT_VALUE ),
    .SPARE_BIT0                               ( SPARE_BIT0 ),
    .SPARE_BIT1                               ( SPARE_BIT1 ),
    .SPARE_BIT2                               ( SPARE_BIT2 ),
    .SPARE_BIT3                               ( SPARE_BIT3 ),
    .SPARE_BIT4                               ( SPARE_BIT4 ),
    .SPARE_BIT5                               ( SPARE_BIT5 ),
    .SPARE_BIT6                               ( SPARE_BIT6 ),
    .SPARE_BIT7                               ( SPARE_BIT7 ),
    .SPARE_BIT8                               ( SPARE_BIT8 ),
    .SPARE_BYTE0                              ( SPARE_BYTE0 ),
    .SPARE_BYTE1                              ( SPARE_BYTE1 ),
    .SPARE_BYTE2                              ( SPARE_BYTE2 ),
    .SPARE_BYTE3                              ( SPARE_BYTE3 ),
    .SPARE_WORD0                              ( SPARE_WORD0 ),
    .SPARE_WORD1                              ( SPARE_WORD1 ),
    .SPARE_WORD2                              ( SPARE_WORD2 ),
    .SPARE_WORD3                              ( SPARE_WORD3 ),
    .SSL_MESSAGE_AUTO                         ( SSL_MESSAGE_AUTO ),
    .TECRC_EP_INV                             ( TECRC_EP_INV ),
    .TL_RBYPASS                               ( TL_RBYPASS ),
    .TL_RX_RAM_RADDR_LATENCY                  ( TL_RX_RAM_RADDR_LATENCY ),
    .TL_RX_RAM_RDATA_LATENCY                  ( TL_RX_RAM_RDATA_LATENCY ),
    .TL_RX_RAM_WRITE_LATENCY                  ( TL_RX_RAM_WRITE_LATENCY ),
    .TL_TFC_DISABLE                           ( TL_TFC_DISABLE ),
    .TL_TX_CHECKS_DISABLE                     ( TL_TX_CHECKS_DISABLE ),
    .TL_TX_RAM_RADDR_LATENCY                  ( TL_TX_RAM_RADDR_LATENCY ),
    .TL_TX_RAM_RDATA_LATENCY                  ( TL_TX_RAM_RDATA_LATENCY ),
    .TL_TX_RAM_WRITE_LATENCY                  ( TL_TX_RAM_WRITE_LATENCY ),
    .TRN_DW                                   ( TRN_DW ),
    .TRN_NP_FC                                ( TRN_NP_FC ),
    .UPCONFIG_CAPABLE                         ( UPCONFIG_CAPABLE ),
    .UPSTREAM_FACING                          ( UPSTREAM_FACING ),
    .UR_ATOMIC                                ( UR_ATOMIC ),
    .UR_CFG1                                  ( UR_CFG1 ),
    .UR_INV_REQ                               ( UR_INV_REQ ),
    .UR_PRS_RESPONSE                          ( UR_PRS_RESPONSE ),
    .USE_RID_PINS                             ( USE_RID_PINS ),
    .USER_CLK_FREQ                            ( USER_CLK_FREQ ),
    .USER_CLK2_DIV2                           ( USER_CLK2_DIV2 ),
    .VC_BASE_PTR                              ( VC_BASE_PTR ),
    .VC_CAP_ID                                ( VC_CAP_ID ),
    .VC_CAP_NEXTPTR                           ( VC_CAP_NEXTPTR ),
    .VC_CAP_ON                                ( VC_CAP_ON ),
    .VC_CAP_REJECT_SNOOP_TRANSACTIONS         ( VC_CAP_REJECT_SNOOP_TRANSACTIONS ),
    .VC_CAP_VERSION                           ( VC_CAP_VERSION ),
    .VC0_CPL_INFINITE                         ( VC0_CPL_INFINITE ),
    .VC0_RX_RAM_LIMIT                         ( VC0_RX_RAM_LIMIT ),
    .VC0_TOTAL_CREDITS_CD                     ( VC0_TOTAL_CREDITS_CD ),
    .VC0_TOTAL_CREDITS_CH                     ( VC0_TOTAL_CREDITS_CH ),
    .VC0_TOTAL_CREDITS_NPD                    ( VC0_TOTAL_CREDITS_NPD ),
    .VC0_TOTAL_CREDITS_NPH                    ( VC0_TOTAL_CREDITS_NPH ),
    .VC0_TOTAL_CREDITS_PD                     ( VC0_TOTAL_CREDITS_PD ),
    .VC0_TOTAL_CREDITS_PH                     ( VC0_TOTAL_CREDITS_PH ),
    .VC0_TX_LASTPACKET                        ( VC0_TX_LASTPACKET ),
    .VSEC_BASE_PTR                            ( VSEC_BASE_PTR ),
    .VSEC_CAP_HDR_ID                          ( VSEC_CAP_HDR_ID ),
    .VSEC_CAP_HDR_REVISION                    ( VSEC_CAP_HDR_REVISION ),
    .VSEC_CAP_ID                              ( VSEC_CAP_ID ),
    .VSEC_CAP_IS_LINK_VISIBLE                 ( VSEC_CAP_IS_LINK_VISIBLE ),
    .VSEC_CAP_NEXTPTR                         ( VSEC_CAP_NEXTPTR ),
    .VSEC_CAP_ON                              ( VSEC_CAP_ON ),
    .VSEC_CAP_VERSION                         ( VSEC_CAP_VERSION )
`ifdef B_TESTMODE
    ,
    .TEST_MODE_PIN_CHAR                       ( TEST_MODE_PIN_CHAR )
`endif

  )
  pcie_block_i (
    .TRNTD                               (trn_td                                     ),
    .TRNTREM                             (trn_trem                                   ),
    .TRNTSOF                             (trn_tsof                                   ),
    .TRNTEOF                             (trn_teof                                   ),
    .TRNTSRCRDY                          (trn_tsrc_rdy                               ),
    .TRNTSRCDSC                          (trn_tsrc_dsc                               ),
    .TRNTERRFWD                          (trn_terrfwd                                ),
    .TRNTECRCGEN                         (trn_tecrc_gen                              ),
    .TRNTSTR                             (trn_tstr                                   ),
    .TRNTCFGGNT                          (trn_tcfg_gnt                               ),
    .TRNRDSTRDY                          (trn_rdst_rdy                               ),
    .TRNRNPREQ                           (trn_rnp_req                                ),
    .TRNRFCPRET                          (trn_rfcp_ret                               ),
    .TRNRNPOK                            (trn_rnp_ok                                 ),
    .TRNFCSEL                            (fc_sel                                     ),
    .MIMTXRDATA                          (mim_tx_rdata                               ),
    .MIMRXRDATA                          (mim_rx_rdata                               ),
    .TRNTDLLPDATA                        (trn_tdllp_data                             ),
    .TRNTDLLPSRCRDY                      (trn_tdllp_src_rdy                          ),
    .LL2TLPRCV                           (ll2_tlp_rcv                                ),
    .LL2SENDENTERL1                      (ll2_send_enter_l1                          ),
    .LL2SENDENTERL23                     (ll2_send_enter_l23                         ),
    .LL2SENDASREQL1                      (ll2_send_as_req_l1                         ),
    .LL2SENDPMACK                        (ll2_send_pm_ack                            ),
    .PL2DIRECTEDLSTATE                   (pl2_directed_lstate                        ),
    .LL2SUSPENDNOW                       (ll2_suspend_now                            ),
    .TL2PPMSUSPENDREQ                    (tl2_ppm_suspend_req                        ),
    .TL2ASPMSUSPENDCREDITCHECK           (tl2_aspm_suspend_credit_check              ),
    .PLDIRECTEDLINKCHANGE                (pl_directed_link_change                    ),
    .PLDIRECTEDLINKWIDTH                 (pl_directed_link_width                     ),
    .PLDIRECTEDLINKSPEED                 (pl_directed_link_speed                     ),
    .PLDIRECTEDLINKAUTON                 (pl_directed_link_auton                     ),
    .PLUPSTREAMPREFERDEEMPH              (pl_upstream_prefer_deemph                  ),
    .PLDOWNSTREAMDEEMPHSOURCE            (pl_downstream_deemph_source                ),
    .PLDIRECTEDLTSSMNEW                  (pl_directed_ltssm_new                      ),
    .PLDIRECTEDLTSSMNEWVLD               (pl_directed_ltssm_new_vld                  ),
    .PLDIRECTEDLTSSMSTALL                (pl_directed_ltssm_stall                    ),
    .PIPERX0CHARISK                      (pipe_rx0_char_is_k                         ),
    .PIPERX1CHARISK                      (pipe_rx1_char_is_k                         ),
    .PIPERX2CHARISK                      (pipe_rx2_char_is_k                         ),
    .PIPERX3CHARISK                      (pipe_rx3_char_is_k                         ),
    .PIPERX4CHARISK                      (pipe_rx4_char_is_k                         ),
    .PIPERX5CHARISK                      (pipe_rx5_char_is_k                         ),
    .PIPERX6CHARISK                      (pipe_rx6_char_is_k                         ),
    .PIPERX7CHARISK                      (pipe_rx7_char_is_k                         ),
    .PIPERX0VALID                        (pipe_rx0_valid                             ),
    .PIPERX1VALID                        (pipe_rx1_valid                             ),
    .PIPERX2VALID                        (pipe_rx2_valid                             ),
    .PIPERX3VALID                        (pipe_rx3_valid                             ),
    .PIPERX4VALID                        (pipe_rx4_valid                             ),
    .PIPERX5VALID                        (pipe_rx5_valid                             ),
    .PIPERX6VALID                        (pipe_rx6_valid                             ),
    .PIPERX7VALID                        (pipe_rx7_valid                             ),
    .PIPERX0DATA                         (pipe_rx0_data                              ),
    .PIPERX1DATA                         (pipe_rx1_data                              ),
    .PIPERX2DATA                         (pipe_rx2_data                              ),
    .PIPERX3DATA                         (pipe_rx3_data                              ),
    .PIPERX4DATA                         (pipe_rx4_data                              ),
    .PIPERX5DATA                         (pipe_rx5_data                              ),
    .PIPERX6DATA                         (pipe_rx6_data                              ),
    .PIPERX7DATA                         (pipe_rx7_data                              ),
    .PIPERX0CHANISALIGNED                (pipe_rx0_chanisaligned                     ),
    .PIPERX1CHANISALIGNED                (pipe_rx1_chanisaligned                     ),
    .PIPERX2CHANISALIGNED                (pipe_rx2_chanisaligned                     ),
    .PIPERX3CHANISALIGNED                (pipe_rx3_chanisaligned                     ),
    .PIPERX4CHANISALIGNED                (pipe_rx4_chanisaligned                     ),
    .PIPERX5CHANISALIGNED                (pipe_rx5_chanisaligned                     ),
    .PIPERX6CHANISALIGNED                (pipe_rx6_chanisaligned                     ),
    .PIPERX7CHANISALIGNED                (pipe_rx7_chanisaligned                     ),
    .PIPERX0STATUS                       (pipe_rx0_status                            ),
    .PIPERX1STATUS                       (pipe_rx1_status                            ),
    .PIPERX2STATUS                       (pipe_rx2_status                            ),
    .PIPERX3STATUS                       (pipe_rx3_status                            ),
    .PIPERX4STATUS                       (pipe_rx4_status                            ),
    .PIPERX5STATUS                       (pipe_rx5_status                            ),
    .PIPERX6STATUS                       (pipe_rx6_status                            ),
    .PIPERX7STATUS                       (pipe_rx7_status                            ),
    .PIPERX0PHYSTATUS                    (pipe_rx0_phy_status                        ),
    .PIPERX1PHYSTATUS                    (pipe_rx1_phy_status                        ),
    .PIPERX2PHYSTATUS                    (pipe_rx2_phy_status                        ),
    .PIPERX3PHYSTATUS                    (pipe_rx3_phy_status                        ),
    .PIPERX4PHYSTATUS                    (pipe_rx4_phy_status                        ),
    .PIPERX5PHYSTATUS                    (pipe_rx5_phy_status                        ),
    .PIPERX6PHYSTATUS                    (pipe_rx6_phy_status                        ),
    .PIPERX7PHYSTATUS                    (pipe_rx7_phy_status                        ),
    .PIPERX0ELECIDLE                     (pipe_rx0_elec_idle                         ),
    .PIPERX1ELECIDLE                     (pipe_rx1_elec_idle                         ),
    .PIPERX2ELECIDLE                     (pipe_rx2_elec_idle                         ),
    .PIPERX3ELECIDLE                     (pipe_rx3_elec_idle                         ),
    .PIPERX4ELECIDLE                     (pipe_rx4_elec_idle                         ),
    .PIPERX5ELECIDLE                     (pipe_rx5_elec_idle                         ),
    .PIPERX6ELECIDLE                     (pipe_rx6_elec_idle                         ),
    .PIPERX7ELECIDLE                     (pipe_rx7_elec_idle                         ),
    .PIPECLK                             (pipe_clk                                   ),
    .USERCLK                             (user_clk                                   ),
    .USERCLK2                            (user_clk2                                  ),
`ifdef VALIDATION
    .USERCLKPREBUF                       (user_clk_prebuf                            ),
    .USERCLKPREBUFEN                     (user_clk_prebuf_en                         ),
`endif
`ifdef B_TESTMODE
    .USERCLKPREBUF                       (user_clk_prebuf                            ),
    .USERCLKPREBUFEN                     (user_clk_prebuf_en                         ),
    .SCANMODEN                           (scanmode_n                                 ),
    .SCANENABLEN                         (scanenable_n                               ),
    .EDTCLK                              (edt_clk                                    ),
    .EDTUPDATE                           (edt_update                                 ),
    .EDTBYPASS                           (edt_bypass                                 ),
    .EDTCONFIGURATION                    (edt_configuration                          ),
    .EDTSINGLEBYPASSCHAIN                (edt_single_bypass_chain                    ),
    .EDTCHANNELSIN1                      (edt_channels_in1                           ),
    .EDTCHANNELSIN2                      (edt_channels_in2                           ),
    .EDTCHANNELSIN3                      (edt_channels_in3                           ),
    .EDTCHANNELSIN4                      (edt_channels_in4                           ),
    .EDTCHANNELSIN5                      (edt_channels_in5                           ),
    .EDTCHANNELSIN6                      (edt_channels_in6                           ),
    .EDTCHANNELSIN7                      (edt_channels_in7                           ),
    .EDTCHANNELSIN8                      (edt_channels_in8                           ),
    .PMVENABLEN                          (pmv_enable_n                               ),
    .PMVSELECT                           (pmv_select                                 ),
    .PMVDIVIDE                           (pmv_divide                                 ),
`endif
//`ifdef SECUREIP
//    .GSR                                 (gsr                                        ),
//`endif
    .SYSRSTN                             (pcie_7x_sys_rst_n                          ),
    .CMRSTN                              (cm_rst_n                                   ),
    .CMSTICKYRSTN                        (cm_sticky_rst_n                            ),
    .FUNCLVLRSTN                         (func_lvl_rst_n                             ),
    .TLRSTN                              (tl_rst_n                                   ),
    .DLRSTN                              (dl_rst_n                                   ),
    .PLRSTN                              (pl_rst_n                                   ),
    .PLTRANSMITHOTRST                    (pl_transmit_hot_rst                        ),
    // Global pins not on Holistic       model
    //.CFGRESET                          (cfg_reset                                  ),
    //.GWE                               (gwe                                        ),
    //.GRESTORE                          (grestore                                   ),
    //.GHIGHB                            (ghigh_b                                    ),
    .CFGMGMTDI                           (cfg_mgmt_di                                ),
    .CFGMGMTBYTEENN                      (cfg_mgmt_byte_en_n                         ),
    .CFGMGMTDWADDR                       (cfg_mgmt_dwaddr                            ),
    .CFGMGMTWRRW1CASRWN                  (cfg_mgmt_wr_rw1c_as_rw_n                   ),
    .CFGMGMTWRREADONLYN                  (cfg_mgmt_wr_readonly_n                     ),
    .CFGMGMTWRENN                        (cfg_mgmt_wr_en_n                           ),
    .CFGMGMTRDENN                        (cfg_mgmt_rd_en_n                           ),
    .CFGERRMALFORMEDN                    (cfg_err_malformed_n                        ),
    .CFGERRCORN                          (cfg_err_cor_n                              ),
    .CFGERRURN                           (cfg_err_ur_n                               ),
    .CFGERRECRCN                         (cfg_err_ecrc_n                             ),
    .CFGERRCPLTIMEOUTN                   (cfg_err_cpl_timeout_n                      ),
    .CFGERRCPLABORTN                     (cfg_err_cpl_abort_n                        ),
    .CFGERRCPLUNEXPECTN                  (cfg_err_cpl_unexpect_n                     ),
    .CFGERRPOISONEDN                     (cfg_err_poisoned_n                         ),
    .CFGERRACSN                          (cfg_err_acs_n                              ),
    .CFGERRATOMICEGRESSBLOCKEDN          (cfg_err_atomic_egress_blocked_n            ),
    .CFGERRMCBLOCKEDN                    (cfg_err_mc_blocked_n                       ),
    .CFGERRINTERNALUNCORN                (cfg_err_internal_uncor_n                   ),
    .CFGERRINTERNALCORN                  (cfg_err_internal_cor_n                     ),
    .CFGERRPOSTEDN                       (cfg_err_posted_n                           ),
    .CFGERRLOCKEDN                       (cfg_err_locked_n                           ),
    .CFGERRNORECOVERYN                   (cfg_err_norecovery_n                       ),
    .CFGERRAERHEADERLOG                  (cfg_err_aer_headerlog                      ),
    .CFGERRTLPCPLHEADER                  (cfg_err_tlp_cpl_header                     ),
    .CFGINTERRUPTN                       (cfg_interrupt_n                            ),
    .CFGINTERRUPTDI                      (cfg_interrupt_di                           ),
    .CFGINTERRUPTASSERTN                 (cfg_interrupt_assert_n                     ),
    .CFGINTERRUPTSTATN                   (cfg_interrupt_stat_n                       ),
    .CFGDSBUSNUMBER                      (cfg_ds_bus_number                          ),
    .CFGDSDEVICENUMBER                   (cfg_ds_device_number                       ),
    .CFGDSFUNCTIONNUMBER                 (cfg_ds_function_number                     ),
    .CFGPORTNUMBER                       (cfg_port_number                            ),
    .CFGPMHALTASPML0SN                   (cfg_pm_halt_aspm_l0s_n                     ),
    .CFGPMHALTASPML1N                    (cfg_pm_halt_aspm_l1_n                      ),
    .CFGPMFORCESTATEENN                  (cfg_pm_force_state_en_n                    ),
    .CFGPMFORCESTATE                     (cfg_pm_force_state                         ),
    .CFGPMWAKEN                          (cfg_pm_wake_n                              ),
    .CFGPMTURNOFFOKN                     (cfg_pm_turnoff_ok_n                        ),
    .CFGPMSENDPMETON                     (cfg_pm_send_pme_to_n                       ),
    .CFGPCIECAPINTERRUPTMSGNUM           (cfg_pciecap_interrupt_msgnum               ),
    .CFGTRNPENDINGN                      (cfg_trn_pending_n                          ),
    .CFGFORCEMPS                         (cfg_force_mps                              ),
    .CFGFORCECOMMONCLOCKOFF              (cfg_force_common_clock_off                 ),
    .CFGFORCEEXTENDEDSYNCON              (cfg_force_extended_sync_on                 ),
    .CFGDSN                              (cfg_dsn                                    ),
    .CFGDEVID                            (cfg_dev_id                                 ),
    .CFGVENDID                           (cfg_vend_id                                ),
    .CFGREVID                            (cfg_rev_id                                 ),
    .CFGSUBSYSID                         (cfg_subsys_id                              ),
    .CFGSUBSYSVENDID                     (cfg_subsys_vend_id                         ),
    .CFGAERINTERRUPTMSGNUM               (cfg_aer_interrupt_msgnum                   ),
    .DRPCLK                              (drp_clk                                    ),
    .DRPEN                               (drp_en                                     ),
    .DRPWE                               (drp_we                                     ),
    .DRPADDR                             (drp_addr                                   ),
    .DRPDI                               (drp_di                                     ),
    //.DRPREADPORT0                      (drp_read_port_0                            ),
    //.DRPREADPORT1                      (drp_read_port_1                            ),
    //.DRPREADPORT2                      (drp_read_port_2                            ),
    //.DRPREADPORT3                      (drp_read_port_3                            ),
    //.DRPREADPORT4                      (drp_read_port_4                            ),
    //.DRPREADPORT5                      (drp_read_port_5                            ),
    //.DRPREADPORT6                      (drp_read_port_6                            ),
    //.DRPREADPORT7                      (drp_read_port_7                            ),
    //.DRPREADPORT8                      (drp_read_port_8                            ),
    //.DRPREADPORT9                      (drp_read_port_9                            ),
    //.DRPREADPORT10                     (drp_read_port_10                           ),
    //.DRPREADPORT11                     (drp_read_port_11                           ),
    //.DRPREADPORT12                     (drp_read_port_12                           ),
    .DBGMODE                             (dbg_mode                                   ),
    .DBGSUBMODE                          (dbg_sub_mode                               ),
    .PLDBGMODE                           (pl_dbg_mode                                ),

    .TRNTDSTRDY                          (trn_tdst_rdy_bus                           ),
    .TRNTERRDROP                         (tx_err_drop                                ),
    .TRNTBUFAV                           (tx_buf_av                                  ),
    .TRNTCFGREQ                          (tx_cfg_req                                 ),
    .TRNRD                               (trn_rd                                     ),
    .TRNRREM                             (trn_rrem                                   ),
    .TRNRSOF                             (trn_rsof                                   ),
    .TRNREOF                             (trn_reof                                   ),
    .TRNRSRCRDY                          (trn_rsrc_rdy                               ),
    .TRNRSRCDSC                          (trn_rsrc_dsc                               ),
    .TRNRECRCERR                         (trn_recrc_err                              ),
    .TRNRERRFWD                          (trn_rerrfwd                                ),
    .TRNRBARHIT                          (trn_rbar_hit                               ),
    .TRNLNKUP                            (trn_lnk_up                                 ),
    .TRNFCPH                             (fc_ph                                      ),
    .TRNFCPD                             (fc_pd                                      ),
    .TRNFCNPH                            (fc_nph                                     ),
    .TRNFCNPD                            (fc_npd                                     ),
    .TRNFCCPLH                           (fc_cplh                                    ),
    .TRNFCCPLD                           (fc_cpld                                    ),
    .MIMTXWDATA                          (mim_tx_wdata                               ),
    .MIMTXWADDR                          (mim_tx_waddr                               ),
    .MIMTXWEN                            (mim_tx_wen                                 ),
    .MIMTXRADDR                          (mim_tx_raddr                               ),
    .MIMTXREN                            (mim_tx_ren                                 ),
    .MIMRXWDATA                          (mim_rx_wdata                               ),
    .MIMRXWADDR                          (mim_rx_waddr                               ),
    .MIMRXWEN                            (mim_rx_wen                                 ),
    .MIMRXRADDR                          (mim_rx_raddr                               ),
    .MIMRXREN                            (mim_rx_ren                                 ),
    .TRNTDLLPDSTRDY                      (trn_tdllp_dst_rdy                          ),
    .TRNRDLLPDATA                        (trn_rdllp_data                             ),
    .TRNRDLLPSRCRDY                      (trn_rdllp_src_rdy                          ),
    .LL2TFCINIT1SEQ                      (ll2_tfc_init1_seq                          ),
    .LL2TFCINIT2SEQ                      (ll2_tfc_init2_seq                          ),
    .PL2SUSPENDOK                        (pl2_suspend_ok                             ),
    .PL2RECOVERY                         (pl2_recovery                               ),
    .PL2RXELECIDLE                       (pl2_rx_elec_idle                           ),
    .PL2RXPMSTATE                        (pl2_rx_pm_state                            ),
    .PL2L0REQ                            (pl2_l0_req                                 ),
    .LL2SUSPENDOK                        (ll2_suspend_ok                             ),
    .LL2TXIDLE                           (ll2_tx_idle                                ),
    .LL2LINKSTATUS                       (ll2_link_status                            ),
    .TL2PPMSUSPENDOK                     (tl2_ppm_suspend_ok                         ),
    .TL2ASPMSUSPENDREQ                   (tl2_aspm_suspend_req                       ),
    .TL2ASPMSUSPENDCREDITCHECKOK         (tl2_aspm_suspend_credit_check_ok           ),
    .PL2LINKUP                           (pl2_link_up                                ),
    .PL2RECEIVERERR                      (pl2_receiver_err                           ),
    .LL2RECEIVERERR                      (ll2_receiver_err                           ),
    .LL2PROTOCOLERR                      (ll2_protocol_err                           ),
    .LL2BADTLPERR                        (ll2_bad_tlp_err                            ),
    .LL2BADDLLPERR                       (ll2_bad_dllp_err                           ),
    .LL2REPLAYROERR                      (ll2_replay_ro_err                          ),
    .LL2REPLAYTOERR                      (ll2_replay_to_err                          ),
    .TL2ERRHDR                           (tl2_err_hdr                                ),
    .TL2ERRMALFORMED                     (tl2_err_malformed                          ),
    .TL2ERRRXOVERFLOW                    (tl2_err_rxoverflow                         ),
    .TL2ERRFCPE                          (tl2_err_fcpe                               ),
    .PLSELLNKRATE                        (pl_sel_lnk_rate                            ),
    .PLSELLNKWIDTH                       (pl_sel_lnk_width                           ),
    .PLLTSSMSTATE                        (pl_ltssm_state                             ),
    .PLLANEREVERSALMODE                  (pl_lane_reversal_mode                      ),
    .PLPHYLNKUPN                         (pl_phy_lnk_up_n                            ),
    .PLTXPMSTATE                         (pl_tx_pm_state                             ),
    .PLRXPMSTATE                         (pl_rx_pm_state                             ),
    .PLLINKUPCFGCAP                      (pl_link_upcfg_cap                          ),
    .PLLINKGEN2CAP                       (pl_link_gen2_cap                           ),
    .PLLINKPARTNERGEN2SUPPORTED          (pl_link_partner_gen2_supported             ),
    .PLINITIALLINKWIDTH                  (pl_initial_link_width                      ),
    .PLDIRECTEDCHANGEDONE                (pl_directed_change_done                    ),
    .PIPETXRCVRDET                       (pipe_tx_rcvr_det                           ),
    .PIPETXRESET                         (pipe_tx_reset                              ),
    .PIPETXRATE                          (pipe_tx_rate                               ),
    .PIPETXDEEMPH                        (pipe_tx_deemph                             ),
    .PIPETXMARGIN                        (pipe_tx_margin                             ),
    .PIPERX0POLARITY                     (pipe_rx0_polarity                          ),
    .PIPERX1POLARITY                     (pipe_rx1_polarity                          ),
    .PIPERX2POLARITY                     (pipe_rx2_polarity                          ),
    .PIPERX3POLARITY                     (pipe_rx3_polarity                          ),
    .PIPERX4POLARITY                     (pipe_rx4_polarity                          ),
    .PIPERX5POLARITY                     (pipe_rx5_polarity                          ),
    .PIPERX6POLARITY                     (pipe_rx6_polarity                          ),
    .PIPERX7POLARITY                     (pipe_rx7_polarity                          ),
    .PIPETX0COMPLIANCE                   (pipe_tx0_compliance                        ),
    .PIPETX1COMPLIANCE                   (pipe_tx1_compliance                        ),
    .PIPETX2COMPLIANCE                   (pipe_tx2_compliance                        ),
    .PIPETX3COMPLIANCE                   (pipe_tx3_compliance                        ),
    .PIPETX4COMPLIANCE                   (pipe_tx4_compliance                        ),
    .PIPETX5COMPLIANCE                   (pipe_tx5_compliance                        ),
    .PIPETX6COMPLIANCE                   (pipe_tx6_compliance                        ),
    .PIPETX7COMPLIANCE                   (pipe_tx7_compliance                        ),
    .PIPETX0CHARISK                      (pipe_tx0_char_is_k                         ),
    .PIPETX1CHARISK                      (pipe_tx1_char_is_k                         ),
    .PIPETX2CHARISK                      (pipe_tx2_char_is_k                         ),
    .PIPETX3CHARISK                      (pipe_tx3_char_is_k                         ),
    .PIPETX4CHARISK                      (pipe_tx4_char_is_k                         ),
    .PIPETX5CHARISK                      (pipe_tx5_char_is_k                         ),
    .PIPETX6CHARISK                      (pipe_tx6_char_is_k                         ),
    .PIPETX7CHARISK                      (pipe_tx7_char_is_k                         ),
    .PIPETX0DATA                         (pipe_tx0_data                              ),
    .PIPETX1DATA                         (pipe_tx1_data                              ),
    .PIPETX2DATA                         (pipe_tx2_data                              ),
    .PIPETX3DATA                         (pipe_tx3_data                              ),
    .PIPETX4DATA                         (pipe_tx4_data                              ),
    .PIPETX5DATA                         (pipe_tx5_data                              ),
    .PIPETX6DATA                         (pipe_tx6_data                              ),
    .PIPETX7DATA                         (pipe_tx7_data                              ),
    .PIPETX0ELECIDLE                     (pipe_tx0_elec_idle                         ),
    .PIPETX1ELECIDLE                     (pipe_tx1_elec_idle                         ),
    .PIPETX2ELECIDLE                     (pipe_tx2_elec_idle                         ),
    .PIPETX3ELECIDLE                     (pipe_tx3_elec_idle                         ),
    .PIPETX4ELECIDLE                     (pipe_tx4_elec_idle                         ),
    .PIPETX5ELECIDLE                     (pipe_tx5_elec_idle                         ),
    .PIPETX6ELECIDLE                     (pipe_tx6_elec_idle                         ),
    .PIPETX7ELECIDLE                     (pipe_tx7_elec_idle                         ),
    .PIPETX0POWERDOWN                    (pipe_tx0_powerdown                         ),
    .PIPETX1POWERDOWN                    (pipe_tx1_powerdown                         ),
    .PIPETX2POWERDOWN                    (pipe_tx2_powerdown                         ),
    .PIPETX3POWERDOWN                    (pipe_tx3_powerdown                         ),
    .PIPETX4POWERDOWN                    (pipe_tx4_powerdown                         ),
    .PIPETX5POWERDOWN                    (pipe_tx5_powerdown                         ),
    .PIPETX6POWERDOWN                    (pipe_tx6_powerdown                         ),
    .PIPETX7POWERDOWN                    (pipe_tx7_powerdown                         ),
`ifdef B_TESTMODE
    .PMVOUT                              (pmv_out                                    ),
    .SCANOUT                             (scanout                                    ),
`endif
    .USERRSTN                            (user_rst_n                                 ),
    .PLRECEIVEDHOTRST                    (pl_received_hot_rst                        ),
    .RECEIVEDFUNCLVLRSTN                 (received_func_lvl_rst_n                    ),
    .LNKCLKEN                            (lnk_clk_en                                 ),
    .CFGMGMTDO                           (cfg_mgmt_do                                ),
    .CFGMGMTRDWRDONEN                    (cfg_mgmt_rd_wr_done_n                      ),
    .CFGERRAERHEADERLOGSETN              (cfg_err_aer_headerlog_set_n                ),
    .CFGERRCPLRDYN                       (cfg_err_cpl_rdy_n                          ),
    .CFGINTERRUPTRDYN                    (cfg_interrupt_rdy_n                        ),
    .CFGINTERRUPTMMENABLE                (cfg_interrupt_mmenable                     ),
    .CFGINTERRUPTMSIENABLE               (cfg_interrupt_msienable                    ),
    .CFGINTERRUPTDO                      (cfg_interrupt_do                           ),
    .CFGINTERRUPTMSIXENABLE              (cfg_interrupt_msixenable                   ),
    .CFGINTERRUPTMSIXFM                  (cfg_interrupt_msixfm                       ),
    .CFGMSGRECEIVED                      (cfg_msg_received                           ),
    .CFGMSGDATA                          (cfg_msg_data                               ),
    .CFGMSGRECEIVEDERRCOR                (cfg_msg_received_err_cor                   ),
    .CFGMSGRECEIVEDERRNONFATAL           (cfg_msg_received_err_non_fatal             ),
    .CFGMSGRECEIVEDERRFATAL              (cfg_msg_received_err_fatal                 ),
    .CFGMSGRECEIVEDASSERTINTA            (cfg_msg_received_assert_int_a              ),
    .CFGMSGRECEIVEDDEASSERTINTA          (cfg_msg_received_deassert_int_a            ),
    .CFGMSGRECEIVEDASSERTINTB            (cfg_msg_received_assert_int_b              ),
    .CFGMSGRECEIVEDDEASSERTINTB          (cfg_msg_received_deassert_int_b            ),
    .CFGMSGRECEIVEDASSERTINTC            (cfg_msg_received_assert_int_c              ),
    .CFGMSGRECEIVEDDEASSERTINTC          (cfg_msg_received_deassert_int_c            ),
    .CFGMSGRECEIVEDASSERTINTD            (cfg_msg_received_assert_int_d              ),
    .CFGMSGRECEIVEDDEASSERTINTD          (cfg_msg_received_deassert_int_d            ),
    .CFGMSGRECEIVEDPMPME                 (cfg_msg_received_pm_pme                    ),
    .CFGMSGRECEIVEDPMETOACK              (cfg_msg_received_pme_to_ack                ),
    .CFGMSGRECEIVEDPMETO                 (cfg_msg_received_pme_to                    ),
    .CFGMSGRECEIVEDSETSLOTPOWERLIMIT     (cfg_msg_received_setslotpowerlimit         ),
    .CFGMSGRECEIVEDUNLOCK                (cfg_msg_received_unlock                    ),
    .CFGMSGRECEIVEDPMASNAK               (cfg_msg_received_pm_as_nak                 ),
    .CFGPCIELINKSTATE                    (cfg_pcie_link_state                        ),
    .CFGPMRCVASREQL1N                    (cfg_pm_rcv_as_req_l1_n                     ),
    .CFGPMRCVREQACKN                     (cfg_pm_rcv_req_ack_n                       ),
    .CFGPMRCVENTERL1N                    (cfg_pm_rcv_enter_l1_n                      ),
    .CFGPMRCVENTERL23N                   (cfg_pm_rcv_enter_l23_n                     ),
    .CFGPMCSRPOWERSTATE                  (cfg_pmcsr_powerstate                       ),
    .CFGPMCSRPMEEN                       (cfg_pmcsr_pme_en                           ),
    .CFGPMCSRPMESTATUS                   (cfg_pmcsr_pme_status                       ),
    .CFGTRANSACTION                      (cfg_transaction                            ),
    .CFGTRANSACTIONTYPE                  (cfg_transaction_type                       ),
    .CFGTRANSACTIONADDR                  (cfg_transaction_addr                       ),
    .CFGCOMMANDIOENABLE                  (cfg_command_io_enable                      ),
    .CFGCOMMANDMEMENABLE                 (cfg_command_mem_enable                     ),
    .CFGCOMMANDBUSMASTERENABLE           (cfg_command_bus_master_enable              ),
    .CFGCOMMANDINTERRUPTDISABLE          (cfg_command_interrupt_disable              ),
    .CFGCOMMANDSERREN                    (cfg_command_serr_en                        ),
    .CFGBRIDGESERREN                     (cfg_bridge_serr_en                         ),
    .CFGDEVSTATUSCORRERRDETECTED         (cfg_dev_status_corr_err_detected           ),
    .CFGDEVSTATUSNONFATALERRDETECTED     (cfg_dev_status_non_fatal_err_detected      ),
    .CFGDEVSTATUSFATALERRDETECTED        (cfg_dev_status_fatal_err_detected          ),
    .CFGDEVSTATUSURDETECTED              (cfg_dev_status_ur_detected                 ),
    .CFGDEVCONTROLCORRERRREPORTINGEN     (cfg_dev_control_corr_err_reporting_en      ),
    .CFGDEVCONTROLNONFATALREPORTINGEN    (cfg_dev_control_non_fatal_reporting_en     ),
    .CFGDEVCONTROLFATALERRREPORTINGEN    (cfg_dev_control_fatal_err_reporting_en     ),
    .CFGDEVCONTROLURERRREPORTINGEN       (cfg_dev_control_ur_err_reporting_en        ),
    .CFGDEVCONTROLENABLERO               (cfg_dev_control_enable_ro                  ),
    .CFGDEVCONTROLMAXPAYLOAD             (cfg_dev_control_max_payload                ),
    .CFGDEVCONTROLEXTTAGEN               (cfg_dev_control_ext_tag_en                 ),
    .CFGDEVCONTROLPHANTOMEN              (cfg_dev_control_phantom_en                 ),
    .CFGDEVCONTROLAUXPOWEREN             (cfg_dev_control_aux_power_en               ),
    .CFGDEVCONTROLNOSNOOPEN              (cfg_dev_control_no_snoop_en                ),
    .CFGDEVCONTROLMAXREADREQ             (cfg_dev_control_max_read_req               ),
    .CFGLINKSTATUSCURRENTSPEED           (cfg_link_status_current_speed              ),
    .CFGLINKSTATUSNEGOTIATEDWIDTH        (cfg_link_status_negotiated_width           ),
    .CFGLINKSTATUSLINKTRAINING           (cfg_link_status_link_training              ),
    .CFGLINKSTATUSDLLACTIVE              (cfg_link_status_dll_active                 ),
    .CFGLINKSTATUSBANDWIDTHSTATUS        (cfg_link_status_bandwidth_status           ),
    .CFGLINKSTATUSAUTOBANDWIDTHSTATUS    (cfg_link_status_auto_bandwidth_status      ),
    .CFGLINKCONTROLASPMCONTROL           (cfg_link_control_aspm_control              ),
    .CFGLINKCONTROLRCB                   (cfg_link_control_rcb                       ),
    .CFGLINKCONTROLLINKDISABLE           (cfg_link_control_link_disable              ),
    .CFGLINKCONTROLRETRAINLINK           (cfg_link_control_retrain_link              ),
    .CFGLINKCONTROLCOMMONCLOCK           (cfg_link_control_common_clock              ),
    .CFGLINKCONTROLEXTENDEDSYNC          (cfg_link_control_extended_sync             ),
    .CFGLINKCONTROLCLOCKPMEN             (cfg_link_control_clock_pm_en               ),
    .CFGLINKCONTROLHWAUTOWIDTHDIS        (cfg_link_control_hw_auto_width_dis         ),
    .CFGLINKCONTROLBANDWIDTHINTEN        (cfg_link_control_bandwidth_int_en          ),
    .CFGLINKCONTROLAUTOBANDWIDTHINTEN    (cfg_link_control_auto_bandwidth_int_en     ),
    .CFGDEVCONTROL2CPLTIMEOUTVAL         (cfg_dev_control2_cpl_timeout_val           ),
    .CFGDEVCONTROL2CPLTIMEOUTDIS         (cfg_dev_control2_cpl_timeout_dis           ),
    .CFGDEVCONTROL2ARIFORWARDEN          (cfg_dev_control2_ari_forward_en            ),
    .CFGDEVCONTROL2ATOMICREQUESTEREN     (cfg_dev_control2_atomic_requester_en       ),
    .CFGDEVCONTROL2ATOMICEGRESSBLOCK     (cfg_dev_control2_atomic_egress_block       ),
    .CFGDEVCONTROL2IDOREQEN              (cfg_dev_control2_ido_req_en                ),
    .CFGDEVCONTROL2IDOCPLEN              (cfg_dev_control2_ido_cpl_en                ),
    .CFGDEVCONTROL2LTREN                 (cfg_dev_control2_ltr_en                    ),
    .CFGDEVCONTROL2TLPPREFIXBLOCK        (cfg_dev_control2_tlp_prefix_block          ),
    .CFGSLOTCONTROLELECTROMECHILCTLPULSE (cfg_slot_control_electromech_il_ctl_pulse  ),
    .CFGROOTCONTROLSYSERRCORRERREN       (cfg_root_control_syserr_corr_err_en        ),
    .CFGROOTCONTROLSYSERRNONFATALERREN   (cfg_root_control_syserr_non_fatal_err_en   ),
    .CFGROOTCONTROLSYSERRFATALERREN      (cfg_root_control_syserr_fatal_err_en       ),
    .CFGROOTCONTROLPMEINTEN              (cfg_root_control_pme_int_en                ),
    .CFGAERECRCCHECKEN                   (cfg_aer_ecrc_check_en                      ),
    .CFGAERECRCGENEN                     (cfg_aer_ecrc_gen_en                        ),
    .CFGAERROOTERRCORRERRREPORTINGEN     (cfg_aer_rooterr_corr_err_reporting_en      ),
    .CFGAERROOTERRNONFATALERRREPORTINGEN (cfg_aer_rooterr_non_fatal_err_reporting_en ),
    .CFGAERROOTERRFATALERRREPORTINGEN    (cfg_aer_rooterr_fatal_err_reporting_en     ),
    .CFGAERROOTERRCORRERRRECEIVED        (cfg_aer_rooterr_corr_err_received          ),
    .CFGAERROOTERRNONFATALERRRECEIVED    (cfg_aer_rooterr_non_fatal_err_received     ),
    .CFGAERROOTERRFATALERRRECEIVED       (cfg_aer_rooterr_fatal_err_received         ),
    .CFGVCTCVCMAP                        (cfg_vc_tcvc_map                            ),
    .DRPRDY                              (drp_rdy                                    ),
    .DRPDO                               (drp_do                                     ),
    //.DRPWRITEEN                        (drp_write_en                               ),
    //.DRPWRITEPORT0                     (drp_write_port_0                           ),
    //.DRPWRITEPORT1                     (drp_write_port_1                           ),
    //.DRPWRITEPORT2                     (drp_write_port_2                           ),
    //.DRPWRITEPORT3                     (drp_write_port_3                           ),
    //.DRPWRITEPORT4                     (drp_write_port_4                           ),
    //.DRPWRITEPORT5                     (drp_write_port_5                           ),
    //.DRPWRITEPORT6                     (drp_write_port_6                           ),
    //.DRPWRITEPORT7                     (drp_write_port_7                           ),
    //.DRPWRITEPORT8                     (drp_write_port_8                           ),
    //.DRPWRITEPORT9                     (drp_write_port_9                           ),
    //.DRPWRITEPORT10                    (drp_write_port_10                          ),
    //.DRPWRITEPORT11                    (drp_write_port_11                          ),
    //.DRPWRITEPORT12                    (drp_write_port_12                          ),
    //.DRPREADADDR                       (drp_read_addr                              ),
    .DBGVECA                             (dbg_vec_a                                  ),
    .DBGVECB                             (dbg_vec_b                                  ),
    .DBGVECC                             (dbg_vec_c                                  ),
    .DBGSCLRA                            (dbg_sclr_a                                 ),
    .DBGSCLRB                            (dbg_sclr_b                                 ),
    .DBGSCLRC                            (dbg_sclr_c                                 ),
    .DBGSCLRD                            (dbg_sclr_d                                 ),
    .DBGSCLRE                            (dbg_sclr_e                                 ),
    .DBGSCLRF                            (dbg_sclr_f                                 ),
    .DBGSCLRG                            (dbg_sclr_g                                 ),
    .DBGSCLRH                            (dbg_sclr_h                                 ),
    .DBGSCLRI                            (dbg_sclr_i                                 ),
    .DBGSCLRJ                            (dbg_sclr_j                                 ),
    .DBGSCLRK                            (dbg_sclr_k                                 ),
    .PLDBGVEC                            (pl_dbg_vec                                 )
    //.XILUNCONNOUT                      (xil_unconn_out                             )
  );

//end pcie_7x_0_pcie_7x }


  //------------------------------------------------------------------------------------------------------------------//
  // PIPE Interface PIPELINE Module                                                                                   //
  //------------------------------------------------------------------------------------------------------------------//
pcie_7x_0_pcie_pipe_pipeline # (

    .LINK_CAP_MAX_LINK_WIDTH ( LINK_CAP_MAX_LINK_WIDTH ),
    .PIPE_PIPELINE_STAGES    ( PIPE_PIPELINE_STAGES )

  )
  pcie_pipe_pipeline_i (

    // Pipe Per-Link Signals
    .pipe_tx_rcvr_det_i       (pipe_tx_rcvr_det),
    .pipe_tx_reset_i          (1'b0), //MV?
    .pipe_tx_rate_i           (pipe_tx_rate),
    .pipe_tx_deemph_i         (pipe_tx_deemph),
    .pipe_tx_margin_i         (pipe_tx_margin),
    .pipe_tx_swing_i          (1'b0),

    .pipe_tx_rcvr_det_o       (pipe_tx_rcvr_det_gt),
    .pipe_tx_reset_o          ( ),
    .pipe_tx_rate_o           (pipe_tx_rate_gt),
    .pipe_tx_deemph_o         (pipe_tx_deemph_gt),
    .pipe_tx_margin_o         (pipe_tx_margin_gt),
    .pipe_tx_swing_o          ( ),

    // Pipe Per-Lane Signals - Lane 0

    .pipe_rx0_char_is_k_o     (pipe_rx0_char_is_k     ),
    .pipe_rx0_data_o          (pipe_rx0_data          ),
    .pipe_rx0_valid_o         (pipe_rx0_valid         ),
    .pipe_rx0_chanisaligned_o (pipe_rx0_chanisaligned ),
    .pipe_rx0_status_o        (pipe_rx0_status        ),
    .pipe_rx0_phy_status_o    (pipe_rx0_phy_status    ),
    .pipe_rx0_elec_idle_i     (pipe_rx0_elec_idle_gt  ),
    .pipe_rx0_polarity_i      (pipe_rx0_polarity      ),
    .pipe_tx0_compliance_i    (pipe_tx0_compliance    ),
    .pipe_tx0_char_is_k_i     (pipe_tx0_char_is_k     ),
    .pipe_tx0_data_i          (pipe_tx0_data          ),
    .pipe_tx0_elec_idle_i     (pipe_tx0_elec_idle     ),
    .pipe_tx0_powerdown_i     (pipe_tx0_powerdown     ),

    .pipe_rx0_char_is_k_i     (pipe_rx0_char_is_k_gt  ),
    .pipe_rx0_data_i          (pipe_rx0_data_gt       ),
    .pipe_rx0_valid_i         (pipe_rx0_valid_gt      ),
    .pipe_rx0_chanisaligned_i (pipe_rx0_chanisaligned_gt),
    .pipe_rx0_status_i        (pipe_rx0_status_gt     ),
    .pipe_rx0_phy_status_i    (pipe_rx0_phy_status_gt ),
    .pipe_rx0_elec_idle_o     (pipe_rx0_elec_idle     ),
    .pipe_rx0_polarity_o      (pipe_rx0_polarity_gt   ),
    .pipe_tx0_compliance_o    (pipe_tx0_compliance_gt ),
    .pipe_tx0_char_is_k_o     (pipe_tx0_char_is_k_gt  ),
    .pipe_tx0_data_o          (pipe_tx0_data_gt       ),
    .pipe_tx0_elec_idle_o     (pipe_tx0_elec_idle_gt  ),
    .pipe_tx0_powerdown_o     (pipe_tx0_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 1

    .pipe_rx1_char_is_k_o     (pipe_rx1_char_is_k     ),
    .pipe_rx1_data_o          (pipe_rx1_data          ),
    .pipe_rx1_valid_o         (pipe_rx1_valid         ),
    .pipe_rx1_chanisaligned_o (pipe_rx1_chanisaligned ),
    .pipe_rx1_status_o        (pipe_rx1_status        ),
    .pipe_rx1_phy_status_o    (pipe_rx1_phy_status    ),
    .pipe_rx1_elec_idle_i     (pipe_rx1_elec_idle_gt  ),
    .pipe_rx1_polarity_i      (pipe_rx1_polarity      ),
    .pipe_tx1_compliance_i    (pipe_tx1_compliance    ),
    .pipe_tx1_char_is_k_i     (pipe_tx1_char_is_k     ),
    .pipe_tx1_data_i          (pipe_tx1_data          ),
    .pipe_tx1_elec_idle_i     (pipe_tx1_elec_idle     ),
    .pipe_tx1_powerdown_i     (pipe_tx1_powerdown     ),

    .pipe_rx1_char_is_k_i     (pipe_rx1_char_is_k_gt  ),
    .pipe_rx1_data_i          (pipe_rx1_data_gt       ),
    .pipe_rx1_valid_i         (pipe_rx1_valid_gt      ),
    .pipe_rx1_chanisaligned_i (pipe_rx1_chanisaligned_gt),
    .pipe_rx1_status_i        (pipe_rx1_status_gt     ),
    .pipe_rx1_phy_status_i    (pipe_rx1_phy_status_gt ),
    .pipe_rx1_elec_idle_o     (pipe_rx1_elec_idle     ),
    .pipe_rx1_polarity_o      (pipe_rx1_polarity_gt   ),
    .pipe_tx1_compliance_o    (pipe_tx1_compliance_gt ),
    .pipe_tx1_char_is_k_o     (pipe_tx1_char_is_k_gt  ),
    .pipe_tx1_data_o          (pipe_tx1_data_gt       ),
    .pipe_tx1_elec_idle_o     (pipe_tx1_elec_idle_gt  ),
    .pipe_tx1_powerdown_o     (pipe_tx1_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 2

    .pipe_rx2_char_is_k_o     (pipe_rx2_char_is_k     ),
    .pipe_rx2_data_o          (pipe_rx2_data          ),
    .pipe_rx2_valid_o         (pipe_rx2_valid         ),
    .pipe_rx2_chanisaligned_o (pipe_rx2_chanisaligned ),
    .pipe_rx2_status_o        (pipe_rx2_status        ),
    .pipe_rx2_phy_status_o    (pipe_rx2_phy_status    ),
    .pipe_rx2_elec_idle_i     (pipe_rx2_elec_idle_gt  ),
    .pipe_rx2_polarity_i      (pipe_rx2_polarity      ),
    .pipe_tx2_compliance_i    (pipe_tx2_compliance    ),
    .pipe_tx2_char_is_k_i     (pipe_tx2_char_is_k     ),
    .pipe_tx2_data_i          (pipe_tx2_data          ),
    .pipe_tx2_elec_idle_i     (pipe_tx2_elec_idle     ),
    .pipe_tx2_powerdown_i     (pipe_tx2_powerdown     ),

    .pipe_rx2_char_is_k_i     (pipe_rx2_char_is_k_gt  ),
    .pipe_rx2_data_i          (pipe_rx2_data_gt       ),
    .pipe_rx2_valid_i         (pipe_rx2_valid_gt      ),
    .pipe_rx2_chanisaligned_i (pipe_rx2_chanisaligned_gt),
    .pipe_rx2_status_i        (pipe_rx2_status_gt     ),
    .pipe_rx2_phy_status_i    (pipe_rx2_phy_status_gt ),
    .pipe_rx2_elec_idle_o     (pipe_rx2_elec_idle     ),
    .pipe_rx2_polarity_o      (pipe_rx2_polarity_gt   ),
    .pipe_tx2_compliance_o    (pipe_tx2_compliance_gt ),
    .pipe_tx2_char_is_k_o     (pipe_tx2_char_is_k_gt  ),
    .pipe_tx2_data_o          (pipe_tx2_data_gt       ),
    .pipe_tx2_elec_idle_o     (pipe_tx2_elec_idle_gt  ),
    .pipe_tx2_powerdown_o     (pipe_tx2_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 3

    .pipe_rx3_char_is_k_o     (pipe_rx3_char_is_k     ),
    .pipe_rx3_data_o          (pipe_rx3_data          ),
    .pipe_rx3_valid_o         (pipe_rx3_valid         ),
    .pipe_rx3_chanisaligned_o (pipe_rx3_chanisaligned ),
    .pipe_rx3_status_o        (pipe_rx3_status        ),
    .pipe_rx3_phy_status_o    (pipe_rx3_phy_status    ),
    .pipe_rx3_elec_idle_i     (pipe_rx3_elec_idle_gt  ),
    .pipe_rx3_polarity_i      (pipe_rx3_polarity      ),
    .pipe_tx3_compliance_i    (pipe_tx3_compliance    ),
    .pipe_tx3_char_is_k_i     (pipe_tx3_char_is_k     ),
    .pipe_tx3_data_i          (pipe_tx3_data          ),
    .pipe_tx3_elec_idle_i     (pipe_tx3_elec_idle     ),
    .pipe_tx3_powerdown_i     (pipe_tx3_powerdown     ),

    .pipe_rx3_char_is_k_i     (pipe_rx3_char_is_k_gt  ),
    .pipe_rx3_data_i          (pipe_rx3_data_gt       ),
    .pipe_rx3_valid_i         (pipe_rx3_valid_gt      ),
    .pipe_rx3_chanisaligned_i (pipe_rx3_chanisaligned_gt),
    .pipe_rx3_status_i        (pipe_rx3_status_gt     ),
    .pipe_rx3_phy_status_i    (pipe_rx3_phy_status_gt ),
    .pipe_rx3_elec_idle_o     (pipe_rx3_elec_idle     ),
    .pipe_rx3_polarity_o      (pipe_rx3_polarity_gt   ),
    .pipe_tx3_compliance_o    (pipe_tx3_compliance_gt ),
    .pipe_tx3_char_is_k_o     (pipe_tx3_char_is_k_gt  ),
    .pipe_tx3_data_o          (pipe_tx3_data_gt       ),
    .pipe_tx3_elec_idle_o     (pipe_tx3_elec_idle_gt  ),
    .pipe_tx3_powerdown_o     (pipe_tx3_powerdown_gt  ),

     // Pipe Per-Lane Signals - Lane 4

    .pipe_rx4_char_is_k_o     (pipe_rx4_char_is_k     ),
    .pipe_rx4_data_o          (pipe_rx4_data          ),
    .pipe_rx4_valid_o         (pipe_rx4_valid         ),
    .pipe_rx4_chanisaligned_o (pipe_rx4_chanisaligned ),
    .pipe_rx4_status_o        (pipe_rx4_status        ),
    .pipe_rx4_phy_status_o    (pipe_rx4_phy_status    ),
    .pipe_rx4_elec_idle_i     (pipe_rx4_elec_idle_gt  ),
    .pipe_rx4_polarity_i      (pipe_rx4_polarity      ),
    .pipe_tx4_compliance_i    (pipe_tx4_compliance    ),
    .pipe_tx4_char_is_k_i     (pipe_tx4_char_is_k     ),
    .pipe_tx4_data_i          (pipe_tx4_data          ),
    .pipe_tx4_elec_idle_i     (pipe_tx4_elec_idle     ),
    .pipe_tx4_powerdown_i     (pipe_tx4_powerdown     ),
    .pipe_rx4_char_is_k_i     (pipe_rx4_char_is_k_gt  ),
    .pipe_rx4_data_i          (pipe_rx4_data_gt       ),
    .pipe_rx4_valid_i         (pipe_rx4_valid_gt      ),
    .pipe_rx4_chanisaligned_i (pipe_rx4_chanisaligned_gt),
    .pipe_rx4_status_i        (pipe_rx4_status_gt     ),
    .pipe_rx4_phy_status_i    (pipe_rx4_phy_status_gt ),
    .pipe_rx4_elec_idle_o     (pipe_rx4_elec_idle     ),
    .pipe_rx4_polarity_o      (pipe_rx4_polarity_gt   ),
    .pipe_tx4_compliance_o    (pipe_tx4_compliance_gt ),
    .pipe_tx4_char_is_k_o     (pipe_tx4_char_is_k_gt  ),
    .pipe_tx4_data_o          (pipe_tx4_data_gt       ),
    .pipe_tx4_elec_idle_o     (pipe_tx4_elec_idle_gt  ),
    .pipe_tx4_powerdown_o     (pipe_tx4_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 5

    .pipe_rx5_char_is_k_o     (pipe_rx5_char_is_k     ),
    .pipe_rx5_data_o          (pipe_rx5_data          ),
    .pipe_rx5_valid_o         (pipe_rx5_valid         ),
    .pipe_rx5_chanisaligned_o (pipe_rx5_chanisaligned ),
    .pipe_rx5_status_o        (pipe_rx5_status        ),
    .pipe_rx5_phy_status_o    (pipe_rx5_phy_status    ),
    .pipe_rx5_elec_idle_i     (pipe_rx5_elec_idle_gt  ),
    .pipe_rx5_polarity_i      (pipe_rx5_polarity      ),
    .pipe_tx5_compliance_i    (pipe_tx5_compliance    ),
    .pipe_tx5_char_is_k_i     (pipe_tx5_char_is_k     ),
    .pipe_tx5_data_i          (pipe_tx5_data          ),
    .pipe_tx5_elec_idle_i     (pipe_tx5_elec_idle     ),
    .pipe_tx5_powerdown_i     (pipe_tx5_powerdown     ),
    .pipe_rx5_char_is_k_i     (pipe_rx5_char_is_k_gt  ),
    .pipe_rx5_data_i          (pipe_rx5_data_gt       ),
    .pipe_rx5_valid_i         (pipe_rx5_valid_gt      ),
    .pipe_rx5_chanisaligned_i (pipe_rx5_chanisaligned_gt),
    .pipe_rx5_status_i        (pipe_rx5_status_gt     ),
    .pipe_rx5_phy_status_i    (pipe_rx5_phy_status_gt ),
    .pipe_rx5_elec_idle_o     (pipe_rx5_elec_idle     ),
    .pipe_rx5_polarity_o      (pipe_rx5_polarity_gt   ),
    .pipe_tx5_compliance_o    (pipe_tx5_compliance_gt ),
    .pipe_tx5_char_is_k_o     (pipe_tx5_char_is_k_gt  ),
    .pipe_tx5_data_o          (pipe_tx5_data_gt       ),
    .pipe_tx5_elec_idle_o     (pipe_tx5_elec_idle_gt  ),
    .pipe_tx5_powerdown_o     (pipe_tx5_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 6

    .pipe_rx6_char_is_k_o     (pipe_rx6_char_is_k     ),
    .pipe_rx6_data_o          (pipe_rx6_data          ),
    .pipe_rx6_valid_o         (pipe_rx6_valid         ),
    .pipe_rx6_chanisaligned_o (pipe_rx6_chanisaligned ),
    .pipe_rx6_status_o        (pipe_rx6_status        ),
    .pipe_rx6_phy_status_o    (pipe_rx6_phy_status    ),
    .pipe_rx6_elec_idle_i     (pipe_rx6_elec_idle_gt  ),
    .pipe_rx6_polarity_i      (pipe_rx6_polarity      ),
    .pipe_tx6_compliance_i    (pipe_tx6_compliance    ),
    .pipe_tx6_char_is_k_i     (pipe_tx6_char_is_k     ),
    .pipe_tx6_data_i          (pipe_tx6_data          ),
    .pipe_tx6_elec_idle_i     (pipe_tx6_elec_idle     ),
    .pipe_tx6_powerdown_i     (pipe_tx6_powerdown     ),
    .pipe_rx6_char_is_k_i     (pipe_rx6_char_is_k_gt  ),
    .pipe_rx6_data_i          (pipe_rx6_data_gt       ),
    .pipe_rx6_valid_i         (pipe_rx6_valid_gt      ),
    .pipe_rx6_chanisaligned_i (pipe_rx6_chanisaligned_gt),
    .pipe_rx6_status_i        (pipe_rx6_status_gt     ),
    .pipe_rx6_phy_status_i    (pipe_rx6_phy_status_gt ),
    .pipe_rx6_elec_idle_o     (pipe_rx6_elec_idle     ),
    .pipe_rx6_polarity_o      (pipe_rx6_polarity_gt   ),
    .pipe_tx6_compliance_o    (pipe_tx6_compliance_gt ),
    .pipe_tx6_char_is_k_o     (pipe_tx6_char_is_k_gt  ),
    .pipe_tx6_data_o          (pipe_tx6_data_gt       ),
    .pipe_tx6_elec_idle_o     (pipe_tx6_elec_idle_gt  ),
    .pipe_tx6_powerdown_o     (pipe_tx6_powerdown_gt  ),

    // Pipe Per-Lane Signals - Lane 7

    .pipe_rx7_char_is_k_o     (pipe_rx7_char_is_k     ),
    .pipe_rx7_data_o          (pipe_rx7_data          ),
    .pipe_rx7_valid_o         (pipe_rx7_valid         ),
    .pipe_rx7_chanisaligned_o (pipe_rx7_chanisaligned ),
    .pipe_rx7_status_o        (pipe_rx7_status        ),
    .pipe_rx7_phy_status_o    (pipe_rx7_phy_status    ),
    .pipe_rx7_elec_idle_i     (pipe_rx7_elec_idle_gt  ),
    .pipe_rx7_polarity_i      (pipe_rx7_polarity      ),
    .pipe_tx7_compliance_i    (pipe_tx7_compliance    ),
    .pipe_tx7_char_is_k_i     (pipe_tx7_char_is_k     ),
    .pipe_tx7_data_i          (pipe_tx7_data          ),
    .pipe_tx7_elec_idle_i     (pipe_tx7_elec_idle     ),
    .pipe_tx7_powerdown_i     (pipe_tx7_powerdown     ),
    .pipe_rx7_char_is_k_i     (pipe_rx7_char_is_k_gt  ),
    .pipe_rx7_data_i          (pipe_rx7_data_gt       ),
    .pipe_rx7_valid_i         (pipe_rx7_valid_gt      ),
    .pipe_rx7_chanisaligned_i (pipe_rx7_chanisaligned_gt),
    .pipe_rx7_status_i        (pipe_rx7_status_gt     ),
    .pipe_rx7_phy_status_i    (pipe_rx7_phy_status_gt ),
    .pipe_rx7_elec_idle_o     (pipe_rx7_elec_idle     ),
    .pipe_rx7_polarity_o      (pipe_rx7_polarity_gt   ),
    .pipe_tx7_compliance_o    (pipe_tx7_compliance_gt ),
    .pipe_tx7_char_is_k_o     (pipe_tx7_char_is_k_gt  ),
    .pipe_tx7_data_o          (pipe_tx7_data_gt       ),
    .pipe_tx7_elec_idle_o     (pipe_tx7_elec_idle_gt  ),
    .pipe_tx7_powerdown_o     (pipe_tx7_powerdown_gt  ),

    // Non PIPE signals
    .pipe_clk                 (pipe_clk               ),
    .rst_n                    (phy_rdy_n              )
  );



//end pcie_7x_0_pcie_top }

  //------------------------------------------------------------------------------------------------------------------//
  // **** V7/K7/A7 GTX Wrapper ****                                                                                   //
  //   The 7-Series GTX Wrapper includes the following:                                                               //
  //     1) Virtex-7 GTX                                                                                              //
  //     2) Kintex-7 GTX                                                                                              //
  //     3) Artix-7  GTP                                                                                              //
  //------------------------------------------------------------------------------------------------------------------//
pcie_7x_0_gt_top #(
    .LINK_CAP_MAX_LINK_WIDTH       ( LINK_CAP_MAX_LINK_WIDTH ),
    .REF_CLK_FREQ                  ( REF_CLK_FREQ ),
    .USER_CLK_FREQ                 ( USER_CLK_FREQ ),
    .USER_CLK2_DIV2                ( USER_CLK2_DIV2 ),

    // synthesis translate_off
    .PL_FAST_TRAIN                 ( ENABLE_FAST_SIM_TRAINING ),
    // synthesis translate_on

    .PCIE_EXT_CLK                  ( PCIE_EXT_CLK ),
    .PCIE_USE_MODE                 ( PCIE_USE_MODE ),
    .PCIE_GT_DEVICE                ( PCIE_GT_DEVICE ),
    .PCIE_PLL_SEL                  ( PCIE_PLL_SEL ),
    .PCIE_ASYNC_EN                 ( PCIE_ASYNC_EN ),
    .PCIE_TXBUF_EN                 ( PCIE_TXBUF_EN ),
    .PCIE_CHAN_BOND                ( PCIE_CHAN_BOND )
  ) gt_top_i (
    // pl ltssm
    .pl_ltssm_state                ( pl_ltssm_state_int ),

    // Pipe Common Signals
    .pipe_tx_rcvr_det              ( pipe_tx_rcvr_det_gt  ),
    .pipe_tx_reset                 ( 1'b0                 ),
    .pipe_tx_rate                  ( pipe_tx_rate_gt      ),
    .pipe_tx_deemph                ( pipe_tx_deemph_gt    ),
    .pipe_tx_margin                ( pipe_tx_margin_gt    ),
    .pipe_tx_swing                 ( 1'b0                 ),

    // Pipe Per-Lane Signals - Lane 0
    .pipe_rx0_char_is_k            ( pipe_rx0_char_is_k_gt),
    .pipe_rx0_data                 ( pipe_rx0_data_gt     ),
    .pipe_rx0_valid                ( pipe_rx0_valid_gt    ),
    .pipe_rx0_chanisaligned        ( pipe_rx0_chanisaligned_gt   ),
    .pipe_rx0_status               ( pipe_rx0_status_gt      ),
    .pipe_rx0_phy_status           ( pipe_rx0_phy_status_gt  ),
    .pipe_rx0_elec_idle            ( pipe_rx0_elec_idle_gt   ),
    .pipe_rx0_polarity             ( pipe_rx0_polarity_gt    ),
    .pipe_tx0_compliance           ( pipe_tx0_compliance_gt  ),
    .pipe_tx0_char_is_k            ( pipe_tx0_char_is_k_gt   ),
    .pipe_tx0_data                 ( pipe_tx0_data_gt        ),
    .pipe_tx0_elec_idle            ( pipe_tx0_elec_idle_gt   ),
    .pipe_tx0_powerdown            ( pipe_tx0_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 1

    .pipe_rx1_char_is_k            ( pipe_rx1_char_is_k_gt),
    .pipe_rx1_data                 ( pipe_rx1_data_gt     ),
    .pipe_rx1_valid                ( pipe_rx1_valid_gt    ),
    .pipe_rx1_chanisaligned        ( pipe_rx1_chanisaligned_gt   ),
    .pipe_rx1_status               ( pipe_rx1_status_gt      ),
    .pipe_rx1_phy_status           ( pipe_rx1_phy_status_gt  ),
    .pipe_rx1_elec_idle            ( pipe_rx1_elec_idle_gt   ),
    .pipe_rx1_polarity             ( pipe_rx1_polarity_gt    ),
    .pipe_tx1_compliance           ( pipe_tx1_compliance_gt  ),
    .pipe_tx1_char_is_k            ( pipe_tx1_char_is_k_gt   ),
    .pipe_tx1_data                 ( pipe_tx1_data_gt        ),
    .pipe_tx1_elec_idle            ( pipe_tx1_elec_idle_gt   ),
    .pipe_tx1_powerdown            ( pipe_tx1_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 2

    .pipe_rx2_char_is_k            ( pipe_rx2_char_is_k_gt),
    .pipe_rx2_data                 ( pipe_rx2_data_gt     ),
    .pipe_rx2_valid                ( pipe_rx2_valid_gt    ),
    .pipe_rx2_chanisaligned        ( pipe_rx2_chanisaligned_gt   ),
    .pipe_rx2_status               ( pipe_rx2_status_gt      ),
    .pipe_rx2_phy_status           ( pipe_rx2_phy_status_gt  ),
    .pipe_rx2_elec_idle            ( pipe_rx2_elec_idle_gt   ),
    .pipe_rx2_polarity             ( pipe_rx2_polarity_gt    ),
    .pipe_tx2_compliance           ( pipe_tx2_compliance_gt  ),
    .pipe_tx2_char_is_k            ( pipe_tx2_char_is_k_gt   ),
    .pipe_tx2_data                 ( pipe_tx2_data_gt        ),
    .pipe_tx2_elec_idle            ( pipe_tx2_elec_idle_gt   ),
    .pipe_tx2_powerdown            ( pipe_tx2_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 3

    .pipe_rx3_char_is_k            ( pipe_rx3_char_is_k_gt),
    .pipe_rx3_data                 ( pipe_rx3_data_gt     ),
    .pipe_rx3_valid                ( pipe_rx3_valid_gt    ),
    .pipe_rx3_chanisaligned        ( pipe_rx3_chanisaligned_gt   ),
    .pipe_rx3_status               ( pipe_rx3_status_gt      ),
    .pipe_rx3_phy_status           ( pipe_rx3_phy_status_gt  ),
    .pipe_rx3_elec_idle            ( pipe_rx3_elec_idle_gt   ),
    .pipe_rx3_polarity             ( pipe_rx3_polarity_gt    ),
    .pipe_tx3_compliance           ( pipe_tx3_compliance_gt  ),
    .pipe_tx3_char_is_k            ( pipe_tx3_char_is_k_gt   ),
    .pipe_tx3_data                 ( pipe_tx3_data_gt        ),
    .pipe_tx3_elec_idle            ( pipe_tx3_elec_idle_gt   ),
    .pipe_tx3_powerdown            ( pipe_tx3_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 4

    .pipe_rx4_char_is_k            ( pipe_rx4_char_is_k_gt),
    .pipe_rx4_data                 ( pipe_rx4_data_gt     ),
    .pipe_rx4_valid                ( pipe_rx4_valid_gt    ),
    .pipe_rx4_chanisaligned        ( pipe_rx4_chanisaligned_gt   ),
    .pipe_rx4_status               ( pipe_rx4_status_gt      ),
    .pipe_rx4_phy_status           ( pipe_rx4_phy_status_gt  ),
    .pipe_rx4_elec_idle            ( pipe_rx4_elec_idle_gt   ),
    .pipe_rx4_polarity             ( pipe_rx4_polarity_gt    ),
    .pipe_tx4_compliance           ( pipe_tx4_compliance_gt  ),
    .pipe_tx4_char_is_k            ( pipe_tx4_char_is_k_gt   ),
    .pipe_tx4_data                 ( pipe_tx4_data_gt        ),
    .pipe_tx4_elec_idle            ( pipe_tx4_elec_idle_gt   ),
    .pipe_tx4_powerdown            ( pipe_tx4_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 5

    .pipe_rx5_char_is_k            ( pipe_rx5_char_is_k_gt),
    .pipe_rx5_data                 ( pipe_rx5_data_gt     ),
    .pipe_rx5_valid                ( pipe_rx5_valid_gt    ),
    .pipe_rx5_chanisaligned        ( pipe_rx5_chanisaligned_gt   ),
    .pipe_rx5_status               ( pipe_rx5_status_gt      ),
    .pipe_rx5_phy_status           ( pipe_rx5_phy_status_gt  ),
    .pipe_rx5_elec_idle            ( pipe_rx5_elec_idle_gt   ),
    .pipe_rx5_polarity             ( pipe_rx5_polarity_gt    ),
    .pipe_tx5_compliance           ( pipe_tx5_compliance_gt  ),
    .pipe_tx5_char_is_k            ( pipe_tx5_char_is_k_gt   ),
    .pipe_tx5_data                 ( pipe_tx5_data_gt        ),
    .pipe_tx5_elec_idle            ( pipe_tx5_elec_idle_gt   ),
    .pipe_tx5_powerdown            ( pipe_tx5_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 6

    .pipe_rx6_char_is_k            ( pipe_rx6_char_is_k_gt),
    .pipe_rx6_data                 ( pipe_rx6_data_gt     ),
    .pipe_rx6_valid                ( pipe_rx6_valid_gt    ),
    .pipe_rx6_chanisaligned        ( pipe_rx6_chanisaligned_gt   ),
    .pipe_rx6_status               ( pipe_rx6_status_gt      ),
    .pipe_rx6_phy_status           ( pipe_rx6_phy_status_gt  ),
    .pipe_rx6_elec_idle            ( pipe_rx6_elec_idle_gt   ),
    .pipe_rx6_polarity             ( pipe_rx6_polarity_gt    ),
    .pipe_tx6_compliance           ( pipe_tx6_compliance_gt  ),
    .pipe_tx6_char_is_k            ( pipe_tx6_char_is_k_gt   ),
    .pipe_tx6_data                 ( pipe_tx6_data_gt        ),
    .pipe_tx6_elec_idle            ( pipe_tx6_elec_idle_gt   ),
    .pipe_tx6_powerdown            ( pipe_tx6_powerdown_gt   ),

    // Pipe Per-Lane Signals - Lane 7

    .pipe_rx7_char_is_k            ( pipe_rx7_char_is_k_gt),
    .pipe_rx7_data                 ( pipe_rx7_data_gt     ),
    .pipe_rx7_valid                ( pipe_rx7_valid_gt    ),
    .pipe_rx7_chanisaligned        ( pipe_rx7_chanisaligned_gt   ),
    .pipe_rx7_status               ( pipe_rx7_status_gt      ),
    .pipe_rx7_phy_status           ( pipe_rx7_phy_status_gt  ),
    .pipe_rx7_elec_idle            ( pipe_rx7_elec_idle_gt   ),
    .pipe_rx7_polarity             ( pipe_rx7_polarity_gt    ),
    .pipe_tx7_compliance           ( pipe_tx7_compliance_gt  ),
    .pipe_tx7_char_is_k            ( pipe_tx7_char_is_k_gt   ),
    .pipe_tx7_data                 ( pipe_tx7_data_gt        ),
    .pipe_tx7_elec_idle            ( pipe_tx7_elec_idle_gt   ),
    .pipe_tx7_powerdown            ( pipe_tx7_powerdown_gt   ),

    // PCI Express Signals
    .pci_exp_txn                   ( pci_exp_txn          ),
    .pci_exp_txp                   ( pci_exp_txp          ),
    .pci_exp_rxn                   ( pci_exp_rxn          ),
    .pci_exp_rxp                   ( pci_exp_rxp          ),

    // Non PIPE Signals
    .sys_clk                       ( sys_clk             ),
    .sys_rst_n                     ( sys_rst_n_int       ),
    .PIPE_MMCM_RST_N               ( pipe_mmcm_rst_n     ),        // Async      | Async
    .pipe_clk                      ( pipe_clk            ),

    .user_clk                      ( user_clk            ),
    .user_clk2                     ( user_clk2           ),
    .phy_rdy_n                     ( phy_rdy_n           ),

    .PIPE_PCLK_IN                  ( pipe_pclk_in ),
    .PIPE_RXUSRCLK_IN              ( pipe_rxusrclk_in ),
    .PIPE_RXOUTCLK_IN              ( pipe_rxoutclk_in ),
    .PIPE_DCLK_IN                  ( pipe_dclk_in ),
    .PIPE_USERCLK1_IN              ( pipe_userclk1_in ),
    .PIPE_USERCLK2_IN              ( pipe_userclk2_in ),
    .PIPE_OOBCLK_IN                ( pipe_oobclk_in ),
    .PIPE_MMCM_LOCK_IN             ( mmcm_lock_int ),

    .PIPE_TXOUTCLK_OUT             ( pipe_txoutclk_out ),
    .PIPE_RXOUTCLK_OUT             ( pipe_rxoutclk_out ),
    .PIPE_PCLK_SEL_OUT             ( pipe_pclk_sel_out ),
    .PIPE_GEN3_OUT                 ( pipe_gen3_out )
  );

  //------------------------------------------------------------------------------------------------------------------//

//end pcie_7x_v2_1_core_top }

   

endmodule // xilinx_k7_pcie_wrapper
