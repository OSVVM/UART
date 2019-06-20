--
--  File Name:         ScoreBoardPkg_Uart.vhd
--  Design Unit Name:  ScoreBoardPkg_Uart
--  OSVVM Release:     OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Instance of Generic Package ScoreboardGenericPkg for OSVVM UART 
--
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date       Version    Description
--    08/2012    2012.08    Generic Instance of ScoreboardGenericPkg
--    08/2014    2013.08    Updated interface for Match and to_string
--    2019.05    2019.05    Initial public release
--
--      Copyright (c) 2006 - 2019 by SynthWorks Design Inc.  All rights reserved.
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

use work.UartTbPkg.all ; 

library OSVVM ;

package ScoreBoardPkg_Uart is new OSVVM.ScoreboardGenericPkg
  generic map (
    ExpectedType        => UartStimType,  
    ActualType          => UartStimType,  
    Match               => Match,  
    expected_to_string  => to_string, 
    actual_to_string    => to_string  
  ) ;  
