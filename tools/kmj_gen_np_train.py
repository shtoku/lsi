import numpy as np
import kmj_gen_np as kgn
from layers import *
from collections import OrderedDict


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元



batch_size = 256    # ミニバッチサイズ
n_epochs = 100      # エポック数
lr = 5e-4           # 学習率


class Network:
  def __init__(self):
    self.params = {}

    self.params['W_emb'] = np.random.uniform(
                             low=-np.sqrt(6 / (char_num + emb_dim)),
                             high=np.sqrt(6 / (char_num + emb_dim)),
                             size=(char_num, emb_dim)
                           )
    
    self.params['W_1'] = np.random.uniform(
                           low=-np.sqrt(6 / (N + hid_dim)),
                           high=np.sqrt(6 / (N + hid_dim)),
                           size=(emb_dim, N, hid_dim)
                         )
    self.params['b_1'] = np.zeros((emb_dim, 1, hid_dim))

    self.params['W_2'] = np.random.uniform(
                           low=-np.sqrt(6 / (emb_dim + 1)),
                           high=np.sqrt(6 / (emb_dim + 1)),
                           size=(hid_dim, emb_dim, 1)
                         )
    self.params['b_2'] = np.zeros((hid_dim, 1, 1))

    self.params['W_3'] = np.random.uniform(
                           low=-np.sqrt(6 / (hid_dim + N)),
                           high=np.sqrt(6 / (hid_dim + N)),
                           size=(N, hid_dim, hid_dim)
                         )
    self.params['b_3'] = np.zeros((N, 1, hid_dim))

    self.params['W_out'] = np.random.uniform(
                             low=-np.sqrt(6 / (hid_dim + char_num)),
                             high=np.sqrt(6 / (hid_dim + char_num)),
                             size=(hid_dim, char_num)
                           )

    self.layers = OrderedDict()
    self.layers['Emb_Layer'] = Emb_Layer(self.params['W_emb'])
    self.layers['Mix_Layer1'] = Mix_Layer(self.params['W_1'], self.params['b_1'])
    self.layers['Mix_Layer2'] = Mix_Layer(self.params['W_2'], self.params['b_2'])
    self.layers['Mix_Layer3'] = Mix_Layer(self.params['W_3'], self.params['b_3'], is_hid=True)
    self.layers['Dense_Layer'] = Dense_Layer(self.params['W_out'])
  
  def forward(self, x):
    for layer in self.layers.values():
      x = layer.forward(x)
    
    return x

  def gradient(self, y, t):
    # Softmax
    y = y - np.max(y, axis=-1, keepdims=True)   # オーバーフロー対策
    y =  np.exp(y) / np.sum(np.exp(y), axis=-1, keepdims=True)
    dout = (y - t) / y.shape[0]

    layers = list(self.layers.values())
    layers.reverse()
    for layer in layers:
      dout = layer.backward(dout)
    
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
  
  dataloader_train.append(dataset_train[n_train*batch_size:])
  dataloader_valid.append(dataset_valid[n_valid*batch_size:])

  # モデルの定義
  net = Network()
  softmax = Softmax_Layer()
  optim = Adam(lr=lr)

  # 学習
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
    
      
    if (epoch+1) % 5 == 0:
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
  
  for _ in range(20):
    z = np.random.uniform(low=-5, high=5, size=(1, hid_dim, 1))
    y = net.layers['Mix_Layer3'].forward(z)
    y = net.layers['Dense_Layer'].forward(y)

    print('new_gen  :', kgn.convert_str(y[0]))


