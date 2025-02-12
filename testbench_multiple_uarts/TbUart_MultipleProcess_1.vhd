--
--  File Name:         TbUart_MultipleProcess_1.vhd.vhd
--  Design Unit Name:  TbUart_MultipleProcess_1.vhd
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--    Test Multiple UARTs, each being dispatched from a separate process
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

architecture MultipleProcess_1 of TestCtrl is

  signal TestDone    : integer_barrier ;
  signal TestActive  : boolean := TRUE ; 
  
  use osvvm_uart.ScoreboardPkg_Uart.all ; 
  signal RxScoreboard : osvvm_uart.ScoreboardPkg_Uart.ScoreboardIdArrayType (1 to NUM_UARTS) ; 
  signal TxFifo       : osvvm_uart.ScoreboardPkg_Uart.ScoreboardIdArrayType (1 to NUM_UARTS) ; 
  
  signal TxReq  : integer_vector (1 to NUM_UARTS) := (others => 0) ; 
  signal RxReq  : integer_vector (1 to NUM_UARTS) := (others => 0) ; 
  
  signal TxIdleProbability : real := 0.05 ; -- 5 %
  signal RxIdleProbability : real := 0.05 ; -- 5 %
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_MultipleProcess_1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    RxScoreboard <= NewID("RxSb",   NUM_UARTS) ; 
    TxFifo       <= NewID("TxFifo", NUM_UARTS) ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen(OSVVM_RESULTS_DIR & "TbUart_MultipleProcess_1.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Do 5 ms of UART transfers and then stop
    wait for 5 ms ; 
    TestActive <= FALSE ; 

    -- Wait for test to finish
    WaitForBarrier(TestDone, 5 ms) ;
    AlertIf(now >= 10 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/TbUart_MultipleProcess_1.txt", "../Uart/testbench/validated_results/TbUart_MultipleProcess_1.txt", "") ; 
    
    -- Create yaml reports for UART scoreboard
    osvvm_uart.ScoreboardPkg_Uart.WriteScoreboardYaml(FileName => "Uart") ;
    EndOfTestReports ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 

  GenerateUartHandlers : for GEN_UART in 1 to NUM_UARTS generate 
    signal RxActive : boolean := TRUE ; 
  begin
    ------------------------------------------------------------
    UartTxProc : process
    ------------------------------------------------------------
      variable TxStim : UartStimType ;
      variable RvCtrl, RvData : RandomPType ; 
    begin
      RvCtrl.InitSeed(RvCtrl'INSTANCE_NAME) ;
      RvData.InitSeed(RvData'INSTANCE_NAME) ;
      wait for 0 ns ; wait for 0 ns ; 

      TransmitLoop : while RxActive loop 
        for i in 1 to RvCtrl.RandInt(1, 20) loop 
          TxStim.Error  := RvData.DistSlv((70,10,10,6,1,1,1,1), 3) ; 
          if TxStim.Error >= 4 then 
            TxStim.Data   := RvData.RandSlv(11,25,8);  -- Break Error
          elsif TxStim.Error <= 1 then 
            TxStim.Data   := RvData.RandSlv(0,255,8);  -- Normal & Parity Errors
          else
            TxStim.Data   := RvData.RandSlv(1,255,8);  -- Stop Error or Stop and Parity
          end if ;
          Push(RxScoreboard(GEN_UART), TxStim) ; 
          Send(UartTxRec(GEN_UART), TxStim.Data, TxStim.Error) ; 
          exit when not RxActive ; 
        end loop ; 
        
        WaitForClock(UartTxRec(GEN_UART), RvCtrl.RandInt(1, 5));

      end loop TransmitLoop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartTxProc ;


    ------------------------------------------------------------
    UartRxProc : process
    ------------------------------------------------------------
      variable ReceivedVal : UartStimType ; 
      variable RvCtrl : RandomPType ; 
    begin
      RvCtrl.InitSeed(RvCtrl'INSTANCE_NAME) ;
      wait for 0 ns ; wait for 0 ns ; 
      ReceiveLoop : while TestActive or not IsEmpty(RxScoreboard(GEN_UART)) loop 
        for i in 1 to RvCtrl.RandInt(1, 20) loop         
          Get(UartRxRec(GEN_UART), ReceivedVal.Data, ReceivedVal.Error) ;
          Check(RxScoreboard(GEN_UART), ReceivedVal ) ; 
          exit when not TestActive ; 
        end loop ;
        RxActive <= TestActive ; 
        
        WaitForClock(UartRxRec(GEN_UART), RvCtrl.RandInt(1, 5));
      end loop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartRxProc ;
  end generate GenerateUartHandlers ; 
  
end MultipleProcess_1 ;

Configuration TbUart_MultipleProcess_1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(MultipleProcess_1) ; 
    end for ; 
  end for ; 
end TbUart_MultipleProcess_1 ; 