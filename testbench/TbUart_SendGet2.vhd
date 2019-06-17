--
--  File Name:          TbUart_SendGet2.vhd
--  Block Name:         Architecture of TestCtrl
--
--  Author:             Jim Lewis, 503-590-4787
--
--  Creation Date:      11/99
--  Last Updated:       5/19
--
--  Description:
--    Basic Testbench for TbUart
--
--  Project:
--        SynthWorks Design Inc.
--        Training Courses
--        11898 SW 128th Ave.
--        Tigard, Or  97223
--        http://www.SynthWorks.com
--        email:  jim@SynthWorks.com
--
--  Copyright (c) 1999-2019 by SynthWorks Design Inc.  All rights reserved.
--
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
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
    -- AlertIfDiff("./results/TbUart_SendGet2.txt", "../Uart/testbench/validated_results/TbUart_SendGet2.txt", "") ; 
    AlertIfDiff("./results/TbUart_SendGet2.txt", "../../VerificationIP_Dev/Uart/testbench/validated_results/TbUart_SendGet2.txt", "") ; 
    
    print("") ;
    ReportAlerts(ExternalErrors => (FAILURE => 0, ERROR => -4, WARNING => 0)) ; 
    print("") ;
    std.env.stop ; 
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
        wait for 500 ns ; 
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        wait for 500 ns ; 
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
        TryExpectValid := TRUE ;     
        TryGet(UartRxRec, RxStim.Data, Available) ;
        exit when Available ;
        Alert("TryGet Failed to return data", FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryGet returned too soon") ;
      RxStim.Error := std_logic_vector(UartRxRec.ErrorFromModel) ; 
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
        wait for 500 ns ; 
        TryGet(UartRxRec, RxStim.Data, RxStim.Error, Available) ;
        exit when Available ;
        wait for 500 ns ; 
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
        wait for 500 ns ; 
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        wait for 500 ns ; 
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        WaitForTransaction(UartRxRec) ;
        TryExpectValid := TRUE ;     
        TryCheck(UartRxRec, ExpectStim.Data, Available) ;
        exit when Available ;
        Alert("TryCheck Failed to return data", FAILURE) ;
      end loop ;
      AlertIf(not TryExpectValid, "TryCheck returned too soon") ;
      RxStim.Data  := std_logic_vector(UartRxRec.DataFromModel) ; 
      RxStim.Error := std_logic_vector(UartRxRec.ErrorFromModel) ; 
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
        wait for 500 ns ; 
        TryCheck(UartRxRec, ExpectStim.Data, ExpectStim.Error, Available) ;
        exit when Available ;
        wait for 500 ns ; 
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