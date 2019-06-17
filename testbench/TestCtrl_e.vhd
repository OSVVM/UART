--
--  File Name:          TestCtrl_e.vhd
--  Block Name:         TestCtrl 
--
--  Author:             Jim Lewis, 503-590-4787
--
--  Creation Date:      11/99
--  Last Updated:       11/01
--
--  Description:
--    Test Control
--    Generates stimulus values and synchronization for 
--    Bus Functional models which handle the stimulus in an
--    interface dependent manner.
--
--  Project:      
--        SynthWorks Design Inc.
--        Training Courses
--        11898 SW 128th Ave.
--        Tigard, Or  97223
--        http://www.SynthWorks.com
--        email:  jim@SynthWorks.com
--
--  Copyright (c) 1999, 2001 by SynthWorks Design Inc.  All rights reserved.
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
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use std.textio.all ;
  
library OSVVM ; 
  context OSVVM.OsvvmContext ; 

library osvvm_uart ; 
  context osvvm_uart.UartContext ; 

entity TestCtrl is
  generic (
    tperiod_Clk           : time := 10 ns 
  ) ; 
  port (
    -- Record Interface
    UartTxRec           : InOut UartRecType ;
    UartRxRec           : InOut UartRecType ;

    -- Global Signal Interface
    Clk                 : In    std_logic ;
    nReset              : In    std_logic 
  ) ;
end TestCtrl ;
