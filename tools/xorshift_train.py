import matplotlib.pyplot as plt


# 固定小数点の桁数
i_len_w = 2           # 整数部の桁数
f_len   = 16          # 小数部の桁数
n_len   = 18          # 整数部 + 小数部 の桁数


# XorShiftのクラス
# # -1~1の乱数を生成(返り値は文字列)
class XorShift:
  def __init__(self, seed):
    self.x = seed
  
  def __call__(self):
    x = self.forward()
    x = format(x, 'b')
    x = ''.join([x[-f_len-1] for _ in range(i_len_w)]) + x[-f_len:]
    x = self.str_to_int(x) / 2**f_len
    return x
  
  def forward(self):
    self.x ^= self.x << 13 & 0xffffffff
    self.x ^= self.x >> 17 & 0xffffffff
    self.x ^= self.x << 5  & 0xffffffff
    return self.x
  
  # strをintに変換
  def str_to_int(self, x):
    return (int(x, 2) - int(int(x[0]) << n_len))


if __name__ == '__main__':
  xors = XorShift(1234)

  size = 10000
  z_list = []
  for _ in range(size):
    z = xors()
    z_list.append(z)
  
  c, l, p = plt.hist(z_list, bins=50)
  plt.show()