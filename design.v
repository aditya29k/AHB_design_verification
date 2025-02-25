`define NON_SEQ 2'd0
`define SEQ 2'd1
`define BUSY 2'd2
`define IDLE 2'd3
 
`define OKAY 2'b00
`define ERROR 2'b01
`define RETRY 2'b10
`define SPLIT 2'b11


module ahb_slv (
    input hclk,
    input hrst,
    input [31:0] haddr,
    input [31:0] hdata,
    input [2:0] hsize,
    input [2:0] hburst,
    input hsel, hwrite,
    input [1:0] htrans,
    output reg [1:0] hresp,
    output reg hready,
    output reg [31:0] hrdata
);

  reg [7:0] mem [256];
  
  //SINGLE TRANSACTION WRITE

  function bit [31:0] single_transaction( input bit [31:0] addr, input bit [2:0] hsize );

    case(hsize)

      3'b000: begin

        mem[addr] = hwdata[7:0];

      end

      3'b001: begin

        mem[addr] = hwdata[7:0];
        mem[addr+1] = hwdata[15:8];

      end

      3'b010: begin

        mem[addr] = hwdata[7:0];
        mem[addr+1] = hwdata[15:8];
        mem[addr+2] = hwdata[23:16];
        mem[addr+3] = hwdata[31:24];

      end

    endcase

    return addr;

  endfunction

  //INCREMENT UNSPECIFIED WRITE

  function bit [31:0] incr_transaction( input bit [31:0] addr, input bit [2:0] hsize );

    bit [31:0] raddr;

    case(hsize)

      3'b000: begin

        mem[addr] = hwdata[7:0];
        raddr = addr + 1;

      end

      3'b001: begin

        mem[addr] = hwdata[7:0];
        mem[addr+1] = hwdata[15:8];
        raddr = addr + 2;

      end

      3'b010: begin

        mem[addr] = hwdata[7:0];
        mem[addr+1] = hwdata[15:8];
        mem[addr+2] = hwdata[23:16];
        mem[addr+3] = hwdata[31:24];
        raddr = addr + 4;

      end

    endcase

    return raddr;

  endfunction

  // BOUNDARY CONDITION

  function bit [7:0] boundary( input bit [2:0] hburst, input bit [2:0] hsize );

    bit [7:0] temp;

    case(hsize)

      3'b000: begin

        case(hburst)

          3'b010: temp = 4*1;

          3'b100: temp = 8*1;

          3'b110: temp = 16*1;

        endcase

      end

      3'b001: begin

        case(hburst)

          3'b010: temp = 4*2;

          3'b100: temp = 8*2;

          3'b110: temp = 16*2;

        endcase

      end

      3'b010: begin

        case(hburst)

          3'b010: temp = 4*4;

          3'b100: temp = 8*4;

          3'b110: temp = 16*4;

        endcase

      end

    endcase

    return temp;

  endfunction

  // WRAP CONDITION WRITE

  function bit [31:0] wrap_wr ( input bit [31:0] addr, input bit [2:0] hsize, input bit [7:0] boundary );

    bit [31:0] addr1, addr2, addr3, addr4;

    case(hsize)

      3'b000: begin

        mem[addr] = hdata[7:0];

        if( (addr+1)%boundary == 0 ) begin

          addr1 = (addr + 1) - boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        return addr1;

      end

      3'b001: begin

        mem[addr] = hdata[7:0];

        if( (addr+1)%boundary == 0 ) begin

          addr1 = (addr + 1) - boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        mem[addr1] = hdata[15:8];

        if( (addr1+1)%boundary == 0 ) begin

          addr2 = ( addr1 + 1 )- boundary;

        end
        else begin

          addr2 = addr1 + 1;

        end

        return addr2;

      end

      3'b010: begin // working on this specifically 4byte data

        mem[addr] = hdata[7:0];

        if( (addr+1)%boundary == 0 ) begin

          addr1 = (addr + 1) - boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        mem[addr1] = hdata[15:8];

        if( (addr1+1)%boundary == 0 ) begin

          addr2 = ( addr1 + 1 )- boundary;

        end

        else begin

          addr2 = addr1 + 1;

        end

        mem[addr2] = temp[23:16];

        if( (addr2+1)%boundary == 0 ) begin

          addr3 = (addr2 + 1) - boundary;

        end

        else begin

          addr3 = addr2 + 1;

        end

        mem[addr3] = temp[31:24];

        if( (addr3+1)%boundary == 0 ) begin

          addr4 = (addr3 + 1) - boundary;

        end

        else begin

          addr4 = addr3 + 1;

        end

        return addr4;

      end

    endcase

  endfunction

  // INCR CONDITION WRITE

  function bit [31:0] incr_wr( input bit [31:0] addr, input bit [2:0] hsize );

    bit [31:0] raddr;

    case(hsize)

      3'b000: begin

        mem[addr] = hdata[7:0];
        raddr = addr + 1;

      end

      3'b001: begin

        mem[addr] = hdata[7:0];
        mem[addr+1] = hdata[15:8];
        raddr = addr + 2;

      end

      3'b010: begin

        mem[addr] = hdata[7:0];
        mem[addr+1] = hdata[15:8];
        mem[addr+2] = hdata[23:16];
        mem[addr+3] = hdata[31:24];
        raddr = addr+4;

      end

    endcase

  endfunction

  // SINGLE TRANSACTION READ

  function bit [31:0] single_transaction_rd ( input bit [31:0] addr, input bit [2:0] hsize );

    case(hsize)

      3'b000: begin

        hrdata[7:0] = mem[addr];

      end

      3'b001: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr+1];

      end

      3'b010: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr+1];
        hrdata[23:16] = mem[addr+2];
        hrdata[31:24] = mem[addr+3];

      end

    endcase

    return addr;

  endfunction

  // INCREMENT TRANSACTION UNSPECIFIED READ

  function bit [31:0] increment_transaction_rd ( input bit [31:0] addr, input bit [2:0] hsize );

    bit [31:0] raddr;

    case(hsize)

      3'b000: begin

        hrdata[7:0] = mem[addr];
        raddr = addr + 1;

      end

      3'b001: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr + 1];
        raddr = addr + 2;

      end

      3'b010: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr+1];
        hrdata[23:16] = mem[addr+2];
        hrdata[31:24] = mem[addr+3];
        raddr = addr + 4;

      end

    endcase

    return raddr;

  endfunction

  // WRAP READ

  function bit [31:0] wrap_rd ( input bit [31:0] addr, input bit [7:0] boundary, input bit [2:0] hsize );

    bit [31:0] addr1, addr2, addr3, addr4;

    case(hsize)

      3'b000: begin

        hrdata[7:0] = mem[addr];

        if((addr+1)%boundary == 0) begin

          addr1 = (addr+1)-boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        return addr1;

      end

      3'b001: begin

        hrdata[7:0] = mem[addr];

        if((addr+1)%boundary == 0) begin

          addr1 = (addr+1) - boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        hrdata[15:8] = mem[addr1];

        if((addr1+1)%boundary == 0) begin

          addr2 = (addr1 + 1) - boundary;

        end

        else begin

          addr2 = addr1 + 1;

        end

        return addr2;

      end

      3'b010: begin

        hrdata[7:0] = mem[addr];

        if((addr+1)%boundary == 0) begin

          addr1 = (addr +1 ) - boundary;

        end

        else begin

          addr1 = addr + 1;

        end

        hrdata[15:8] = mem[addr1];

        if((addr1+1)%boundary == 0) begin

          addr2 = (addr1 + 1) - boundary;

        end

        else begin

          addr2 = addr1 + 1;

        end

        hrdata[23:16] = mem[addr2];

        if((addr2+1)%boundary == 0) begin

          addr3 = (addr2 + 1) - boundary;

        end

        else begin

          addr3 = addr2 + 1;

        end

        hrdata[31:24] = mem[addr3];

        if((addr3+1)%boundary == 0) begin

          addr4 = (addr3+1) - boundary;

        end

        else begin

          addr4 = addr3+1;

        end

        return addr4;

      end

    endcase

  endfunction

  // INCREMENT READ

  function bit [31:0] increment_transaction_rd ( input bit [31:0] addr, input bit [2:0] hsize );

    bit [31:0] raddr;

    case(hsize)

      3'b000: begin

        hrdata[7:0] = mem[addr];
        raddr = addr + 1;

      end

      3'b001: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr+1];
        raddr = addr + 2;

      end

      3'b010: begin

        hrdata[7:0] = mem[addr];
        hrdata[15:8] = mem[addr + 1];
        hrdata[23:16] = mem[addr + 2];
        hrdata[31:24] = mem[addr + 3];
        raddr = addr + 4;

      end

    endcase

    return raddr;

  endfunction
  
  typedef enum { idle = 0, check = 1, write = 2, read = 3, addr_decode = 4 } state_type;
  state_type state, next_state;

  always@(posedge clk) begin
    
    if(!hrst) begin
      
      state <= idle;
      
    end
    
    else begin
      
      state <= next_state;
      
    end
    
  end
  
  integer len_count = 0;
  reg first = 0;
  reg [31:0] retaddr; // stores the adsress
  reg [7:0] retboundary; // stores boundary
  reg [31:0] next_addr; // stores SEQ address
  
  always@(state) begin
    
    case(state)
      
      idle: begin
        
        len_count = 0;
        first = 0;
        next_state = check;
        hresp = `OKAY;
        hready = 1'b0;
        
      end
      
      check: begin
        
        hready = 1'b0;
        
        if(hrst&&hsel&&hwrite) begin
          
          if(haddr<256) begin
            
            next_state = addr_decode;
            
          end
          
          else begin
            
            next_state = idle;
            hresp = `ERROR;
            
          end
          
        end
        
        else if(hrst&&hsel&&!hwrite) begin
          
          if(haddr<256) begin
            
            next_state = addr_decode;
            
          end
          
          else begin
            
            next_state = idle;
            hresp = `ERROR;
            
          end
          
        end
        
        else begin
          
          next_state = idle;
          
        end
        
      end
      
      addr_decode: begin
        
        if(htrans == `NON_SEQ) begin
          
          next_addr = haddr;
          
          if(hwrite) begin
            
            next_state = write;
            
          end
          
          else begin
            
            next_state = read;
            
          end
          
        end
        
        else if(htrans == `SEQ) begin
          
          next_addr = retaddr;
          
          if(hwrite) begin
            
            next_state = write;
            
          end
          
          else begin
            
            next_state = read;
            
          end
          
        end
        
      end
      
      write: begin
        
        case(hbusrt)
          
          // SINGLE WRITE
          
          3'b000: begin
            
            retaddr = single_transaction(next_addr, hsize);
            hready = 1'b1;
            next_state = idle;
            hresp = `OKAY;
            
          end
          
          // INCR UNSPECIFIED WRITE
          
          3'b001: begin
            
            hready = 1'b1;
            hresp = `OKAY;
            
            if(len_count < 32) begin // max transaction are 32 because max 1024kb limit and data is 4byte(my fixed data limit) so (1024/8*1byte) can increase my fix data limit then add more else if statements acc to hsize(000:- 1byte 001: 2byte 010: 4byte)
              
              retaddr = incr_transaction(next_addr, hsize);
              len_count = len_count + 1;
              next_state = check;
              
            end
            else begin
              
              next_state = idle;
              len_count = 0;
              
            end
            
          end
         
          // WRAP 4 (addr will be rotating after 16byte boundary)
          
          3'b010: begin
            
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_wr(next_addr, hsize, boundary);
            hready = 1'b1;
            hresp = `OKAY;
            
            if(len_count < 3) begin
              
              next_state = check;
              len_count = len_count + 1;
              
            end
            
            else begin
              
              next_state = idle;
              len_count = 0;
              
            end
            
          end
          
          // INCR 4
          
          3'b011: begin// 4beat increment
            
            hready = 1;
            retaddr = incr_wr(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count < 3) begin
              
              next_state = check;
              len_count = len_count + 1;
              
            end
            
            else begin
              
              next_state = idle;
              len_count = 0;
              
            end
            
          end
          
          // WRAP 8
          
          3'b100: begin
            
            hready = 1'b1;
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_wr(next_addr, hsize, boundary);
            hresp = `OKAY;
            
            if(len_count < 7) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count <= 0;
              next_state <= idle;
              
            end
            
          end
          
          // INCR 8
          
          3'b101: begin
            
            hready = 1'b1;
            retaddr = incr_wr(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count<7) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // WRAP 16
          
          3'b110: begin
            
            hready = 1'b1;
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_wr(next_addr, hsize, boundary);
            hresp = `OKAY;
            
            if(len_count<15) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // INCR 16
          
          3'b111: begin
            
            hready = 1'b1;
            retaddr = incr_wr(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count < 15) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
        endcase
        
      end
      
      read: begin
        
        case(hburst)
          
          // SINGLE 
          3'b000: begin
            
            retaddr = single_transaction_read ( next_addr, hsize );
            hready = 1'b1;            
            hresp = `OKAY;
            next_state = idle;
            
          end
          
          // INCR UNSPECIFIED
          
          3'b001: begin

            hready = 1'b1;
            hresp = `OKAY;
            
            for(len_count<32) begin
              
              retaddr = increment_transaction_rd (next_addr, hsize);
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // WRAP 4
          
          3'b010: begin
            
            hready = 1'b1;
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_rd(next_addr, hsize, boundary);
            hresp = `OKAY;
            
            if(len_count < 3) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // INCR 4
          
          3'b011: begin
            
            hready = 1'b1;
            retaddr = wrap_rd(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count < 3) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // WRAP 8
          
          3'b100: begin
            
            hready = 1'b1;
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_rd(next_addr, hsize, boundary);
            hresp = `OKAY;
            
            if(len_count < 7) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // INRC 8
          
          3'b101: begin
            
            hready = 1'b1;
            retaddr = wrap_rd(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count < 7) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // WRAP 16
          
          3'b110: begin
            
            hready = 1'b1;
            retboundary = boundary(hburst, hsize);
            retaddr = wrap_rd(next_addr, hsize, boundary);
            hresp = `OKAY;
            
            if(len_count < 15) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
          // INCR 16
          
          3'b111: begin
            
            hready = 1'b1;
            retaddr = wrap_rd(next_addr, hsize);
            hresp = `OKAY;
            
            if(len_count < 15) begin
              
              len_count = len_count + 1;
              next_state = check;
              
            end
            
            else begin
              
              len_count = 0;
              next_state = idle;
              
            end
            
          end
          
        endcase
        
      end
      
    endcase
    
  end
  

endmodule
