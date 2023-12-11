import numpy as np
import kmj_gen_np as kgn
from layers_np import *
from collections import OrderedDict


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元



batch_size = 8      # ミニバッチサイズ
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
# batch_size: 8, lr: 0.001, i_len:8
# EPOCH:   1, Train Loss: 32.54446  Acc: 0.357, Valid Loss: 26.92791  Acc: 0.430
# EPOCH:   2, Train Loss: 24.78248  Acc: 0.462, Valid Loss: 23.16067  Acc: 0.481
# EPOCH:   3, Train Loss: 21.83537  Acc: 0.521, Valid Loss: 20.64173  Acc: 0.543
# EPOCH:   4, Train Loss: 19.60747  Acc: 0.566, Valid Loss: 18.62666  Acc: 0.578
# EPOCH:   5, Train Loss: 17.69908  Acc: 0.598, Valid Loss: 16.88712  Acc: 0.610
# EPOCH:   6, Train Loss: 16.08023  Acc: 0.632, Valid Loss: 15.41215  Acc: 0.641
# EPOCH:   7, Train Loss: 14.68007  Acc: 0.668, Valid Loss: 14.11074  Acc: 0.674
# EPOCH:   8, Train Loss: 13.42758  Acc: 0.699, Valid Loss: 12.94986  Acc: 0.706
# EPOCH:   9, Train Loss: 12.35737  Acc: 0.723, Valid Loss: 12.01143  Acc: 0.724
# EPOCH:  10, Train Loss: 11.50777  Acc: 0.742, Valid Loss: 11.27303  Acc: 0.740
# EPOCH:  11, Train Loss: 10.82428  Acc: 0.756, Valid Loss: 10.67728  Acc: 0.754
# EPOCH:  12, Train Loss: 10.25968  Acc: 0.768, Valid Loss: 10.18462  Acc: 0.765
# EPOCH:  13, Train Loss:  9.78176  Acc: 0.780, Valid Loss:  9.76669  Acc: 0.774
# EPOCH:  14, Train Loss:  9.36783  Acc: 0.789, Valid Loss:  9.40356  Acc: 0.781
# EPOCH:  15, Train Loss:  9.00253  Acc: 0.797, Valid Loss:  9.08121  Acc: 0.788
# EPOCH:  16, Train Loss:  8.67507  Acc: 0.804, Valid Loss:  8.78927  Acc: 0.797
# EPOCH:  17, Train Loss:  8.37714  Acc: 0.811, Valid Loss:  8.51961  Acc: 0.802
# EPOCH:  18, Train Loss:  8.10216  Acc: 0.816, Valid Loss:  8.26671  Acc: 0.806
# EPOCH:  19, Train Loss:  7.84614  Acc: 0.822, Valid Loss:  8.02941  Acc: 0.812
# EPOCH:  20, Train Loss:  7.60840  Acc: 0.826, Valid Loss:  7.81089  Acc: 0.816
# base     : (　・ー́　・　)
# generate : (　・ώ　・　)
# base     : (((*。_。)
# generate : (((*。▽。)
# base     : (　　́_ゝ`)。。
# generate : (　　́_·`)|♪
# base     : ヽ(*　́∀`)ノ
# generate : ヽ(*　́∀`)ノ
# base     : (　△́　)
# generate : (　Д́　)
# base     : ┌(　゚Д゚)ノ
# generate : ヽ(　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : ~_(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : ||ヾ(　・ω@)
# base     : (　́　゚∀　゚`)
# generate : (　́　゚∀　゚*)
# base     : (゚Д゚ヾ　)
# generate : (゚゚́●　)
# base     : !(。^。)
# generate : \(。^。)
# base     : (꒪ω꒪)
# generate : (·ω·)
# base     : (ΘoΘ)σ
# generate : (·o◎))
# base     : シヾ(*　▽́　*)
# generate : ゝヾ(*　▽́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(=　▽́　o)♪
# base     : (__)
# generate : (__)
# base     : (　*`ω　́)
# generate : (　*`ω　́)
# base     : ('-'*)ノ
# generate : ('-'*)ノ
# base     : (-:-)
# generate : (-д-)
# base     : o(　̄ー　̄;)ゞ
# generate : o(　̄ー　̄;)o
# new_gen  : )?)̄`ノ̄!o
# new_gen  : ♪ヾ|o゚ノ_ー
# new_gen  : ☆*_・♪
# new_gen  : ヾ(。。-　_<゚)
# new_gen  : o(・・。~ノ・
# new_gen  : ^́*_)/^̄)
# new_gen  : ̄　・)゚∀・`)
# new_gen  : ・_・　_ω・・)
# new_gen  : !((*゚-**)!
# new_gen  : (*/Д*≧　)
# new_gen  : ๑Д̄*ω̄
# new_gen  : ^ω♪?ヾ̄　ω)
# new_gen  : !(๑(ω)/ノ♪
# new_gen  : (^　^*̄!)
# new_gen  : __*)
# new_gen  : /~≧)_*__・
# new_gen  : ω|)Д。o(・.・
# new_gen  : ヾ*・▽∀)ノノ*
# new_gen  : ω̄(o・ώ́()
# new_gen  : v(/^・)・)
# new_gen  : ♪((∀!
# new_gen  : ωωω̄)́̄;　
# new_gen  : (̄　▽́∀)Σノ
# new_gen  : ^^...;;))~
# new_gen  : ?!ノ̄o*̄)
# new_gen  : ・・　・ヾ*・́)
# new_gen  : !・(・`o)
# new_gen  : (゚_゚^♪
# new_gen  : ωωo)∀ώ)ω
# new_gen  : (\☆_;)
# new_gen  : ;　`_∀́・(
# new_gen  : ̄̄oo\!
# new_gen  : (/oω*)
# new_gen  : (;゚∇`　ノ̄*)
# new_gen  : v(*(ー_-))
# new_gen  : m(　▽・/o♪
# new_gen  : _].o|・゚・
# new_gen  : ♪(　^!∀・)
# new_gen  : ♪((^゚*))!ノ
# new_gen  : ~ヾ*):[
# new_gen  : ・▽^́　|)
# new_gen  : *oノ_*　ω^)
# new_gen  : /・^・(。ヾω)
# new_gen  : ω・(　̄̄)
# new_gen  : ̄*　)!　)/
# new_gen  : ω)()　(・　̄
# new_gen  : )ωω_`。*|♪
# new_gen  : ♪(●∀●))_・゚
# new_gen  : !!　̄_o♪
# new_gen  : ♪((^o*))ノ
# new_gen  : *(~o`o∀　o
# new_gen  : (((▽`ooo
# new_gen  : ;。;(゚)▽_　)
# new_gen  : ω・・　　)
# new_gen  : ♪(≧・)
# new_gen  : (*^(_　())
# new_gen  : ♪̄*_∀　
# new_gen  : ゚(。ノ)ωヾ;)
# new_gen  : o;^ω-)̄
# new_gen  : (゚　'*　?
# new_gen  : 　♪　/(・;　/)
# new_gen  : _(ω(*(|ヾ)
# new_gen  : ̄　●́)́^ヾ)
# new_gen  : (。^..-　!!!
# new_gen  : ω)̄)ō♪
# new_gen  : 　　ヾ*Д・∀·　)
# new_gen  : ((。;　ω-*)
# new_gen  : ヾ(;　　∀　))ノ
# new_gen  : (()!.))))
# new_gen  : 　*・̄(　)゚)
# new_gen  : ((·Дo~゚
# new_gen  : 　(　　∀́　　)
# new_gen  : /~♪\*)
# new_gen  : ~⌒゚̄-́　・|
# new_gen  : ;;.ー゚　/
# new_gen  : ́(.　*ω)
# new_gen  : ;ノノ^)?
# new_gen  : ((・)
# new_gen  : (*>ωo*)・
# new_gen  : (((　(　*))
# new_gen  : (　(∇。-oo)!
# new_gen  : ∀ω・　)))
# new_gen  : ・(・~!*/・ω
# new_gen  : `(^▽~))・　-
# new_gen  : *(*|　o)
# new_gen  : o*　--;　)♪
# new_gen  : (('Д・)oo!
# new_gen  : !!_∇゚　ヾ　　)
# new_gen  : o(Д́　/
# new_gen  : "))。・^-**)
# new_gen  : !・ノ・　))
# new_gen  : (`(。^　/□゚)
# new_gen  : ヽ　̄̄_ヾ̄))
# new_gen  : 。^　(。。-^)
# new_gen  : ^*゚̄_゚̄　
# new_gen  : (ゞヾ(▼∀))ノ
# new_gen  : ((`>́)ω　)
# new_gen  : ヽヾ'∇^)-|~!
# new_gen  : ヾ(　́∀́̄)
# new_gen  : (　_　^・^)