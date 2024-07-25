# UART Verification Component Change Log

| Revision  |  Release Summary | 
------------|----------- 
| 2024.07   |  Updated Tb for CreateClock relocation.  Minor updates to work around tool issues.
| 2022.11   |  Updated DEMO testbench for using multiple VC
| 2022.10   |  Added DEMO testbench for using multiple VC
|           |  Changed PRIVATE to PRIVATE_NAME
| 2022.05   |  Updated FIFOs so they are Search => PRIVATE. Added MODEL_ID_NAME generic
| 2022.03   |  Updated to use singleton based FIFOs.  Updated calls for AlertLogIDs. 
| 2022.02   |  Replaced to_hstring with to_hxstring in UartRx and UartTbPkg 
| 2021.09   |  Updated testbenches to create YAML reports 
| 2021.02   |  Updated resizing of values to/from Stream MIT 
| 2020.10   |  Updated for updates to Stream MIT 
| 2020.07   |  Updated to use Stream MIT
| 2020.01   |  Updated to Apache Licenses
| 2019.05   |  Updated for OSVVM public release
| 1999.01   |  Developed as part of SynthWorks' Advanced VHDL Testbenches and Verification Class

## 2024.07
- Updated Tb for CreateClock relocation.  
- Minor updates to UartTx and UartRx for Xcelium. 
- Added deprecated/ScoreboardPkg_Uart for Xcelium.
- Removed UartRecArrayType - All uses were replaced by StreamRecArrayType.
- UartRx: replaced individual references of use osvvm.ScoreboardPkg_slv.NewID with use osvvm.ScoreboardPkg_slv.all for VCS

## 2022.11 November 2022
- Updated UART/testbench_multiple_uarts testbench for using multiple OSVVM VC using for Generate
- Added usage of new StreamRecArrayType and StreamTransactionArrayPkg
- Added new examples:  SingleProcess1, SingleProcessLoop_1, SingleProcessLoop_2, and MultipleProcess_1    
- Added GHDL_Debug directory to support GHDL 

## 2022.10 October 2022
- Added UART/testbench_multiple_uarts testbench for using multiple OSVVM VC using for Generate
- Changed PRIVATE to PRIVATE_NAME

## 2022.05 May 2022
- Updated FIFOs so they are Search => PRIVATE.  Was only problematic in generate loops.
- Added MODEL_ID_NAME generic

## 2022.02  February 2022
Replaced to_hstring with to_hxstring in UartRx and UartTbPkg.

## 2021.09  September 2021
Updated testbenches to create YAML reports.

## 2021.02  February 2021
Minor updates to resize values to/from the Stream Model Independent Transactions.

## 2020.10 October 2020
Minor updates for updates to Stream Model Independent Transactions.
Resulted in port name changes - was going to use alias, but did not work in some tools

## 2020.07 July 2020
Major release.  Now uses StreamTransactionPkg.

 
## Copyright and License
Copyright (C) 1999-2020 by [SynthWorks Design Inc.](http://www.synthworks.com/)   
Copyright (C) 2020 by [OSVVM contributors](CONTRIBUTOR.md)   

This file is part of OSVVM.

    Licensed under Apache License, Version 2.0 (the "License")
    You may not use this file except in compliance with the License.
    You may obtain a copy of the License at

  [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
