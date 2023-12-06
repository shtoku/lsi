@echo off
rem Usage : .\iv [_tb.v]

del /Q a.out
iverilog -W all ^
         -g2012 ^
         -I ../include ^
         -Y .sv ^
         -y ../src ^
         -y ../src/emb_layer ^
         -y ../src/mix_layer ^
         -y ../src/dense_layer ^
         -y ../src/comp_layer ^
         -y ../src/rand_layer ^
         %1