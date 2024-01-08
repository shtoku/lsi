import numpy as np
import os
import glob
import kmj_gen_np as kgn
from kmj_gen_train import Network
from layers import *
from xorshift_train import XorShift


PATH_TB = '../data/tb/train/'


N = 10              # 最大文字数
char_num = 72       # 文字種数
emb_dim = 12        # 文字ベクトルの次元
hid_dim = 12        # 潜在ベクトルの次元


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
def output_file(filename, x, i_len=i_len, f_len=f_len, mode='a'):
  with open(filename, mode) as file:
    for value in x:
      temp = convert_fixed2(value, i_len, f_len)
      file.write(temp + '\n')


def remove_file():
  for p in glob.glob(PATH_TB + '**/*.txt', recursive=True):
    if os.path.isfile(p):
        os.remove(p)



# 順伝播の入出力サンプルを作成する関数
def output_forward(x, net):
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_in.txt', x, i_len=8, f_len=0)
  x = net.layers['Emb_Layer'].forward(x)
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_out.txt', x.flatten(), i_len=2, f_len=16)

  x = np.concatenate([x, np.zeros((hid_dim-N, hid_dim))], axis=0)

  output_file(PATH_TB + 'mix_layer/mix_layer1_forward_in.txt', x.flatten())
  x = net.layers['Mix_Layer1'].forward(x)
  output_file(PATH_TB + 'mix_layer/mix_layer1_forward_out.txt', x.flatten())

  output_file(PATH_TB + 'tanh_layer/tanh_layer1_forward_in.txt', x.flatten())
  x = net.layers['Tanh_Layer1'].forward(x)
  output_file(PATH_TB + 'tanh_layer/tanh_layer1_forward_out.txt', x.flatten(), i_len=2, f_len=16)

  output_file(PATH_TB + 'mix_layer/mix_layer2_forward_in.txt', x.flatten())
  x = net.layers['Mix_Layer2'].forward(x)
  output_file(PATH_TB + 'mix_layer/mix_layer2_forward_out.txt', x.flatten())

  output_file(PATH_TB + 'tanh_layer/tanh_layer2_forward_in.txt', x.flatten())
  x = net.layers['Tanh_Layer2'].forward(x)
  output_file(PATH_TB + 'tanh_layer/tanh_layer2_forward_out.txt', x.flatten(), i_len=2, f_len=16)

  x = np.full((hid_dim, hid_dim), x[:, 0]).T

  output_file(PATH_TB + 'mix_layer/mix_layer3_forward_in.txt', x.flatten())
  x = net.layers['Mix_Layer3'].forward(x)
  output_file(PATH_TB + 'mix_layer/mix_layer3_forward_out.txt', x.flatten())

  output_file(PATH_TB + 'tanh_layer/tanh_layer3_forward_in.txt', x.flatten())
  x = net.layers['Tanh_Layer3'].forward(x)
  output_file(PATH_TB + 'tanh_layer/tanh_layer3_forward_out.txt', x.flatten(), i_len=2, f_len=16)

  x = x[:N, :]
  
  output_file(PATH_TB + 'dense_layer/dense_layer_forward_in.txt', x.flatten(), i_len=2, f_len=16)
  x = net.layers['Dense_Layer'].forward(x)
  output_file(PATH_TB + 'dense_layer/dense_layer_forward_out.txt', x.flatten())

  output_file(PATH_TB + 'comp_layer/comp_layer_in.txt', x.flatten())
  num = x.argmax(axis=-1)
  output_file(PATH_TB + 'comp_layer/comp_layer_out.txt', x.max(axis=-1).flatten())
  output_file(PATH_TB + 'comp_layer/comp_layer_num.txt', num.flatten(), i_len=8, f_len=0)

  return x


