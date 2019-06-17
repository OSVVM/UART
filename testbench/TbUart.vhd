--
--  File Name:          TbUart.vhd
--  Block Name:         TbUart 
--
--  Author:             Jim Lewis, 503-590-4787
--
--  Creation Date:      11/99
--  Last Updated:       05/19
--
--  Description:
--    Testbench that connects UartTx and UartRx
--    
--
--  Project:      
--        SynthWorks Design Inc.
--        Training Courses
--        11898 SW 128th Ave.
--        Tigard, Or  97223
--        http://www.SynthWorks.com
--        email:  jim@SynthWorks.com
--
--  Copyright (c) 1999 - 2019 by SynthWorks Design Inc.  All rights reserved.
--
--  
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;

  use std.textio.all ;

library osvvm ;
  context osvvm.OsvvmContext ;

  library osvvm_uart ;
  context osvvm_uart.UartContext ;

entity TbUart is 
end TbUart ;

architecture TestHarness of TbUart is

  constant tperiod_Clk  : time := 10 ns ;
  constant tpd          : time := 2 ns ;
  signal Clk            : std_logic := '0' ;
  signal nReset         : std_logic ;

  -- Uart Interface
  signal SerialData     : std_logic ;

  ------------------------------------------------------------
  component TestCtrl 
  -- Stimulus generation and synchronization
  ------------------------------------------------------------
  generic (
    tperiod_Clk           : time := 10 ns 
  ) ; 
  port (
    UartTxRec          : InOut UartRecType ;
    UartRxRec          : InOut UartRecType ;

    Clk                : In    std_logic ;
    nReset             : In    std_logic 
  ) ;
  end component ;

  signal UartTxRec           : UartRecType ;
  signal UartRxRec           : UartRecType ;



begin

  ------------------------------------------------------------
  -- create Clock 
  Osvvm.TbUtilPkg.CreateClock ( 
  ------------------------------------------------------------
    Clk        => Clk, 
    Period     => tperiod_Clk 
  )  ; 
  
  ------------------------------------------------------------
  -- create nReset 
  Osvvm.TbUtilPkg.CreateReset ( 
  ------------------------------------------------------------
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => tpd
  ) ;


  ------------------------------------------------------------
  UartTx_1 : UartTx 
  ------------------------------------------------------------
  port map (
    TransactionRec      => UartTxRec,
    SerialDataOut       => SerialData   
  ) ;


  ------------------------------------------------------------
  UartRx_1 : UartRx 
  ------------------------------------------------------------
  port map (
    TransactionRec      => UartRxRec,
    SerialDataIn        => SerialData 
  ) ;


  ------------------------------------------------------------
  TestCtrl_1 : TestCtrl 
  -- Stimulus generation and synchronization
  ------------------------------------------------------------
  generic map (
    tperiod_Clk         => tperiod_Clk
  ) 
  port map (
    UartTxRec             => UartTxRec,
    UartRxRec             => UartRxRec,

    Clk                   => Clk,
    nReset                => nReset
  ) ;

end TestHarness ;