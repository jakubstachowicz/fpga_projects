//-----------------------------------------------------
// 3-bitowy licznik Graya z zadania nr 2
//-----------------------------------------------------
#include "systemc.h"

SC_MODULE (top) {
  sc_in_clk     clk_i;
  sc_in<bool>   rst_i;
  sc_out<sc_uint<3> > led_o;

  //------------Local Variables Here---------------------
  sc_uint<3> binary_count;

  //------------Code Starts Here-------------------------
  // Below function implements actual counter logic
  void counter_process() {
      if (rst_i.read() == 1) {
          binary_count = 0;
          led_o.write(0);
      }
      else if (clk_i.event() && clk_i.read() == 1) {
          binary_count = binary_count + 1;

          sc_uint<3> gray_val = binary_count ^ (binary_count >> 1);

          led_o.write(gray_val);

          cout << "@" << sc_time_stamp() << " :: led_o: "
              << led_o.read() << " (binary_count: " << binary_count << ")" << endl;
      }
  }

  // Constructor for the counter
  // Since this counter is a positive edge trigged one,
  // We trigger the below block with respect to positive
  // edge of the clock and also when ever reset changes state
  SC_CTOR(top) {
    cout<<"Executing new"<<endl;
    SC_METHOD(counter_process);
    sensitive << rst_i;
    sensitive << clk_i.pos();
  } // End of Constructor

}; // End of Module 
