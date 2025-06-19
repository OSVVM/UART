--
--  File Name:         SingleProcess_1.vhd
--  Design Unit Name:  SingleProcess_1
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
--    2022.10           Derrived from SingleProcess_1.vhd
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

architecture SingleProcess_1 of TestCtrl is

  signal TestDone    : integer_barrier ;
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbUart_SingleProcess_1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(DEBUG, TRUE) ;    -- Enable PASSED logs

    -- Wait for testbench initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;
    
    -- Wait for test to finish
    WaitForBarrier(TestDone, 100 ms) ;
    AlertIf(now >= 100 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
--    AffirmIfTranscriptsMatch(PATH_TO_VALIDATED_RESULTS) ;

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
  begin
    SendAsync(UartTxRec( 1), Data => X"01", Param => "000") ; 
    SendAsync(UartTxRec( 2), Data => X"02", Param => "000") ; 
    SendAsync(UartTxRec( 3), Data => X"03", Param => "000") ; 
    SendAsync(UartTxRec( 4), Data => X"04", Param => "000") ; 
    SendAsync(UartTxRec( 5), Data => X"05", Param => "000") ; 
    SendAsync(UartTxRec( 6), Data => X"06", Param => "000") ; 
    SendAsync(UartTxRec( 7), Data => X"07", Param => "000") ; 
    SendAsync(UartTxRec( 8), Data => X"08", Param => "000") ; 
    SendAsync(UartTxRec( 9), Data => X"09", Param => "000") ; 
    SendAsync(UartTxRec(10), Data => X"0A", Param => "000") ; 
    SendAsync(UartTxRec(11), Data => X"0B", Param => "000") ; 
    SendAsync(UartTxRec(12), Data => X"0C", Param => "000") ; 
    SendAsync(UartTxRec(13), Data => X"0D", Param => "000") ; 
    SendAsync(UartTxRec(14), Data => X"0E", Param => "000") ; 
    SendAsync(UartTxRec(15), Data => X"0F", Param => "000") ; 
    SendAsync(UartTxRec(16), Data => X"10", Param => "000") ; 
    
    Check(UartRxRec( 1), Data => X"01", Param => "000") ; 
    Check(UartRxRec( 2), Data => X"02", Param => "000") ; 
    Check(UartRxRec( 3), Data => X"03", Param => "000") ; 
    Check(UartRxRec( 4), Data => X"04", Param => "000") ; 
    Check(UartRxRec( 5), Data => X"05", Param => "000") ; 
    Check(UartRxRec( 6), Data => X"06", Param => "000") ; 
    Check(UartRxRec( 7), Data => X"07", Param => "000") ; 
    Check(UartRxRec( 8), Data => X"08", Param => "000") ; 
    Check(UartRxRec( 9), Data => X"09", Param => "000") ; 
    Check(UartRxRec(10), Data => X"0A", Param => "000") ; 
    Check(UartRxRec(11), Data => X"0B", Param => "000") ; 
    Check(UartRxRec(12), Data => X"0C", Param => "000") ; 
    Check(UartRxRec(13), Data => X"0D", Param => "000") ; 
    Check(UartRxRec(14), Data => X"0E", Param => "000") ; 
    Check(UartRxRec(15), Data => X"0F", Param => "000") ; 
    Check(UartRxRec(16), Data => X"10", Param => "000") ; 
    
    WaitForBarrier(TestDone) ;
    wait ; 
  end process CentralTestProc ; 

end SingleProcess_1 ;
Configuration TbUart_SingleProcess_1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(SingleProcess_1) ; 
    end for ; 
  end for ; 
end TbUart_SingleProcess_1 ; 