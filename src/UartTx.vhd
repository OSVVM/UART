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
--    Date      Version    Description
--    05/2022   2022.05    Updated FIFOs so they are Search => PRIVATE, Added MODEL_ID_NAME generic
--    03/2022   2022.03    Updated to use singleton based FIFOs.  Updated calls for AlertLogIDs
--    08/2021   2021.08    Initialized NumDataBits, ParityMode, and NumStopBits
--    02/2021   2021.02    Updated for resizing Data and Param to/from TransRec
--    10/2020   2020.10    Update for updates to stream MIT
--    07/2020   2020.07    Converted transactions to stream MIT 
--    01/2020   2020.01    Updated license notice
--    05/2019   2019.05    Updated for OSVVM public release
--    1999      1999.00    Developed for SynthWorks' Advanced VHDL Testbenches and Verification Class
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 1999 - 2021 by SynthWorks Design Inc.
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

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;

library OSVVM ; 
  context OSVVM.OsvvmContext ; 

library osvvm_common ; 
  context osvvm_common.OsvvmCommonContext ;  
  use osvvm.ScoreboardPkg_slv.all ;

  use work.UartTbPkg.all ;

entity UartTx is 
  generic (
    MODEL_ID_NAME           : string := "" ;
    DEFAULT_BAUD            : time    := UART_BAUD_PERIOD_125K ;
    DEFAULT_NUM_DATA_BITS   : integer := UARTTB_DATA_BITS_8 ; 
    DEFAULT_PARITY_MODE     : integer := UARTTB_PARITY_EVEN ; 
    DEFAULT_NUM_STOP_BITS   : integer := UARTTB_STOP_BITS_1  
  ) ;
  port (
    TransRec          : InOut UartRecType ;
    SerialDataOut     : Out   std_logic := '1' 
  ) ;
  
  -- Use MODEL_ID_NAME Generic if set, otherwise,
  -- use model instance label (preferred if set as entityname_1)
  constant MODEL_INSTANCE_NAME : string :=
    IfElse(MODEL_ID_NAME'length > 0, MODEL_ID_NAME, 
      to_lower(PathTail(UartTx'PATH_NAME))) ;
      
end UartTx ;
architecture model of UartTx is

  signal UartTxClk : std_logic := '0'  ;
  
  signal ModelID  : AlertLogIDType ;
  
  signal TransmitFifo : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;  
  signal TransmitRequestCount, TransmitDoneCount      : integer := 0 ;   

  -- Set initial values for configurable modes
  signal ParityMode  : integer := UARTTB_PARITY_EVEN ;
  signal NumStopBits : integer := UARTTB_STOP_BITS_1 ;
  signal NumDataBits : integer := UARTTB_DATA_BITS_8 ;
  signal Baud        : time    := UART_BAUD_PERIOD_125K ; -- init for clock start

begin


  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  Initialize : process
    variable ID : AlertLogIDType ; 
  begin
    ID             := NewID(MODEL_INSTANCE_NAME) ; 
    ModelID        <= ID ; 
    TransmitFifo   <= NewID("TransmitFifo", ID, ReportMode => DISABLED, Search => PRIVATE) ; 
    wait ; 
  end process Initialize ;


  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    alias Operation : StreamOperationType is TransRec.Operation ;
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
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;
      
--!      Operation := TransRec.Operation ;
      
      case Operation is
        when SEND | SEND_ASYNC =>
          TxStim.Data  := SafeResize(TransRec.DataToModel, TxStim.Data'length) ;
          TxStim.Error := to_01(SafeResize(TransRec.ParamToModel, TxStim.Error'length)) ;
--          if TxStim.Error(TxStim.Error'right) = '-' then 
--            TxStim.Error := (TxStim.Error'range => '0') ;
--          end if ; 
          Push(TransmitFifo, TxStim.Data & TxStim.Error) ;
          Log(ModelID, 
            "SEND Queueing Transaction: " & to_string(TxStim) & 
            "  Operation # " & to_string(TransmitRequestCount + 1),
            INFO, Enable => TransRec.BoolToModel
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
          WaitCycles := TransRec.IntToModel ;
          wait for (WaitCycles * Baud) - 1 ns ;
          wait until UartTxClk = '1' ;
          
        when GET_ALERTLOG_ID =>
          TransRec.IntFromModel <= ModelID ;

        when GET_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= TransmitDoneCount ;

        when SET_MODEL_OPTIONS =>
          case TransRec.Options is
            when UartOptionType'pos(SET_PARITY_MODE) => 
              ParityMode    <= CheckParityMode(ModelID, TransRec.IntToModel, TransRec.BoolToModel) ; 
            when UartOptionType'pos(SET_STOP_BITS) =>
              NumStopBits   <= CheckNumStopBits(ModelID, TransRec.IntToModel, TransRec.BoolToModel) ; 
            when UartOptionType'pos(SET_DATA_BITS) =>      
              NumDataBits   <= CheckNumDataBits(ModelID, TransRec.IntToModel, TransRec.BoolToModel) ; 
            when UartOptionType'pos(SET_BAUD) =>
              Baud          <= CheckBaud(ModelID, TransRec.TimeToModel, TransRec.BoolToModel) ;  
            when others =>              
              Alert(ModelID, "SetOptions, Unimplemented Option: " & to_string(UartOptionType'val(TransRec.Options)), FAILURE) ;
          end case ; 

        when MULTIPLE_DRIVER_DETECT =>
          Alert(ModelID, "Multiple Drivers on Transaction Record." & 
                         "  Transaction # " & to_string(TransRec.Rdy), FAILURE) ;

        when others =>
          Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE) ;

      end case ;
    end loop TransactionDispatcherLoop ;
  end process TransactionDispatcher ;


  ------------------------------------------------------------
  -- Uart Clock
  --   Period = TransRec.Baud 
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
    wait for 0 ns ; 
    
    TransmitLoop : loop 
      -- Find Transaction
      if Empty(TransmitFifo) then
        WaitForToggle(TransmitRequestCount) ;
      else 
        wait for 0 ns ; -- allow TransmitRequestCount to settle if both happen at same time.
      end if ;
      
      (TxStim.Data, TxStim.Error) := Pop(TransmitFifo) ;
      
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
