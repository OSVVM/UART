--
--  File Name:         TbUart_Options2.vhd
--  Design Unit Name:  TbUart_Options2
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Validate Parity Mode, Stopbits, DataBits, Baud with invalid values
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

architecture Options2 of TestCtrl is

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
    SetAlertLogName("TbUart_Options2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard.SetAlertLogID("UART_SB1") ; 
    TbID <= GetAlertLogID("TB") ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen("./results/TbUart_Options2.txt") ;
--    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 10 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbUart_Options2.txt", "../Uart/testbench/validated_results/TbUart_Options2.txt", "") ; 
    
    EndOfTestReports(ExternalErrors => (FAILURE => 0, ERROR => -16, WARNING => 0)) ; 
    std.env.stop(SumAlertCount(GetAlertCount + (FAILURE => 0, ERROR => -16, WARNING => 0))) ;
    wait ; 
  end process ControlProc ; 

  ------------------------------------------------------------
  -- UartTxProc
  --   Provides transactions to UartTx via Send
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
  UartTxProc : process
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
    WaitForClock(UartTxRec, 2) ; 
    
    wait for 0 ns ;
    SetUartBaud       (UartTxRec, 0 ns) ;      -- Error => 8 us
    SetUartNumDataBits(UartTxRec, 4) ;         -- Error => 8 Data Bits
    SetUartParityMode (UartTxRec, 2) ;         -- Error => EVEN
    SetUartNumStopBits(UartTxRec, 0) ;         -- Error => 1 Stop Bit
    
    WaitForClock(UartTxRec, 2) ; 
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Send(UartTxRec, X"10") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmTxCycles (UartTxID, ElapsedTime, 8 us, 0, Cycles => 11) ; 
    WaitForClock(UartTxRec, 1) ; 
    
    SetUartState (
      TransactionRec => UartTxRec,
      Baud           => 12 us ,
      DataBits       => UARTTB_DATA_BITS_6 ,
      ParityMode     => UARTTB_PARITY_ODD ,
      StopBits       => UARTTB_STOP_BITS_2 
    ) ;
    
    WaitForClock(UartTxRec, 2) ; 
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Send(UartTxRec, X"11") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmTxCycles (UartTxID, ElapsedTime, 12 us, 0, Cycles => 10) ; 
    WaitForClock(UartTxRec, 1) ; 

    SetUartState (
      TransactionRec => UartTxRec,
      Baud           => -5 us ,                -- 8 us
      DataBits       => 9 ,                    -- 8 Data Bits
      ParityMode     => 10 ,                   -- EVEN
      StopBits       => 3                      -- 1 Stop Bit
    ) ;
    
    WaitForClock(UartTxRec, 2) ; 
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Send(UartTxRec, X"12") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmTxCycles (UartTxID, ElapsedTime, 8 us, 0, Cycles => 11) ; 
    WaitForClock(UartTxRec, 1) ; 

    SetUartState (
      TransactionRec => UartTxRec,
      Baud           => 4 us ,                -- 4 us
      DataBits       => 7 ,                   -- 7 Data Bits
      ParityMode     => UARTTB_PARITY_ODD ,   -- EVEN
      StopBits       => UARTTB_STOP_BITS_1    -- 1 Stop Bit
    ) ;
    
    WaitForClock(UartTxRec, 2) ; 
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Send(UartTxRec, X"13") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmTxCycles (UartTxID, ElapsedTime, 4 us, 0, Cycles => 10) ; 

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
    WaitForClock(UartRxRec, 2) ; 
    
    Log(RxLogID, "Setting Invalid Values: Baud (8 us), NumDataBits (8), ParityMode(EVEN), NumStopBits(1) to valid values", INFO) ;
    SetUartBaud       (UartRxRec, 0 ns) ;      -- Error => 8 us
    SetUartNumDataBits(UartRxRec, 4) ;         -- Error => 8 Data Bits
    SetUartParityMode (UartRxRec, 2) ;         -- Error => EVEN
    SetUartNumStopBits(UartRxRec, 0) ;         -- Error => 1 Stop Bit
    
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Check(UartRxRec, X"10") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmRxCycles (UartRxID, ElapsedTime, 8 us, 0, MaxCycles => 11, MinCycles => 9) ; 
    WaitForClock(UartRxRec, 1) ; 


    BlankLine(2) ;
    Log(RxLogID, "Setting Valid: Baud(12 us), NumDataBits(6), ParityMode(ODD), NumStopBits(2) to valid values", INFO) ;
    SetUartState (
      TransactionRec => UartRxRec,
      Baud           => 12 us ,
      DataBits       => UARTTB_DATA_BITS_6 ,
      ParityMode     => UARTTB_PARITY_ODD ,
      StopBits       => UARTTB_STOP_BITS_2 
    ) ;
    
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Check(UartRxRec, X"11") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmRxCycles (UartRxID, ElapsedTime, 12 us, 0, MaxCycles => 9, MinCycles => 8) ; 
    WaitForClock(UartRxRec, 2) ; 


    BlankLine(2) ;
    Log(RxLogID, "Setting Invalid Values: Baud(8 us), NumDataBits(8), ParityMode(EVEN), NumStopBits(1) to valid values", INFO) ;
    SetUartState (
      TransactionRec => UartRxRec,
      Baud           => -5 us ,                -- 8 us
      DataBits       => 9 ,                    -- 8 Data Bits
      ParityMode     => 10 ,                   -- EVEN
      StopBits       => 3                      -- 1 Stop Bit
    ) ;
    
    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Check(UartRxRec, X"12") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmRxCycles (UartRxID, ElapsedTime, 8 us, 0, MaxCycles => 11, MinCycles => 10) ; 
    WaitForClock(UartRxRec, 1) ; 


    BlankLine(2) ;
    Log(RxLogID, "Setting Valid:  Baud(4 us), NumDataBits(7), ParityMode(ODD), NumStopBits(1)", INFO) ;
    SetUartState (
      TransactionRec => UartRxRec,
      Baud           => 4 us ,                -- 4 us
      DataBits       => 7 ,                   -- 7 Data Bits
      ParityMode     => UARTTB_PARITY_ODD ,   -- ODD
      StopBits       => UARTTB_STOP_BITS_1    -- 1 Stop Bit
    ) ;

    WaitForBarrier(SetParmBarrier) ;

    StartTime := NOW ; 
    Check(UartRxRec, X"13") ;
    ElapsedTime := NOW - StartTime ; 
    AffirmRxCycles (UartRxID, ElapsedTime, 4 us, 0, MaxCycles => 10, MinCycles => 9) ; 

    --
    ------------------------------------------------------------
    -- End of test.  Wait for outputs to propagate and signal TestDone
    wait for 4 * UART_BAUD_PERIOD_115200 ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process UartRxProc ;

end Options2 ;
Configuration TbUart_Options2 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(Options2) ; 
    end for ; 
  end for ; 
end TbUart_Options2 ; 