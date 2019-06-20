--
--  File Name:         UartTx.vhd
--  Design Unit Name:  UartTx
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      UART Transmitter Model
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date       Version    Description
--    1999       1999.00    Developed for SynthWorks' Advanced VHDL Testbenches and Verification Class
--    2019.05    2019.05    Updated for OSVVM public release
--
--      Copyright (c) 1999 - 2019 by SynthWorks Design Inc.  All rights reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;

library OSVVM ; 
  context OSVVM.OsvvmContext ; 

library osvvm_vip ; 
  context osvvm_vip.OsvvmVipContext ;  

  use work.UartTbPkg.all ;

entity UartTx is 
  generic (
    DEFAULT_BAUD            : time    := UART_BAUD_PERIOD_125K ;
    DEFAULT_NUM_DATA_BITS   : integer := UARTTB_DATA_BITS_8 ; 
    DEFAULT_PARITY_MODE     : integer := UARTTB_PARITY_EVEN ; 
    DEFAULT_NUM_STOP_BITS   : integer := UARTTB_STOP_BITS_1  
  ) ;
  port (
    TransactionRec      : InOut UartRecType ;

    SerialDataOut       : Out   std_logic := '1' 
  ) ;
end UartTx ;
architecture model of UartTx is

  signal UartTxClk : std_logic := '0'  ;
  
  constant MODEL_INSTANCE_NAME : string := PathTail(to_lower(UartTx'PATH_NAME)) ; 
  signal ModelID  : AlertLogIDType ;
  
  shared variable TransmitFifo     : osvvm.ScoreboardPkg_slv.ScoreboardPType ; 
  signal TransmitRequestCount, TransmitDoneCount      : integer := 0 ;   

  -- Set initial values for configurable modes
  signal ParityMode  : integer ;
  signal NumStopBits : integer ;
  signal NumDataBits : integer ;
  signal Baud        : time    := UART_BAUD_PERIOD_125K ; -- init for clock start

begin


  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  Initialize : process
    variable ID : AlertLogIDType ; 
  begin
    ID                         := GetAlertLogID(MODEL_INSTANCE_NAME) ; 
    ModelID                    <= ID ; 
    TransmitFifo.SetAlertLogID(MODEL_INSTANCE_NAME & ": Transmit FIFO", ID) ;
    wait ; 
  end process Initialize ;


  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    variable Operation : TransactionRec.Operation'subtype ;
    variable WaitCycles : integer ;
    variable TxStim : UartStimType ;
  begin
    wait for 0 ns ; -- Let ModelID get set
    -- Initialize
    ParityMode    <= CheckParityMode (ModelID, DEFAULT_PARITY_MODE,   FALSE) ; 
    NumStopBits   <= CheckNumStopBits(ModelID, DEFAULT_NUM_STOP_BITS, FALSE) ; 
    NumDataBits   <= CheckNumDataBits(ModelID, DEFAULT_NUM_DATA_BITS, FALSE) ; 
    Baud          <= CheckBaud(ModelID, DEFAULT_BAUD, FALSE) ;  

    TransactionDispatcherLoop : loop 
      WaitForTransaction(
         Clk      => UartTxClk,
         Rdy      => TransactionRec.Rdy,
         Ack      => TransactionRec.Ack
      ) ;
      
      Operation := TransactionRec.Operation ;
      
      case Operation is
        when SEND | SEND_ASYNC =>
          TxStim.Data  := std_logic_vector(TransactionRec.DataToModel) ;
          TxStim.Error := std_logic_vector(TransactionRec.ErrorToModel) ;
          TransmitFifo.Push(TxStim.Data & TxStim.Error) ;
          Log(ModelID, 
            "SEND Queueing Transaction: " & to_string(TxStim) & 
            "  Operation # " & to_string(TransmitRequestCount + 1),
            INFO, Enable => TransactionRec.BoolToModel
          ) ; 
          Increment(TransmitRequestCount) ;
          wait for 0 ns ; 
          if Operation = SEND then
            if TransmitRequestCount /= TransmitDoneCount then 
              wait until TransmitRequestCount = TransmitDoneCount ;
            end if ; 
          end if ; 
        
        when WAIT_FOR_TRANSACTION =>
          if TransmitRequestCount /= TransmitDoneCount then 
            wait until TransmitRequestCount = TransmitDoneCount ;
          end if ; 

        when WAIT_FOR_CLOCK =>
          WaitCycles := TransactionRec.IntToModel ;
          wait for (WaitCycles * Baud) - 1 ns ;
          wait until UartTxClk = '1' ;
          
        when GET_ALERT_LOG_ID =>
          TransactionRec.IntFromModel <= ModelID ;

        when GET_TRANSACTION_COUNT =>
          TransactionRec.IntFromModel <= TransmitDoneCount ;

        when SET_OPTIONS =>
          case TransactionRec.Option is
            when UartOptionType'pos(SET_PARITY_MODE) => 
              ParityMode    <= CheckParityMode(ModelID, TransactionRec.IntToModel, TransactionRec.BoolToModel) ; 
            when UartOptionType'pos(SET_STOP_BITS) =>
              NumStopBits   <= CheckNumStopBits(ModelID, TransactionRec.IntToModel, TransactionRec.BoolToModel) ; 
            when UartOptionType'pos(SET_DATA_BITS) =>      
              NumDataBits   <= CheckNumDataBits(ModelID, TransactionRec.IntToModel, TransactionRec.BoolToModel) ; 
            when UartOptionType'pos(SET_BAUD) =>
              Baud          <= CheckBaud(ModelID, TransactionRec.TimeToModel, TransactionRec.BoolToModel) ;  
            when others =>     
              alert(ModelID, "SetOptions: " & to_string(TransactionRec.Option) & ". Unsupported Option was Ignored", ERROR) ;
          end case ; 
        
        when others =>
          Alert(ModelID, "Unimplemented Transaction", FAILURE) ;
          
      end case ;
    end loop TransactionDispatcherLoop ;
  end process TransactionDispatcher ;


  ------------------------------------------------------------
  -- Uart Clock
  --   Period = TransactionRec.Baud 
  ------------------------------------------------------------
  UartTxClk <= not UartTxClk after Baud / 2 ; 

  ------------------------------------------------------------
  -- Uart Transmit Functionality 
  --   Wait for Transaction
  --   Serially transmit data from the record
  --   Calculate and transmit parity
  ------------------------------------------------------------
  UartTransmitHandler : process
    variable TxStim : UartStimType ;
  begin
    -- Initialize
    SerialDataOut <= '1' ; 
    
    TransmitLoop : loop 
      -- Find Transaction
      if TransmitFifo.Empty then
        WaitForToggle(TransmitRequestCount) ;
      else 
        wait for 0 ns ; -- allow TransmitRequestCount to settle if both happen at same time.
      end if ;
      
      (TxStim.Data, TxStim.Error) := TransmitFifo.Pop ;
      
      Log(ModelID, 
        "SEND Starting: " & to_string(TxStim) & 
        "  Operation # " & to_string(TransmitRequestCount),
        DEBUG
      ) ; 
    
      if TxStim.Error(UARTTB_BREAK_INDEX) = '0' then  
        -- Normal Data Transmission
        -- Drive Start Bit
        SerialDataOut <= '0' ;
        wait until UartTxClk = '1' ;

        -- Drive Data Bits
        for i in 0 to NumDataBits - 1 loop 
          SerialDataOut <= TxStim.Data(i) ; 
          wait until UartTxClk = '1' ;
        end loop ;

        -- Drive Parity 
        if ParityMode /= UARTTB_PARITY_NONE then
          -- Drive Parity 
          if TxStim.Error(UARTTB_PARITY_INDEX) = '0' then  
            SerialDataOut <= CalcParity(TxStim.Data, ParityMode) ;   
          else 
            SerialDataOut <= not CalcParity(TxStim.Data, ParityMode) ; 
          end if ; 
          wait until UartTxClk = '1' ;
        end if ; 

        -- Drive Stop Bit
        for i in 1 to NumStopBits loop 
          if TxStim.Error(UARTTB_STOP_INDEX) = '1' then  
            SerialDataOut <= '0' ;
            wait until UartTxClk = '1' ;
          else 
            SerialDataOut <= '1' ;
            wait until UartTxClk = '1' ;
          end if ; 
        end loop ;
        -- if Stop Error, finish at '1'
        if TxStim.Error(UARTTB_STOP_INDEX) = '1' then  
          SerialDataOut <= '1' ;
          wait until UartTxClk = '1' ;
        end if ; 
        
      else  

        -- Break Handling
        SerialDataOut <= '0' ;
        wait for to_integer(TxStim.Data) * Baud - 1 ns ; 
        wait until UartTXClk = '1' ; 
        SerialDataOut <= '1' ;
        wait until UartTXClk = '1' ; 

      end if ; 
    
      -- Signal completion
      Increment(TransmitDoneCount) ;
    end loop TransmitLoop ; 
  end process UartTransmitHandler ; 

end model ;
