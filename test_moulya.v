// Code your testbench here
// or browse Examples
module tb_act_low_decoder;
  logic A,B,en; 
  logic [3:0] Z, Z1,Z2;
  
  //act_low_decoder_gates dut1(.Z(Z), .A(A), .B(B), .en(en));
  //act_low_decoder_ternary dut2(.Z (Z1), .A(A), .B(B), .en(en)); 
  //act_low_decoder_casez dut3(.Z (Z2), .A(A), .B(B), .en(en));
  
initial begin
    $display("Testing 2:4 Active Low Decoder cicuit");
  
  for (int i=0; i<8; i=i+1) begin
      {en,A,B} = i;
   // $display("en=%0b, A=%0b, B=%0b, Z=%4b", en,A,B,Z);
   //$display("en=%0b, A=%0b, B=%0b, Z1=%4b", en,A,B,Z1);
   // $display("en=%0b, A=%0b, B=%0b, Z2=%4b at %0t", en,A,B,Z2, $time);
    
    $display("en=%b  a=%b b=%b %b=Z %b=Z1 %b=Z2", en, A, B, Z, Z1, Z2);
    
    //output comparison
    
    
          #5;

     end
end

  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #100; $finish;
  end
endmodule
