--
--  File Name:         GhdlDebugLoop_1.vhd
--  Design Unit Name:  GhdlDebugLoop_1
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
--    2022.10           Derrived from GhdlDebugLoop_1.vhd
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

architecture GhdlDebugLoop_1 of TestCtrl is

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
    SetTestName("TbUart_GhdlDebugLoop_1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(DEBUG, TRUE) ;    -- Enable PASSED logs
    UartScoreboard <= NewID("UART_SB", NUM_UARTS) ; 

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen(OSVVM_RESULTS_DIR & "GhdlDebugLoop_1.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 1 ms) ;
    AlertIf(now >= 1 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/GhdlDebugLoop_1.txt", "../Uart/testbench/validated_results/GhdlDebugLoop_1.txt", "") ; 

    -- Create yaml reports for UART scoreboard
    osvvm_uart.ScoreboardPkg_Uart.WriteScoreboardYaml(FileName => GetTestName & "_sb_Uart.yml") ;
    EndOfTestReports ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 
  
  
  ------------------------------------------------------------
  CentralTestProc : process
  --   Source of all test information
  --   Used to test the UART Receiver in the UUT
  ------------------------------------------------------------
    variable TxStim, RxExpected : UartStimType ;
    variable UartNum : integer ; 
    variable RvData  : RandomPType ; 
  begin
    RvData.InitSeed(RvData'INSTANCE_NAME) ;
    wait for 0 ns ; wait for 0 ns ;
    for i in 1 to 16 loop 
      TxStim.Error := "000" ; -- No error
      TxStim.Data  := to_slv(i, 8) ;  
      
      -- Cannot index a signal parameter without a static value
--!!      SendAsync(UartTxRec(i), TxStim.Data, TxStim.Error) ; 
      -- The following is a workaround
      SendAsync(UartTxRec, i, TxStim.Data, TxStim.Error) ; 
    end loop ; 
    
    for i in 1 to 16 loop 
      RxExpected.Error := "000" ; -- No error
      RxExpected.Data  := to_slv(i, 8) ;  
      -- Cannot index a signal parameter without a static value
--!!      Check(UartRxRec(i), RxExpected.Data, RxExpected.Error) ;
      -- The following is a workaround
      Check(UartRxRec, i, RxExpected.Data, RxExpected.Error) ;
    end loop ; 
    TestActive <= FALSE ; 
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 

end GhdlDebugLoop_1 ;
Configuration TbUart_GhdlDebugLoop_1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(GhdlDebugLoop_1) ; 
    end for ; 
  end for ; 
end TbUart_GhdlDebugLoop_1 ; 