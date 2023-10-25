@echo off
rem Usage : .\iv [_tb.v]

del /Q a.out
iverilog -W all ^
         -g2012 ^
         -I ../include ^
         -y ../src ^
         %1