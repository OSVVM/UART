--
--  File Name:         TbUart_Scoreboard1.vhd
--  Design Unit Name:  TbUart_Scoreboard1
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Validate Scoreboard_Uart with  
--       All status in = status out = 2**3, 
--       all status in vs out = 2**6 with data equal, 
--       all status in vs out with data /= 
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

architecture Scoreboard1 of TestCtrl is

  signal CheckErrors : boolean ;
  signal TestActive  : boolean := TRUE ;

  signal TestDone    : integer_barrier := 1 ;
  
  use osvvm_uart.ScoreboardPkg_Uart.all ; 
  shared variable UartScoreboard : osvvm_uart.ScoreboardPkg_Uart.ScoreboardPType ; 

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName("TbUart_Scoreboard1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_Scoreboard1.txt") ;
--    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    AlertIf(now >= 100 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbUart_Scoreboard1.txt", "../Uart/testbench/validated_results/TbUart_Scoreboard1.txt", "") ; 
    
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -(44 + 48), WARNING => 0)) ; 
    std.env.stop(SumAlertCount(GetAlertCount + (FAILURE => 0, ERROR => -(44 + 48), WARNING => 0))) ;
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- UartTxProc
  --   Provides transactions to UartTx via Send
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
  UartTxProc : process
    variable UartTxID, TxLogID : AlertLogIDType ; 
    variable TxStim, ExpStim : UartStimType ;
    
  begin
    
    GetAlertLogID(UartTxRec, UartTxID) ; 
    SetLogEnable(UartTxID, INFO, TRUE) ;
    WaitForClock(UartTxRec, 2) ; 
    TxLogID := GetAlertLogID("TB UartTxProc") ;
    SetLogEnable (TxLogID, INFO, TRUE) ;
    
log(TxLogID, "Sequence 1 -- Basic Transfer with Passing data and status", INFO) ;
    for i in 0 to 2**3 -1 loop -- 8 values
      TxStim.Data   := to_slv(i+8, 8) ;
      ExpStim.Data  := TxStim.Data ;
      TxStim.Error  := to_slv(i, 3) ;
      ExpStim.Error := TxStim.Error ;
      UartScoreboard.Push( ExpStim ) ; 
      Send(UartTxRec, TxStim.Data, TxStim.Error) ;
    end loop ; 
    
    AffirmIfEqual(GetAlertCount, 0, "Alert Count") ;

    BlankLine(2) ;
log(TxLogID, "Sequence 2 -- All Status Values, 64 - 20 mismatches", INFO) ;
    for i in 0 to 2**6 -1 loop  -- 64 vaules
      TxStim.Data   := to_slv(i, 8) ;
      ExpStim.Data  := TxStim.Data ;
      TxStim.Error  := TxStim.Data(5 downto 3) ;
      ExpStim.Error := TxStim.Data(2 downto 0) ;
      UartScoreboard.Push( ExpStim ) ; 
      Send(UartTxRec, TxStim.Data, TxStim.Error) ;
    end loop ; 
    
     AffirmIfEqual(GetAlertCount, 44, "Alert Count") ;
     
    BlankLine(2) ;
log(TxLogID, "Sequence 3 -- Data mismatch with All Status Values, 64 - 16 mismatches", INFO) ;
    for i in 0 to 2**6 -1 loop  -- 64 vaules
      TxStim.Data   := to_slv(i, 8) ;
      ExpStim.Data  := to_slv(i + 1, 8) ;
      TxStim.Error  := TxStim.Data(5 downto 3) ;
      ExpStim.Error := TxStim.Data(2 downto 0) ;
      UartScoreboard.Push( ExpStim ) ; 
      Send(UartTxRec, TxStim.Data, TxStim.Error) ;
    end loop ; 
    
    
log(TxLogID, "Sentinal Transfer to mark end of test", INFO) ;
    TestActive <= FALSE after 8 us ;  -- last one 
    UartScoreboard.Push( UartStimType'(X"50", UARTTB_NO_ERROR) ) ; 
    Send(UartTxRec, X"50") ;
    
    AffirmIfEqual(GetAlertCount, 44 + 48, "Alert Count") ;
    
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTxProc ;


  ------------------------------------------------------------
  -- UartRxProc
  --   Gets transactions from UartRx via UartGet and UartCheck
  --   Used to test the UART Transmitter in the UUT
  ------------------------------------------------------------
  UartRxProc : process
    variable ReceivedVal : UartStimType ; 
  begin

    UartReceiveLoop : while TestActive loop 
      Get(UartRxRec, ReceivedVal.Data, ReceivedVal.Error) ;
      UartScoreboard.Check( ReceivedVal ) ; 
    end loop ;
    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartRxProc ;


end Scoreboard1 ;
Configuration TbUart_Scoreboard1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(Scoreboard1) ; 
    end for ; 
  end for ; 
end TbUart_Scoreboard1 ; 