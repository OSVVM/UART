--
--  File Name:         UartRx.vhd
--  Design Unit Name:  UartRx
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      UART Receiver Model - 16X Clock based sampling
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
--    02/2022   2022.02    Replaced to_hstring with to_hxstring
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

  use std.textio.all ;

library OSVVM ;
  context OSVVM.OsvvmContext ; 
--  use osvvm.ScoreboardPkg_slv.all ;
--!! GHDL
  use osvvm.ScoreboardPkg_slv.NewID ;
  use osvvm.ScoreboardPkg_slv.Empty ;
  use osvvm.ScoreboardPkg_slv.Push ;
  use osvvm.ScoreboardPkg_slv.Pop ;

library osvvm_common ; 
  context osvvm_common.OsvvmCommonContext ;  

  use work.UartTbPkg.all ;

entity UartRx is
  generic (
    MODEL_ID_NAME           : string := "" ;
    DEFAULT_BAUD            : time    := UART_BAUD_PERIOD_125K ;
    DEFAULT_NUM_DATA_BITS   : integer := UARTTB_DATA_BITS_8 ; 
    DEFAULT_PARITY_MODE     : integer := UARTTB_PARITY_EVEN ; 
    DEFAULT_NUM_STOP_BITS   : integer := UARTTB_STOP_BITS_1  
  ) ;
  port (
    TransRec         : InOut UartRecType ;
    SerialDataIn     : In    std_logic
  ) ;
  -- Use MODEL_ID_NAME Generic if set, otherwise,
  -- use model instance label (preferred if set as entityname_1)
  constant MODEL_INSTANCE_NAME : string :=
    IfElse(MODEL_ID_NAME'length > 0, MODEL_ID_NAME, 
      to_lower(PathTail(UartRx'PATH_NAME))) ;

end UartRx ;
architecture model of UartRx is

  -- Clock Generation
  signal Uart16XClk        : std_logic := '0' ;
  
  -- SerialDataIn preprocessing
  signal iSerialDataIn   : std_logic ;

  -- Sample Bit Signaling
  signal SampleBitCount  : unsigned(3 downto 0) := "0110" ;
  signal SampleBit       : std_logic := '0' ;

  -- Statemachine Type and State Signal declarations
  type RxStateType is (RX_IDLE, RX_HUNT, RX_DATA, RX_PARITY, RX_STOP, RX_BREAK) ;
  signal RxState : RxStateType := RX_IDLE ;

  signal DataBitCount : integer := 0;
  signal LastDataBit : std_logic ;

  signal ModelID  : AlertLogIDType ;

  signal ReceiveFifo : osvvm.ScoreboardPkg_slv.ScoreboardIDType ;

  signal ReceiveCount : integer := 0 ;   
  
  -- Set initial values for configurable modes
  signal ParityMode  : integer := UARTTB_PARITY_EVEN;
  signal NumStopBits : integer := UARTTB_STOP_BITS_1 ;
  signal NumDataBits : integer := UARTTB_DATA_BITS_8 ;
  signal Baud        : time    := UART_BAUD_PERIOD_125K ; -- init for clock start

begin

  ------------------------------------------------------------
  --  Initialize alerts
  ------------------------------------------------------------
  InitializeAlerts : process
    variable ID : AlertLogIDType ;
  begin
    ID            := NewID(MODEL_INSTANCE_NAME) ;
    ModelID       <= ID ; 
    ReceiveFifo   <= NewID("ReceiveFifo", ID, ReportMode => DISABLED, Search => PRIVATE) ;
    wait ;
  end process InitializeAlerts ;
  
  
  ------------------------------------------------------------
  --  Transaction Dispatcher
  --    Dispatches transactions to
  ------------------------------------------------------------
  TransactionDispatcher : process
    alias Operation : StreamOperationType is TransRec.Operation ;
    variable WaitCycles : integer ;
    variable RxStim, ExpectedStim : UartStimType ;
  begin
    wait for 0 ns ; -- Let ModelID get set
    -- Initialize defaults
    ParityMode    <= CheckParityMode (ModelID, DEFAULT_PARITY_MODE,   FALSE) ; 
    NumStopBits   <= CheckNumStopBits(ModelID, DEFAULT_NUM_STOP_BITS, FALSE) ; 
    NumDataBits   <= CheckNumDataBits(ModelID, DEFAULT_NUM_DATA_BITS, FALSE) ; 
    Baud          <= CheckBaud(ModelID, DEFAULT_BAUD, FALSE) ;  

    TransactionDispatcherLoop : loop 
      WaitForTransaction(
         Clk      => Uart16XClk,
         Rdy      => TransRec.Rdy,
         Ack      => TransRec.Ack
      ) ;
      
--**      Operation := TransRec.Operation ;
      
      case Operation is
        when GET | TRY_GET | CHECK | TRY_CHECK =>
          if Empty(ReceiveFifo) and IsTry(Operation) then
            -- Return if no data
            TransRec.BoolFromModel <= FALSE ; 
          else
            -- Get data
            TransRec.BoolFromModel <= TRUE ; 
            if Empty(ReceiveFifo) then 
              -- Wait for data
              WaitForToggle(ReceiveCount) ;
            else 
              -- Settling for when not Empty at current time, but ReceiveCount not updated yet
              -- ReceiveCount used in reporting below.
              wait for 0 ns ; 
            end if ; 
            -- Put Data and Parameters into record
            (RxStim.Data, RxStim.Error) := pop(ReceiveFifo) ;
            TransRec.DataFromModel   <= SafeResize(RxStim.Data,  TransRec.DataFromModel'length) ; 
            TransRec.ParamFromModel  <= SafeResize(RxStim.Error, TransRec.ParamFromModel'length); 
            
            if IsCheck(Operation) then
              ExpectedStim := 
                (Data  => SafeResize(TransRec.DataToModel, ExpectedStim.Data'length), 
                 Error => to_01(SafeResize(TransRec.ParamToModel, ExpectedStim.Error'length))) ;
              if Match(RxStim, ExpectedStim) then
                AffirmPassed(ModelID,
                  "Received: " & to_string(RxStim) & 
                  ".  Operation # " & to_string(ReceiveCount),
                  TransRec.BoolToModel or IsLogEnabled(ModelID, INFO) ) ;
              else
                AffirmError(ModelID,
                  "Received: " & to_string(RxStim) & 
                  ".  Expected: " & to_string(ExpectedStim) & 
                  ".  Operation # " & to_string(ReceiveCount) ) ;
              end if ; 
            else
              Log(ModelID, 
                "Received: " & to_string(RxStim) & 
                ".  Operation # " & to_string(ReceiveCount),
                INFO, Enable => TransRec.BoolToModel
              ) ; 
            end if ;
          end if ; 
          
        when WAIT_FOR_TRANSACTION =>
          if Empty(ReceiveFifo) then 
            WaitForToggle(ReceiveCount) ;
          end if ; 

        when WAIT_FOR_CLOCK =>
          WaitCycles := TransRec.IntToModel ;
          -- Log(ModelID, 
          --   "WaitForClock:  WaitCycles = " & to_string(WaitCycles),
          --   INFO
          -- ) ; 
          wait for (WaitCycles * Baud) - 1 ns ;
          wait until Uart16XClk = '1' ;
          
        when GET_ALERTLOG_ID =>
          TransRec.IntFromModel <= ModelID ;

        when GET_TRANSACTION_COUNT =>
          TransRec.IntFromModel <= ReceiveCount ;

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
  --  Generate 16X Baud Clock
  ------------------------------------------------------------
  Uart16XClkProc : process
  begin
    wait for Baud / 16 ;
    Uart16XClk <= '0', '1' after Baud / 32 ;
  end process ;


  ------------------------------------------------------------
  --  Pre-Process Inputs
  ------------------------------------------------------------
  iSerialDataIn <= to_X01(SerialDataIn) ;


  ------------------------------------------------------------
  -- UART Receiver Statemachine
  --    Note for testbench, no reset needed, initial value = power on reset value
  ------------------------------------------------------------
  UartRxStateProc : process
  begin
    wait until Uart16XClk = '1' ;

    case RxState is
      when RX_IDLE =>
        if iSerialDataIn = '0' then
          RxState <= RX_HUNT ;
        end if ;

      when RX_HUNT =>
        if iSerialDataIn /= '0' then
          RxState <= RX_IDLE ;
        elsif SampleBit = '1' then
          RxState <= RX_DATA ;
        end if ;

      when RX_DATA =>
        if SampleBit = '1' and LastDataBit = '1' then
          if ParityMode = UARTTB_PARITY_NONE then
            RxState <= RX_STOP ; 
          else 
            RxState <= RX_PARITY ; 
          end if ; 
        end if ;

      when RX_PARITY =>
        if SampleBit = '1' then
          RxState <= RX_STOP ;
        end if ;

      when RX_STOP =>
        if SampleBit = '1' then
          if iSerialDataIn = '1' then
            RxState <= RX_IDLE ;
          else
            RxState <= RX_BREAK ;
          end if ;
        end if ;

      when RX_BREAK =>
        if SampleBit = '1' then
          if iSerialDataIn = '1' then
            RxState <= RX_IDLE ;
          else
            RxState <= RX_BREAK ;
          end if ;
        end if ;
    end case ;
  end process ;


  ------------------------------------------------------------
  -- Data Capture Logic
  --    Separate from statemachine for readability
  --    For a one process statemachine, this can be coded with the statemachine
  ------------------------------------------------------------
  UartDataHandler : process
    variable RxData    : std_logic_vector(7 downto 0) ;
    variable RxParity  : std_logic ;
    variable ErrorMode : std_logic_vector(TransRec.ParamFromModel'range) ;
  begin
    wait on Uart16XClk until Uart16XClk = '1' and SampleBit = '1' ;
    case RxState is

      when RX_DATA =>
        RxData(DataBitCount) := iSerialDataIn ;
        DataBitCount <= DataBitCount + 1 ;

      when RX_PARITY =>
        RxParity := iSerialDataIn ;

      when RX_STOP =>
        ErrorMode(UARTTB_PARITY_INDEX) := CalcParity(RxData, ParityMode) ?/= RxParity ;
        ErrorMode(UARTTB_STOP_INDEX)   := not to_01(iSerialDataIn) ;
        ErrorMode(UARTTB_BREAK_INDEX)  := not (iSerialDataIn or RxParity or (or RxData)) ;
        if ErrorMode(UARTTB_BREAK_INDEX) = '1' then 
          Log(ModelID, "UartRx  Break Detected", INFO) ;
        end if ; 
        
        -- Hand off values to Transaction Handler
        push(ReceiveFifo, RxData & ErrorMode) ;
        increment(ReceiveCount) ;
        
        -- Log at interface at DEBUG level
        Log(ModelID, 
          "Received:" & 
          " Data = " & to_hxstring(RxData) & 
          ", Parity = " & to_string(RxParity) & 
          ", Stop = " & to_string(iSerialDataIn) & 
          ", Parity Error = " & to_string(ErrorMode(UARTTB_PARITY_INDEX)) & 
          ", Stop Error = " & to_string(ErrorMode(UARTTB_STOP_INDEX)) & 
          ", Break Error = " & to_string(ErrorMode(UARTTB_BREAK_INDEX)) & 
          ",  Operation # " & to_string(ReceiveCount),
          DEBUG
        ) ;
        
      when others =>
        DataBitCount <= 0 ;
        RxData       := (others => '0') ;   -- %% Tb2 Lab 10.1.5
        RxParity := '-'  ; -- No Parity
        ErrorMode := (others => '0') ;

    end case ;
  end process UartDataHandler ;

  LastDataBit <= '1' when DataBitCount = (NumDataBits - 1) else '0' ;


  ------------------------------------------------------------
  -- Sample Bit Signaling
  ------------------------------------------------------------
  SampleBitCntProc : process
  begin
    wait until Uart16XClk = '1' ;
    if RxState = RX_IDLE then
      SampleBitCount <= "0110" ;

    else
      SampleBitCount <= SampleBitCount - 1 ;

    end if ;
  end process ;

  SampleBit <= '1' when SampleBitCount = 0 else '0' ;


end model ;



