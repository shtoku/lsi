// define Network parameter
`define N           10                // max characters of Kaomoji 
`define CHAR_NUM    64                // character list length
`define EMB_DIM     12                // character vector length
`define HID_DIM     12                // hidden vector length

// define bit width
`define I_LEN       8                 // integer part bit width
`define F_LEN       16                // fractional part bit width
`define N_LEN       24                // integer + fractional part bit width
`define I_LEN_W     2                 // integer part bit width for ram (else W_out)
`define F_LEN_W     16                // fractional part bit width for ram (else W_out)
`define N_LEN_W     18                // integer + fractional part bit width for ram (else W_out)
`define CHAR_LEN    8                 // integer bit width of character list

`define DATA_N      6                 // read ram 1 time, read 6 data.

// define traing parameter
`define BATCH_SIZE  2                 // mini batch size
`define BATCH_SHIFT 1                 // log2(BATCH_SIZE), used for division.
`define MOMENTUM    `N_LEN_W'h0E666   // momentum=0.9
`define LR          `N_LEN_W'h00041   // learning rate=0.001

// define mode
`define MODE_LEN    2
`define TRAIN       `MODE_LEN'd0      // training
`define FORWARD     `MODE_LEN'd1      // forward
`define GEN_SIMI    `MODE_LEN'd2      // generate similar one
`define GEN_NEW     `MODE_LEN'd3      // generate new one

// define state_main
`define STATE_LEN   4
`define M_IDLE      `STATE_LEN'd0     // main idle
`define M_S1        `STATE_LEN'd1     // main step 1. forward1
`define M_S2        `STATE_LEN'd2     // main step 2. forward2 and backward1
`define M_S3        `STATE_LEN'd3     // main step 3. backward2
`define M_UPDATE    `STATE_LEN'd4     // main update parameter
`define M_FIN       `STATE_LEN'd5     // main finish

// define state_forward
`define F_IDLE      `STATE_LEN'd0     // forward idle
`define F_RECV      `STATE_LEN'd1     // forward receive
`define F_EMB       `STATE_LEN'd2     // forward emb_layer
`define F_MIX1      `STATE_LEN'd3     // forward mix_layer1
`define F_TANH1     `STATE_LEN'd4     // forward tanh_layer1
`define F_MIX2      `STATE_LEN'd5     // forward mix_layer2
`define F_TANH2     `STATE_LEN'd6     // forward tanh_layer2
`define F_MIX3      `STATE_LEN'd7     // forward mix_layer3
`define F_TANH3     `STATE_LEN'd8     // forward tanh_layer3
`define F_DENS      `STATE_LEN'd9     // forward dense_layer
`define F_COMP      `STATE_LEN'd10    // forward comp_layer
`define F_SEND      `STATE_LEN'd11    // forward send
`define F_FIN       `STATE_LEN'd12    // forward finish

// define state_backward
`define B_IDLE      `STATE_LEN'd0     // backward idle
`define B_SMAX      `STATE_LEN'd1     // backward softmax_layer
`define B_DENS      `STATE_LEN'd2     // backward dense_layer
`define B_TANH3     `STATE_LEN'd3     // backward tanh_layer3
`define B_MIX3      `STATE_LEN'd4     // backward mix_layer3
`define B_TANH2     `STATE_LEN'd5     // backward tanh_layer2
`define B_MIX2      `STATE_LEN'd6     // backward mix_layer2
`define B_TANH1     `STATE_LEN'd7     // backward tanh_layer1
`define B_MIX1      `STATE_LEN'd8     // backward mix_layer1
`define B_EMB       `STATE_LEN'd9     // backward emb_layer
`define B_FIN       `STATE_LEN'd10    // backward finish