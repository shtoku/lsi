// define Network parameter
`define N           10                // max characters of Kaomoji 
`define CHAR_NUM    200               // character list length
`define EMB_DIM     24                // character vector length
`define HID_DIM     24                // hidden vector length

// define bit width
`define I_LEN       6                 // integer part bit width
`define F_LEN       10                // fractional part bit width
`define N_LEN       16                // integer + fractional part bit width
`define CHAR_LEN    8                 // integer bit width of character list

// define state
`define STATE_LEN   4                 // state bit width
`define IDLE        `STATE_LEN'd0     // idle
`define RECV        `STATE_LEN'd1     // receive
`define EMB         `STATE_LEN'd2     // emb_layer
`define MIX1        `STATE_LEN'd3     // mix_layer1
`define MIX2        `STATE_LEN'd4     // mix_layer2
`define MIX3        `STATE_LEN'd5     // mix_layer3
`define DENS        `STATE_LEN'd6     // dense_layer
`define COMP        `STATE_LEN'd7     // comp_layer
`define SEND        `STATE_LEN'd8     // send