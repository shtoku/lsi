import numpy as np
import kmj_gen_np as kgn
from layers import *
from collections import OrderedDict


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元



batch_size = 8      # ミニバッチサイズ
n_epochs = 100      # エポック数
lr = 1e-3           # 学習率


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
    self.layers['Tanh_Layer1'] = Tanh_Layer()
    self.layers['Mix_Layer2'] = Mix_Layer(self.params['W_2'], self.params['b_2'])
    self.layers['Tanh_Layer2'] = Tanh_Layer()
    self.layers['Mix_Layer3'] = Mix_Layer(self.params['W_3'], self.params['b_3'], is_hid=True)
    self.layers['Tanh_Layer3'] = Tanh_Layer()
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
  optim = Momentum(lr=lr)

  # 学習
  print('batch_size: {:}, lr: {:}'.format(batch_size, lr))
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
  
  for _ in range(100):
    z = np.random.uniform(low=-1, high=1, size=(1, hid_dim, 1))
    y = net.layers['Mix_Layer3'].forward(z)
    y = net.layers['Tanh_Layer3'].forward(y)
    y = net.layers['Dense_Layer'].forward(y)

    print('new_gen  :', kgn.convert_str(y[0]))


# batch_size: 8, lr: 0.001
# EPOCH:   5, Train Loss: 18.51250  Acc: 0.588, Valid Loss: 17.57885  Acc: 0.610
# EPOCH:  10, Train Loss: 11.86244  Acc: 0.735, Valid Loss: 11.59037  Acc: 0.741
# EPOCH:  15, Train Loss:  9.02389  Acc: 0.802, Valid Loss:  9.01679  Acc: 0.801
# EPOCH:  20, Train Loss:  7.57755  Acc: 0.832, Valid Loss:  7.71806  Acc: 0.827
# EPOCH:  25, Train Loss:  6.69192  Acc: 0.850, Valid Loss:  6.91968  Acc: 0.846
# EPOCH:  30, Train Loss:  6.04742  Acc: 0.862, Valid Loss:  6.34696  Acc: 0.857
# EPOCH:  35, Train Loss:  5.54058  Acc: 0.873, Valid Loss:  5.90647  Acc: 0.867
# EPOCH:  40, Train Loss:  5.12889  Acc: 0.882, Valid Loss:  5.55518  Acc: 0.875
# EPOCH:  45, Train Loss:  4.78700  Acc: 0.890, Valid Loss:  5.26692  Acc: 0.883
# EPOCH:  50, Train Loss:  4.49772  Acc: 0.897, Valid Loss:  5.02603  Acc: 0.886
# EPOCH:  55, Train Loss:  4.24898  Acc: 0.903, Valid Loss:  4.82226  Acc: 0.890
# EPOCH:  60, Train Loss:  4.03198  Acc: 0.908, Valid Loss:  4.64771  Acc: 0.894
# EPOCH:  65, Train Loss:  3.84020  Acc: 0.912, Valid Loss:  4.49577  Acc: 0.896
# EPOCH:  70, Train Loss:  3.66872  Acc: 0.916, Valid Loss:  4.36148  Acc: 0.899
# EPOCH:  75, Train Loss:  3.51389  Acc: 0.920, Valid Loss:  4.24156  Acc: 0.901
# EPOCH:  80, Train Loss:  3.37299  Acc: 0.923, Valid Loss:  4.13385  Acc: 0.902
# EPOCH:  85, Train Loss:  3.24398  Acc: 0.926, Valid Loss:  4.03662  Acc: 0.903
# EPOCH:  90, Train Loss:  3.12539  Acc: 0.929, Valid Loss:  3.94840  Acc: 0.906
# EPOCH:  95, Train Loss:  3.01607  Acc: 0.931, Valid Loss:  3.86798  Acc: 0.909
# EPOCH: 100, Train Loss:  2.91507  Acc: 0.934, Valid Loss:  3.79444  Acc: 0.911
# base     : (　・ー́　・　)
# generate : (　・ー́　・　)
# base     : (((*。_。)
# generate : (((*。_。)
# base     : (　　́_ゝ`)。。
# generate : (　　́_ゝ`)。。
# base     : ヽ(*　́∀`)ノ
# generate : ヽ(*　́∀`)ノ
# base     : (　△́　)
# generate : (　艸́　)
# base     : ┌(　゚Д゚)ノ
# generate : ┌(　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : ~.(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : ||ヾ(　・ω|　
# base     : (　́　゚∀　゚`)
# generate : (　́　゚∀　゚`)
# base     : (゚Д゚ヾ　)
# generate : (゚Д゚ヾ　)
# base     : !(。^。)
# generate : !(。^。)
# base     : (꒪ω꒪)
# generate : (‘ω꒪)
# base     : (ΘoΘ)σ
# generate : (]o’)σ
# base     : シヾ(*　▽́　*)
# generate : シヾ(*　▽́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(=　▽́　●)ヽ
# base     : (__)
# generate : (__)
# base     : (　*`ω　́)
# generate : (　　`ω　́)
# base     : ('-'*)ノ
# generate : ('-'*)ノ
# base     : (-:-)
# generate : (-:-)
# base     : o(　̄ー　̄;)ゞ
# generate : o(　̄ー　̄;)o
# new_gen  : (　o゚　̄*̄*♪
# new_gen  : (ー∇●　□☆.
# new_gen  : ◇_　゚)σ。!!
# new_gen  : !!^∇゚ρ!ヽシ
# new_gen  : ・-　̄ノ?
# new_gen  : ゚Д•・.ω!∇
# new_gen  : →^∀_)♪o≦。
# new_gen  : ლლ⊃ノ~<゚)　
# new_gen  : (́_゚=゚ー@
# new_gen  : ;^`~●/<(♪
# new_gen  : =●●m゚゚̄　*
# new_gen  : )(・□゚　*　
# new_gen  : <⌒□́@)>)m
# new_gen  : ;・へ~).)
# new_gen  : !●*艸・ノ゚;゚)
# new_gen  : ___≦~T\
# new_gen  : ~.ー~'T゙!~
# new_gen  : ヽ☆・∇'ノ;ー♪
# new_gen  : (!o/)-)彡
# new_gen  : |・ω~~·_≦)/
# new_gen  : (ヾ゚┏●/。)
# new_gen  : (ー▼^?　ノ-
# new_gen  : !!*ー*ヾ̄
# new_gen  : )ノ~)ωД;;)
# new_gen  : ゚Д^人<o
# new_gen  : ・】-~'ヾ≧ー　
# new_gen  : (　_д|・ヾー*゚
# new_gen  : .<□́^"　T)~
# new_gen  : Σ(▼oω⌒ヾo!
# new_gen  : )((-⌒^-　!=
# new_gen  : ~~ヾ.T.・　
# new_gen  : ー-.`.　^́⊂)
# new_gen  : -ヽ・o　∀゚Д*)
# new_gen  : __・∀σ●^')ノ
# new_gen  : !๑_　~̄*)/
# new_gen  : **σ゚□-)ノ!
# new_gen  : T_@:T;~)-
# new_gen  : ~?-(-([_\
# new_gen  : (=●=_^̄　゚
# new_gen  : !)(_^́^**
# new_gen  : ?~ω☆^σ;ーl
# new_gen  : (Д　*ω　　๑　)
# new_gen  : (σд)))~♪
# new_gen  : ゚σ;(・.<<
# new_gen  : )●゚　́=>!<"
# new_gen  : (　\ヾ□・-○))
# new_gen  : 　;゚;o)ノ
# new_gen  : ⊃Д　ノ☆/
# new_gen  : 　　.゚;!'))
# new_gen  : *;●^へ-　!ლ
# new_gen  : (_";*o'^
# new_gen  : ☆o_●ヽ　☆́!
# new_gen  : b\=,・-)。!
# new_gen  : (]_°?ヾノ.♪
# new_gen  : ♪ヾ(∇^;~。!.
# new_gen  : "~ノω_)、♪
# new_gen  : ()゚́・`)σ
# new_gen  : ●)#;|o|=^
# new_gen  : !!　,ωー*/)
# new_gen  : (　゚v~-")-
# new_gen  : ノ(^~゚()
# new_gen  : (oヾー^≦'
# new_gen  : 。!**ゞ)◎)
# new_gen  : 　　ё・(　!ー
# new_gen  : ?~ヾmT-[)
# new_gen  : ゚゚ヾ_　́Д`
# new_gen  : ≧≦~̄*・([)
# new_gen  : ⌒σ∇o);!
# new_gen  : ~~・-o><・。
# new_gen  : \●^~)๑`))o
# new_gen  : (゚。゚.≦/♪
# new_gen  : (·・*・(o彡
# new_gen  : (*~-。。-　*
# new_gen  : ⌒\̄　、*\_
# new_gen  : ☆o*(゚*
# new_gen  : ♪\((ω　ー;)o
# new_gen  : 、_-^-o_
# new_gen  : ~)(́)/^)
# new_gen  : ヾ(=゚-ヾ*)/!
# new_gen  : (〃·、\=T'・)
# new_gen  : ((`~*!ゞ̄　
# new_gen  : *゚・;--・∩ゝ)
# new_gen  : ヽ(・_)・゚゚　)
# new_gen  : ]゚;;ω=ω○*]
# new_gen  : ・♪(≧́σ゚)v
# new_gen  : ∩　^д　　(　)□
# new_gen  : !/゚m　^゚゚*☆
# new_gen  : ;^\・_.)_)
# new_gen  : mo>'́@　|⌒
# new_gen  : ]|;　゚;((　☆
# new_gen  : )!(́・ー・=゚)
# new_gen  : ()(=^¬<
# new_gen  : 【゚へ⌒`!~o!
# new_gen  : (_!;ー;+=^・
# new_gen  : ((×≧з̄ノー
# new_gen  : (●・Oώ　)∑
# new_gen  : ノ!;(　()　)
# new_gen  : ☆oヾд^~┐ノ
# new_gen  : !?-Д゚\)-ー)
# new_gen  : !!'ω^'彡'