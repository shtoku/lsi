import numpy as np
import kmj_gen_np as kgn
import kmj_gen_sim as kgs
from layers import *
from collections import OrderedDict
np.set_printoptions(precision=10)


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 72       # 文字種数
emb_dim = 12        # 文字ベクトルの次元
hid_dim = 12        # 潜在ベクトルの次元


batch_size = 2      # ミニバッチサイズ
n_epochs = 35       # エポック数
lr = 1e-3           # 学習率


class Network:
  def __init__(self):
    self.params = {}
    self.params['W_emb'] = convert_fixed(kgn.read_param(PATH_DEC + 'emb_layer_W_emb.txt').reshape(char_num, emb_dim))

    W_1 = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_1.txt').reshape(emb_dim, N, hid_dim))
    self.params['W_1'] = np.concatenate([W_1, np.zeros((hid_dim, hid_dim-N, hid_dim))], axis=1)
    self.params['b_1'] = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_1.txt').reshape(emb_dim, hid_dim))

    W_2 = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_2.txt').reshape(hid_dim, emb_dim, 1))
    self.params['W_2'] = np.concatenate([W_2, np.zeros((hid_dim, hid_dim, hid_dim-1))], axis=2)
    b_2 = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_2.txt').reshape(hid_dim, 1))
    self.params['b_2'] = np.concatenate([b_2, np.zeros((hid_dim, hid_dim-1))], axis=1)

    W_3 = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_W_3.txt').reshape(N, hid_dim, hid_dim))
    self.params['W_3'] = np.concatenate([W_3, np.zeros((hid_dim-N, hid_dim, hid_dim))], axis=0)
    b_3 = convert_fixed(kgn.read_param(PATH_DEC + 'mix_layer_b_3.txt').reshape(N, hid_dim))
    self.params['b_3'] = np.concatenate([b_3, np.zeros((hid_dim-N, hid_dim))], axis=0)

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
    x = self.layers['Emb_Layer'].forward(x)
    x = np.concatenate([x, np.zeros((hid_dim-N, hid_dim))], axis=0)
    x = self.layers['Mix_Layer1'].forward(x)
    x = self.layers['Tanh_Layer1'].forward(x)
    x = self.layers['Mix_Layer2'].forward(x)
    x = self.layers['Tanh_Layer2'].forward(x)
    x = np.full((hid_dim, hid_dim), x[:, 0]).T
    x = self.layers['Mix_Layer3'].forward(x)
    x = self.layers['Tanh_Layer3'].forward(x)
    x = x[:N, :]
    x = self.layers['Dense_Layer'].forward(x)
    
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
    y[range(len(y)), t] -= 1.0
    dout = convert_fixed(y / batch_size)

    dout = self.layers['Dense_Layer'].backward(dout)
    dout = np.concatenate([dout, np.zeros((hid_dim-N, hid_dim))], axis=0)
    dout = self.layers['Tanh_Layer3'].backward(dout)
    dout = self.layers['Mix_Layer3'].backward(dout)
    dout = dout.sum(axis=1, keepdims=True)
    dout = np.concatenate([dout, np.zeros((hid_dim, hid_dim-1))], axis=1)
    dout = self.layers['Tanh_Layer2'].backward(dout)
    dout = self.layers['Mix_Layer2'].backward(dout)
    dout = self.layers['Tanh_Layer1'].backward(dout)
    dout = self.layers['Mix_Layer1'].backward(dout)
    dout = dout[:N, :]
    dout = self.layers['Emb_Layer'].backward(dout)
    
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
  
  # dataloader_train.append(dataset_train[n_train*batch_size:])
  # dataloader_valid.append(dataset_valid[n_valid*batch_size:])

  # モデルの定義
  net = Network()
  optim = Momentum(lr=lr)

  # 学習
  print('fixed ver')
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
        acc_train += (y.argmax(axis=-1) == x).sum()
      
      optim.update(net.params, net.grads)
    
    for batch in dataloader_valid:
      net.zero_grads()
      for x in batch:
        y = net.forward(x)
        loss = crossEntropyLoss(y, x)
        losses_valid.append(loss)
        acc_valid += (y.argmax(axis=-1) == x).sum()    
      
    if (epoch+1) % 1 == 0:
      print('EPOCH: {:>3}, Train Loss: {:>8.5f}  Acc: {:>.3f}, Valid Loss: {:>8.5f}  Acc: {:>.3f}'.format(
          epoch+1,
          np.mean(losses_train),
          acc_train / (train_size * N),
          np.mean(losses_valid),
          acc_valid / (valid_size * N)
      ))
  

  # テスト
  for x in dataset_test[:20]:
    y = net.forward(x)
    x = (range(char_num) == x.reshape(N, 1))

    print('base     :', kgn.convert_str(x))
    print('generate :', kgn.convert_str(y))
  
  for _ in range(100):
    z = np.random.uniform(low=-1, high=1, size=(hid_dim, 1))
    z = convert_fixed(z)
    y = net.layers['Mix_Layer3'].forward(z)
    y = net.layers['Tanh_Layer3'].forward(y)
    y = net.layers['Dense_Layer'].forward(y)

    print('new_gen  :', kgn.convert_str(y))


