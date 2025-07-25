--
--  File Name:         TbUart_UartX16_2.vhd
--  Design Unit Name:  TbUart_UartX16_2
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
--    Date / Version    Description
--    2022.10           Derrived from TbUart_UartX1_2.vhd
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 1999 - 2022 by SynthWorks Design Inc.
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

architecture UartX16_1 of TestCtrl is

  signal TestDone    : integer_barrier ;
  signal TestActive  : boolean := TRUE ; 
  
  use osvvm_uart.ScoreboardPkg_Uart.all ; 
  signal RxScoreboard : osvvm_uart.ScoreboardPkg_Uart.ScoreboardIdArrayType (1 to NUM_UARTS) ; 
  signal TxFifo       : osvvm_uart.ScoreboardPkg_Uart.ScoreboardIdArrayType (1 to NUM_UARTS) ; 
  
  signal TxReq  : integer_vector (1 to NUM_UARTS) := (others => 0) ; 
  signal RxReq  : integer_vector (1 to NUM_UARTS) := (others => 0) ; 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_UartX16_2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    RxScoreboard <= NewID("RxSb",   NUM_UARTS) ; 
    TxFifo       <= NewID("TxFifo", NUM_UARTS) ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    
    TranscriptClose ; 
--    AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ;
    
    -- Create yaml reports for UART scoreboard
    osvvm_uart.ScoreboardPkg_Uart.WriteScoreboardYaml(FileName => "Uart") ;
    EndOfTestReports(TimeOut => (now >= 100 ms)) ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 
  
  
  ------------------------------------------------------------
  CentralTestProc : process
  --   Source of all test information
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
    variable UartStim : UartStimType ;
    variable UartNum : integer ; 
  begin
    wait for 0 ns ; wait for 0 ns ;
    for i in 0 to 2**8 - 1 loop 
      -- Formulate stimulus value
      UartNum := i mod NUM_UARTS + 1 ; 
      UartStim.Data   := to_slv((i + 1) mod 256, 8) ;  -- values 0 to 255
      UartStim.Error  := to_slv(0, 3) ;          -- no errors
      
      -- Hand off data to the send side
      Push(TxFifo(UartNum), UartStim) ; 
      TxReq(UartNum) <= increment(TxReq(UartNum)) ;
      -- increment(TxReq(UartNum)) ;  -- Not static signal
      
      -- Hand off Data to the receive side
      Push(RxScoreboard(UartNum), UartStim) ; 
      RxReq(UartNum) <= increment(RxReq(UartNum)) ;
      wait for UART_BAUD_PERIOD_125K ; 
--      wait for 11 * UART_BAUD_PERIOD_125K ; 
    end loop ; 
    TestActive <= FALSE ; 
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 


  GenerateUartHandlers : for GEN_UART in 1 to NUM_UARTS generate 
  begin
    ------------------------------------------------------------
    UartTxProc : process
    ------------------------------------------------------------
      variable TxStim : UartStimType ;
    begin
      wait for 0 ns ; wait for 0 ns ; 

      TransmitLoop : loop 
        exit when not TestActive ;
        if IsEmpty(TxFifo(GEN_UART)) then
          wait on TxReq(GEN_UART), TestActive ; 
          exit when not TestActive and IsEmpty(TxFifo(GEN_UART)) ;
        end if ; 
        TxStim := Pop(TxFifo(GEN_UART)) ; 
        SendAsync(UartTxRec(GEN_UART), TxStim.Data, TxStim.Error) ; 
      end loop TransmitLoop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartTxProc ;


    ------------------------------------------------------------
    UartRxProc : process
    ------------------------------------------------------------
      variable ReceivedVal : UartStimType ; 
    begin
      wait for 0 ns ; wait for 0 ns ; 
      ReceiveLoop : loop 
        exit when not TestActive ;
        if IsEmpty(RxScoreboard(GEN_UART)) then
          wait on RxReq(GEN_UART), TestActive ; 
          exit when not TestActive and IsEmpty(TxFifo(GEN_UART)) ;
        end if ; 
        
        Get(UartRxRec(GEN_UART), ReceivedVal.Data, ReceivedVal.Error) ;
        Check(RxScoreboard(GEN_UART), ReceivedVal ) ; 
      end loop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartRxProc ;
  end generate GenerateUartHandlers ; 


end UartX16_1 ;
Configuration TbUart_UartX16_2 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(UartX16_1) ; 
    end for ; 
  end for ; 
end TbUart_UartX16_2 ; 