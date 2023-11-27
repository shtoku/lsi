import numpy as np
import matplotlib.pyplot as plt
import kmj_gen as kg
import kmj_gen_sim as kgs


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元

# 固定小数点の桁数
i_len = 6           # 整数部の桁数
f_len = 10          # 小数部の桁数
n_len = 16          # 整数部 + 小数部 の桁数


# XorShiftのクラス
# # -1~1の乱数を生成(返り値は文字列)
class XorShift:
  def __init__(self, seed):
    self.x = seed
  
  def __call__(self):
    x = self.forward()
    x = format(x, 'b')
    x = ''.join([x[-f_len-1] for _ in range(i_len)]) + x[-f_len:]
    return x
  
  def forward(self):
    self.x ^= self.x << 13 & 0xffffffff
    self.x ^= self.x >> 17 & 0xffffffff
    self.x ^= self.x << 5  & 0xffffffff
    return self.x


if __name__ == '__main__':
  xors = XorShift(1234)

  size = 10000
  z_list = []
  for _ in range(size):
    z = xors()
    z_list.append(kg.str_to_int(z) / 2**f_len)
  
  c, l, p = plt.hist(z_list, bins=50)
  plt.show()