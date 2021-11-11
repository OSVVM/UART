--
--  File Name:         TbUart_Checkers1.vhd
--  Design Unit Name:  TbUart_Checkers1
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Validate check with data error, Parity, Stop, Parity+Stop, 
--      and Break errors generate error messages
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
architecture Checkers1 of TestCtrl is

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
    SetAlertLogName("TbUart_Checkers1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_Checkers1.txt") ;
--    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbUart_Checkers1.txt", "../Uart/testbench/validated_results/TbUart_Checkers1.txt", "") ; 
    
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -15, WARNING => 0)) ; 
    std.env.stop(SumAlertCount(GetAlertCount + (FAILURE => 0, ERROR => -15, WARNING => 0))) ;
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- UartTxProc
  --   Provides transactions to UartTx via Send
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
  UartTxProc : process
    variable TxProcID : AlertLogIDType ; 
    variable TransactionCount, ErrorCount : integer ;
  begin
    
    TxProcID := GetAlertLogID("UartTxProc") ;

    WaitForClock(UartTxRec, 2) ; 
    
    --  Sequence 1
    Send(UartTxRec, X"50") ;
    Send(UartTxRec, X"51", UARTTB_PARITY_ERROR) ;
    Send(UartTxRec, X"52", UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"53", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"11", UARTTB_BREAK_ERROR) ;
    
    GetTransactionCount(UartTxRec, TransactionCount) ;
    AffirmIfEqual(TxProcID, TransactionCount, 5, "Transaction Count") ;
    GetErrorCount(UartTxRec, ErrorCount) ;
    AffirmIfEqual(TxProcID, ErrorCount, 0, "Error Count") ;
    
    --  Sequence 2
    Send(UartTxRec, X"60", UARTTB_NO_ERROR) ;
    Send(UartTxRec, X"61", UARTTB_PARITY_ERROR) ;
    Send(UartTxRec, X"62", UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"63", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"12", UARTTB_BREAK_ERROR) ;
    
    --  Sequence 3
    Send(UartTxRec, X"70", UARTTB_NO_ERROR) ;
    Send(UartTxRec, X"71", UARTTB_PARITY_ERROR) ;
    Send(UartTxRec, X"72", UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"73", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"13", UARTTB_BREAK_ERROR) ;
    
    --  Sequence 4
    Send(UartTxRec, X"80", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send(UartTxRec, X"81", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    WaitForClock(UartTxRec, 8) ;
    

    TestActive <= FALSE ;  -- last one 

    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTxProc ;


  ------------------------------------------------------------
  -- UartTbRxProc
  --   Gets transactions from UartRx via UartGet and UartCheck
  --   Used to test the UART Transmitter in the UUT
  ------------------------------------------------------------
  UartTbRxProc : process
    variable RxStim, ExpectStim : UartStimType ; 
    variable Available, TryExpectValid : boolean ;

    variable RxProcID : AlertLogIDType ; 
    variable TransactionCount, ErrorCount : integer ;
  begin
    
    RxProcID := GetAlertLogID("TB UartRxProc") ;
    WaitForClock(UartRxRec, 2) ; 

    -- Validate Check with 1 parameter with data errors, expecting 5 errors
    -- SendGet1 already tests Check with 1 parameter with parity, stop, parity+stop, and break errors
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"40", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"41", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"42", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"43", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"40", UARTTB_BREAK_ERROR) ;
      end case ; 
      -- Check with one parameter
      Check(UartRxRec, ExpectStim.Data) ;
    end loop ;
    AffirmIf(GetAlertCount = 5, "Expecting 5 Errors") ; 
    GetTransactionCount(UartRxRec, TransactionCount) ;
    AffirmIfEqual(RxProcID, TransactionCount, 5, "Transaction Count") ;
    GetErrorCount(UartRxRec, ErrorCount) ;
    AffirmIfEqual(RxProcID, ErrorCount, 5, "Expecting 5 Errors,") ;
    
    
    -- Validate Check with 2 parameters with data errors, expecting 4 errors
    -- Break error will pass
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"40", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"41", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"42", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"43", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"44", UARTTB_BREAK_ERROR) ;
      end case ; 
      -- Check with two parameters
      Check(UartRxRec, ExpectStim.Data, ExpectStim.Error) ;
    end loop ;
    GetTransactionCount(UartRxRec, TransactionCount) ;
    AffirmIfEqual(RxProcID, TransactionCount, 10, "Transaction Count") ;
    GetErrorCount(UartRxRec, ErrorCount) ;
    AffirmIfEqual(RxProcID, ErrorCount, 9, "Expecting 9 Errors,") ;
        
    -- Validate Check with 2 parameters with PE, SE, PE+SE, and BE errors, expecting 4 errors
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"70", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"71", UARTTB_NO_ERROR) ;
        when 3 =>  ExpectStim := (X"72", UARTTB_NO_ERROR) ;
        when 4 =>  ExpectStim := (X"73", UARTTB_NO_ERROR) ;
        when 5 =>  ExpectStim := (X"74", UARTTB_NO_ERROR) ;
      end case ; 
      -- Check with two parameters
      Check(UartRxRec, ExpectStim.Data, ExpectStim.Error) ;
    end loop ;
    GetErrorCount(UartRxRec, ErrorCount) ;
    AffirmIfEqual(RxProcID, ErrorCount, 13, "Expecting 13 Errors,") ;
    
    -- Validate Check with 2 parameters with PE+SE error variations, expecting 2 errors
    for i in 1 to 2 loop     
      case i is
        when 1 =>  ExpectStim := (X"80", UARTTB_PARITY_ERROR) ;
        when 2 =>  ExpectStim := (X"81", UARTTB_STOP_ERROR) ;
      end case ; 
      -- Check with two parameters
      Check(UartRxRec, ExpectStim.Data, ExpectStim.Error) ;
    end loop ;
    GetErrorCount(UartRxRec, ErrorCount) ;
    AffirmIfEqual(RxProcID, ErrorCount, 15, "Expecting 15 Errors,") ;

    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbRxProc ;

end Checkers1 ;
Configuration TbUart_Checkers1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(Checkers1) ; 
    end for ; 
  end for ; 
end TbUart_Checkers1 ; 