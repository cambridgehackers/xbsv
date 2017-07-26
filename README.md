Connectal
====


Connectal provides a hardware-software interface for applications split
between user mode code and custom hardware in an FPGA.  Portal can
automatically build the software and hardware glue for a message based
interface and also provides for configuring and using shared memory
between applications and hardware. Communications between hardware and
software are provided by a bidirectional flow of events and regions of
memory shared between hardware and software.  Events from software to
hardware are called requests and events from hardware to software are
called indications, but in fact they are symmetric.

A logical request/indication pair is referred to as a portal".  An
application can make use of multiple portals, which may be specified
independently. A portal is specified by a BSV interface declaration,
from which `connectalgen` generates BSV and C++ wrappers and
proxies.

Connectal has a mailing list:
   https://groups.google.com/forum/#!forum/connectal

The Connectal repo has moved to https://github.com/cambridgehackers/connectal
