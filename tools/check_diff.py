import numpy as np
import kmj_gen_np as kgn
import kmj_gen_np_train as kgnt
import kmj_gen_train as kgt

np.set_printoptions(precision=10)

batch_size = 8
lr = 1e-3

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

# dataloader_train.append(dataset_train[n_train*batch_size:])
# dataloader_valid.append(dataset_valid[n_valid*batch_size:])

# モデルの定義
kgnt_net = kgnt.Network()
kgnt_optim = kgnt.Momentum(lr=lr)
kgt_net = kgt.Network()
kgt_optim = kgt.Momentum(lr=lr)

for i, batch in enumerate(dataloader_train[:10]):
  kgnt_y = kgnt_net.forward(batch)
  kgnt_grads = kgnt_net.gradient(kgnt_y, batch)
  kgnt_optim.update(kgnt_net.params, kgnt_grads)

  kgt_net.zero_grads()
  for j, x in enumerate(batch):
    kgt_y = kgt_net.forward(x)
    kgt_net.gradient(kgt_y, x)

    diff_y = np.abs(kgnt_y[j] - kgt_y)
    if diff_y.max() > 1e-3:
      print('y diff max:', diff_y.max(), i)
  
  kgt_optim.update(kgt_net.params, kgt_net.grads)

  for key in kgnt_grads.keys():
    diff_grad = np.abs(kgnt_grads[key] - kgt_net.grads[key])
    if diff_grad.max() > 1e-3:
      print(key, 'grad diff max:', diff_grad.max(), i)
    
    diff_param = np.abs(kgnt_net.params[key] - kgt_net.params[key])
    if diff_param.max() > 1e-3:
      print(key, 'param diff max:', diff_param.max(), i)
