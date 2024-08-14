
```python
costheta = np.cos(theta)
sintheta = np.sin(theta)
```
```verilog
cordic_0 cordic_u (
    .aclk                 (i_clk),
    .s_axis_phase_tvalid (s_cordic_tvalid),
    .s_axis_phase_tdata  (s_cordic),
    .m_axis_dout_tvalid  (m_cordic_tvalid),
    .m_axis_dout_tdata   (m_cordic)
);
```

```python
    x = x + tau * x_dot
```
If the data type is an integer, they are very similar.
```verilog
   x = x + tau * x_dot
```
If the data type is floating-point, you can directly use the available Xilinx IP cores.
```verilog
    floating_multiply TAUxxacc_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_TAUxxacc_tvalid),
        .s_axis_a_tdata       (TAU),
        .s_axis_b_tvalid      (s_TAUxxacc_tvalid),
        .s_axis_b_tdata       (s_TAUxxacc_xacc),
        .m_axis_result_tvalid (m_TAUxxacc_tvalid),
        .m_axis_result_tdata  (m_TAUxxacc)
    );

    floating_point_adder next_x_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_dot_tvalid),
        .s_axis_a_tdata       (x_dot),
        .s_axis_b_tvalid      (s_next_x_dot_tvalid),
        .s_axis_b_tdata       (s_TAUxxacc),
        .m_axis_result_tvalid (m_next_x_dot_tvalid),
        .m_axis_result_tdata  (m_next_x_dot)
    );
```
```python
    x > x_threshold
```
If the data type is an integer, they are very similar.
```verilog
    x > x_threshold
```
If the data type is floating-point, you can directly use the available Xilinx IP cores.
```verilog
    floating_point_greater_than_or_equal next_x_greater_threshold_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_greater_threshold_tvalid),
        .s_axis_a_tdata       (s_next_x_greater_threshold_a),
        .s_axis_b_tvalid      (s_next_x_greater_threshold_tvalid),
        .s_axis_b_tdata       (s_next_x_greater_threshold_b),
        .m_axis_result_tvalid (m_next_x_greater_threshold_tvalid),
        .m_axis_result_tdata  (m_next_x_greater_threshold)
    );
```
# condition statement 
```python
    reward = 0.0 if not terminated else 1.0

```
```verilog
    assign o_reward = terminated ? 1 : 0;
```

def encode(self, taxi_row, taxi_col, pass_loc, dest_idx):
    i = ((taxi_row * 5 + taxi_col) * 5 + pass_loc)*4 +dest_idx;
    return i

module Encode(
    input [2:0] taxi_row,    
    input [2:0] taxi_col,
    input [2:0] pass_loc,    
    input [1:0] dest_idx,    
    output reg [8:0] encoded_state  
);

always @(*) begin
    encoded_state = ((taxi_row * 5 + taxi_col) * 5 + pass_loc)*4 +dest_idx;
end

endmodule






<div style="width: 48%; float: left;">

### Python代码

```Python code
def encode(self, taxi_row, taxi_col, pass_loc, dest_idx):
    i = taxi_row
    i = i * 5 + taxi_col
    i = i * 5 + pass_loc
    i = i * 4 + dest_idx
    return i
```
 </div>

<div style="width: 48%; float: right;">

### Verilog code
```verilog
module Encode(
    input [2:0] taxi_row,    
    input [2:0] taxi_col,
    input [2:0] pass_loc,    
    input [1:0] dest_idx,    
    output reg [8:0] i 
);
always @(*) begin
    i = taxi_row;
    i = i * 5 + taxi_col;
    i = i * 5 + pass_loc;
    i = i * 4 + dest_idx;
end
endmodule
```
</div>
 
<div style="width: 48%; float: left;">

### Python代码

```Python code
def decode(self, i):
    out = []
    out.append(i % 4)
    i = i // 4
    out.append(i % 5)
    i = i // 5
    out.append(i % 5)
    i = i // 5
    out.append(i)
    assert 0 <= i < 5
    return reversed(out)

```
 </div>

<div style="width: 48%; float: right;">

### Verilog code
```verilog
module decode(
    input [8:0] i, // 
    output reg [1:0] dest_idx, // 
    output reg [2:0] pass_idx, // 
    output reg [2:0] taxi_col, // 
    output reg [2:0] taxi_row  // 
);

integer intermediate;

always @ (*) begin
    dest_idx = i % 4;  
    intermediate = i / 4;
    pass_idx = intermediate % 5;  
    intermediate = intermediate / 5;
    taxi_col = intermediate % 5; 
    intermediate = intermediate / 5;
    taxi_row = intermediate;  
end 
endmodule

```
</div>
 
| **Python代码** | **Verilog代码** |
|----------------|-----------------|
| ```python      | ```verilog       |
| def encode...  | module Encode... |
| i = taxi_row   | always @(*) ...  |
| ...            | ...              |
| ```            | ```              |