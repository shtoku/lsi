@echo off
rem Usage : .\wave

del /Q dump.vcd
vvp a.out
gtkwave -g dump.vcd