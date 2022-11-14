--
--  File Name:         GhdlDebug_3.vhd
--  Design Unit Name:  GhdlDebug_3
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
--    2022.10           Derrived from GhdlDebug_3.vhd
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

architecture GhdlDebug_3 of TestCtrl is

  signal TestDone    : integer_barrier ;
  signal TbID        : AlertLogIDType ; 
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_GhdlDebug_3") ;
    TbID <= NewID("Testbench") ; 
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(DEBUG, TRUE) ;    -- Enable PASSED logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen(OSVVM_RESULTS_DIR & "GhdlDebug_3.txt") ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    AlertIf(now >= 100 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AlertIfDiff("./results/GhdlDebug_3.txt", "../Uart/testbench/validated_results/GhdlDebug_3.txt", "") ; 

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
    variable Data : std_logic_vector (7 downto 0) ; 
    variable Error : std_logic_vector (3 downto 1) ; 
  begin
    SendAsync(UartTxRec, 1, Data => X"01", Param => "000") ; 
    
    Get(UartRxRec, 1, Data => Data, Param => Error) ; 
    log(TbID, "Received: " & to_string(UartStimType'(Data, Error))) ; 
    AffirmIfEqual(TbID, Data, X"01", "Data: ") ; 
    AffirmIfEqual(TbID, Error, "000", "Error: ") ; 
    
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 

end GhdlDebug_3 ;
Configuration TbUart_GhdlDebug_3 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(GhdlDebug_3) ; 
    end for ; 
  end for ; 
end TbUart_GhdlDebug_3 ; 