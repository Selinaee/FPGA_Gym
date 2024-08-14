`timescale 1ns / 1ps


module FPGA_Top(
    // PCIe ports
    input        i_pcie_clk_p,
    input        i_pcie_clk_n,
    input  [7:0] i_pcie_7x_mgt_rtl_rxn,
    input  [7:0] i_pcie_7x_mgt_rtl_rxp,
    output [7:0] o_pcie_7x_mgt_rtl_txn,
    output [7:0] o_pcie_7x_mgt_rtl_txp,
    input        i_pcie_rstn,

    // system clock
    input        i_sys_clk_p,
    input        i_sys_clk_n,

    // Pushbutton Switches
    input        i_sw_n,
    input        i_sw_e,
    input        i_sw_s,
    input        i_sw_w,
    input        i_sw_c,

    // DIP Switches
    input  [7:0] i_dip_sw,

    // LEDs
    output [7:0] o_led
    );

    // PCIe ports
        wire pcie_o_user_lnk_up;
        wire pcie_o_user_rstn;

    // connect ports
        assign o_led[0] = pcie_o_user_lnk_up;
        assign o_led[1] = pcie_o_user_rstn;
        assign o_led[2] = 1'b0;
        assign o_led[3] = 1'b0;
        assign o_led[4] = 1'b0;
        assign o_led[5] = 1'b0;
        assign o_led[6] = 1'b0;
        assign o_led[7] = i_sw_c;

    wire pcie_i_clk;
    IBUFDS_GTE2 refclk_ibuf (.O(pcie_i_clk), .ODIV2(), .I(i_pcie_clk_p), .CEB(1'b0), .IB(i_pcie_clk_n));
    pcie_wrapper u_pcie_wrapper(
        .i_pcie_clk          ( pcie_i_clk            ),
        .i_rstn              ( i_pcie_rstn           ),
        .i_sys_clk_clk_n     ( i_sys_clk_n           ),
        .i_sys_clk_clk_p     ( i_sys_clk_p           ),
        .o_user_lnk_up       ( pcie_o_user_lnk_up    ),
        .o_user_rstn         ( pcie_o_user_rstn      ),
        .pcie_7x_mgt_rtl_rxn ( i_pcie_7x_mgt_rtl_rxn ),
        .pcie_7x_mgt_rtl_rxp ( i_pcie_7x_mgt_rtl_rxp ),
        .pcie_7x_mgt_rtl_txn ( o_pcie_7x_mgt_rtl_txn ),
        .pcie_7x_mgt_rtl_txp ( o_pcie_7x_mgt_rtl_txp )
    );

endmodule
