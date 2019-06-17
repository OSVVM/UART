--
--  File Name:            UartRxComponentPkg.vhd
--  Block Name:           UartRxComponentPkg
--
--  Author:               Jim Lewis, 503-590-4787
--
--      Copyright (c) 1999 - 2015 by SynthWorks Design Inc.  All rights reserved.
--
--  Creation Date:        2/1999
--  Last Updated:         1/2015
--
--  Description:
--    UART Receiver Bus Functional Model
--
--  Project:
--                SynthWorks Design Inc.
--                Training Courses
--                Jim Lewis
--                11898 SW 128th Ave.
--                Tigard, Or  97223
--
--  $Id: $
--
--  $Revision: $
--
--  Revision History:
--    $Log: $
--
--  Known Bugs:
--    None
--

library ieee ;
  use ieee.std_logic_1164.all ;

library OSVVM ;
  context OSVVM.OsvvmContext ; 

  use work.UartTbPkg.all ;
  
package UartRxComponentPkg is 

  component UartRx is
    generic (
      DEFAULT_PARITY_MODE     : integer := UARTTB_PARITY_EVEN ; 
      DEFAULT_NUM_STOP_BITS   : integer := UARTTB_STOP_BITS_1 ; 
      DEFAULT_NUM_DATA_BITS   : integer := UARTTB_DATA_BITS_8 ; 
      DEFAULT_BAUD            : time    := UART_BAUD_PERIOD_115200  
    ) ;
    port (
      TransactionRec         : InOut UartRecType ;
      SerialDataIn           : In    std_logic
    ) ;
  end component UartRx ;
  
end package UartRxComponentPkg ; 