# 2023/12/03
# EPOCH:   5, Train Loss: 30.21795  Acc: 0.343, Valid Loss: 30.67166  Acc: 0.353
# EPOCH:  10, Train Loss: 26.84537  Acc: 0.425, Valid Loss: 27.30762  Acc: 0.435
# EPOCH:  15, Train Loss: 22.55685  Acc: 0.500, Valid Loss: 23.05981  Acc: 0.505
# EPOCH:  20, Train Loss: 18.47162  Acc: 0.589, Valid Loss: 18.95856  Acc: 0.593
# EPOCH:  25, Train Loss: 14.68891  Acc: 0.675, Valid Loss: 15.36898  Acc: 0.679
# EPOCH:  30, Train Loss: 11.95858  Acc: 0.729, Valid Loss: 12.86160  Acc: 0.729
# EPOCH:  35, Train Loss: 10.04198  Acc: 0.766, Valid Loss: 11.13331  Acc: 0.764
# EPOCH:  40, Train Loss:  8.63234  Acc: 0.794, Valid Loss:  9.91007  Acc: 0.789
# EPOCH:  45, Train Loss:  7.58643  Acc: 0.814, Valid Loss:  9.03597  Acc: 0.806
# EPOCH:  50, Train Loss:  6.79483  Acc: 0.829, Valid Loss:  8.37386  Acc: 0.818
# EPOCH:  55, Train Loss:  6.17571  Acc: 0.842, Valid Loss:  7.83936  Acc: 0.827
# EPOCH:  60, Train Loss:  5.67482  Acc: 0.852, Valid Loss:  7.39113  Acc: 0.835
# EPOCH:  65, Train Loss:  5.25601  Acc: 0.861, Valid Loss:  7.00758  Acc: 0.842
# EPOCH:  70, Train Loss:  4.89455  Acc: 0.870, Valid Loss:  6.67516  Acc: 0.847
# EPOCH:  75, Train Loss:  4.57356  Acc: 0.878, Valid Loss:  6.38305  Acc: 0.854
# EPOCH:  80, Train Loss:  4.28268  Acc: 0.885, Valid Loss:  6.12164  Acc: 0.860
# EPOCH:  85, Train Loss:  4.01648  Acc: 0.891, Valid Loss:  5.88292  Acc: 0.866
# EPOCH:  90, Train Loss:  3.77100  Acc: 0.898, Valid Loss:  5.66221  Acc: 0.871
# EPOCH:  95, Train Loss:  3.54273  Acc: 0.904, Valid Loss:  5.45863  Acc: 0.876
# EPOCH: 100, Train Loss:  3.32911  Acc: 0.910, Valid Loss:  5.27211  Acc: 0.881
# base     : (　・ー́　・　)
# generate : (　・ー́　　)
# base     : (((*。_。)
# generate : (((*。_。)
# base     : (　　́_ゝ`)。。
# generate : (　　́_ゝ`)-?
# base     : ヽ(*　́∀`)ノ
# generate : ヽ(*　́∀`)ノ
# base     : (　△́　)
# generate : (　△́　)
# base     : ┌(　゚Д゚)ノ
# generate : ┌(　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : _ノ(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : ||ヾ(　・ω|。
# base     : (　́　゚∀　゚`)
# generate : (　́　'∀　゚^)
# base     : (゚Д゚ヾ　)
# generate : (゚Д゚ヾ　)
# base     : !(。^。)
# generate : !(。^。)
# base     : (꒪ω꒪)
# generate : (:ω꒪)
# base     : (ΘoΘ)σ
# generate : (゚oΘ)σ
# base     : シヾ(*　▽́　*)
# generate : ♪ヾ(*　▽́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(=　▽́　*)☆
# base     : (__)
# generate : (__)〆
# base     : (　*`ω　́)
# generate : (　*`ω　́)
# base     : ('-'*)ノ
# generate : ('-'*)ノ
# base     : (-:-)
# generate : (-:-)
# base     : o(　̄ー　̄;)ゞ
# generate : o(　̄ー　̄;)♪
# new_gen  : Σ(　vε`ロ)
# new_gen  : (`≦-ロ)∀　`)
# new_gen  : !.・∵])⌒。|
# new_gen  : Σロ皿∵:!
# new_gen  : (ヾ`・`∪)L≦
# new_gen  : *'・^_y^　)
# new_gen  : 　・``　≦)̆
# new_gen  : l　;^皿≦*_∠ฺ
# new_gen  : ;`ノლิヾ　≦≦
# new_gen  : !(o)>┐≦≦
# new_gen  : ノ_0∀^　ゞω)
# new_gen  : ヾ^ペO*゚)・・
# new_gen  : [(-'　ิ≦
# new_gen  : 　≦(`з̆’◕)
# new_gen  : .ーд・)ノシ!!
# new_gen  : ٩٩(((　ω◕ლ)
# new_gen  : ∫(`)(　д))
# new_gen  : !゙‿　♡!ó
# new_gen  : ∀꒪皿ε-　
# new_gen  : 　　''٩`зฺ)◉