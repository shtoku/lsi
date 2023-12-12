@echo off
rem Usage : .\iv [_tb.v]

del /Q a.out
iverilog -W all ^
         -g2012 ^
         -I ../../include ^
         -Y .sv ^
         -y ../../src/trained ^
         -y ../../src/trained/emb_layer ^
         -y ../../src/trained/mix_layer ^
         -y ../../src/trained/dense_layer ^
         -y ../../src/trained/comp_layer ^
         -y ../../src/trained/rand_layer ^
         %1