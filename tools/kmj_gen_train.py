import numpy as np
import kmj_gen_np as kgn
from layers import *
from collections import OrderedDict
np.set_printoptions(precision=10)


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


batch_size = 2      # ミニバッチサイズ
n_epochs = 10       # エポック数
lr = 1e-3           # 学習率


class Network:
  def __init__(self):
    self.params = {}
    self.params['W_emb'] = convert_fixed(kgn.read_param(PATH_DEC + 'emb_layer_W_emb.txt').reshape(char_num, emb_dim))
    self.params['W_1'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_1.txt').reshape(emb_dim, N, hid_dim))
    self.params['b_1'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_1.txt').reshape(emb_dim, hid_dim))
    self.params['W_2'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_2.txt').reshape(hid_dim, emb_dim, 1))
    self.params['b_2'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_2.txt').reshape(hid_dim, 1))
    self.params['W_3'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_3.txt').reshape(N, hid_dim, hid_dim))
    self.params['b_3'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_3.txt').reshape(N, hid_dim))
    self.params['W_out'] = convert_fixed(kgn.read_param(PATH_DEC + 'dense_layer_W_out.txt').reshape(hid_dim, char_num))

    self.grads = {}
    self.zero_grads()

    self.layers = OrderedDict()
    self.layers['Emb_Layer'] = Emb_Layer(self.params['W_emb'])
    self.layers['Mix_Layer1'] = Mix_Layer(self.params['W_1'], self.params['b_1'], 1)
    self.layers['Tanh_Layer1'] = Tanh_Layer()
    self.layers['Mix_Layer2'] = Mix_Layer(self.params['W_2'], self.params['b_2'], 2)
    self.layers['Tanh_Layer2'] = Tanh_Layer()
    self.layers['Mix_Layer3'] = Mix_Layer(self.params['W_3'], self.params['b_3'], 3)
    self.layers['Tanh_Layer3'] = Tanh_Layer()
    self.layers['Dense_Layer'] = Dense_Layer(self.params['W_out'])

  def forward(self, x):
    for key, layer in self.layers.items():
      x = layer.forward(x)
      if x.max() > 2**(i_len-1) or x.min() < -2**(i_len-1):
        print(x.max(), x.min(), key)
    
    return x
  
  def zero_grads(self):
    self.grads['W_emb'] = np.zeros_like(self.params['W_emb'])
    self.grads['W_1'] = np.zeros_like(self.params['W_1'])
    self.grads['b_1'] = np.zeros_like(self.params['b_1'])
    self.grads['W_2'] = np.zeros_like(self.params['W_2'])
    self.grads['b_2'] = np.zeros_like(self.params['b_2'])
    self.grads['W_3'] = np.zeros_like(self.params['W_3'])
    self.grads['b_3'] = np.zeros_like(self.params['b_3'])
    self.grads['W_out'] = np.zeros_like(self.params['W_out'])

  def gradient(self, y, t):
    # Softmax
    y = softmax(y)
    dout = (y - t) / batch_size
    dout = convert_fixed(dout)

    layers = list(self.layers.values())
    layers.reverse()
    for layer in layers:
      dout = layer.backward(dout)
    
    self.grads['W_emb'] += self.layers['Emb_Layer'].dW
    self.grads['W_1'] += self.layers['Mix_Layer1'].dW
    self.grads['b_1'] += self.layers['Mix_Layer1'].db
    self.grads['W_2'] += self.layers['Mix_Layer2'].dW
    self.grads['b_2'] += self.layers['Mix_Layer2'].db
    self.grads['W_3'] += self.layers['Mix_Layer3'].dW
    self.grads['b_3'] += self.layers['Mix_Layer3'].db
    self.grads['W_out'] += self.layers['Dense_Layer'].dW
    


if __name__ == '__main__':
  # データセットの読み込み
  kmj_dataset = kgn.read_dataset('../data/dataset/kaomoji_MAX=10_DA.txt')

  # データの前処理
  kmj_onehot = kgn.preprocess(kmj_dataset)

  # データセットを分割
  train_size = int(len(kmj_dataset) * 0.85)
  valid_size = int(len(kmj_dataset) * 0.10)
  test_size  = len(kmj_dataset) - train_size - valid_size

  dataset_train = kmj_onehot[:train_size]
  dataset_valid = kmj_onehot[train_size:train_size+valid_size]
  dataset_test  = kmj_onehot[train_size+valid_size:]

  # ミニバッチに分割
  n_train = int(train_size / batch_size)
  n_valid = int(valid_size / batch_size)

  dataloader_train = [dataset_train[i*batch_size:(i+1)*batch_size] for i in range(n_train)]
  dataloader_valid = [dataset_valid[i*batch_size:(i+1)*batch_size] for i in range(n_valid)]
  
  dataloader_train.append(dataset_train[n_train*batch_size:])
  dataloader_valid.append(dataset_valid[n_valid*batch_size:])

  # モデルの定義
  net = Network()
  optim = Momentum(lr=lr)

  # 学習
  print('batch_size: {:}, lr: {:}, i_len:{:}, f_len: {:}'.format(batch_size, lr, i_len, f_len))
  for epoch in range(n_epochs):
    losses_train = []
    losses_valid = []
    acc_train = 0
    acc_valid = 0

    for batch in dataloader_train:
      net.zero_grads()
      for x in batch:
        y = net.forward(x)
        loss = crossEntropyLoss(y, x)
        net.gradient(y, x)
        losses_train.append(loss)
        acc_train += (y.argmax(axis=-1) == x.argmax(axis=-1)).sum()
      
      optim.update(net.params, net.grads)
    
    for batch in dataloader_valid:
      net.zero_grads()
      for x in batch:
        y = net.forward(x)
        loss = crossEntropyLoss(y, x)
        losses_valid.append(loss)
        acc_valid += (y.argmax(axis=-1) == x.argmax(axis=-1)).sum()    
      
    if (epoch+1) % 1 == 0:
      print('EPOCH: {:>3}, Train Loss: {:>8.5f}  Acc: {:>.3f}, Valid Loss: {:>8.5f}  Acc: {:>.3f}'.format(
          epoch+1,
          np.mean(losses_train),
          acc_train / (train_size * N),
          np.mean(losses_valid),
          acc_valid / (valid_size * N)
      ))