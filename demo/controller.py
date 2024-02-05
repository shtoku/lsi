import numpy as np
from time import sleep
from pynq import PL, Overlay, MMIO, allocate

# PL制御クラス
class Controller:
  def __init__(self, bitfile, batch_size, N):
    PL.reset()
    ol = Overlay(bitfile)

    dma = ol.axi_dma_0
    self.dma_send = dma.sendchannel
    self.dma_recv = dma.recvchannel

    self.top_mmio = MMIO(ol.ip_dict['top_0']['phys_addr'], ol.ip_dict['top_0']['addr_range'])
    self.top_mmio.write(0*4, 0b0000)  # slv_reg0[2:0] : {next, run, rst_n}
    
    self.input_buffer  = allocate(shape=(batch_size, N), dtype=np.uint8)
    self.output_buffer = allocate(shape=(batch_size, N), dtype=np.uint8)
  
  def send_data(self, data):
    # while not self.dma_send.idle:
    #   sleep(0.001)
    self.input_buffer[:] = data
    
    self.dma_send.transfer(self.input_buffer)
  
  def recv_data(self):
    # while not self.dma_recv.idle:
    #   sleep(0.001)
    self.dma_recv.transfer(self.output_buffer)
    return self.output_buffer
  
  def run_mode(self, mode=1):
    self.top_mmio.write(1*4, mode)  # slv_reg1[1:0] : mode    
    self.top_mmio.write(0*4, 0b101) # slv_reg0[2:0] : {next, run, rst_n}   
    self.top_mmio.write(0*4, 0b011) # slv_reg0[2:0] : {next, run, rst_n}

    # slv_reg2[0] : finish
    while self.top_mmio.read(2*4) != 1:
      sleep(0.001)