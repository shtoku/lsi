import numpy as np
import kmj_gen_np as kgn
import kmj_gen_sim as kgs
from layers import *
from collections import OrderedDict
np.set_printoptions(precision=10)


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


batch_size = 8      # ミニバッチサイズ
n_epochs = 10       # エポック数
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

    print('base     :', kgs.convert_str(x))
    print('generate :', kgn.convert_str(y))
  
  for _ in range(100):
    z = np.random.uniform(low=-1, high=1, size=(hid_dim, 1))
    z = convert_fixed(z)
    y = net.layers['Mix_Layer3'].forward(z)
    y = net.layers['Tanh_Layer3'].forward(y)
    y = net.layers['Dense_Layer'].forward(y)

    print('new_gen  :', kgn.convert_str(y))


# fixed ver
# batch_size: 8, lr: 0.001, i_len:8, f_len: 16
# EPOCH:   1, Train Loss: 32.71446  Acc: 0.352, Valid Loss: 27.25101  Acc: 0.423
# EPOCH:   2, Train Loss: 25.31803  Acc: 0.451, Valid Loss: 23.84107  Acc: 0.468
# EPOCH:   3, Train Loss: 22.92326  Acc: 0.489, Valid Loss: 22.01107  Acc: 0.503
# EPOCH:   4, Train Loss: 21.16168  Acc: 0.528, Valid Loss: 20.53221  Acc: 0.535
# EPOCH:   5, Train Loss: 19.74830  Acc: 0.560, Valid Loss: 19.16264  Acc: 0.569
# EPOCH:   6, Train Loss: 18.24478  Acc: 0.594, Valid Loss: 17.59392  Acc: 0.609
# EPOCH:   7, Train Loss: 16.68622  Acc: 0.627, Valid Loss: 16.08543  Acc: 0.641
# EPOCH:   8, Train Loss: 15.29247  Acc: 0.653, Valid Loss: 14.83610  Acc: 0.660
# EPOCH:   9, Train Loss: 14.18054  Acc: 0.676, Valid Loss: 13.89194  Acc: 0.680
# EPOCH:  10, Train Loss: 13.31101  Acc: 0.696, Valid Loss: 13.12636  Acc: 0.697
# base     : (　・ー́　・　)
# generate : (　・∀́　・　)
# base     : (((*。_。)
# generate : (((*)。)
# base     : (　　́_ゝ`)。。
# generate : (　　́_^`)ノ)
# base     : ヽ(*　́∀`)ノ
# generate : ♪(*　́∀`)ノ
# base     : (　△́　)
# generate : (　Д́　)
# base     : ┌(　゚Д゚)ノ
# generate : ♪(　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : _ヾ(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : ☆~ヾ(　・^̄)
# base     : (　́　゚∀　゚`)
# generate : (　̄　　́　゚　)
# base     : (゚Д゚ヾ　)
# generate : (゚゚̄　)
# base     : !(。^。)
# generate : !(。^;)
# base     : (꒪ω꒪)
# generate : (。ω≦)
# base     : (ΘoΘ)σ
# generate : (.o≦)ノ
# base     : シヾ(*　▽́　*)
# generate : ♪ヾ(*　∀́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(*　∀́　*)ノ
# base     : (__)
# generate : (-_)
# base     : (　*`ω　́)
# generate : (　(`∀　́)
# base     : ('-'*)ノ
# generate : ヾ(≧∀≦*)ノ
# base     : (-:-)
# generate : (-。-)
# base     : o(　̄ー　̄;)ゞ
# generate : o(　̄▽　̄*)
# new_gen  : ・!(()　　(!
# new_gen  : ・　̄　́̄　`̄
# new_gen  : (　̄_̄　))
# new_gen  : !!(゚(_　　　　
# new_gen  : !!^・・ー~)
# new_gen  : (*　゚_・́)~
# new_gen  : ヾ(・_・!
# new_gen  : ー　・)・^)
# new_gen  : `(^́　)♪
# new_gen  : 　*(^(*　・(
# new_gen  : ^　(_!_　
# new_gen  : ^^　・)ノ!^)
# new_gen  : ゚゚゚∀́)ノ!
# new_gen  : (・　゚()^*)
# new_gen  : !!(*_　^
# new_gen  : ・・(　　́　́)
# new_gen  : o・・・^)_
# new_gen  : 　　゚(　・　*
# new_gen  : ́(　^　)ノ)
# new_gen  : ・・_　̄ωω
# new_gen  : ・(゚　́∀・)-)
# new_gen  : (・-)　)
# new_gen  : !((*(́　!
# new_gen  : 　(　(
# new_gen  : !!*゚((^*!
# new_gen  : (^́　(　̄　)
# new_gen  : 。　゚≦)・`
# new_gen  : )́^^(・♪　!
# new_gen  : 　。~・;))
# new_gen  : ・・((・́　ノ
# new_gen  : ・・∀^・)
# new_gen  : !　・(・́^　́
# new_gen  : ヾ゚_́́*　♪!
# new_gen  : !　・・!*)))
# new_gen  : !　((((́　
# new_gen  : ω)))
# new_gen  : (*・)^　!
# new_gen  : ・∀^`　　!
# new_gen  : 　(!()　))
# new_gen  : __　(_　^)̄
# new_gen  : (・)^̄(・(̄
# new_gen  : ヾ゚()*)*
# new_gen  : ~・(・)ヾ
# new_gen  : (̄　!　)
# new_gen  : *　　́　)(　　
# new_gen  : _́　́　・)
# new_gen  : 　)・^^))゚)
# new_gen  : !o*;̄^)♪!
# new_gen  : *`((`　)!!
# new_gen  : !((^・　・　)
# new_gen  : ・　　́　`ノ・)
# new_gen  : !_)　(
# new_gen  : ()・ω)*)・・
# new_gen  : ゚((・・́)
# new_gen  : )・　　　゚̄́́　
# new_gen  : ♪　(・　((・^)
# new_gen  : !*(・)^^~
# new_gen  : )((^ノ)ノ
# new_gen  : (　・・()・
# new_gen  : `(゚^　̄)^`
# new_gen  : ♪　*　!　^
# new_gen  : (　(́　　　)
# new_gen  : ♪^(・・)́∀́
# new_gen  : (`゚`*　・́)
# new_gen  : !(*ヾ̄　́
# new_gen  : ^・・・　　　)~
# new_gen  : 　^(()ノ(
# new_gen  : ()・_　*(・^^
# new_gen  : )　`^))^)
# new_gen  : ((^　・・・)(
# new_gen  : ゚゚̄∀̄　_))
# new_gen  : )(　　　̄!
# new_gen  : ^・(・^　)
# new_gen  : ゚　・(́・　　)
# new_gen  : (*^・())♪
# new_gen  : ・　゚∀́ヾo)
# new_gen  : (゚^!(()
# new_gen  : (。o∀゚)♪~
# new_gen  : 　*゚　́∀　　_　
# new_gen  : 　^^*　)
# new_gen  : !　́　̄　　!!
# new_gen  : (-(^)
# new_gen  : (*　́∀　　)・(
# new_gen  : (゚　゚́)_・・)
# new_gen  : (^　・ωo゚・
# new_gen  : ^(*　*̄)̄
# new_gen  : ^　*̄_・　̄　・
# new_gen  : !*ノ　*)^
# new_gen  : 　・)(・́　*̄
# new_gen  : o・́　)_)()
# new_gen  : (　゚́・)・　)
# new_gen  : ^・・(゚　　　
# new_gen  : (。́▽・・　)
# new_gen  : `(・(　()̄
# new_gen  : (*_(**　~)!
# new_gen  : ・_　・*　・・
# new_gen  : !　・　　_^́　
# new_gen  : )　(゚(　　^̄(
# new_gen  : ・　　)̄　)
# new_gen  : ^)́　^　́́́́