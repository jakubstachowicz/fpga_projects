//-----------------------------------------------------
// Testbench for the 
// 3-bitowy licznik Graya z zadania nr 2
//-----------------------------------------------------
#include "systemc.h"
#include "design.h"
#include <iostream>

int sc_main (int argc, char* argv[]) {
  sc_signal<bool>   clk_i;
  sc_signal<bool>   rst_i;
  sc_signal<sc_uint<3> > led_o;

  // Connect the DUT
  top counter("COUNTER");
  counter.clk_i(clk_i);
  counter.rst_i(rst_i);
  counter.led_o(led_o);
  
  sc_start(1, SC_NS);

  // Open VCD file
  sc_trace_file *wf = sc_create_vcd_trace_file("counter");
  // Dump the desired signals
  sc_trace(wf, clk_i, "clk_i");
  sc_trace(wf, rst_i, "rst_i");
  sc_trace(wf, led_o, "led_o");

  // Initialize all variables
  rst_i = 0;       // initial value of reset
  for (int i=0;i<5;i++) {
      clk_i = 0;
    sc_start(1, SC_NS);
    clk_i = 1;
    sc_start(1, SC_NS);
  }
  rst_i = 1;    // Assert the reset
  cout << "@" << sc_time_stamp() <<" Asserting reset\n" << endl;
  for (int i=0;i<10;i++) {
    clk_i = 0; 
    sc_start(1, SC_NS);
    clk_i = 1;
    sc_start(1, SC_NS);
  }
  rst_i = 0;    // De-assert the reset
  cout << "@" << sc_time_stamp() <<" De-Asserting reset\n" << endl;
  for (int i=0;i<500;i++) {
    clk_i = 0; 
    sc_start(1, SC_NS);
    clk_i = 1;
    sc_start(1, SC_NS);
  }
  cout << "@" << sc_time_stamp() <<" Terminating simulation\n" << endl;
  sc_close_vcd_trace_file(wf);
  return 0;// Terminate simulation
}
