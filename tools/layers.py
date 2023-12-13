import numpy as np
# np.set_printoptions(precision=10)
                    

# 固定小数点の桁数
i_len = 8           # 整数部の桁数
f_len = 16          # 小数部の桁数
n_len = 24          # 整数部 + 小数部 の桁数

i_len_w = 2         # W_out 以外の整数部の桁数


# 固定小数点精度に変換する関数
def convert_fixed(x, bit=f_len):
  return np.floor(x * 2**bit) / 2**bit


# 固定小数点精度の行列積(2次元×2次元のみ)
def dot_fixed(a, b):
  a = np.expand_dims(a, -2)
  c = (a * b.T)
  c = convert_fixed(c)
  return c.sum(axis=-1)


def softmax(x):
  # Softmax
  x = x - np.max(x, axis=-1, keepdims=True)   # オーバーフロー対策
  #-16以下は-16とする処理を挟む exp(-16) = 0.0
  x = convert_fixed(x, bit=6) # 整数部：4，小数部：6

  exp = np.exp(x) # 0~1の間になる
  exp = convert_fixed(exp) # 整数部：2，小数部：16

  sum = np.sum(exp, axis=-1, keepdims=True)
  sum = convert_fixed(sum, bit=2) # 整数部：8，小数部：2
  if sum.max() > 2**(i_len) or sum.min() < -2**(i_len):
    print(sum.max(), sum.min(), 'softmax sum')
  
  inv = convert_fixed(1.0 / sum) # 整数部：2，小数部：16
  if inv.max() > 2**(i_len_w-1) or inv.min() < -2**(i_len_w-1):
    print(inv.max(), inv.min(), 'softmax sum inverse')
  
  out =  exp * inv
  out = convert_fixed(out)

  return out


def crossEntropyLoss(y, t):
  # Softmax
  y = softmax(y)

  # CrossEntropyLoss
  temp = convert_fixed(np.log(y + 1e-7))
  loss = -np.sum(temp[range(len(y)), t])
  
  return loss


# emb_layer
class Emb_Layer:
  def __init__(self, W):
    self.W = W

    self.x = None
    self.dW = None
  
  def forward(self, x):
    self.x = x
    out = self.W[x]

    return out
  
  def backward(self, dout):
    dx = dot_fixed(dout, self.W.T)
    self.dW = np.zeros_like(self.W)
    for i in range(len(dout)):
      self.dW[self.x[i]] += dout[i]

    return dx


# mix_layer
class Mix_Layer:
  def __init__(self, W, b, state):
    self.W = W
    self.b = b

    self.x = None
    self.dW = None
    self.db = None

    self.state = state

  def forward(self, x):
    self.x = x
    x = x.T
    x = np.expand_dims(x, -2)
    y = x * self.W.transpose(0, 2, 1)
    y = convert_fixed(y)
    y = y.sum(axis=-1)
    out = y + self.b

    return out
  
  def backward(self, dout):
    dout = np.expand_dims(dout, -2)
    dx = dout * self.W
    dx = convert_fixed(dx)
    dx = dx.sum(axis=-1)

    if self.state == 3:
      dx = dx.sum(axis=0, keepdims=True)
    dx = dx.T
    
    x = self.x.T
    x = np.expand_dims(x, -2)
    x = x.transpose(0, 2, 1) * dout

    self.dW = convert_fixed(x)
    self.db = dout.squeeze(-2)
    
    return dx


# tanh_layer
class Tanh_Layer:
  def __init__(self):
    self.out = None
  
  def forward(self, x):
    x = convert_fixed(x, bit=6) # 整数部：4，小数部：6
    out = np.tanh(x) # -1~1の間になる
    out = convert_fixed(out)
    self.out = out

    return out
  
  def backward(self, dout):
    temp = self.out**2
    temp = convert_fixed(temp)
    dx = dout * (1.0 - temp)
    dx = convert_fixed(dx)

    return dx


# dense_layer
class Dense_Layer:
  def __init__(self, W):
    self.W = W

    self.x = None
    self.dW = None
  
  def forward(self, x):
    self.x = x
    out = dot_fixed(x, self.W)

    return out
  
  def backward(self, dout):
    dx = dot_fixed(dout, self.W.T)
    self.dW = dot_fixed(self.x.T, dout)

    return dx


# optimizer Momentum
class Momentum:

  """Momentum SGD"""

  def __init__(self, lr=0.01, momentum=0.9):
    self.lr = convert_fixed(lr)
    self.momentum = convert_fixed(momentum)
    self.v = None
      
  def update(self, params, grads):
    if self.v is None:
      self.v = {}
      for key, val in params.items():                                
        self.v[key] = np.zeros_like(val)
            
    for key in params.keys():
      self.v[key] = convert_fixed(self.momentum*self.v[key]) - convert_fixed(self.lr*grads[key])
      params[key] += self.v[key]

      if params[key].max() > 2**(i_len_w-1) or params[key].min() < -2**(i_len_w-1):
        if key == 'W_out':
          continue
        print(params[key].max(), params[key].min(), key)
      if grads[key].max() > 2**(i_len_w-1) or grads[key].min() < -2**(i_len_w-1):
        if key == 'W_out':
          continue
        print(grads[key].max(), grads[key].min(), key)
      if self.v[key].max() > 2**(i_len_w-1) or self.v[key].min() < -2**(i_len_w-1):
        if key == 'W_out':
          continue
        print(self.v[key].max(), self.v[key].min(), key)