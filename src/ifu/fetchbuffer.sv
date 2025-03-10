///////////////////////////////////////////
// fetchbuffer.sv
//
// Written: chickson@hmc.edu ; vkrishna@hmc.edu
// Created: 30 September 2024
// Modified: 3 October 2024
//
// Purpose: Store multiple instructions in a cyclic FIFO
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fetchbuffer import cvw::*; #(parameter cvw_t P, parameter WIDTH = 32) (
    input  logic                      clk,  reset,
    input  logic                      StallFBF, StallD, FlushD,
    input  logic [WIDTH-1:0]          nop,
    input  logic [P.XLEN + WIDTH-1:0] WriteData,
    output logic [P.XLEN + WIDTH-1:0] ReadData,
    output logic                      FetchBufferStallF,
    output logic                      NoStallPCF
);
  logic                             WriteEnable, ReadEnable;
  logic                             Empty, Full, FullDelay, FullRisingEdge;           // Full edge detection 
  logic [P.FETCHBUFFER_ENTRIES-1:0] ReadPtr, WritePtr;                                // One-hot encoded read and write pointers
  logic [P.FETCHBUFFER_ENTRIES-1:0] WriteEnableOH;                                    // One-hot encoded write enable for flop array
  logic [P.XLEN + WIDTH-1:0]        ReadReg            [P.FETCHBUFFER_ENTRIES - 1:0]; // Outputs of FIFO registers
  logic [P.XLEN + WIDTH-1:0]        DaoArr             [P.FETCHBUFFER_ENTRIES - 1:0]; // Array of dist. and-or mux entries
  logic [P.XLEN + WIDTH-1:0]        ReadFetchBuffer;                                  // Output of dist. and-or mux 

  assign Empty  = |(ReadPtr & WritePtr); // Bitwise and the read&write ptr, and or the bits of the result together
  assign Full   = |({WritePtr[P.FETCHBUFFER_ENTRIES-2:0], WritePtr[P.FETCHBUFFER_ENTRIES-1]} & ReadPtr); // Same as above but left rotate WritePtr to "add 1"
  assign FetchBufferStallF = Full;

  // Full signal edge detection
  always_ff @(posedge clk) 
    if (reset) FullDelay <= 0;
    else       FullDelay <= Full;
  assign FullRisingEdge = Full & ~FullDelay;
  assign NoStallPCF = FullRisingEdge & ReadEnable; // ???

  assign ReadEnable    = ~StallD & ~Empty;
  assign WriteEnable   = (~Full | (FullRisingEdge & ReadEnable)) & ~StallFBF ; // "SOME SPECIAL CASE"
  assign WriteEnableOH = {P.FETCHBUFFER_ENTRIES{WriteEnable}} & WritePtr;

  // FIFO entries created with an array of enableable and loadable flip-flops
  // TODO: Maybe change to read on falling clk edge
  flopenl #(P.XLEN + WIDTH) fbEntries[P.FETCHBUFFER_ENTRIES-1:0] (.clk, .load(reset | FlushD), .en(WriteEnableOH), .d(WriteData), .val({{P.XLEN{1'b0}}, nop}), .q(ReadReg));

  // Distributed and-or mux
  for (genvar i = 0; i < P.FETCHBUFFER_ENTRIES; i++) begin
    // & the output of each FIFO entry with the corresponding write pointer bit
    assign DaoArr[i] = ReadPtr[i] ? ReadReg[i] : '0;
  end
  // or the above array entries together to select the entry to read
  or_rows #(P.FETCHBUFFER_ENTRIES, P.XLEN + WIDTH) ReadFBAOMux (.a(DaoArr), .y(ReadFetchBuffer));

  // if empty, read a nop with PC = 0 rather than the FIFO entry
  assign ReadData = Empty ? {{P.XLEN{1'b0}}, nop} : ReadFetchBuffer;

  // Pointer logic
  always_ff @(posedge clk) begin : shiftRegister
    if (reset | FlushD) begin
      WritePtr <= {{P.FETCHBUFFER_ENTRIES - 1{1'b0}}, 1'b1};
      ReadPtr  <= {{P.FETCHBUFFER_ENTRIES - 1{1'b0}}, 1'b1};
    end else begin
      // rotate the pointers unless write or read is disabled (internally or due to a stall)
      WritePtr <= WriteEnable ? {WritePtr[P.FETCHBUFFER_ENTRIES-2:0], WritePtr[P.FETCHBUFFER_ENTRIES-1]} : WritePtr;
      ReadPtr  <= ReadEnable  ? {ReadPtr[P.FETCHBUFFER_ENTRIES-2:0],   ReadPtr[P.FETCHBUFFER_ENTRIES-1]} : ReadPtr;
    end
  end
endmodule
