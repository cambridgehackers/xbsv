// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import GetPut::*;
import BRAM::*;
import FIFO::*;
import Vector::*;
import Gearbox::*;

import PortalMemory::*;
import PortalSMemory::*;


interface ReadChan2BRAM#(type a);
   method Action start(a x);
   method ActionValue#(Bool) finished();
endinterface

module mkReadChan2BRAM#(ReadChan rc, BRAMServer#(a,d) br)(ReadChan2BRAM#(a))
   provisos(Bits#(d,dsz),
	    Div#(64,dsz,nd),
	    Mul#(nd,dsz,64),
	    Eq#(a),
	    Ord#(a),
	    Arith#(a),
	    Bits#(a,b__),
	    Add#(1, c__, nd),
	    Add#(a__, dsz, 64));
   
   Clock clk <- exposeCurrentClock;
   Reset rst <- exposeCurrentReset;
   
   FIFO#(void) f <- mkSizedFIFO(1);
   Gearbox#(nd,1,d) gb <- mkNto1Gearbox(clk,rst,clk,rst); 
   Reg#(a) i <- mkReg(0);
   Reg#(Bool) iv <- mkReg(False);
   Reg#(a) j <- mkReg(0);
   Reg#(Bool) jv <- mkReg(False);
   Reg#(a) n <- mkReg(0);

   rule loadReq(iv);
      rc.readReq.put(?);
      i <= i+fromInteger(valueOf(nd));
      iv <= (i < n);
   endrule
   
   rule loadResp;
      let rv <- rc.readData.get;
      Vector#(nd,d) rvv = unpack(rv);
      gb.enq(rvv);
   endrule
   
   rule load(jv);
      br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:j, datain:gb.first[0]});
      gb.deq;
      jv <= (j < n);
      j <= j+1;
      if (j == n)
	 f.enq(?);
   endrule
   
   rule discard(!jv);
      gb.deq;
   endrule
   
   method Action start(a x);
      iv <= True;
      jv <= True;
      i <= 0;
      j <= 0;
      n <= x;
   endmethod
   
   method ActionValue#(Bool) finished();
      f.deq;
      return True;
   endmethod
   
endmodule