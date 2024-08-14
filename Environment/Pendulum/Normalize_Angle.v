module Normalize_Angle (
    input wire i_clk,
    input wire i_ena,

    input  wire [31:0] i_th,
    output wire [31:0] o_th,
    output wire        o_valid
    );

    parameter PI   = 32'h40490fdb; //  3.1415926536
    parameter NPI  = 32'hc0490fdb; // -3.1415926536
    parameter PI2  = 32'h40c90fdb; //  6.2831853072

    // u_Greater ports
    wire        gtr_i_a_valid;
    wire [31:0] gtr_i_a;
    wire        gtr_i_b_valid;
    wire [31:0] gtr_i_b;
    wire        gtr_o_result_valid;
    wire [7:0]  gtr_o_result;

    // u_Less ports
    wire        les_i_a_valid;
    wire [31:0] les_i_a;
    wire        les_i_b_valid;
    wire [31:0] les_i_b;
    wire        les_o_result_valid;
    wire [7:0]  les_o_result;

    // u_Adder ports
    wire        add_i_a_valid;
    wire [31:0] add_i_a;
    wire        add_i_b_valid;
    wire [31:0] add_i_b;
    wire        add_o_result_valid;
    wire [31:0] add_o_result;

    // u_Subtracter ports
    wire        sub_i_a_valid;
    wire [31:0] sub_i_a;
    wire        sub_i_b_valid;
    wire [31:0] sub_i_b;
    wire        sub_o_result_valid;
    wire [31:0] sub_o_result;

    // connect ports
        // Normalize_Angle outputs
        assign o_th    = |gtr_o_result ? sub_o_result :
                         |les_o_result ? add_o_result : i_th;
        assign o_valid = gtr_o_result_valid & les_o_result_valid & add_o_result_valid & sub_o_result_valid;
        // u_Greater inputs
        assign gtr_i_a_valid = i_ena;
        assign gtr_i_a = i_th;
        assign gtr_i_b_valid = i_ena;
        assign gtr_i_b = PI;
        // u_Less inputs
        assign les_i_a_valid = i_ena;
        assign les_i_a = i_th;
        assign les_i_b_valid = i_ena;
        assign les_i_b = NPI;
        // u_Adder inputs
        assign add_i_a_valid = i_ena;
        assign add_i_a = i_th;
        assign add_i_b_valid = i_ena;
        assign add_i_b = PI2;
        // u_Subtracter inputs
        assign sub_i_a_valid = i_ena;
        assign sub_i_a = i_th;
        assign sub_i_b_valid = i_ena;
        assign sub_i_b = PI2;

    Comparator_Greater u_Greater ( // i_data > i_max
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( gtr_i_a_valid ),      // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( gtr_i_a[31:0] ),      // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( gtr_i_b_valid ),      // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( gtr_i_b[31:0] ),      // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( gtr_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( gtr_o_result[7:0] )   // output wire [7 : 0]  m_axis_result_tdata
    );
    Comparator_Less u_Less ( // i_data < i_min
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( les_i_a_valid ),      // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( les_i_a[31:0] ),      // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( les_i_b_valid ),      // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( les_i_b[31:0] ),      // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( les_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( les_o_result[7:0] )   // output wire [7 : 0]  m_axis_result_tdata
    );
    Adder u_Adder (
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( add_i_a_valid ),      // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( add_i_a[31:0] ),      // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( add_i_b_valid ),      // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( add_i_b[31:0] ),      // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( add_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( add_o_result[31:0] )  // output wire [31 : 0] m_axis_result_tdata
    );
    Subtracter u_Subtracter (
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( sub_i_a_valid ),      // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( sub_i_a[31:0] ),      // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( sub_i_b_valid ),      // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( sub_i_b[31:0] ),      // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( sub_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( sub_o_result[31:0] )  // output wire [31 : 0] m_axis_result_tdata
    );
endmodule