# fixed ver
# batch_size: 32, lr: 0.001, i_len:8, f_len: 16
# EPOCH:   1, Train Loss: 35.83966  Acc: 0.237, Valid Loss: 28.93384  Acc: 0.332
# EPOCH:   2, Train Loss: 27.77369  Acc: 0.343, Valid Loss: 26.86635  Acc: 0.361
# EPOCH:   3, Train Loss: 25.90408  Acc: 0.384, Valid Loss: 25.37519  Acc: 0.394
# EPOCH:   4, Train Loss: 24.79449  Acc: 0.411, Valid Loss: 24.48075  Acc: 0.416
# EPOCH:   5, Train Loss: 23.85992  Acc: 0.432, Valid Loss: 23.54161  Acc: 0.440
# EPOCH:   6, Train Loss: 22.92613  Acc: 0.453, Valid Loss: 22.66697  Acc: 0.456
# EPOCH:   7, Train Loss: 22.16878  Acc: 0.467, Valid Loss: 22.01457  Acc: 0.467
# EPOCH:   8, Train Loss: 21.60576  Acc: 0.476, Valid Loss: 21.52983  Acc: 0.473
# EPOCH:   9, Train Loss: 21.17331  Acc: 0.483, Valid Loss: 21.13464  Acc: 0.479
# EPOCH:  10, Train Loss: 20.81265  Acc: 0.489, Valid Loss: 20.78402  Acc: 0.487
# EPOCH:  11, Train Loss: 20.46899  Acc: 0.497, Valid Loss: 20.43951  Acc: 0.494
# EPOCH:  12, Train Loss: 20.11560  Acc: 0.506, Valid Loss: 20.07807  Acc: 0.502
# EPOCH:  13, Train Loss: 19.73894  Acc: 0.515, Valid Loss: 19.70425  Acc: 0.513
# EPOCH:  14, Train Loss: 19.35395  Acc: 0.526, Valid Loss: 19.34202  Acc: 0.521
# EPOCH:  15, Train Loss: 18.98958  Acc: 0.535, Valid Loss: 19.00413  Acc: 0.530
# EPOCH:  16, Train Loss: 18.65958  Acc: 0.543, Valid Loss: 18.70455  Acc: 0.538
# EPOCH:  17, Train Loss: 18.36001  Acc: 0.551, Valid Loss: 18.42200  Acc: 0.546
# EPOCH:  18, Train Loss: 18.08226  Acc: 0.558, Valid Loss: 18.15447  Acc: 0.554
# EPOCH:  19, Train Loss: 17.81355  Acc: 0.565, Valid Loss: 17.89731  Acc: 0.560
# EPOCH:  20, Train Loss: 17.55880  Acc: 0.573, Valid Loss: 17.65107  Acc: 0.566
# EPOCH:  21, Train Loss: 17.30876  Acc: 0.579, Valid Loss: 17.41484  Acc: 0.572
# EPOCH:  22, Train Loss: 17.06669  Acc: 0.585, Valid Loss: 17.18635  Acc: 0.579
# EPOCH:  23, Train Loss: 16.83463  Acc: 0.590, Valid Loss: 16.95788  Acc: 0.583
# EPOCH:  24, Train Loss: 16.60815  Acc: 0.594, Valid Loss: 16.74205  Acc: 0.587
# EPOCH:  25, Train Loss: 16.39556  Acc: 0.598, Valid Loss: 16.53649  Acc: 0.590
# EPOCH:  26, Train Loss: 16.19171  Acc: 0.601, Valid Loss: 16.33834  Acc: 0.594
# EPOCH:  27, Train Loss: 16.00071  Acc: 0.605, Valid Loss: 16.15114  Acc: 0.597
# EPOCH:  28, Train Loss: 15.82245  Acc: 0.609, Valid Loss: 15.97905  Acc: 0.601
# EPOCH:  29, Train Loss: 15.65240  Acc: 0.612, Valid Loss: 15.81894  Acc: 0.605
# EPOCH:  30, Train Loss: 15.49507  Acc: 0.615, Valid Loss: 15.66519  Acc: 0.609
# EPOCH:  31, Train Loss: 15.34323  Acc: 0.618, Valid Loss: 15.51692  Acc: 0.612
# EPOCH:  32, Train Loss: 15.19907  Acc: 0.621, Valid Loss: 15.37692  Acc: 0.614
# EPOCH:  33, Train Loss: 15.06325  Acc: 0.625, Valid Loss: 15.24350  Acc: 0.618
# EPOCH:  34, Train Loss: 14.93149  Acc: 0.628, Valid Loss: 15.11154  Acc: 0.620
# EPOCH:  35, Train Loss: 14.80625  Acc: 0.631, Valid Loss: 14.99198  Acc: 0.623
# base     : (　・ー́　・　)
# generate : (　・ω　　　)
# base     : (((*。_。)
# generate : ((゚ω　)
# base     : (　　́_ゝ`)。。
# generate : (　　́`*)!
# base     : ヽ(*　́∀`)ノ
# generate : ヾ(*　∀`*)
# base     : (　́　)
# generate : (　́　)
# base     : (　゚Д゚)ノ
# generate : (　^゚́)
# base     : _/(゚Д゚　)
# generate : !ヾ(゚_゚　)
# base     : ||ヾ(　・ω|　
# generate : !!(・-^^*
# base     : (　́　゚∀　゚`)
# generate : (　　　　`　̄))
# base     : (゚Д゚ヾ　)
# generate : (*́-́　)
# base     : !(。^。)
# generate : ヾ(・^_)
# base     : (ω)
# generate : ()
# base     : (o)σ
# generate : (^)!
# base     : ヾ(*　▽́　*)
# generate : ヾ(　　`́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : !(*　́́　))
# base     : (__)
# generate : (　_)
# base     : (　*`ω　́)
# generate : (　́)　*)
# base     : ('-'*)ノ
# generate : (^-^*)
# base     : (-:-)
# generate : (^-^)
# base     : o(　̄ー　̄;)ゞ
# generate : (　　́　̄　)
# new_gen  : (　)
# new_gen  : (・・)　
# new_gen  : 　(　)
# new_gen  : *((()(　
# new_gen  : (　́　)・
# new_gen  : (　　
# new_gen  : ((　　)・)
# new_gen  : !(*(^・　̄)
# new_gen  : ヾ(*゚-・　　))
# new_gen  : 　(()()(
# new_gen  : 　^(^　
# new_gen  : (**^)^)
# new_gen  : (　^^()
# new_gen  : *(((　-　
# new_gen  : ((　ω)　̄
# new_gen  : ()́　)ノ
# new_gen  : ヾ　̄)
# new_gen  : *)*(
# new_gen  : (**()・^*`
# new_gen  : (　^^)
# new_gen  : (-・)ノ・・`
# new_gen  : (゚-・*)・)
# new_gen  : (*^(^・^)`
# new_gen  : !!・^^^)・)
# new_gen  : (・・)
# new_gen  : 　(()　)
# new_gen  : ヾ(*^^́　))
# new_gen  : (*()(
# new_gen  : (́ω)
# new_gen  : (*)　)(()
# new_gen  : (!(　)
# new_gen  : *(・^　
# new_gen  : (^()))!!
# new_gen  : )(^　))
# new_gen  : ^**^^^
# new_gen  : (　(　̄
# new_gen  : ヾ(^ω^́・)
# new_gen  : (*ω^--)
# new_gen  : (・^-)・・~~!
# new_gen  : *((́　́)
# new_gen  : !(!^^-・・
# new_gen  : 　^́　))()
# new_gen  : ^((
# new_gen  : (^)・)^
# new_gen  : ヾ(・　
# new_gen  : ((*　^̄*)ノ!
# new_gen  : !(・ω　(
# new_gen  : 　()(　)
# new_gen  : (　　゚)　　
# new_gen  : ́　^^^・
# new_gen  : (^))
# new_gen  : (*(ω　　)
# new_gen  : ((　́)
# new_gen  : ((　()
# new_gen  : (^ω^)!
# new_gen  : ノ(!(((
# new_gen  : (　ω　́
# new_gen  : (*　　　　*)
# new_gen  : 　)()()・(
# new_gen  : (　　　)))
# new_gen  : (　　　)　　)*)
# new_gen  : ノ(・・・
# new_gen  : )(^(^・́)
# new_gen  : (!)
# new_gen  : (--(^・)ノ!
# new_gen  : !(*^-・　　)
# new_gen  : 　　)^)・)
# new_gen  : (　　　　　
# new_gen  : (*^ω　))
# new_gen  : !!((・ω　)*
# new_gen  : (　^ω　*　))
# new_gen  : (　　　)(́　　)
# new_gen  : (^`・)・)ノ
# new_gen  : (*　́　`)
# new_gen  : (;)))
# new_gen  : (　　^・́　)
# new_gen  : ・(　́)
# new_gen  : !ヾ(・・-)ノ
# new_gen  : (*́́　)ノ
# new_gen  : *(!!
# new_gen  : (*^)!
# new_gen  : 　^)　　()
# new_gen  : (　)
# new_gen  : ヾ　`^　^^))
# new_gen  : !*(^^^
# new_gen  : !(!ω　))
# new_gen  : ・^́　
# new_gen  : (・^-!
# new_gen  : !((　́*)
# new_gen  : ((　　　)
# new_gen  : (*　^　))
# new_gen  : (*　()　`*)
# new_gen  : !(・́　)・
# new_gen  : (*ヾ・)・
# new_gen  : (^(^)　)
# new_gen  : ヾ*　́　)
# new_gen  : (　*^)　)
# new_gen  : (*(-(　
# new_gen  : (　))(
# new_gen  : !(^(^́　　)