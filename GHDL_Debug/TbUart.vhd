--
--  File Name:         TbUart.vhd
--  Design Unit Name:  TbUart
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Testbench that connects UartTx and UartRx
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    1999      1999.00    Developed for SynthWorks' Advanced VHDL Testbenches and Verification Class
--    05/2019   2019.05    Updated for OSVVM public release
--    01/2020   2020.01    Updated license notice
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 1999 - 2020 by SynthWorks Design Inc.
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
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
  generic (
    NUM_UARTS : integer := 16
  ) ; 
end TbUart ;

architecture TestHarness of TbUart is

  constant tperiod_Clk  : time := 10 ns ;
  constant tpd          : time := 2 ns ;
  signal Clk            : std_logic := '0' ;
  signal nReset         : std_logic ;

  ------------------------------------------------------------
  component TestCtrl is
  -- Stimulus generation and synchronization
  ------------------------------------------------------------
    generic (
      NUM_UARTS : integer := 16
    ) ; 
    port (
      UartTxRec          : InOut UartRecArrayType ;
      UartRxRec          : InOut UartRecArrayType ;

      nReset             : In    std_logic 
    ) ;
  end component TestCtrl ;

--  signal UartTxRec      : UartRecArrayType (1 to NUM_UARTS) ;
--  signal UartRxRec      : UartRecArrayType (1 to NUM_UARTS) ;
  signal UartTxRec, UartRxRec : StreamRecArrayType(1 to NUM_UARTS)(
    DataToModel   (UartTb_DataType'range), 
    ParamToModel  (UartTb_ErrorModeType'range), 
    DataFromModel (UartTb_DataType'range), 
    ParamFromModel(UartTb_ErrorModeType'range) 
  ) ;

  -- Uart Interface
  signal SerialData     : std_logic_vector (1 to NUM_UARTS) ;


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


  GenerateUartInstances : for GEN_UART in 1 to NUM_UARTS generate 
  begin
    ------------------------------------------------------------
    UartTx_1 : UartTx 
    ------------------------------------------------------------
    generic map (
      MODEL_ID_NAME       => "UartTx_" & to_string(GEN_UART)
    ) 
    port map (
      TransRec            => UartTxRec(GEN_UART),
      SerialDataOut       => SerialData(GEN_UART)   
    ) ;

    ------------------------------------------------------------
    UartRx_1 : UartRx 
    ------------------------------------------------------------
    generic map (
      MODEL_ID_NAME       => "UartRx_" & to_string(GEN_UART)
    ) 
    port map (
      TransRec            => UartRxRec(GEN_UART),
      SerialDataIn        => SerialData(GEN_UART) 
    ) ;
  end generate GenerateUartInstances ; 

  ------------------------------------------------------------
  TestCtrl_1 : TestCtrl 
  -- Stimulus generation and synchronization
  ------------------------------------------------------------
  generic map (
    NUM_UARTS             => NUM_UARTS
  ) 
  port map (
    UartTxRec             => UartTxRec,
    UartRxRec             => UartRxRec,

    nReset                => nReset
  ) ;

end TestHarness ;