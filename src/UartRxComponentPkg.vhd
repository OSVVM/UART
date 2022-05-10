--
--  File Name:         UartRxComponentPkg.vhd
--  Design Unit Name:  UartRxComponentPkg
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Component in package to facilitate usage of component instantiation
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    05/2019   2019.05    Updated for OSVVM public release
--    01/2020   2020.01    Updated license notice
--
--
--  This file is part of OSVVM.
--
--  Copyright (c) 2019 - 2020 by SynthWorks Design Inc.
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

library OSVVM ;
  context OSVVM.OsvvmContext ; 

  use work.UartTbPkg.all ;
  
package UartRxComponentPkg is 

  component UartRx is
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
  end component UartRx ;
  
end package UartRxComponentPkg ; 