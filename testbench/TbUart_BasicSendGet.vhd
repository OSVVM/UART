--
--  File Name:          TbUart_BasicSendGet.vhd
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

architecture BasicSendGet of TestCtrl is

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
    SetAlertLogName("TbUart_BasicSendGet") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_BasicSendGet.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 5 ms) ;
    AlertIf(now >= 5 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
    -- AlertIfDiff("./results/TbUart_BasicSendGet.txt", "../Uart/testbench/validated_results/TbUart_BasicSendGet.txt", "") ; 
    AlertIfDiff("./results/TbUart_BasicSendGet.txt", "../../VerificationIP_Dev/Uart/testbench/validated_results/TbUart_BasicSendGet.txt", "") ; 
    
    print("") ;
    ReportAlerts(ExternalErrors => (FAILURE => 0, ERROR => -6, WARNING => 0)) ; 
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
  begin
    
    -- Check initialization of SerialData
    wait for 10 * UART_BAUD_PERIOD_115200 ;

    UartStimLoop : for I in 1 to 2 loop 
      if I = 1 then 
        print(LF & "Sequence 1, Don't Check Errors, Generates 6 Errors") ; 
        CheckErrors <= FALSE ;
      else 
        print(LF & "Sequence 2, Check Errors, Generates 0 Errors") ; 
        CheckErrors <= TRUE ;
      end if ; 
      
      -- Nominal Values
      UartScoreboard.Push( UartStimType'(X"40", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"40", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"41", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"41", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"42", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"42", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"43", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"43", UARTTB_NO_ERROR) ;
      wait for 8 * UART_BAUD_PERIOD_115200 ; 

      -- Parity Error Injection
      UartScoreboard.Push( UartStimType'(X"51", UARTTB_PARITY_ERROR) ) ; 
      Send(UartTxRec, X"51", UARTTB_PARITY_ERROR) ;
      wait for 2 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"52", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"52", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"53", UARTTB_PARITY_ERROR) ) ; 
      Send(UartTxRec, X"53", UARTTB_PARITY_ERROR) ;
      wait for 2 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"54", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"54", UARTTB_NO_ERROR) ;
      wait for 8 * UART_BAUD_PERIOD_115200 ; 

      -- Stop Error Injection
      UartScoreboard.Push( UartStimType'(X"61", UARTTB_STOP_ERROR) ) ; 
      Send(UartTxRec, X"61", UARTTB_STOP_ERROR) ;
      wait for 10 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"62", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"62", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"63", UARTTB_STOP_ERROR) ) ; 
      Send(UartTxRec, X"63", UARTTB_STOP_ERROR) ;
      wait for 10 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"64", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"64", UARTTB_NO_ERROR) ;
      wait for 8 * UART_BAUD_PERIOD_115200 ; 

      -- Stop Error Injection
      UartScoreboard.Push( UartStimType'(X"0D", UARTTB_BREAK_ERROR) ) ; 
      Send(UartTxRec, X"0D", UARTTB_BREAK_ERROR) ;
      wait for 4 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"82", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"82", UARTTB_NO_ERROR) ;
      UartScoreboard.Push( UartStimType'(X"10", UARTTB_BREAK_ERROR) ) ; 
      Send(UartTxRec, X"10", UARTTB_BREAK_ERROR) ;
      wait for 4 * UART_BAUD_PERIOD_115200 ; 
      UartScoreboard.Push( UartStimType'(X"84", UARTTB_NO_ERROR) ) ; 
      Send(UartTxRec, X"84", UARTTB_NO_ERROR) ;
    end loop UartStimLoop ;
    
    TestActive <= FALSE ;  -- last one 

    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbTxProc ;


  ------------------------------------------------------------
  -- UartTbRxProc
  --   Gets transactions from UartRx via Get and UartCheck
  --   Used to test the UART Transmitter in the UUT
  ------------------------------------------------------------
  UartTbRxProc : process
    variable ReceivedVal : UartStimType ; 
  begin

    UartReceiveLoop : while TestActive loop 
      Get(UartRxRec, ReceivedVal.Data, ReceivedVal.Error) ;
      if not CheckErrors then 
        ReceivedVal.Error := UARTTB_NO_ERROR ; 
      end if ; 
      UartScoreboard.Check( ReceivedVal ) ; 
      wait for UART_BAUD_PERIOD_115200 ;  
    end loop ;
    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbRxProc ;

end BasicSendGet ;
Configuration TbUart_BasicSendGet of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(BasicSendGet) ; 
    end for ; 
  end for ; 
end TbUart_BasicSendGet ; 