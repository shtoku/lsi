import numpy as np
import kmj_gen_np as kgn
from layers_np import *
from collections import OrderedDict


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 72       # 文字種数
emb_dim = 12        # 文字ベクトルの次元
hid_dim = 12        # 潜在ベクトルの次元



batch_size = 32     # ミニバッチサイズ
n_epochs = 20       # エポック数
lr = 1e-3           # 学習率


class Network:
  def __init__(self):
    self.params = {}
    self.params['W_emb'] = kgn.read_param(PATH_DEC + 'emb_layer_W_emb.txt').reshape(char_num, emb_dim)
    self.params['W_1'] = kgn.read_param(PATH_DEC + 'mix_layer_W_1.txt').reshape(emb_dim, N, hid_dim)
    self.params['b_1'] = kgn.read_param(PATH_DEC + 'mix_layer_b_1.txt').reshape(emb_dim, 1, hid_dim)
    self.params['W_2'] = kgn.read_param(PATH_DEC + 'mix_layer_W_2.txt').reshape(hid_dim, emb_dim, 1)
    self.params['b_2'] = kgn.read_param(PATH_DEC + 'mix_layer_b_2.txt').reshape(hid_dim, 1, 1)
    self.params['W_3'] = kgn.read_param(PATH_DEC + 'mix_layer_W_3.txt').reshape(N, hid_dim, hid_dim)
    self.params['b_3'] = kgn.read_param(PATH_DEC + 'mix_layer_b_3.txt').reshape(N, 1, hid_dim)
    self.params['W_out'] = kgn.read_param(PATH_DEC + 'dense_layer_W_out.txt').reshape(hid_dim, char_num)

    # self.params['W_emb'] = np.random.uniform(
    #                          low=-np.sqrt(6 / (char_num + emb_dim)),
    #                          high=np.sqrt(6 / (char_num + emb_dim)),
    #                          size=(char_num, emb_dim)
    #                        )
    
    # self.params['W_1'] = np.random.uniform(
    #                        low=-np.sqrt(6 / (N + hid_dim)),
    #                        high=np.sqrt(6 / (N + hid_dim)),
    #                        size=(emb_dim, N, hid_dim)
    #                      )
    # self.params['b_1'] = np.zeros((emb_dim, 1, hid_dim))

    # self.params['W_2'] = np.random.uniform(
    #                        low=-np.sqrt(6 / (emb_dim + 1)),
    #                        high=np.sqrt(6 / (emb_dim + 1)),
    #                        size=(hid_dim, emb_dim, 1)
    #                      )
    # self.params['b_2'] = np.zeros((hid_dim, 1, 1))

    # self.params['W_3'] = np.random.uniform(
    #                        low=-np.sqrt(6 / (hid_dim + N)),
    #                        high=np.sqrt(6 / (hid_dim + N)),
    #                        size=(N, hid_dim, hid_dim)
    #                      )
    # self.params['b_3'] = np.zeros((N, 1, hid_dim))

    # self.params['W_out'] = np.random.uniform(
    #                          low=-np.sqrt(6 / (hid_dim + char_num)),
    #                          high=np.sqrt(6 / (hid_dim + char_num)),
    #                          size=(hid_dim, char_num)
    #                        )

    self.layers = OrderedDict()
    self.layers['Emb_Layer'] = Emb_Layer(self.params['W_emb'])
    self.layers['Mix_Layer1'] = Mix_Layer(self.params['W_1'], self.params['b_1'])
    self.layers['Tanh_Layer1'] = Tanh_Layer()
    self.layers['Mix_Layer2'] = Mix_Layer(self.params['W_2'], self.params['b_2'])
    self.layers['Tanh_Layer2'] = Tanh_Layer()
    self.layers['Mix_Layer3'] = Mix_Layer(self.params['W_3'], self.params['b_3'], is_hid=True)
    self.layers['Tanh_Layer3'] = Tanh_Layer()
    self.layers['Dense_Layer'] = Dense_Layer(self.params['W_out'])
  
  def forward(self, x):
    for key, layer in self.layers.items():
      x = layer.forward(x)
      if x.max() > 2**(i_len-1) or x.min() < -2**(i_len-1):
        print(x.max(), x.min(), key)
    
    return x

  def gradient(self, y, t):
    # Softmax
    y = y - np.max(y, axis=-1, keepdims=True)   # オーバーフロー対策
    y =  np.exp(y) / np.sum(np.exp(y), axis=-1, keepdims=True)
    dout = (y - t) / y.shape[0]

    layers = list(self.layers.items())
    layers.reverse()
    for key, layer in layers:
      dout = layer.backward(dout)
      if dout.max() > 2**(i_len-1) or dout.min() < -2**(i_len-1):
        print(dout.max(), dout.min(), key)
    
    grads = {}
    grads['W_emb'] = self.layers['Emb_Layer'].dW

    grads['W_1'] = self.layers['Mix_Layer1'].dW
    grads['b_1'] = self.layers['Mix_Layer1'].db
    grads['W_2'] = self.layers['Mix_Layer2'].dW
    grads['b_2'] = self.layers['Mix_Layer2'].db
    grads['W_3'] = self.layers['Mix_Layer3'].dW
    grads['b_3'] = self.layers['Mix_Layer3'].db
    
    grads['W_out'] = self.layers['Dense_Layer'].dW

    return grads   



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
  
  # dataloader_train.append(dataset_train[n_train*batch_size:])
  # dataloader_valid.append(dataset_valid[n_valid*batch_size:])

  # モデルの定義
  net = Network()
  softmax = Softmax_Layer()
  optim = Momentum(lr=lr)

  # 学習
  print('float ver')
  print('batch_size: {:}, lr: {:}, i_len:{:}'.format(batch_size, lr, i_len))
  for epoch in range(n_epochs):
    losses_train = []
    losses_valid = []
    acc_train = 0
    acc_valid = 0

    for x in dataloader_train:
      y = net.forward(x)
      loss = softmax.forward(y, x)
      grads = net.gradient(y, x)
      
      optim.update(net.params, grads)
      
      losses_train.append(loss)
      acc_train += (y.argmax(axis=-1) == x.argmax(axis=-1)).sum()
    
    for x in dataloader_valid:
      y = net.forward(x)
      loss = softmax.forward(y, x)
      
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
  

  # テスト
  for x in dataset_test[:20]:
    x = np.expand_dims(x, axis=0)
    y = net.forward(x)

    print('base     :', kgn.convert_str(x[0]))
    print('generate :', kgn.convert_str(y[0]))
  
  for _ in range(100):
    z = np.random.uniform(low=-1, high=1, size=(1, hid_dim, 1))
    y = net.layers['Mix_Layer3'].forward(z)
    y = net.layers['Tanh_Layer3'].forward(y)
    y = net.layers['Dense_Layer'].forward(y)

    print('new_gen  :', kgn.convert_str(y[0]))


