--
--  File Name:         SingleProcessLoop_2.vhd
--  Design Unit Name:  SingleProcessLoop_2
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--     Multiple UART test
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date / Version    Description
--    2022.10           Derrived from SingleProcessLoop_2.vhd
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

architecture SingleProcessLoop_2 of TestCtrl is

  signal TestDone    : integer_barrier ;
  signal TestActive  : boolean := TRUE ; 
  
  use osvvm_uart.ScoreboardPkg_Uart.all ; 
  signal UartScoreboard : osvvm_uart.ScoreboardPkg_Uart.ScoreboardIdArrayType (1 to NUM_UARTS) ; 

  type UartStimArrayType is array (integer range <>) of UartStimType ;
  
  signal TxStim : UartStimArrayType (1 to NUM_UARTS) ; 
  signal RxReq  : integer_vector (1 to NUM_UARTS) := (others => 0); 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_SingleProcessLoop_2") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(DEBUG, TRUE) ;    -- Enable PASSED logs
    UartScoreboard <= NewID("UART_SB", NUM_UARTS) ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen(OSVVM_RESULTS_DIR & "SingleProcessLoop_2.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    AlertIf(now >= 100 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/SingleProcessLoop_2.txt", "../Uart/testbench/validated_results/SingleProcessLoop_2.txt", "") ; 

    -- Create yaml reports for UART scoreboard
    osvvm_uart.ScoreboardPkg_Uart.WriteScoreboardYaml(FileName => "Uart") ;
    EndOfTestReports ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 
  
  
  ------------------------------------------------------------
  CentralTestProc : process
  --   Source of all test information
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
    variable TxStim, RxReceived : UartStimType ;
    variable UartNum : integer ; 
    variable RvData  : RandomPType ; 
  begin
    RvData.InitSeed(RvData'INSTANCE_NAME) ;
    wait for 0 ns ; wait for 0 ns ;
    for i in 1 to 16 loop 
      TxStim.Error  := RvData.DistSlv((70,10,10,6,1,1,1,1), 3) ; 
      if TxStim.Error >= 4 then 
        TxStim.Data   := RvData.RandSlv(11,25,8);  -- Break Error
      elsif TxStim.Error <= 1 then 
        TxStim.Data   := RvData.RandSlv(0,255,8);  -- Normal & Parity Errors
      else
        TxStim.Data   := RvData.RandSlv(1,255,8);  -- Stop Error or Stop and Parity
      end if ;
      
      -- Send
      Push(UartScoreboard(i), TxStim) ; 
      -- Cannot index a signal parameter without a static value
--!!      SendAsync(UartTxRec(i), TxStim.Data, TxStim.Error) ; 
      -- The following is a workaround
      SendAsync(UartTxRec, i, TxStim.Data, TxStim.Error) ; 
    end loop ; 
    TxStim := (Data => X"AA", Error => "000") ; 
    -- Indexing the signal parameter with a static value is allowed
    Push(UartScoreboard(5), TxStim) ; 
    SendAsync(UartTxRec(5), TxStim.Data, TxStim.Error) ;
    
    for i in 1 to 16 loop 
      -- Cannot index a signal parameter without a static value
--!!      Get(UartRxRec(i), RxReceived.Data, RxReceived.Error) ;
      -- The following is a workaround
      Get(UartRxRec, i, RxReceived.Data, RxReceived.Error) ;
      log("UartRx received: " & to_string(RxReceived), DEBUG) ;
      Check(UartScoreboard(i), RxReceived ) ; 
    end loop ; 
    -- Indexing the signal parameter with a static value is allowed
    Get(UartRxRec(5), RxReceived.Data, RxReceived.Error) ;
    Check(UartScoreboard(5), RxReceived ) ; 
    TestActive <= FALSE ; 
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 

end SingleProcessLoop_2 ;
Configuration TbUart_SingleProcessLoop_2 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(SingleProcessLoop_2) ; 
    end for ; 
  end for ; 
end TbUart_SingleProcessLoop_2 ; 