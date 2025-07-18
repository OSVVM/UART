--
--  File Name:         TbUart_UartX16_1.vhd
--  Design Unit Name:  TbUart_UartX16_1
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
--    2022.10           Derrived from TbUart_UartX16_1.vhd
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
    SetTestName("TbUart_UartX16_1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    UartScoreboard <= NewID("UART_SB", NUM_UARTS) ; 

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
--      UartNum := 1 ;
      UartStim.Data   := to_slv(i mod 256, 8) ;  -- values 0 to 255
      UartStim.Error  := to_slv(0, 3) ;          -- no errors
      
      -- Hand off data to the send side
      TxStim(UartNum) <= UartStim ;
      
      -- Hand off Data to the receive side
      Push(UartScoreboard(UartNum), UartStim) ; 
      RxReq(UartNum) <= RxReq(UartNum) + 1 ;
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
    begin
      wait for 0 ns ; wait for 0 ns ; 

      loop 
        exit when not TestActive ;
        wait on TxStim(GEN_UART)'transaction, TestActive ; 
        exit when not TestActive ;
        SendAsync(UartTxRec(GEN_UART), TxStim(GEN_UART).Data, TxStim(GEN_UART).Error) ; 
      end loop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartTxProc ;


    ------------------------------------------------------------
    UartRxProc : process
    ------------------------------------------------------------
      variable ReceivedVal : UartStimType ; 
    begin
      wait for 0 ns ; wait for 0 ns ; 
      UartReceiveLoop : loop 
        exit when not TestActive ;
        if IsEmpty(UartScoreboard(GEN_UART)) then
          wait on RxReq(GEN_UART), TestActive ; 
          exit when not TestActive ;
        end if ; 
        
        Get(UartRxRec(GEN_UART), ReceivedVal.Data, ReceivedVal.Error) ;
        Check(UartScoreboard(GEN_UART), ReceivedVal ) ; 
      end loop ;
      
      WaitForBarrier(TestDone) ;
      wait ;
    end process UartRxProc ;
  end generate GenerateUartHandlers ; 


end UartX16_1 ;
Configuration TbUart_UartX16_1 of TbUart is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(UartX16_1) ; 
    end for ; 
  end for ; 
end TbUart_UartX16_1 ; 