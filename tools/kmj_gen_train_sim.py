import numpy as np
import kmj_gen_np as kgn
from kmj_gen_train import Network
from layers import Momentum, crossEntropyLoss, i_len, f_len


PATH_TB = '../data/tb/train/'


batch_size = 8      # ミニバッチサイズ
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
def output_file(filename, x, i_len=i_len, f_len=f_len):
  with open(filename, 'w') as file:
    for value in x:
      temp = convert_fixed2(value, i_len, f_len)
      file.write(temp + '\n')


# 順伝播の入出力サンプルを作成する関数
def output_forward(x, net):
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_in.txt', x, i_len=8, f_len=0)
  x = net.layers['Emb_Layer'].forward(x)
  output_file(PATH_TB + 'emb_layer/emb_layer_forward_out.txt', x.flatten(), i_len=2, f_len=16)
  x = net.layers['Mix_Layer1'].forward(x)
  x = net.layers['Tanh_Layer1'].forward(x)
  x = net.layers['Mix_Layer2'].forward(x)
  x = net.layers['Tanh_Layer2'].forward(x)
  x = net.layers['Mix_Layer3'].forward(x)
  x = net.layers['Tanh_Layer3'].forward(x)
  x = net.layers['Dense_Layer'].forward(x)

  return x


if __name__ == '__main__':
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
    net.gradient(y, x)
    losses_train.append(loss)
    acc_train += (y.argmax(axis=-1) == x).sum()
  
  optim.update(net.params, net.grads)
  print(loss, acc_train)


# fixed sample ver
# batch_size: 8, lr: 0.001
# 52.99134826660156 0