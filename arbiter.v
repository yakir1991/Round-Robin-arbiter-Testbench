//-----------------------------------------------------------------------------
// Project       : Ayalon
//-----------------------------------------------------------------------------
// File          : arbiter.v
// Author        : zeevb 
// Created       : 24 Jun 2008
// Last modified : 24 Jun 2008
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2007 by Valens-Semiconductor This model is the confidential and
// proprietary property of Valens-Semiconductor and the possession or use of this
// file requires a written license from Valens-Semiconductor.
//------------------------------------------------------------------------------
// Modification history :
// 24 Jun 2008 : created
//-----------------------------------------------------------------------------

module arbiter
  (
   // Master Host
   mcpu,
   maddr,
   mrd,
   mwr,
   mbe,
   mdwr,
   mdrd,
   mack,
   // Slave Host
   scpu,
   saddr,
   srd,
   swr,
   sbe,
   sdwr,
   sdrd,
   sack,
   // Test Host
   tcpu,
   taddr,
   trd,
   twr,
   tbe,
   tdwr,
   tdrd,
   tack,
   // Extra Host
   ecpu,
   eaddr,
   erd,
   ewr,
   ebe,
   edwr,
   edrd,
   eack,
   // device
   add_bus,
   byte_en,
   wr_bus,
   rd_bus,
   data_bus_wr,
   data_bus_rd,
   ack_bus,
   cpu_bus,
   // General
   clk,
   reset_n
   );

   //******************************************************************************
   // Parameters
   // *****************************************************************************
   parameter AW         = 32;
   parameter DW         = 32;
   parameter BW         = 4;
   parameter TW         = 16;
   		        
   parameter NSTM_IDLE  =  0;
   parameter NSTM_MSWR  =  1;
   parameter NSTM_MSRD  =  2;
   parameter NSTM_MACK  =  3;
   parameter NSTM_SLWR  =  4;
   parameter NSTM_SLRD  =  5;
   parameter NSTM_SACK  =  6;
   parameter NSTM_TEWR  =  7;
   parameter NSTM_TERD  =  8;
   parameter NSTM_TACK  =  9;
   parameter NSTM_EXWR  =  10;
   parameter NSTM_EXRD  =  11;
   parameter NSTM_EACK  =  12;
		        
   parameter ASTM_IDLE  =  1 << NSTM_IDLE;
   parameter ASTM_MSWR  =  1 << NSTM_MSWR;
   parameter ASTM_MSRD  =  1 << NSTM_MSRD;
   parameter ASTM_MACK  =  1 << NSTM_MACK;
   parameter ASTM_SLWR  =  1 << NSTM_SLWR;
   parameter ASTM_SLRD  =  1 << NSTM_SLRD;
   parameter ASTM_SACK  =  1 << NSTM_SACK;
   parameter ASTM_TEWR  =  1 << NSTM_TEWR;
   parameter ASTM_TERD  =  1 << NSTM_TERD;
   parameter ASTM_TACK  =  1 << NSTM_TACK;
   parameter ASTM_EXWR  =  1 << NSTM_EXWR;
   parameter ASTM_EXRD  =  1 << NSTM_EXRD;
   parameter ASTM_EACK  =  1 << NSTM_EACK;

   parameter CURR_MSTR  = 3'b000;
   parameter CURR_SLAV  = 3'b001;
   parameter CURR_TEST  = 3'b010;
   parameter CURR_EXTR  = 3'b011;
   parameter NEXT_DUMY  = 3'b111;
   
   //******************************************************************************
   // Port Declarations
   // *****************************************************************************
   input [AW-1:0]  maddr;
   input 	   mrd;
   input 	   mwr;
   input [BW-1:0]  mbe;
   input [DW-1:0]  mdwr;
   output [DW-1:0] mdrd;
   output [1:0]    mack;
   input 	   mcpu;
   
   input [AW-1:0]  saddr;
   input 	   srd;
   input 	   swr;
   input [BW-1:0]  sbe;
   input [DW-1:0]  sdwr;
   output [DW-1:0] sdrd;
   output [1:0]    sack;
   input 	   scpu;
   
   input [AW-1:0]  taddr;
   input 	   trd;
   input 	   twr;
   input [BW-1:0]  tbe;
   input [DW-1:0]  tdwr;
   output [DW-1:0] tdrd;
   output [1:0]    tack;
   input 	   tcpu;
   
   input [AW-1:0]  eaddr;
   input 	   erd;
   input 	   ewr;
   input [BW-1:0]  ebe;
   input [DW-1:0]  edwr;
   output [DW-1:0] edrd;
   output [1:0]    eack;
   input 	   ecpu;
   
   output [AW-1:0] add_bus;
   output [BW-1:0] byte_en;
   output 	   wr_bus;
   output 	   rd_bus;
   output [DW-1:0] data_bus_wr;
   input [DW-1:0]  data_bus_rd;
   input 	   ack_bus;
   output 	   cpu_bus;
   
   input 	   clk;
   input 	   reset_n; 
   
   //******************************************************************************
   // Internal Register Declarations
   // *****************************************************************************
   reg [12:0] 	   astm_stm; 
   reg [TW-1:0]    timeout_cnt;
   reg [DW-1:0]    data_bus_rd_d;
   reg [AW-1:0]    add_bus;
   reg [BW-1:0]    byte_en;
   reg 		   cpu_bus;
   reg [DW-1:0]    data_bus_wr;
   reg [2:0] 	   current_m;
   reg [2:0] 	   next_m;
   reg 		   timeout_d;
   
   //******************************************************************************
   // Internal Wires  Declarations
   // *****************************************************************************
   wire 	   timeout;
   wire [TW-1:0]   timeout_limit;
   wire [12:0] 	   next_astm_stm;
   
   //******************************************************************************
   // Bus Access
   // *****************************************************************************
   assign mack   = {timeout_d, astm_stm[NSTM_MACK]};
   assign sack   = {timeout_d, astm_stm[NSTM_SACK]};
   assign tack   = {timeout_d, astm_stm[NSTM_TACK]};
   assign eack   = {timeout_d, astm_stm[NSTM_EACK]};
   
   assign wr_bus = astm_stm[NSTM_MSWR] || astm_stm[NSTM_SLWR] || astm_stm[NSTM_TEWR] || astm_stm[NSTM_EXWR];
   assign rd_bus = astm_stm[NSTM_MSRD] || astm_stm[NSTM_SLRD] || astm_stm[NSTM_TERD] || astm_stm[NSTM_EXRD];
   assign mdrd   = data_bus_rd_d;
   assign sdrd   = data_bus_rd_d;
   assign tdrd   = data_bus_rd_d;
   assign edrd   = data_bus_rd_d;

   always @*
     case (current_m)
       CURR_MSTR : next_m = srd || swr ? CURR_SLAV : trd || twr ? CURR_TEST : erd || ewr ? CURR_EXTR : NEXT_DUMY;
       CURR_SLAV : next_m = trd || twr ? CURR_TEST : erd || ewr ? CURR_EXTR : mrd || mwr ? CURR_MSTR : NEXT_DUMY;
       CURR_TEST : next_m = erd || ewr ? CURR_EXTR : mrd || mwr ? CURR_MSTR : srd || swr ? CURR_SLAV : NEXT_DUMY;
       CURR_EXTR : next_m = mrd || mwr ? CURR_MSTR : srd || swr ? CURR_SLAV : trd || twr ? CURR_TEST : NEXT_DUMY;
       default   : next_m = mrd || mwr ? CURR_MSTR : srd || swr ? CURR_SLAV : trd || twr ? CURR_TEST : erd || ewr ? CURR_EXTR : NEXT_DUMY;
     endcase // case (current_m)
   
   always @(posedge clk or negedge reset_n)
     if (!reset_n)
       begin
	  add_bus     <= {AW{1'b0}};
	  byte_en     <= {BW{1'b0}};
	  cpu_bus     <= 1'b0;
	  data_bus_wr <= {DW{1'b0}};
	  current_m   <= CURR_MSTR;
       end
     else if ((astm_stm[NSTM_IDLE] || astm_stm[NSTM_MACK] || astm_stm[NSTM_SACK] || astm_stm[NSTM_TACK] || astm_stm[NSTM_EACK]) && (mrd || mwr || srd || swr || trd || twr || erd || ewr))
       begin
	  add_bus     <= next_m == CURR_MSTR ? maddr : next_m == CURR_SLAV ? saddr : next_m == CURR_TEST ? taddr : eaddr;
	  byte_en     <= next_m == CURR_MSTR ? mbe   : next_m == CURR_SLAV ? sbe   : next_m == CURR_TEST ? tbe   : ebe;
	  cpu_bus     <= next_m == CURR_MSTR ? mcpu  : next_m == CURR_SLAV ? scpu  : next_m == CURR_TEST ? tcpu  : ecpu;
	  data_bus_wr <= next_m == CURR_MSTR ? mdwr  : next_m == CURR_SLAV ? sdwr  : next_m == CURR_TEST ? tdwr  : edwr;
	  current_m   <= next_m;
       end
     else if ((ack_bus || timeout) && (astm_stm[NSTM_MSWR] || astm_stm[NSTM_SLWR]  || astm_stm[NSTM_TEWR] || astm_stm[NSTM_EXWR] || astm_stm[NSTM_MSRD] || astm_stm[NSTM_SLRD] || astm_stm[NSTM_TERD] || astm_stm[NSTM_EXRD]))
       begin
	  add_bus     <= {AW{1'b0}};
	  byte_en     <= {BW{1'b0}};
	  cpu_bus     <= 1'b0;
	  data_bus_wr <= {DW{1'b0}};
       end
   
   always @(posedge clk or negedge reset_n)
     if (!reset_n)
       data_bus_rd_d <= {DW{1'b0}};
     else if (ack_bus)
       data_bus_rd_d <= data_bus_rd;
   
   //******************************************************************************
   // Arbitration state machine
   // *****************************************************************************
   assign next_astm_stm = next_m == CURR_MSTR ? (mrd ? ASTM_MSRD : mwr ? ASTM_MSWR : ASTM_IDLE) :
			  next_m == CURR_SLAV ? (srd ? ASTM_SLRD : swr ? ASTM_SLWR : ASTM_IDLE) : 
			  next_m == CURR_TEST ? (trd ? ASTM_TERD : twr ? ASTM_TEWR : ASTM_IDLE) : 
		          next_m == CURR_EXTR ? (erd ? ASTM_EXRD : ewr ? ASTM_EXWR : ASTM_IDLE) : ASTM_IDLE;
   
   always @(posedge clk or negedge reset_n)
     if (!reset_n)
       astm_stm <= ASTM_IDLE;
     else
       case (astm_stm)
	 ASTM_IDLE  : astm_stm <= next_astm_stm;				    
	 ASTM_MSWR  : astm_stm <= ack_bus || timeout ? ASTM_MACK : ASTM_MSWR;    
	 ASTM_MSRD  : astm_stm <= ack_bus || timeout ? ASTM_MACK : ASTM_MSRD;    
	 ASTM_MACK  : astm_stm <= next_astm_stm;				    
	 ASTM_SLWR  : astm_stm <= ack_bus || timeout ? ASTM_SACK : ASTM_SLWR;    
	 ASTM_SLRD  : astm_stm <= ack_bus || timeout ? ASTM_SACK : ASTM_SLRD;    
	 ASTM_SACK  : astm_stm <= next_astm_stm;				    
	 ASTM_TEWR  : astm_stm <= ack_bus || timeout ? ASTM_TACK : ASTM_TEWR;    
	 ASTM_TERD  : astm_stm <= ack_bus || timeout ? ASTM_TACK : ASTM_TERD;    
	 ASTM_TACK  : astm_stm <= next_astm_stm;                                 
	 ASTM_EXWR  : astm_stm <= ack_bus || timeout ? ASTM_EACK : ASTM_EXWR; 
	 ASTM_EXRD  : astm_stm <= ack_bus || timeout ? ASTM_EACK : ASTM_EXRD; 
	 ASTM_EACK  : astm_stm <= next_astm_stm;                              
	 default    : astm_stm <= ASTM_IDLE;
       endcase // casex (astm_stm)
   
   //******************************************************************************
   // Time Out Counter
   // *****************************************************************************
   assign timeout_limit = ({TW{1'b1}} - 1);
   assign timeout       = timeout_cnt == timeout_limit;
   
   always @(posedge clk or negedge reset_n)
     if (!reset_n)
       timeout_cnt <= {TW{1'b0}};
     else if (astm_stm[NSTM_MSWR] || astm_stm[NSTM_MSRD] || astm_stm[NSTM_SLWR] || astm_stm[NSTM_SLRD] || astm_stm[NSTM_EXWR] || astm_stm[NSTM_EXRD] || astm_stm[NSTM_TEWR] || astm_stm[NSTM_TERD])
       timeout_cnt <= &timeout_cnt ? timeout_cnt : timeout_cnt + 1'b1;
     else
       timeout_cnt <= {TW{1'b0}};
      
   always @(posedge clk or negedge reset_n)
     if (!reset_n)
       timeout_d <= 1'b0;
     else
       timeout_d <= timeout;
   
endmodule // arbiter
