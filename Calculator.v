timescale 1ns / 1ps
module project(
    input clock_100Mhz, // 100 Mhz clock source on Basys 3 FPGA
    input reset, // reset
    input [4:0] arithmetic,
    input sel1, sel2, sel3, sel4,
    output reg [3:0] Anode_Activate,
    output reg [7:0] LED_out
    );
    reg [26:0] one_tick_counter;
    reg [15:0] temp1;
    reg [15:0] temp2;
    reg [15:0] temp3;
    reg [15:0] tempwhole;
    reg negative;
    reg [15:0] displayed_number;
    reg [4:0] LED_BCD;
    reg [19:0] refresh_counter;
    wire [1:0] LED_activating_counter; 
                 
    always @(posedge clock_100Mhz or posedge reset)
    begin
        if(reset==1)
            one_tick_counter <= 0;
        else begin
            if(sel1 == 0 && sel2 == 0 && sel3 == 0 && sel4 == 0 && arithmetic[1] == 0 && arithmetic[2] == 0 && arithmetic[3] == 0 && arithmetic[4] == 0) 
                 one_tick_counter <= 0;
            else if(one_tick_counter < 10)
                 one_tick_counter <= one_tick_counter + 1;
        end
    end 
    assign one_digit = (one_tick_counter==1 && sel1==1)?1:0;
    assign two_digit = (one_tick_counter==1 && sel2==1)?1:0;
    assign three_digit = (one_tick_counter==1 && sel3==1)?1:0;
    assign four_digit = (one_tick_counter==1 && sel4==1)?1:0;
    assign add = (one_tick_counter==1 && arithmetic[4]==1)?1:0;
    assign sub = (one_tick_counter==1 && arithmetic[3]==1)?1:0;
    assign multiply = (one_tick_counter==1 && arithmetic[2]==1)?1:0;
    assign div = (one_tick_counter==1 && arithmetic[1]==1)?1:0;
    always @(posedge clock_100Mhz or posedge reset)
    begin
        if(one_tick_counter == 1)
            negative = 1'b0;
        if(reset==1)
            begin
            negative <= 1'b0;
            displayed_number <= 0;
            temp1 <= 0;
            end
        else if(one_digit==1)
            begin
             if(displayed_number%10<9) begin
             displayed_number <= displayed_number + 1;
             tempwhole <= displayed_number + 1;
             end
             else begin
             displayed_number <= displayed_number -9;
                          tempwhole <= displayed_number -9;
                          end
             end
        else if(two_digit==1) 
             begin
                     if(displayed_number%100<90) begin
                     displayed_number <= displayed_number + 10;
                     tempwhole <= displayed_number + 10;
                     end
                     else begin
                     displayed_number <= displayed_number -90;
                                  tempwhole <= displayed_number -90;
                                  end
                     end
        else if(three_digit==1) 
             begin
                     if(displayed_number%1000<900) begin
                     displayed_number <= displayed_number + 100;
                     tempwhole <= displayed_number + 100;
                     end
                     else begin
                     displayed_number <= displayed_number -900;
                                  tempwhole <= displayed_number -900;
                                  end
                     end
        else if(four_digit==1) 
             begin
                     if(displayed_number<9000) begin
                     displayed_number <= displayed_number + 1000;
                     tempwhole <= displayed_number + 1000;
                     end
                     else begin
                     displayed_number <= displayed_number -9000;
                                  tempwhole <= displayed_number -9000;
                                  end
                     end
        else if(add == 1)
            begin
             temp1 = (displayed_number/100);
             temp2 = (displayed_number%100);
             displayed_number = (temp1 + temp2)%10000;
            end
        else if(sub == 1)
             begin
              temp1 = (displayed_number/100);
              temp2 = (displayed_number%100);
              if(temp1 != 0 || temp2 != 0)
                if(temp1 >= temp2)
                    displayed_number = (temp1 - temp2)%10000;
                else if(temp2 > temp1)
                    begin
                    displayed_number = (temp2 - temp1)%10000;
                    negative = 1'b1;
                    end
             end
        else if(multiply == 1)
             begin
              temp1 = (displayed_number/100);
              temp2 = (displayed_number%100);
              if(temp1 != 0 || temp2 != 0)
                displayed_number = (temp1*temp2)%10000;
             end
        else if(div == 1)
             begin
              temp1 = (displayed_number/100)*10;
              temp2 = (displayed_number%100);
              if(temp1 != 0 || temp2 != 0) begin
                displayed_number = (temp1 / temp2)%10000;
                if((displayed_number%10)<5)
                    displayed_number = displayed_number/10;
                else
                    displayed_number = (displayed_number+10)/10;
                end
             end
        else if(arithmetic[0] == 1) begin
             displayed_number = tempwhole;
             negative = 1'b0;
             end
    end
    always @(posedge clock_100Mhz or posedge reset)
    begin 
        if(reset==1)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end 
    assign LED_activating_counter = refresh_counter[19:18];
    always @(*)
    begin
        case(LED_activating_counter)
        2'b00: begin
            Anode_Activate = 4'b0111; 
            LED_BCD = displayed_number/1000;
              end
        2'b01: begin
            Anode_Activate = 4'b1011; 
            if(negative == 1'b1)
                LED_BCD = 5'b11111;
            else if(negative == 1'b0 && arithmetic[4] == 0 && arithmetic[3] == 0 && arithmetic[2] == 0 && arithmetic[1] == 0)
                LED_BCD = (displayed_number % 1000)/100 + 10000;
            else
                LED_BCD = (displayed_number % 1000)/100;
              end
        2'b10: begin
            Anode_Activate = 4'b1101; 
            LED_BCD = ((displayed_number % 1000)%100)/10;
                end
        2'b11: begin
            Anode_Activate = 4'b1110; 
            LED_BCD = ((displayed_number % 1000)%100)%10;
    
               end
        endcase
       

    end
    always @(*)

    begin
        case(LED_BCD)
        5'b00000: LED_out = 8'b00000011; // "0"     
        5'b00001: LED_out = 8'b10011111; // "1" 
        5'b00010: LED_out = 8'b00100101; // "2" 
        5'b00011: LED_out = 8'b00001101; // "3" 
        5'b00100: LED_out = 8'b10011001; // "4" 
        5'b00101: LED_out = 8'b01001001; // "5" 
        5'b00110: LED_out = 8'b01000001; // "6" 
        5'b00111: LED_out = 8'b00011111; // "7" 
        5'b01000: LED_out = 8'b00000001; // "8"     
        5'b01001: LED_out = 8'b00001001; // "9" 
        5'b10000: LED_out = 8'b00000010; // "0."     
                5'b10001: LED_out = 8'b10011110; // "1." 
                5'b10010: LED_out = 8'b00100100; // "2." 
                5'b10011: LED_out = 8'b00001100; // "3." 
                5'b10100: LED_out = 8'b10011000; // "4." 
                5'b10101: LED_out = 8'b01001000; // "5." 
                5'b10110: LED_out = 8'b01000000; // "6." 
                5'b10111: LED_out = 8'b00011110; // "7." 
                5'b11000: LED_out = 8'b00000000; // "8."     
                5'b11001: LED_out = 8'b00001000; // "9." 
        5'b11111: LED_out = 8'b11111101; // "-"
        default: LED_out = 8'b00000011; // "0"
        endcase
    end
 endmodule



//TESTBENCH
// Code your testbench here
// or browse Examples
module project_sim();
  reg reset;
  reg [4:0] arithmetic;
  reg sel1, sel2, sel3, sel4;
  wire [15:0] displayed_number;
  reg clock_100Mhz;
  reg [26:0] one_tick_counter;
  reg [15:0] temp1;
  reg [15:0] temp2;
  reg [15:0] temp3;
  reg [15:0] tempwhole;
  reg negative;
  reg one_digit;
  reg [3:0] i;
  
  project uut(.reset(reset), .arithmetic(arithmetic), .sel1(sel1), .sel2(sel2), .sel3(sel3), .sel4(sel4), .displayed_number(displayed_number), .clock_100Mhz(clock_100Mhz), .one_tick_counter(one_tick_counter), .temp1(temp1), .temp2(temp2), .temp3(temp3), .tempwhole(tempwhole), .negative(negative), .one_digit(one_digit));

  initial begin
  	$dumpfile("dump.vcd");
    $dumpvars(1);
  end
  
  initial begin
    reset = 0;
    arithmetic[2] = 0;
    arithmetic[4] = 0;
    sel1 = 0;
    sel2 = 0;
    sel3 = 0;
    sel4 = 0;
    #1000;
    reset = 1;
    #1000;
    reset = 0;
    #1000;
    clock_100Mhz = 0;
    #1000;
    clock_100Mhz = 1;
    #1000
    for(i = 0; i < 9; i++) begin
    	sel1 = 1;
      	#5;
      	sel1 = 0;
      	#5;
    end
    for(i = 0; i < 9; i++) begin
    	sel2 = 1;
      	#5;
      	sel2 = 0;
      	#5;
    end
    for(i = 0; i < 9; i++) begin
    	sel3 = 1;
      	#5;
      	sel3 = 0;
      	#5;
    end
    for(i = 0; i < 9; i++) begin
    	sel4 = 1;
      	#5;
      	sel4 = 0;
      	#5;
    end
    for(i = 1; i < 5; i++) begin
      arithmetic[i] = 1;
      #5;
      arithmetic[i] = 0;
      #10;
      arithmetic[0] = 1; //Return original numbers
      #5;
      arithmetic[0] = 0;
      #10;
    end
    #100;
    for(i = 0; i < 9; i++) begin
    	sel1 = 1;
      	#5;
      	sel1 = 0;
      	#5;
    end
    #10;
    arithmetic[3] = 1;
    #5;
    arithmetic[3] = 0;
    #10;
    arithmetic[0] = 1;
    #5;
    arithmetic[0] = 0;
    #10;
    arithmetic[1] = 1;
    #5;
    arithmetic[1] = 0;
    #10;
    arithmetic[0] = 1;
    #5;
    arithmetic[0] = 0;
    #100;
    for(i = 0; i < 3; i++) begin
    	sel3 = 1;
      	#5;
      	sel3 = 0;
      	#5;
    end
    for(i = 0; i < 4; i++) begin
    	sel4 = 1;
      	#5;
      	sel4 = 0;
      	#5;
    end
    #10;
    arithmetic[3] = 1;
    #5;
    arithmetic[3] = 0;
    #10;
    arithmetic[0] = 1;
    #5;
    arithmetic[0] = 0;
    #10;
    arithmetic[2] = 1;
    #5;
    arithmetic[2] = 0;
    #10;
    arithmetic[0] = 1;
    #5;
    arithmetic[0] = 0;
    #10;
    arithmetic[1] = 1;
    #5;
    arithmetic[1] = 0;
    #10;
    arithmetic[0] = 1;
    #5;
    arithmetic[0] = 0;
    for(i = 0; i < 2; i++) begin
    	sel2 = 1;
      	#5;
      	sel2 = 0;
      	#5;
    end
    for(i = 0; i < 2; i++) begin
    	sel1 = 1;
      	#5;
      	sel1 = 0;
      	#5;
    end
    #100;
    arithmetic[1] = 1;
    #5;
    arithmetic[1] = 0;
  end
  endmodule



