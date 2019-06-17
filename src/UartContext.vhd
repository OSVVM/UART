--
--  File Name:         UartContext.vhd
--  Design Unit Name:  UartContext
--  Revision:          STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--
--  Description
--      Context Declaration for OSVVM packages
--
--  Developed by/for:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        11898 SW 128th Ave.  Tigard, Or  97223
--        http://www.SynthWorks.com
--
--  Latest standard version available at:
--        http://www.SynthWorks.com/downloads
--
--  Revision History:      
--    Date      Version    Description
--    01/2019   2019.01    Initial Revision
--
--
--  Copyright (c) 2017-2019 by SynthWorks Design Inc.  All rights reserved.
--
--  Verbatim copies of this source file may be used and
--  distributed without restriction.
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--  
--      http://www.apache.org/licenses/LICENSE-2.0
--  
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

context UartContext is
    library osvvm_vip ; 
      context osvvm_vip.OsvvmVipContext ;  

    library osvvm_uart ;  
    use osvvm_uart.UartTbPkg.all ; 
    use osvvm_uart.UartTxComponentPkg.all ; 
    use osvvm_uart.UartRxComponentPkg.all ; 
    use osvvm_uart.ScoreboardPkg_Uart.all ;
end context UartContext ; 

