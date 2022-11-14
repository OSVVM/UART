--
--  File Name:         SingleProcessLoop_1.vhd
--  Design Unit Name:  SingleProcessLoop_1
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
--    2022.10           Derrived from SingleProcessLoop_1.vhd
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

architecture SingleProcessLoop_1 of TestCtrl is

  signal TestDone    : integer_barrier ;
  
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_SingleProcessLoop_1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
--    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs
--    SetLogEnable(DEBUG, TRUE) ;    -- Enable DEBUG logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen(OSVVM_RESULTS_DIR & "SingleProcessLoop_1.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    AlertIf(now >= 100 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/SingleProcessLoop_1.txt", "../Uart/testbench/validated_results/SingleProcessLoop_1.txt", "") ; 

    -- Create yaml reports for UART scoreboard
    osvvm_uart.ScoreboardPkg_Uart.WriteScoreboardYaml(FileName => GetTestName & "_sb_Uart.yml") ;
    EndOfTestReports ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 
  
  
  ------------------------------------------------------------
  CentralTestProc : process
  ------------------------------------------------------------
  begin
    wait for 0 ns ; wait for 0 ns ;
    for i in 1 to 16 loop      
      -- Send
      -- Cannot index a signal parameter without a static value
--!!      SendAsync(UartTxRec(i), to_slv(i, 8), "000") ; 
      -- The following is a workaround
      SendAsync(UartTxRec, i, to_slv(i, 8), "000") ; 
    end loop ; 
    -- Indexing the signal parameter with a static value is allowed
    SendAsync(UartTxRec(5), X"AA", "000") ;
    
    for i in 1 to 16 loop 
      -- Cannot index a signal parameter without a static value
--!!      Check(UartRxRec(i), to_slv(i, 8), "000") ;
      -- The following is a workaround
      Check(UartRxRec, i, to_slv(i, 8), "000") ;
    end loop ; 
    -- Indexing the signal parameter with a static value is allowed
    Check(UartRxRec(5), X"AA", "000") ;
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 

end SingleProcessLoop_1 ;
Configuration TbUart_SingleProcessLoop_1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(SingleProcessLoop_1) ; 
    end for ; 
  end for ; 
end TbUart_SingleProcessLoop_1 ; 