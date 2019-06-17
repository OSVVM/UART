--
--  File Name:         ScoreBoardPkg_Loopback.vhd
--  Design Unit Name:  ScoreBoardPkg_Loopback
--  Revision:          STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis          email:  jim@synthworks.com
--
--
--  Description:
--    Instance of Generic Package ScoreboardGenericPkg for UART transfers
--
--  Developed for:
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
--    08/2012   2012.08    Generic Instance of ScoreboardGenericPkg
--    08/2014   2013.08    Updated interface for Match and to_string
--    11/2016   2016.11    Released as part of OSVVM library
--
--
--  Copyright (c) 2006 - 2016 by SynthWorks Design Inc.  All rights reserved.
--
--  Verbatim copies of this source file may be used and
--  distributed without restriction.
--
--  This source file is free software; you can redistribute it
--  and/or modify it under the terms of the ARTISTIC License
--  as published by The Perl Foundation; either version 2.0 of
--  the License, or (at your option) any later version.
--
--  This source is distributed in the hope that it will be
--  useful, but WITHOUT ANY WARRANTY; without even the implied
--  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
--  PURPOSE. See the Artistic License for details.
--
--  You should have received a copy of the license with this source.
--  If not download it from,
--     http://www.perlfoundation.org/artistic_license_2_0
--
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
