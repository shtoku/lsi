# coding: utf-8
import numpy as np


# emb_layer
class Emb_Layer:
  def __init__(self, W):
    self.W = W

    self.x = None
    self.dW = None
  
  def forward(self, x):
    self.x = x
    out = np.matmul(x, self.W)

    return out
  
  def backward(self, dout):
    dx = np.matmul(dout, self.W.T)
    self.dW = np.matmul(self.x.transpose(0, 2, 1), dout).sum(axis=0)

    return dx



# mix_layer
class Mix_Layer:
  def __init__(self, W, b, is_hid=False):
    self.W = W
    self.b = b

    self.x = None
    self.dW = None
    self.db = None

    self.is_hid = is_hid

  def forward(self, x):
    self.x = x
    x = x.transpose(0, 2, 1)
    x = np.expand_dims(x, -2)
    out = np.matmul(x, self.W) + self.b

    return out.squeeze(-2)
  
  def backward(self, dout):
    dout = np.expand_dims(dout, -2)
    dx = np.matmul(dout, self.W.transpose(0, 2, 1))
    if self.is_hid:
      dx = dx.sum(axis=1)
    else:
      dx = dx.squeeze(-2)
    dx = dx.transpose(0, 2, 1)
    
    x = self.x.transpose(0, 2, 1)
    x = np.expand_dims(x, -2)
    x = x.transpose(0, 1, 3, 2)
    self.dW = np.matmul(x, dout).sum(axis=0)
    self.db = dout.sum(axis=0)
    
    return dx


# dense_layer
class Dense_Layer:
  def __init__(self, W):
    self.W = W

    self.x = None
    self.dW = None
  
  def forward(self, x):
    self.x = x
    out = np.matmul(x, self.W)

    return out
  
  def backward(self, dout):
    dx = np.matmul(dout, self.W.T)
    self.dW = np.matmul(self.x.transpose(0, 2, 1), dout).mean(axis=0)

    return dx


# Softmax_Layer
class Softmax_Layer:
  def __init__(self):
    self.loss = None
    self.y = None
    self.t = None

  def forward(self, y, t):
    self.t = t
  
    # Softmax
    y = y - np.max(y, axis=-1, keepdims=True)   # オーバーフロー対策
    self.y =  np.exp(y) / np.sum(np.exp(y), axis=-1, keepdims=True)

    # CrossEntropyLoss
    self.loss = -np.sum(t * np.log(self.y + 1e-7)) / y.shape[0]
        
    return self.loss


# optimizer Adam
class Adam:

  """Adam (http://arxiv.org/abs/1412.6980v8)"""

  def __init__(self, lr=0.001, beta1=0.9, beta2=0.999):
    self.lr = lr
    self.beta1 = beta1
    self.beta2 = beta2
    self.iter = 0
    self.m = None
    self.v = None
      
  def update(self, params, grads):
    if self.m is None:
      self.m, self.v = {}, {}
      for key, val in params.items():
        self.m[key] = np.zeros_like(val)
        self.v[key] = np.zeros_like(val)
    
    self.iter += 1
    lr_t  = self.lr * np.sqrt(1.0 - self.beta2**self.iter) / (1.0 - self.beta1**self.iter)
    
    for key in params.keys():
      self.m[key] += (1 - self.beta1) * (grads[key] - self.m[key])
      self.v[key] += (1 - self.beta2) * (grads[key]**2 - self.v[key])
      
      params[key] -= lr_t * self.m[key] / (np.sqrt(self.v[key]) + 1e-7)