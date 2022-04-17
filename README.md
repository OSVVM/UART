# UART Verification Component Library 
The UART Verification Component Library 
contains UART Transmitter and Receiver 
verification components. 
Both of these verification components simplify 
injecting and checking for
parity, stop, and break errors.  

## Testbenches are Included 

Testbenches are in the Git repository, so you can 
run a simulation and see a live example 
of how to use the models.

## UART Project Structure
   * UART
      * src
      * testbench
         
## Release History
For the release history see, [CHANGELOG.md](CHANGELOG.md)

## Learning OSVVM
You can find an overview of OSVVM at [osvvm.github.io](https://osvvm.github.io).
Alternately you can find our pdf documentation at 
[OSVVM Documentation Repository](https://github.com/OSVVM/Documentation#readme).

You can also learn OSVVM by taking the class, [Advanced VHDL Verification and Testbenches - OSVVM&trade; BootCamp](https://synthworks.com/vhdl_testbench_verification.htm)

## Download OSVVM Libraries
OSVVM is available as either a git repository 
[OsvvmLibraries](https://github.com/osvvm/OsvvmLibraries) 
or zip file from [osvvm.org Downloads Page](https://osvvm.org/downloads).

On GitHub, all OSVVM libraries are a submodule of the repository OsvvmLibraries. Download all OSVVM libraries using git clone with the “–recursive” flag: 
```    
  $ git clone --recursive https://github.com/osvvm/OsvvmLibraries
```

## Run The Demos
A great way to get oriented with OSVVM is to run the demos.
For directions on running the demos, see [OSVVM Scripts](https://github.com/osvvm/OSVVM-Scripts#readme).

## Participating and Project Organization 
The OSVVM project welcomes your participation with either 
issue reports or pull requests.

You can find the project [Authors here](AUTHORS.md) and
[Contributors here](CONTRIBUTORS.md).

### UART/src
UART verification components.
Uses OSVVM Model Independent Transactions for Streaming,
See OSVVM-Common repository, file Common/src/StreamTransactionPkg.vhd

   * UartTbPkg.vhd
      * Constants and subprograms that support the UART and UART scoreboards.
   * ScoreboardPkg_Uart.vhd
      * ScoreboardGeneric instance to support the UART.
   * UartTxComponentPkg.vhd
      * Package containing a component declaration for UART Transmitter verification component. 
   * UartRxComponentPkg.vhd
      * Package containing a component declaration for UART Receiver verification component. 
   * UartContext.vhd
      * References all packages required to use the UART verification components
   * UartTx.vhd
      * UART Transmitter verification component. 
   * UartRx.vhd
      * UART Receiver verification component. 

For current compile order see UART/UART.pro.

### UART/testbench
   * TbUart.vhd
      * Test harness for UART testbench
   * TestCtrl_e.vhd
      * Entity for TestCtrl - the test sequencer
   * TbUart_SendGet1.vhd
      * Test architecture SendGet1 and configuration TbUart_SendGet1
   * TbUart_SendGet2.vhd
      * Test architecture SendGet2 and configuration TbUart_SendGet2
   * TbUart_Options1.vhd
      * Test architecture Options1 and configuration TbUart_Options1
   * TbUart_Options2.vhd
      * Test architecture Options2 and configuration TbUart_Options2
   * TbUart_Checkers1.vhd
      * Test architecture Checkers1 and configuration TbUart_Checkers1
   * TbUart_Checkers2.vhd
      * Test architecture Checkers2 and configuration TbUart_Checkers2
   * TbUart_Scoreboard1.vhd
      * Test architecture Scoreboard1 and configuration TbUart_Scoreboard1
   * TbUart_Overload1.vhd
      * Test architecture Overload1 and configuration TbUart_Overload1

For current compile order see UART/testbench/testbench.pro.

## More Information on OSVVM

**OSVVM Forums and Blog:**     [http://www.osvvm.org/](http://www.osvvm.org/)   
**Gitter:** [https://gitter.im/OSVVM/Lobby](https://gitter.im/OSVVM/Lobby)  
**Documentation:** [osvvm.github.io](https://osvvm.github.io)    
**Documentation:** [PDF Documentation](https://github.com/OSVVM/Documentation)  

## Copyright and License
Copyright (C) 2006-2022 by [SynthWorks Design Inc.](http://www.synthworks.com/)  
Copyright (C) 2022 by [OSVVM Authors](AUTHORS.md)   

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
