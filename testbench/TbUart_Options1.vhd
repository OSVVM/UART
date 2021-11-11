--
--  File Name:         TbUart_Options1.vhd
--  Design Unit Name:  TbUart_Options1
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Validate all valid values Parity Mode, Stopbits, DataBits, Baud
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

architecture Options1 of TestCtrl is

  signal CheckErrors     : boolean ;
  signal TestActive      : boolean := TRUE ;

  signal TestDone        : integer_barrier := 1 ;
  signal SetParmBarrier  : integer_barrier := 1 ;
  
  use osvvm_uart.ScoreboardPkg_Uart.all ; 
  shared variable UartScoreboard : osvvm_uart.ScoreboardPkg_Uart.ScoreboardPType ; 
  
  signal TbID : AlertLogIDType ;

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName("TbUart_Options1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 
    TbID <= GetAlertLogID("TB") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_Options1.txt") ;
--    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--   AlertIfDiff("./results/TbUart_Options1.txt", "../Uart/testbench/validated_results/TbUart_Options1.txt", "") ; 

    EndOfTestReports ; 
    std.env.stop(GetAlertCount) ; 
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- UartTbTxProc
  --   Provides transactions to UartTx via Send
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
  UartTbTxProc : process
    variable UartTxID, TxLogID : AlertLogIDType ; 
    variable Baud : time ; 
    variable ParityMode : UartTb_ParityModeType ; 
    variable StartTime, ElapsedTime : time ; 
    variable AdjustRxCycles : integer ;
    ----------------------------------------
    procedure AffirmTxCycles (
      AlertLogID     : AlertLogIDType ;
      ElapsedTime    : time ; 
      Baud           : time ; 
      AdjustRxCycles : integer ;
      Cycles         : integer  
    ) is 
      constant AdjCycles : integer := Cycles - AdjustRxCycles ; 
    begin
      AffirmIf(AlertLogID, ElapsedTime = AdjCycles * Baud ,
          "ElapsedTime (" & to_string(AdjCycles) & " Cycles) = " & to_string(ElapsedTime, 1 ns),
          "  " & to_string(AdjCycles) & " Cycles * Baud = " & to_string(Cycles * Baud, 1 ns)) ; 
    end procedure AffirmTxCycles ; 
    ----------------------------------------
  begin

    GetAlertLogID(UartTxRec, UartTxID) ; 
    SetLogEnable(UartTxID, INFO, TRUE) ;
    TxLogID := GetAlertLogID("TB UartTxProc") ;
    SetLogEnable (TxLogID, INFO, FALSE) ;

    for i in 1 to 5 loop
      case i is
        when 1 =>  Baud :=  4000 ns ;  ParityMode := UARTTB_PARITY_ODD ;   AdjustRxCycles := 0 ;
        when 2 =>  Baud :=  6000 ns ;  ParityMode := UARTTB_PARITY_EVEN ;  AdjustRxCycles := 0 ;
        when 3 =>  Baud :=  8000 ns ;  ParityMode := UARTTB_PARITY_ZERO ;  AdjustRxCycles := 0 ;
        when 4 =>  Baud := 10000 ns ;  ParityMode := UARTTB_PARITY_ONE ;   AdjustRxCycles := 0 ;
        when 5 =>  Baud := 12000 ns ;  ParityMode := UARTTB_PARITY_NONE ;  AdjustRxCycles := 1 ;
      end case ; 
      Log(TxLogID, "Setting ParityMode to " & to_string(ParityMode), INFO) ;
      SetUartParityMode(UartTxRec, ParityMode) ;
      Log(TxLogID, "Setting Baud to " & to_string(Baud, 1 ns), INFO) ;
      SetUartBaud(UartTxRec, Baud) ;
      WaitForBarrier(SetParmBarrier) ;
      WaitForClock(UartTxRec, 1) ; 

      StartTime := NOW ; 
      WaitForClock(UartTxRec, 1) ; 
      ElapsedTime := NOW - StartTime ; 
      AffirmIf(UartTxID, ElapsedTime = Baud, "1 clock = " & to_string(ElapsedTime, 1 ns)) ; 
      
      StartTime := NOW ; 
      WaitForClock(UartTxRec, 2) ; 
      ElapsedTime := NOW - StartTime ; 
      AffirmIf(UartTxID, ElapsedTime = 2 * Baud, "2 clocks = " & to_string(ElapsedTime, 1 ns)) ; 
      
      StartTime := NOW ; 
      Send(UartTxRec, X"10") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 11) ; 

      Log(TxLogID, "Setting DataBits to 5", INFO) ;
      SetUartNumDataBits(UartTxRec, UARTTB_DATA_BITS_5) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"D1") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 8) ; 

      Log(TxLogID, "Setting DataBits to 6", INFO) ;
      SetUartNumDataBits(UartTxRec, UARTTB_DATA_BITS_6) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"D2") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 9) ; 

      Log(TxLogID, "Setting DataBits to 7", INFO) ;
      SetUartNumDataBits(UartTxRec, UARTTB_DATA_BITS_7) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"13") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 10) ; 

      Log(TxLogID, "Setting DataBits to 8", INFO) ;
      SetUartNumDataBits(UartTxRec, UARTTB_DATA_BITS_8) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"14") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 11) ; 

      Log(TxLogID, "Setting StopBits to 2", INFO) ;
      SetUartNumStopBits(UartTxRec, UARTTB_STOP_BITS_2) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"15") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 12) ; 

      Log(TxLogID, "Setting StopBits to 1", INFO) ;
      SetUartNumStopBits(UartTxRec, UARTTB_STOP_BITS_1) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Send(UartTxRec, X"16") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmTxCycles (UartTxID, ElapsedTime, Baud, AdjustRxCycles, Cycles => 11) ; 
      BlankLine(2) ;
    end loop ; 

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
    variable UartRxID, RxLogID : AlertLogIDType ; 
    variable Baud : time ; 
    variable ParityMode : UartTb_ParityModeType ; 
    variable StartTime, ElapsedTime : time ; 
    variable RxCycles, AdjustRxCycles : integer ;
    ----------------------------------------
    procedure AffirmRxCycles (
      AlertLogID     : AlertLogIDType ;
      ElapsedTime    : time ; 
      Baud           : time ; 
      AdjustRxCycles : integer ;
      MinCycles      : integer ; 
      MaxCycles      : integer  
    ) is 
      constant AdjMaxCycles : integer := MaxCycles - AdjustRxCycles ; 
      constant AdjMinCycles : integer := MinCycles - AdjustRxCycles ; 
    begin
      AffirmIf(AlertLogID, ElapsedTime < AdjMaxCycles * Baud and ElapsedTime > AdjMinCycles * Baud,
          "Between " & to_string(AdjMinCycles) & " and " & to_string(AdjMaxCycles) & " ElapsedTime = " & to_string(ElapsedTime, 1 ns)) ; 
    end procedure AffirmRxCycles ; 
    ----------------------------------------
  begin

    GetAlertLogID(UartRxRec, UartRxID) ; 
    SetLogEnable (UartRxID, INFO, TRUE) ;
    SetLogEnable (UartRxID, DEBUG, TRUE) ;
    RxLogID := GetAlertLogID("TB UartRxProc") ;
    SetLogEnable (RxLogID, INFO, FALSE) ;

    for i in 1 to 5 loop
      case i is
        when 1 =>  Baud :=  4000 ns ;  ParityMode := UARTTB_PARITY_ODD ;   AdjustRxCycles := 0 ;
        when 2 =>  Baud :=  6000 ns ;  ParityMode := UARTTB_PARITY_EVEN ;  AdjustRxCycles := 0 ;
        when 3 =>  Baud :=  8000 ns ;  ParityMode := UARTTB_PARITY_ZERO ;  AdjustRxCycles := 0 ;
        when 4 =>  Baud := 10000 ns ;  ParityMode := UARTTB_PARITY_ONE ;   AdjustRxCycles := 0 ;
        when 5 =>  Baud := 12000 ns ;  ParityMode := UARTTB_PARITY_NONE ;  AdjustRxCycles := 1 ;
      end case ; 
      wait for 0 ns ; -- allow TX to report first.
      Log(RxLogID, "Setting ParityMode to " & to_string(ParityMode), INFO) ;
      SetUartParityMode(UartRxRec, ParityMode) ;
      Log(RxLogID, "Setting Baud to " & to_string(Baud, 1 ns), INFO) ;
      SetUartBaud(UartRxRec, Baud) ;
      WaitForBarrier(SetParmBarrier) ;
      WaitForClock(UartRxRec, 2) ; 

      StartTime := NOW ; 
      WaitForClock(UartRxRec, 1) ; 
      ElapsedTime := NOW - StartTime ; 
      AffirmIf(UartRxID, ElapsedTime = Baud, "1 clock = " & to_string(ElapsedTime, 1 ns)) ; 
      
      StartTime := NOW ; 
      WaitForClock(UartRxRec, 2) ; 
      ElapsedTime := NOW - StartTime ; 
      AffirmIf(UartRxID, ElapsedTime = 2 * Baud, "2 clocks = " & to_string(ElapsedTime, 1 ns)) ; 
      
      StartTime := NOW ; 
      Check(UartRxRec, X"10") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 11, MinCycles => 9) ; 

      Log(RxLogID, "Setting DataBits to 5", INFO) ;
      SetUartNumDataBits(UartRxRec, UARTTB_DATA_BITS_5) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"11") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 8, MinCycles => 7) ; 

      Log(RxLogID, "Setting DataBits to 6", INFO) ;
      SetUartNumDataBits(UartRxRec, UARTTB_DATA_BITS_6) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"12") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 9, MinCycles => 8) ; 

      Log(RxLogID, "Setting DataBits to 7", INFO) ;
      SetUartNumDataBits(UartRxRec, UARTTB_DATA_BITS_7) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"13") ;
      ElapsedTime := NOW - StartTime ; 
      RxCycles := 10 - AdjustRxCycles ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 10, MinCycles => 9) ; 

      Log(RxLogID, "Setting DataBits to 8", INFO) ;
      SetUartNumDataBits(UartRxRec, UARTTB_DATA_BITS_8) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"14") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 11, MinCycles => 10) ; 


      Log(RxLogID, "Setting StopBits to 2", INFO) ;
      SetUartNumStopBits(UartRxRec, UARTTB_STOP_BITS_2) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"15") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 12, MinCycles => 10) ; 


      Log(RxLogID, "Setting StopBits to 1", INFO) ;
      SetUartNumStopBits(UartRxRec, UARTTB_STOP_BITS_1) ;
      WaitForBarrier(SetParmBarrier) ;
      
      StartTime := NOW ; 
      Check(UartRxRec, X"16") ;
      ElapsedTime := NOW - StartTime ; 
      AffirmRxCycles (UartRxID, ElapsedTime, Baud, AdjustRxCycles, MaxCycles => 11, MinCycles => 10) ; 
    end loop ; 

    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartTbRxProc ;

end Options1 ;
Configuration TbUart_Options1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(Options1) ; 
    end for ; 
  end for ; 
end TbUart_Options1 ; 