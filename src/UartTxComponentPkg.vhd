--
--  File Name:        UartTx.vhd
--  Block Name:       UartTx
--
--  Author:           Jim Lewis, 503-590-4787
--
--      Copyright (c) 1999 - 2015 by SynthWorks Design Inc.  All rights reserved.
--
--  Creation Date:    2/11/99
--  Last Updated:     1/2015
--
--  Description:
--    UART Transmitter Bus Functional Model 
--
--    
--  Project:      
--        SynthWorks Design Inc.
--        Training Courses
--        Jim Lewis
--        11898 SW 128th Ave.
--        Tigard, Or  97223
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

package UartTxComponentPkg is 

  component UartTx is 
    generic (
      DEFAULT_PARITY_MODE     : integer := UARTTB_PARITY_EVEN ; 
      DEFAULT_NUM_STOP_BITS   : integer := UARTTB_STOP_BITS_1 ; 
      DEFAULT_NUM_DATA_BITS   : integer := UARTTB_DATA_BITS_8 ; 
      DEFAULT_BAUD            : time    := UART_BAUD_PERIOD_115200  
    ) ;
    port (
      TransactionRec      : InOut UartRecType ;
      SerialDataOut       : Out   std_logic := '1' 
    ) ;
  end component UartTx ;
  
end package UartTxComponentPkg ; 
