package EchoWrapper;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import Adapter::*;
import AxiMasterSlave::*;
import AxiClientServer::*;
import HDMI::*;
import Zynq::*;
import Imageon::*;
import Vector::*;
import SpecialFIFOs::*;
import AxiDMA::*;
import Echo::*;
import CoreEchoIndicationWrapper::*;
import CoreEchoRequestWrapper::*;
import AxiScratchPad::*;
import PCIE::*;


interface EchoWrapper;
    interface Axi3Slave#(32,32,4,SizeOf#(TLPTag)) ctrl;
    interface Vector#(1,ReadOnly#(Bit#(1))) interrupts;



    interface LEDS leds;


endinterface

module mkEchoWrapper(EchoWrapper);
    Reg#(Bit#(TLog#(1))) axiSlaveWS <- mkReg(0);
    Reg#(Bit#(TLog#(1))) axiSlaveRS <- mkReg(0); 
    CoreEchoIndicationWrapper coreIndicationWrapper <- mkCoreEchoIndicationWrapper();

    EchoIndication indication = (interface EchoIndication;
        interface CoreEchoIndication coreIndication = coreIndicationWrapper.indication;
    endinterface);

    EchoRequest echoRequest <- mkEchoRequest( indication);

    CoreEchoRequestWrapper coreRequestWrapper <- mkCoreEchoRequestWrapper(echoRequest.coreRequest,coreIndicationWrapper);
    AxiScratchPad axiScratchPad <- mkAxiScratchPad();

    Vector#(2,Axi3Slave#(32,32,4,SizeOf#(TLPTag))) ctrls_v;
    Vector#(1,ReadOnly#(Bit#(1))) interrupts_v;
    ctrls_v[0] = coreIndicationWrapper.ctrl;
    ctrls_v[1] = axiScratchPad.ctrl;

    interrupts_v[0] = coreIndicationWrapper.interrupt;

    let ctrl_mux <- mkAxiSlaveMux(ctrls_v);



    interface LEDS leds = echoRequest.leds;


    interface ctrl = ctrl_mux;
    interface Vector interrupts = interrupts_v;
endmodule
endpackage: EchoWrapper