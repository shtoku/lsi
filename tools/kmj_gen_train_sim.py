import numpy as np
import os
import glob
import kmj_gen_np as kgn
from kmj_gen_train import Network
from layers import *


PATH_TB = '../data/tb/train/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


batch_size = 2      # ミニバッチサイズ
n_epochs = 10       # エポック数
lr = 1e-3           # 学習率


# ミニバッチを作成する関数
def create_batch(batch_size):
  # データセットの読み込み
  kmj_dataset = kgn.read_dataset('../data/dataset/kaomoji_MAX=10_DA.txt')

  # データの前処理
  kmj_onehot = kgn.preprocess(kmj_dataset)
  kmj_int = kmj_onehot.argmax(axis=-1)

  # データセットを分割
  train_size = int(len(kmj_dataset) * 0.85)
  valid_size = int(len(kmj_dataset) * 0.10)
  test_size  = len(kmj_dataset) - train_size - valid_size

  dataset_train = kmj_int[:train_size]
  dataset_valid = kmj_int[train_size:train_size+valid_size]
  dataset_test  = kmj_int[train_size+valid_size:]

  # ミニバッチに分割
  n_train = int(train_size / batch_size)
  n_valid = int(valid_size / batch_size)

  dataloader_train = [dataset_train[i*batch_size:(i+1)*batch_size] for i in range(n_train)]
  dataloader_valid = [dataset_valid[i*batch_size:(i+1)*batch_size] for i in range(n_valid)]

  return dataloader_train, dataloader_valid


# 10進数を固定小数点2進数に変換する関数
def convert_fixed2(x, i_len, f_len):
  n_len = i_len + f_len
  temp = int(np.floor(x * 2**f_len))
  return format(temp & ((1 << n_len) - 1), '0' + str(n_len) + 'b')


# ファイルに出力する関数
def output_file(filename, x, i_len=i_len, f_len=f_len, mode='w'):
  with open(filename, mode) as file:
    for value in x:
      temp = convert_fixed2(value, i_len, f_len)
      file.write(temp + '\n')


def remove_file():
  for p in glob.glob(PATH_TB + '**/*.txt', recursive=True):
    if os.path.isfile(p):
        os.remove(p)



# 順伝播の入出力サンプルを作成する関数
def output_forward(x, net, name=''):
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_in' + str(name) + '.txt', x, i_len=8, f_len=0)
  x = net.layers['Emb_Layer'].forward(x)
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_out' + str(name) + '.txt', x.flatten(), i_len=2, f_len=16)
  x = np.concatenate([x, np.zeros((hid_dim-N, hid_dim))], axis=0)
  x = net.layers['Mix_Layer1'].forward(x)
  x = net.layers['Tanh_Layer1'].forward(x)
  x = net.layers['Mix_Layer2'].forward(x)
  x = net.layers['Tanh_Layer2'].forward(x)
  x = np.full((hid_dim, hid_dim), x[:, 0]).T
  x = net.layers['Mix_Layer3'].forward(x)
  x = net.layers['Tanh_Layer3'].forward(x)
  x = x[:N, :]
  x = net.layers['Dense_Layer'].forward(x)

  return x


# 逆伝播の入出力サンプルを作成する関数
def output_backward(y, t, net):
  # Softmax
    y = softmax(y)
    y[range(len(y)), t] -= 1.0
    dout = convert_fixed(y / batch_size)

    dout = net.layers['Dense_Layer'].backward(dout)
    dout = np.concatenate([dout, np.zeros((hid_dim-N, hid_dim))], axis=0)
    dout = net.layers['Tanh_Layer3'].backward(dout)
    dout = net.layers['Mix_Layer3'].backward(dout)
    dout = dout.sum(axis=1, keepdims=True)
    dout = np.concatenate([dout, np.zeros((hid_dim, hid_dim-1))], axis=1)
    dout = net.layers['Tanh_Layer2'].backward(dout)
    dout = net.layers['Mix_Layer2'].backward(dout)
    dout = net.layers['Tanh_Layer1'].backward(dout)
    dout = net.layers['Mix_Layer1'].backward(dout)
    dout = dout[:N, :]
    output_file(PATH_TB + 'emb_layer/emb_layer_backward_in.txt', dout.flatten(), i_len=2, f_len=16, mode='a')
    dout = net.layers['Emb_Layer'].backward(dout)
    
    net.grads['W_emb'] += net.layers['Emb_Layer'].dW
    net.grads['W_1'] += net.layers['Mix_Layer1'].dW
    net.grads['b_1'] += net.layers['Mix_Layer1'].db
    net.grads['W_2'] += net.layers['Mix_Layer2'].dW
    net.grads['b_2'] += net.layers['Mix_Layer2'].db
    net.grads['W_3'] += net.layers['Mix_Layer3'].dW
    net.grads['b_3'] += net.layers['Mix_Layer3'].db
    net.grads['W_out'] += net.layers['Dense_Layer'].dW


if __name__ == '__main__':
  remove_file()
  dataloader_train, _  = create_batch(batch_size)

  net = Network()
  optim = Momentum(lr=lr)

  # 学習
  print('fixed sample ver')
  print('batch_size: {:}, lr: {:}'.format(batch_size, lr))
  losses_train = []
  acc_train = 0

  net.zero_grads()
  for i, x in enumerate(dataloader_train[0]):
    if i == 0:
      y = output_forward(x, net)
    else:
      y = net.forward(x)
    loss = crossEntropyLoss(y, x)
    output_backward(y, x, net)
    losses_train.append(loss)
    acc_train += (y.argmax(axis=-1) == x).sum()
  
  optim.update(net.params, net.grads)
  print(loss, acc_train)

  x = dataloader_train[1][0]
  y = output_forward(x, net, name='_for_backward')
  print(y.sum())


# fixed sample ver
# batch_size: 2, lr: 0.001
# 52.89280700683594 0
# 1.3714752197265625