# 逆伝播の入出力サンプルを作成する関数
def output_backward(y, t, net):
  output_file(PATH_TB + 'softmax_layer/softmax_layer_num.txt', t.flatten(), i_len=8, f_len=0)
  output_file(PATH_TB + 'softmax_layer/softmax_layer_max.txt', y.max(axis=-1).flatten())
  output_file(PATH_TB + 'softmax_layer/softmax_layer_in.txt', y.flatten())
  # Softmax
  y = softmax(y)
  y[range(len(y)), t] -= 1.0
  dout = convert_fixed(y / batch_size)
  output_file(PATH_TB + 'softmax_layer/softmax_layer_out.txt', dout.flatten(), i_len=2, f_len=16)

  output_file(PATH_TB + 'dense_layer/dense_layer_backward_in.txt', dout.flatten(), i_len=2, f_len=16)
  dout = net.layers['Dense_Layer'].backward(dout)
  output_file(PATH_TB + 'dense_layer/dense_layer_backward_out.txt', dout.flatten())

  dout = np.concatenate([dout, np.zeros((hid_dim-N, hid_dim))], axis=0)

  output_file(PATH_TB + 'tanh_layer/tanh_layer3_backward_in.txt', dout.flatten())
  dout = net.layers['Tanh_Layer3'].backward(dout)
  output_file(PATH_TB + 'tanh_layer/tanh_layer3_backward_out.txt', dout.flatten())

  output_file(PATH_TB + 'mix_layer/mix_layer3_backward_in.txt', dout.flatten())
  dout = net.layers['Mix_Layer3'].backward(dout)
  output_file(PATH_TB + 'mix_layer/mix_layer3_backward_out.txt', dout.flatten())
  
  dout = dout.sum(axis=1, keepdims=True)
  dout = np.concatenate([dout, np.zeros((hid_dim, hid_dim-1))], axis=1)
  
  output_file(PATH_TB + 'tanh_layer/tanh_layer2_backward_in.txt', dout.flatten())
  dout = net.layers['Tanh_Layer2'].backward(dout)
  output_file(PATH_TB + 'tanh_layer/tanh_layer2_backward_out.txt', dout.flatten())

  output_file(PATH_TB + 'mix_layer/mix_layer2_backward_in.txt', dout.flatten())
  dout = net.layers['Mix_Layer2'].backward(dout)
  output_file(PATH_TB + 'mix_layer/mix_layer2_backward_out.txt', dout.flatten())

  output_file(PATH_TB + 'tanh_layer/tanh_layer1_backward_in.txt', dout.flatten())
  dout = net.layers['Tanh_Layer1'].backward(dout)
  output_file(PATH_TB + 'tanh_layer/tanh_layer1_backward_out.txt', dout.flatten())

  output_file(PATH_TB + 'mix_layer/mix_layer1_backward_in.txt', dout.flatten())
  dout = net.layers['Mix_Layer1'].backward(dout)
  output_file(PATH_TB + 'mix_layer/mix_layer1_backward_out.txt', dout.flatten())

  dout = dout[:N, :]

  output_file(PATH_TB + 'emb_layer/emb_layer_backward_in.txt', dout.flatten())
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
  dataloader_train, _  = create_batch(batch_size)

  net = Network()
  optim = Momentum(lr=lr)

  # 学習
  print('fixed sample ver')
  print('batch_size: {:}, lr: {:}'.format(batch_size, lr))
  losses_train = []
  acc_train = 0

  # when batch_size == 2
  remove_file()
  for batch in dataloader_train[:4]:
    net.zero_grads()
    for x in batch:
      y = output_forward(x, net)
      loss = crossEntropyLoss(y, x)
      output_backward(y, x, net)
      losses_train.append(loss)
      acc_train += (y.argmax(axis=-1) == x).sum()
    optim.update(net.params, net.grads)


  # batch_size != 2
  # os.remove(PATH_TB + 'emb_layer/emb_layer_forward_in.txt')
  # os.remove(PATH_TB + 'comp_layer/comp_layer_out.txt')
  # for batch in dataloader_train[:4]:
  #   net.zero_grads()
  #   for x in batch:
  #     output_file(PATH_TB + 'emb_layer/emb_layer_forward_in.txt', x, i_len=8, f_len=0)
  #     y = net.forward(x)
  #     output_file(PATH_TB + 'comp_layer/comp_layer_out.txt', y.max(axis=-1).flatten())
  #     loss = crossEntropyLoss(y, x)
  #     net.gradient(y, x)
  #     losses_train.append(loss)
  #     acc_train += (y.argmax(axis=-1) == x).sum()
  #   optim.update(net.params, net.grads)
  

  # generate similar sample
  net = Network()
  optim = Momentum(lr=lr)
  losses_train = []
  acc_train = 0
  
  # os.remove(PATH_TB + 'generate/generate_in.txt')
  # os.remove(PATH_TB + 'generate/gen_simi_out.txt')
  # os.remove(PATH_TB + 'generate/gen_new_out.txt')
  for batch in dataloader_train[:2]:
    net.zero_grads()
    for x in batch:
      output_file(PATH_TB + 'generate/generate_in.txt', x, i_len=8, f_len=0)
      y = net.forward(x)
      output_file(PATH_TB + 'generate/gen_simi_out.txt', y.max(axis=-1).flatten())
      output_file(PATH_TB + 'generate/gen_new_out.txt',  y.max(axis=-1).flatten())
      loss = crossEntropyLoss(y, x)
      net.gradient(y, x)
      losses_train.append(loss)
      acc_train += (y.argmax(axis=-1) == x).sum()
    optim.update(net.params, net.grads)
  
  xors = XorShift(6568)
  for batch in dataloader_train[2:4]:
    for x in batch:
      output_file(PATH_TB + 'generate/generate_in.txt', x, i_len=8, f_len=0)

      # generate similar
      x = net.layers['Emb_Layer'].forward(x)
      x = np.concatenate([x, np.zeros((hid_dim-N, hid_dim))], axis=0)
      x = net.layers['Mix_Layer1'].forward(x)
      x = net.layers['Tanh_Layer1'].forward(x)
      x = net.layers['Mix_Layer2'].forward(x)
      x = net.layers['Tanh_Layer2'].forward(x)

      
      noise = np.empty((hid_dim,))
      z = np.empty((hid_dim,))
      for i in range(hid_dim):
        rand = xors()
        noise[i] = rand / 4   # generate similar
        z[i] = rand           # generate new
      noise = convert_fixed(noise)
      z = convert_fixed(z)

      x = x[:, 0] + noise
      x = np.full((hid_dim, hid_dim), x).T
      x = net.layers['Mix_Layer3'].forward(x)
      x = net.layers['Tanh_Layer3'].forward(x)
      x = x[:N, :]
      y = net.layers['Dense_Layer'].forward(x)

      output_file(PATH_TB + 'generate/gen_simi_out.txt', y.max(axis=-1).flatten())

      # generate new
      x = np.full((hid_dim, hid_dim), z).T
      x = net.layers['Mix_Layer3'].forward(x)
      x = net.layers['Tanh_Layer3'].forward(x)
      x = x[:N, :]
      y = net.layers['Dense_Layer'].forward(x)
    
      output_file(PATH_TB + 'generate/gen_new_out.txt', y.max(axis=-1).flatten())
  
  print(np.mean(losses_train), acc_train)