# float ver
# batch_size: 32, lr: 0.001, i_len:8
# EPOCH:   1, Train Loss: 35.71628  Acc: 0.236, Valid Loss: 29.14088  Acc: 0.334
# EPOCH:   2, Train Loss: 27.92831  Acc: 0.345, Valid Loss: 26.88671  Acc: 0.373
# EPOCH:   3, Train Loss: 25.94903  Acc: 0.396, Valid Loss: 25.42030  Acc: 0.408
# EPOCH:   4, Train Loss: 24.78276  Acc: 0.424, Valid Loss: 24.35855  Acc: 0.432
# EPOCH:   5, Train Loss: 23.66027  Acc: 0.447, Valid Loss: 23.17865  Acc: 0.454
# EPOCH:   6, Train Loss: 22.57292  Acc: 0.471, Valid Loss: 22.17912  Acc: 0.475
# EPOCH:   7, Train Loss: 21.69875  Acc: 0.487, Valid Loss: 21.40326  Acc: 0.488
# EPOCH:   8, Train Loss: 21.00769  Acc: 0.499, Valid Loss: 20.78649  Acc: 0.499
# EPOCH:   9, Train Loss: 20.41628  Acc: 0.511, Valid Loss: 20.24228  Acc: 0.511
# EPOCH:  10, Train Loss: 19.87379  Acc: 0.522, Valid Loss: 19.74805  Acc: 0.521
# EPOCH:  11, Train Loss: 19.38288  Acc: 0.530, Valid Loss: 19.30690  Acc: 0.528
# EPOCH:  12, Train Loss: 18.94537  Acc: 0.537, Valid Loss: 18.90922  Acc: 0.535
# EPOCH:  13, Train Loss: 18.54953  Acc: 0.544, Valid Loss: 18.54322  Acc: 0.542
# EPOCH:  14, Train Loss: 18.18408  Acc: 0.549, Valid Loss: 18.20133  Acc: 0.549
# EPOCH:  15, Train Loss: 17.84080  Acc: 0.555, Valid Loss: 17.87744  Acc: 0.555
# EPOCH:  16, Train Loss: 17.51401  Acc: 0.563, Valid Loss: 17.56712  Acc: 0.559
# EPOCH:  17, Train Loss: 17.20117  Acc: 0.569, Valid Loss: 17.26898  Acc: 0.565
# EPOCH:  18, Train Loss: 16.90201  Acc: 0.575, Valid Loss: 16.98355  Acc: 0.570
# EPOCH:  19, Train Loss: 16.61640  Acc: 0.581, Valid Loss: 16.71143  Acc: 0.578
# EPOCH:  20, Train Loss: 16.34398  Acc: 0.587, Valid Loss: 16.45315  Acc: 0.583
# base     : (　・ー́　・　)
# generate : (　　　・　　　)
# base     : (((*。_。)
# generate : ヾ((^)
# base     : (　　́_ゝ`)。。
# generate : (　　　゚`　)!
# base     : ヽ(*　́∀`)ノ
# generate : !(*　^́　)!
# base     : (　́　)
# generate : (　́　)
# base     : (　゚Д゚)ノ
# generate : (　^　　)!
# base     : _/(゚Д゚　)
# generate : ヾヾ(　　́　)
# base     : ||ヾ(　・ω|　
# generate : !!ヾ(　́^)　
# base     : (　́　゚∀　゚`)
# generate : (　　　　́　　))
# base     : (゚Д゚ヾ　)
# generate : (*(^(　)
# base     : !(。^。)
# generate : !(・^・)
# base     : (ω)
# generate : (_)
# base     : (o)σ
# generate : (　)!
# base     : ヾ(*　▽́　*)
# generate : (　　́́　　)
# base     : ヾ(=　▽́　=)ヽ
# generate : !(　　ώ　*)
# base     : (__)
# generate : (*^)
# base     : (　*`ω　́)
# generate : (　　　́　*)
# base     : ('-'*)ノ
# generate : (　^^*)
# base     : (-:-)
# generate : (^∀^)
# base     : o(　̄ー　̄;)ゞ
# generate : !(　　́　　　))
# new_gen  : 　　　　^)　
# new_gen  : ())))(́()
# new_gen  : (()(　))
# new_gen  : ((　　)　　*
# new_gen  : (　　　　)
# new_gen  : (*∀^))
# new_gen  : (((́))
# new_gen  : (*))()
# new_gen  : ())))()
# new_gen  : ())　))
# new_gen  : ((　))))(
# new_gen  : (^(　　(　　
# new_gen  : )((　(ヾ̄
# new_gen  : !(　()())
# new_gen  : !ヾ　(　　　　)ノ
# new_gen  : ^)((()
# new_gen  : ()
# new_gen  : (()^)))(ヾ
# new_gen  : (^^　))(
# new_gen  : ((^^^(**
# new_gen  : (())^))(
# new_gen  : )((
# new_gen  : 　)
# new_gen  : (()))
# new_gen  : ()))
# new_gen  : (　　　(　()
# new_gen  : 　　(　`　
# new_gen  : !((　∀)　)
# new_gen  : !(　　́^)　)
# new_gen  : (　　　∀`)
# new_gen  : )(^　(
# new_gen  : *　(　　)(
# new_gen  : ★()))()
# new_gen  : (*́・)　))
# new_gen  : (　(^`)ノ(
# new_gen  : (　́　́`)!
# new_gen  : ()()(　
# new_gen  : ^)*))(ヾ
# new_gen  : 　(*())　!
# new_gen  : !ヾ　　ώ　・)
# new_gen  : ((　))))
# new_gen  : (ε^)!
# new_gen  : ヾ())()(ヾ
# new_gen  : (()))
# new_gen  : ((　(　))
# new_gen  : )(((　(^^)
# new_gen  : (　)　)
# new_gen  : (())
# new_gen  : `ε^^)
# new_gen  : (^　^()()
# new_gen  : !　　()　)
# new_gen  : (^　゚)ノ!
# new_gen  : )((▽(́́
# new_gen  : ((　　　)　)
# new_gen  : (　　　`)
# new_gen  : !(((　・)ノ
# new_gen  : (　)　)
# new_gen  : !!((　()
# new_gen  : !((^　)
# new_gen  : (()))(
# new_gen  : ((^))(
# new_gen  : ()(((
# new_gen  : (　　()(　・)
# new_gen  : ()(　　))
# new_gen  : !()(
# new_gen  : !)((́・)
# new_gen  : ())*)
# new_gen  : (　()()
# new_gen  : !!((　́　*!
# new_gen  : !(*(^́　)
# new_gen  : ヾ((()
# new_gen  : ((　(　)*
# new_gen  : (・^^)　
# new_gen  : ()▽　))(
# new_gen  : (・　　)　*)
# new_gen  : 　(　　)　
# new_gen  : ())
# new_gen  : ()()((-　)
# new_gen  : ((^))(
# new_gen  : (*　-`)!
# new_gen  : (　　^)
# new_gen  : ♪ヾ^)*
# new_gen  : ^()(ヾ
# new_gen  : ヾ(^)　))(
# new_gen  : (　^　)
# new_gen  : )(　　))　)
# new_gen  : ()
# new_gen  : (・・　))
# new_gen  : (()*)
# new_gen  : )((*)(ヾ_
# new_gen  : (ノ)
# new_gen  : ((　^゚　
# new_gen  : ()
# new_gen  : (　))
# new_gen  : (*・-*
# new_gen  : ()
# new_gen  : !ヾ(^(^)()
# new_gen  : )(　(　!
# new_gen  : (　(・(
# new_gen  : (())　