import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import FloatingPoint::*;
import FixedPoint::*;
import DefaultValue::*;
import Randomizable::*;
import Vector::*;
import StmtFSM::*;
import Pipe::*;
import FIFO::*;
import FpMac::*;

typedef FixedPoint#(16,16) Fixed;

interface Alu#(type numtype);
   interface Put#(Tuple2#(numtype,numtype)) request;
   interface Get#(Tuple2#(numtype,Exception)) response;
endinterface

typeclass AluClass#(type numtype);
   module mkAdder#(RoundMode rmode)(Alu#(numtype));
   module mkAddPipe#(PipeOut#(Tuple2#(numtype,numtype)) xypipe)(PipeOut#(numtype));
   module mkSubtracter#(RoundMode rmode)(Alu#(numtype));
   module mkSubPipe#(PipeOut#(Tuple2#(numtype,numtype)) xypipe)(PipeOut#(numtype));
   module mkMultiplier#(RoundMode rmode)(Alu#(numtype));
endtypeclass

(* synthesize *)
module mkFloatAdder#(RoundMode rmode)(Alu#(Float));
`ifdef BSIM
   let adder <- mkFPAdder(rmode);
`else
   let adder <- mkXilinxFPAdder(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
	 match { .a, .b } = req;
	 let tpl3 = tuple3(a, b, rmode);
         adder.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- adder.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

module mkFloatAddPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
   let adder <- mkFloatAdder(defaultValue);
   FIFOF#(Float) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      adder.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- adder.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFloatSubtracter#(RoundMode rmode)(Alu#(Float));
`ifdef BSIM
   let adder <- mkFPAdder(rmode);
`else
   let adder <- mkXilinxFPAdder(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
	 match { .a, .b } = req;
	 let tpl3 = tuple3(a, negate(b), rmode);
         adder.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- adder.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

module mkFloatSubPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
   let subtracter <- mkFloatSubtracter(defaultValue);
   FIFOF#(Float) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      subtracter.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- subtracter.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFloatMultiplier#(RoundMode rmode)(Alu#(Float));
`ifdef BSIM
   let multiplier <- mkFPMultiplier(rmode);
`else
   let multiplier <- mkXilinxFPMultiplier(rmode);
`endif
   interface Put request;
      method Action put(Tuple2#(Float,Float) req);
         multiplier.request.put(req);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Float,Exception)) get();
	 let resp <- multiplier.response.get();
	 return resp;
      endmethod
   endinterface
endmodule

instance AluClass#(Float);
   module mkAdder#(RoundMode rmode)(Alu#(Float));
      let adder <- mkFloatAdder(rmode);
      return adder;
   endmodule
   module mkAddPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
      let pipe <- mkFloatAddPipe(xypipe);
      return pipe;
   endmodule
   module mkSubtracter#(RoundMode rmode)(Alu#(Float));
      let sub <- mkFloatSubtracter(rmode);
      return sub;
   endmodule
   module mkMultiplier#(RoundMode rmode)(Alu#(Float));
      let mul <- mkFloatMultiplier(rmode);
      return mul;
   endmodule
   module mkSubPipe#(PipeOut#(Tuple2#(Float,Float)) xypipe)(PipeOut#(Float));
      let pipe <- mkFloatSubPipe(xypipe);
      return pipe;
   endmodule
endinstance

(* synthesize *)
module mkFixedAdder#(RoundMode rmode)(Alu#(Fixed));
   FIFO#(Fixed) fifo <- mkFIFO();
   interface Put request;
      method Action put(Tuple2#(Fixed,Fixed) req);
	 match { .a, .b } = req;
	 fifo.enq(a + b);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Fixed,Exception)) get();
	 let resp <- toGet(fifo).get();
	 return tuple2(resp,defaultValue);
      endmethod
   endinterface
endmodule

module mkFixedAddPipe#(PipeOut#(Tuple2#(Fixed,Fixed)) xypipe)(PipeOut#(Fixed));
   let adder <- mkFixedAdder(defaultValue);
   FIFOF#(Fixed) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      adder.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- adder.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFixedSubtracter#(RoundMode rmode)(Alu#(Fixed));
   FIFO#(Fixed) fifo <- mkFIFO();
   interface Put request;
      method Action put(Tuple2#(Fixed,Fixed) req);
	 match { .a, .b } = req;
	 fifo.enq(a - b);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Fixed,Exception)) get();
	 let resp <- toGet(fifo).get();
	 return tuple2(resp, defaultValue);
      endmethod
   endinterface
endmodule

module mkFixedSubPipe#(PipeOut#(Tuple2#(Fixed,Fixed)) xypipe)(PipeOut#(Fixed));
   let subtracter <- mkFixedSubtracter(defaultValue);
   FIFOF#(Fixed) fifo <- mkFIFOF();
   rule consumexy;
      let xy = xypipe.first();
      xypipe.deq;
      subtracter.request.put(tuple2(tpl_1(xy),tpl_2(xy)));
   endrule
   rule enqout;
      let resp <- subtracter.response.get();
      fifo.enq(tpl_1(resp));
   endrule
   return toPipeOut(fifo);
endmodule

(* synthesize *)
module mkFixedMultiplier#(RoundMode rmode)(Alu#(Fixed));
   FIFO#(Fixed) fifo <- mkFIFO();
   interface Put request;
      method Action put(Tuple2#(Fixed,Fixed) req);
	 match { .a, .b } = req;
	 fifo.enq(a * b);
      endmethod
   endinterface
   interface Get response;
      method ActionValue#(Tuple2#(Fixed,Exception)) get();
	 let resp <- toGet(fifo).get();
	 return tuple2(resp, defaultValue);
      endmethod
   endinterface
endmodule

instance AluClass#(Fixed);
   module mkAdder#(RoundMode rmode)(Alu#(Fixed));
      let adder <- mkFixedAdder(rmode);
      return adder;
   endmodule
   module mkAddPipe#(PipeOut#(Tuple2#(Fixed,Fixed)) xypipe)(PipeOut#(Fixed));
      let pipe <- mkFixedAddPipe(xypipe);
      return pipe;
   endmodule
   module mkSubtracter#(RoundMode rmode)(Alu#(Fixed));
      let sub <- mkFixedSubtracter(rmode);
      return sub;
   endmodule
   module mkMultiplier#(RoundMode rmode)(Alu#(Fixed));
      let mul <- mkFixedMultiplier(rmode);
      return mul;
   endmodule
   module mkSubPipe#(PipeOut#(Tuple2#(Fixed,Fixed)) xypipe)(PipeOut#(Fixed));
      let pipe <- mkFixedSubPipe(xypipe);
      return pipe;
   endmodule
endinstance

(* synthesize *)
module mkRandomPipe(PipeOut#(Float));
   let randomizer <- mkConstrainedRandomizer(0, 1024);

   Reg#(Bool) initted <- mkReg(False);
   rule first if (!initted);
      randomizer.cntrl.init();
      initted <= True;
   endrule

   let pipe_out <- mkPipeOut(interface Get#(Float);
				method ActionValue#(Float) get();
				   let v <- randomizer.next();
				   Float f = fromInt32(v); 
				   return f;
				endmethod
			     endinterface);
   return pipe_out;
endmodule

