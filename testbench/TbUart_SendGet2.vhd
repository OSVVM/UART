--
--  File Name:         TbUart_SendGet2.vhd
--  Design Unit Name:  TbUart_SendGet2
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Validate SendAsync, TryGet, TryCheck transactions with errors in PE, SE, and BE 
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

architecture SendGet2 of TestCtrl is

  signal CheckErrors : boolean ;
  signal TestActive  : boolean := TRUE ;

  signal TestDone    : integer_barrier := 1 ;
  signal StartSequence2    : integer_barrier := 1 ;
  
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
    SetAlertLogName("TbUart_SendGet2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_SendGet2.txt") ;
--    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbUart_SendGet2.txt", "../Uart/testbench/validated_results/TbUart_SendGet2.txt", "") ; 
    
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -4, WARNING => 0)) ; 
    std.env.stop(SumAlertCount(GetAlertCount + (FAILURE => 0, ERROR => -4, WARNING => 0))) ;
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- UartTbTxProc
  --   Provides transactions to UartTx via Send
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
  UartTbTxProc : process
    variable UartTxID : AlertLogIDType ; 
  begin
    
    GetAlertLogID(UartTxRec, UartTxID) ; 
    SetLogEnable(UartTxID, INFO, TRUE) ;
    WaitForClock(UartTxRec, 2) ; 
    
    --  Sequence 1
    SendAsync(UartTxRec, X"50") ;
    SendAsync(UartTxRec, X"51", UARTTB_PARITY_ERROR) ;
    SendAsync(UartTxRec, X"52", UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"53", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"11", UARTTB_BREAK_ERROR) ;
    WaitForTransaction(UartTxRec) ;
    
--    WaitForBarrier(StartSequence2) ;
    
    --  Sequence 2
    SendAsync(UartTxRec, X"60", UARTTB_NO_ERROR) ;
    SendAsync(UartTxRec, X"61", UARTTB_PARITY_ERROR) ;
    SendAsync(UartTxRec, X"62", UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"63", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send     (UartTxRec, X"12", UARTTB_BREAK_ERROR) ;
    
    --  Sequence 3
    SendAsync(UartTxRec, X"70", UARTTB_NO_ERROR) ;
    SendAsync(UartTxRec, X"71", UARTTB_PARITY_ERROR) ;
    SendAsync(UartTxRec, X"72", UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"73", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"13", UARTTB_BREAK_ERROR) ;
    WaitForTransaction(UartTxRec) ;
    
    --  Sequence 4
    SendAsync(UartTxRec, X"80") ;
    SendAsync(UartTxRec, X"81", UARTTB_PARITY_ERROR) ;
    SendAsync(UartTxRec, X"82", UARTTB_STOP_ERROR) ;
    SendAsync(UartTxRec, X"83", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
    Send     (UartTxRec, X"14", UARTTB_BREAK_ERROR) ;
    WaitForClock(UartTxRec, 8) ;
    
    TestActive <= FALSE ;  -- last one 

    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbTxProc ;


  ------------------------------------------------------------
  -- UartTbRxProc
  --   Gets transactions from UartRx via UartGet and UartCheck
  --   Used to test the UART Transmitter in the UUT
  ------------------------------------------------------------
  UartTbRxProc : process
    variable RxStim, ExpectStim : UartStimType ; 
    variable Available, TryExpectValid : boolean ;
    variable UartRxID : AlertLogIDType ; 
  begin

    GetAlertLogID(UartRxRec, UartRxID) ; 
    SetLogEnable(UartRxID, INFO, TRUE) ;
    Log("WaitForClock 2, Start") ;
    WaitForClock(UartRxRec, 2) ; 
    Log("WaitForClock 2, End") ;

    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"50", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"51", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"52", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"53", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"00", UARTTB_BREAK_ERROR) ;
      end case ; 
      loop      
        TryExpectValid := FALSE ;     
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
        TryExpectValid := TRUE ;     
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        Alert("TryGet Failed to return data", FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryGet returned too soon") ;
      RxStim.Error := SafeResize(UartRxRec.ParamFromModel, RxStim.Error'length) ; 
      AffirmIf(osvvm_UART.UartTbPkg.Match(RxStim, ExpectStim), 
        "Received: " & to_string(RxStim), 
        ".  Expected: " & to_string(ExpectStim) ) ;
    end loop ;
    
--    WaitForBarrier(StartSequence2) ;
    
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"60", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"61", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"62", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"63", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"64", UARTTB_BREAK_ERROR) ;
      end case ; 
      loop      
        TryExpectValid := FALSE ;     
        TryGet(UartRxRec, RxStim.Data, RxStim.Error, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryGet(UartRxRec, RxStim.Data, RxStim.Error, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryGet(UartRxRec, RxStim.Data, RxStim.Error, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
--        WaitForClock(UartRxRec, 12) ; 
        TryExpectValid := TRUE ;     
        TryGet(UartRxRec, RxStim.Data, RxStim.Error, Available) ;
        exit when Available ;
        Alert("TryGet Failed to return data.  i = " & to_string(i), FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryGet returned too soon") ;
      AffirmIf(osvvm_UART.UartTbPkg.Match(RxStim, ExpectStim), 
        "Received: " & to_string(RxStim), 
        ".  Expected: " & to_string(ExpectStim) ) ;
    end loop ;
        
    
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"70", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"71", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"72", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"73", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"74", UARTTB_BREAK_ERROR) ;
      end case ; 
      loop      
        TryExpectValid := FALSE ;     
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
        TryExpectValid := TRUE ;     
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        Alert("TryCheck Failed to return data", FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryCheck returned too soon") ;
      RxStim.Data  := SafeResize(UartRxRec.DataFromModel,  RxStim.Data'length) ; 
      RxStim.Error := SafeResize(UartRxRec.ParamFromModel, RxStim.Error'length) ; 
      AffirmIf(osvvm_UART.UartTbPkg.Match(RxStim, ExpectStim), 
        "Received: " & to_string(RxStim), 
        ".  Expected: " & to_string(ExpectStim) ) ;
    end loop ;
    AffirmIf(GetAlertCount = 4, "Expecting 4 Errors") ; 
    
    for i in 1 to 5 loop     
      case i is
        when 1 =>  ExpectStim := (X"80", UARTTB_NO_ERROR) ;
        when 2 =>  ExpectStim := (X"81", UARTTB_PARITY_ERROR) ;
        when 3 =>  ExpectStim := (X"82", UARTTB_STOP_ERROR) ;
        when 4 =>  ExpectStim := (X"83", UARTTB_PARITY_ERROR + UARTTB_STOP_ERROR) ;
        when 5 =>  ExpectStim := (X"00", UARTTB_BREAK_ERROR) ;
      end case ; 
      loop      
        TryExpectValid := FALSE ;     
        TryCheck(UartRxRec, ExpectStim.Data, ExpectStim.Error, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryCheck(UartRxRec, ExpectStim.Data, ExpectStim.Error, Available) ;
        exit when Available ;
        -- wait for 500 ns ; 
        WaitForClock(UartRxRec, 2) ;
        TryCheck(UartRxRec, ExpectStim.Data, ExpectStim.Error, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
        TryExpectValid := TRUE ;     
        TryCheck(UartRxRec, ExpectStim.Data, ExpectStim.Error, Available) ;
        exit when Available ;
        Alert("TryCheck Failed to return data", FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryCheck returned too soon") ;
    end loop ;

    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbRxProc ;

end SendGet2 ;
Configuration TbUart_SendGet2 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(SendGet2) ; 
    end for ; 
  end for ; 
end TbUart_SendGet2 ; 