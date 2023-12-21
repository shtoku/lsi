@echo off
rem Usage : .\iv [_tb.v]

del /Q a.out
iverilog -W all ^
         -g2012 ^
         -I ../../include ^
         -Y .sv ^
         -y ../../src/train ^
         -y ../../src/train/state_machine ^
         -y ../../src/train/emb_layer ^
         -y ../../src/train/mix_layer ^
         -y ../../src/train/dense_layer ^
         -y ../../src/train/tanh_layer ^
         -y ../../src/train/comp_layer ^
         -y ../../src/train/rand_layer ^
         %1