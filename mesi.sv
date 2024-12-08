module cacheL2; 
 logic[31:0] address;
 int read, write, hit, misses, opcode;
 logic clk;
 typedef enum logic [2:0] {M,E,S,I} mesistate;
 typedef enum { READ, WRITE, INVALIDATE, RWIM } busOp;
 typedef enum { NOHIT, HIT, HITM } Snoopresult;
 typedef enum { GETLINE, SENDLINE, INVALIDATELINE, EVICTLINE } message;
 logic [13:0] index;
 int line;
 struct {
	logic[11:0] tag,
	logic valid,
	mesistate mesi,
	} st_cacheL2;
	
	logic [14:0] PLRU [16384];
	
	st_cacheL2 cache [16384][16];
	
	always_ff@(posedge clk) begin
		case(opcode)
			0 : begin
				if (cache[index][line].mesi == S)begin
					message = SENDLINE;
				end
			    else if (cache[index][line].mesi == M)begin
					message = SENDLINE; 
				end
				else if (cache[index][line].mesi == E)begin
				    message = SENDLINE;
				end
			end
			1 : begin
				if (cache[index][line].mesi == S)begin
					busOp = INVALIDATE;
					message = GETLINE;
					cache[index][line].mesi = M;
				end
			    else if (cache[index][line].mesi == M)begin
				end
				else if (cache[index][line].mesi == E)begin
				    message = GETLINE;
					cache[index][line].mesi = M;
				end
			end
			2 : begin
				if (cache[index][line].mesi == S)begin
					message = SENDLINE;
				end
			    else if (cache[index][line].mesi == M)begin
					message = SENDLINE; 
				end
				else if (cache[index][line].mesi == E)begin
				    message = SENDLINE;
				end
			end
			3 : begin
				if (cache[index][line].mesi == S) begin
					message = SENDLINE;
				end
				else if (cache[index][line].mesi == M)begin
					busOp = WRITE;
					message =GETLINE;
					cache[index][line].mesi = S;
				end
				else if (cache[index][line].mesi == E)begin
				end
			end
			4 : begin
				if (cache[index][line].mesi == I) begin
					message = SENDLINE;
				end
			end
			5 : begin
				if (cache[index][line].mesi == S) begin
					message = INVALIDATELINE;
					cache[index][line].mesi = I;
				end
				else if (cache[index][line].mesi == M)begin
					busOp = WRITE;
					message =INVALIDATELINE;
					cache[index][line].mesi = I;
				end
				else if (cache[index][line].mesi == E)begin
					message = INVALIDATELINE;
				end
			end
			6 : begin
				if (cache[index][line].mesi == S) begin
					message = INVALIDATELINE;
					cache[index][line].mesi = I;
				end
			end
		endcase
			else begin
			case (opcode)
			0 : begin
				if (cache[index][line].mesi == I) begin
					busOp == READ;
				    message == SENDLINE;
					//get snoop result
					cache[index][line].mesi = S;					
				end
				else if (cache[index][line].mesi == I) begin
					busOp == READ;
				    message == SENDLINE;
					//get snoop result
					cache[index][line].mesi = E;
				end
			end
			1 : begin
				if (cache[index][line].mesi == I) begin
					busOp == RWIM;
					message == GETLINE;
					cache[index][line].mesi = M;
				end	
			end
			2 : begin
				if (cache[index][line].mesi == I) begin
					busOp == READ;
				    message == SENDLINE;
					//get snoop result
					cache[index][line].mesi = S;					
				end
				else if (cache[index][line].mesi == I) begin
					busOp == READ;
				    message == SENDLINE;
					//get snoop result
					cache[index][line].mesi = E;
				end
			end
			3 : begin
				if (cache[index][line].mesi == I) begin
				    Snoopresult == NOHIT;
				end
			end
			4 : begin
				if (cache[index][line].mesi == I) begin
				end
			end
			5 : begin
				if (cache[index][line].mesi == I) begin
				end
			end
			6 : begin
				if (cache[index][line].mesi == I) begin
				end
			end
				
	end
