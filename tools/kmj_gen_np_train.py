import numpy as np
import kmj_gen_np as kgn
from layers import *
from collections import OrderedDict


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元



batch_size = 16     # ミニバッチサイズ
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
  optim = Adam(lr=lr)

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


# batch_size: 16, lr: 0.001
# EPOCH:   5, Train Loss: 12.45193  Acc: 0.701, Valid Loss: 11.81269  Acc: 0.714
# EPOCH:  10, Train Loss:  7.82158  Acc: 0.810, Valid Loss:  8.03228  Acc: 0.803
# EPOCH:  15, Train Loss:  6.03102  Acc: 0.852, Valid Loss:  6.55761  Acc: 0.841
# EPOCH:  20, Train Loss:  4.97990  Acc: 0.878, Valid Loss:  5.70525  Acc: 0.859
# EPOCH:  25, Train Loss:  4.26161  Acc: 0.896, Valid Loss:  5.11676  Acc: 0.875
# EPOCH:  30, Train Loss:  3.72526  Acc: 0.909, Valid Loss:  4.66679  Acc: 0.883
# EPOCH:  35, Train Loss:  3.30197  Acc: 0.920, Valid Loss:  4.29890  Acc: 0.892
# EPOCH:  40, Train Loss:  2.95454  Acc: 0.929, Valid Loss:  3.99476  Acc: 0.896
# EPOCH:  45, Train Loss:  2.65942  Acc: 0.936, Valid Loss:  3.73760  Acc: 0.903
# EPOCH:  50, Train Loss:  2.40068  Acc: 0.943, Valid Loss:  3.50642  Acc: 0.909
# EPOCH:  55, Train Loss:  2.17053  Acc: 0.950, Valid Loss:  3.29430  Acc: 0.914
# EPOCH:  60, Train Loss:  1.96643  Acc: 0.955, Valid Loss:  3.10617  Acc: 0.920
# EPOCH:  65, Train Loss:  1.78678  Acc: 0.960, Valid Loss:  2.94376  Acc: 0.923
# EPOCH:  70, Train Loss:  1.62865  Acc: 0.964, Valid Loss:  2.80411  Acc: 0.926
# EPOCH:  75, Train Loss:  1.48837  Acc: 0.968, Valid Loss:  2.68486  Acc: 0.929
# EPOCH:  80, Train Loss:  1.36261  Acc: 0.972, Valid Loss:  2.58523  Acc: 0.932
# EPOCH:  85, Train Loss:  1.24888  Acc: 0.975, Valid Loss:  2.50568  Acc: 0.934
# EPOCH:  90, Train Loss:  1.14577  Acc: 0.977, Valid Loss:  2.44474  Acc: 0.937
# EPOCH:  95, Train Loss:  1.05238  Acc: 0.980, Valid Loss:  2.39803  Acc: 0.939
# EPOCH: 100, Train Loss:  0.96791  Acc: 0.983, Valid Loss:  2.36091  Acc: 0.940
# base     : (　・ー́　・　)
# generate : (　・ー́　・　)
# base     : (((*。_。)
# generate : (((*。_。)
# base     : (　　́_ゝ`)。。
# generate : (　　́_ゝ`)o。
# base     : ヽ(*　́∀`)ノ
# generate : ヽ(*　́∀`)ノ
# base     : (　△́　)
# generate : (　△́　)
# base     : ┌(　゚Д゚)ノ
# generate : ┌(　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : ☆。(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : ||ヾ(　・ω|/
# base     : (　́　゚∀　゚`)
# generate : (　́　゚∀　゚`)
# base     : (゚Д゚ヾ　)
# generate : (゚Д゚ヾ　)
# base     : !(。^。)
# generate : !(。^。)
# base     : (꒪ω꒪)
# generate : (꒪ω꒪)
# base     : (ΘoΘ)σ
# generate : (ΘoΘ)σ
# base     : シヾ(*　▽́　*)
# generate : シヾ(*　▽́　*)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(=　▽́　=)ヽ
# base     : (__)
# generate : (__)
# base     : (　*`ω　́)
# generate : (　*`ω　́)
# base     : ('-'*)ノ
# generate : ('-'*)ノ
# base     : (-:-)
# generate : (-:-)
# base     : o(　̄ー　̄;)ゞ
# generate : o(　̄ー　̄;)=
# new_gen  : !*°　(∵*　|σ
# new_gen  : 　*(ゞд┏　v◆<
# new_gen  : ΨΣ*×ロ゚　
# new_gen  : ♪　・)ノ　▼
# new_gen  : ‐ノ゚^✧♪!ლ
# new_gen  : *・∀ェ≦)(、ヮ
# new_gen  : !?|∩[ヾ)・
# new_gen  : !♪*♥×　・≡°)
# new_gen  : σ*о・」∇×!(┌
# new_gen  : ヘェ皿】♂)Ψ
# new_gen  : (ノ◕)*)lД‐)
# new_gen  : ∇゚▽m’o^☆∩ゞ
# new_gen  : ゚　ノ[・×┓òヽ
# new_gen  : (-+)~T*
# new_gen  : ((ˇ≦●・^
# new_gen  : ^。<|ヘ|)・◇
# new_gen  : [/・ヾ<「)?~♪
# new_gen  : O))∀。_◎)
# new_gen  : ・(|'́́)。　。
# new_gen  : (ー▽)!!ò
# new_gen  : ?ゞT.≧□[■/
# new_gen  : ιヾ~ゝ▽σb)ノ♪
# new_gen  : ヾ(^∵(ヽ┃ゞ~≡
# new_gen  : (〃♪▼)ゝ♪▽♪
# new_gen  : *♪×ˇ́)Σ(L
# new_gen  : ゥヾ◎^_:σ-。
# new_gen  : ♪+・ヮ　oT
# new_gen  : ヾ*/×゚)0　★*
# new_gen  : (`(ฺ艸(*ฺ
# new_gen  : A　lω　(
# new_gen  : ≡▼▽з★ェ▼!!
# new_gen  : ・ヾ┏A┓ώ。。|
# new_gen  : !★ゞ°"┳(←=
# new_gen  : ゚メ・ヾ皿゚o」艸【
# new_gen  : |。‘(◎◕•)_
# new_gen  : ^T^゚ゞゝ◎ψ
# new_gen  : ッ!∀́・·
# new_gen  : ゚Uc▼ヾロ゚))!
# new_gen  : ヘ(〆*◇ゝ▼=ヾ♪
# new_gen  : Ψ　「ー゚∀○ヽ⊃
# new_gen  : q=∂▽∀)゚・]
# new_gen  : `」ヾ*^́<
# new_gen  : 　(・▼)v`)っ!
# new_gen  : \I≡_・。m★
# new_gen  : ―っ∠　∂ロ゚**
# new_gen  : ヾ*́('(◎、)
# new_gen  : ヘヘ　∇　^゚゚|゚
# new_gen  : 　゚́́=)゚l)
# new_gen  : ((・へ　▽̄∀[
# new_gen  : o>.(^∀ω・・.
# new_gen  : ι　・・⊂/ノ!シლ
# new_gen  : (゚人;　　
# new_gen  : o*.ゝヾ∂-~
# new_gen  : ┌])(·・′|(┌
# new_gen  : (╹×ロ·3Ψッ
# new_gen  : ┳=▽*・シ∥)#
# new_gen  : σ(#́ロ∀o)(
# new_gen  : .*)θ)o。)o!
# new_gen  : ゚。ι|·。|⊃
# new_gen  : (。;°)ωo)
# new_gen  : (　Ψ(ノ▽Φ`))
# new_gen  : |>◎+))」)・♪
# new_gen  : 。・〃'ゞ)(　ω
# new_gen  : ゚。,^▼ヘ*O."
# new_gen  : !ヾ~̄^∀́)
# new_gen  : (◎≦)•[)д
# new_gen  : 　・)-)ロ,◎;
# new_gen  : ・∀▼┌Θ┏ゝ▼)
# new_gen  : `(·゚ω‘٩♪!
# new_gen  : ━━~~■)ゞノ★
# new_gen  : ♪̄`╹×ω゚
# new_gen  : ・~*　Cз̄)ゝ<
# new_gen  : 　^.゚((・)o)
# new_gen  : ・。。^′・̄)┌
# new_gen  : ゞヾ^　+、ゝ▼)┌
# new_gen  : O′゚O(|、|
# new_gen  : 」|)A∀。ヾ、)
# new_gen  : ゙)▽o*・^;\)
# new_gen  : ฅ((∀ロ。Д_)[
# new_gen  : (・((Д*・O・
# new_gen  : ♪Σヾ〃|Θシ!
# new_gen  : ((ヾ∇_~/⊃_ー
# new_gen  : o(ゝo・-　;)
# new_gen  : @^?▽⊂∠.▼彡
# new_gen  : ∑ヾ)ヮ)∩|)[
# new_gen  : ♡(　(・ゝ*o(
# new_gen  : *◎┓'ゞ‘)
# new_gen  : l。△̆))ლ゚)♪
# new_gen  : |*ω✿O!艸
# new_gen  : ゞლо・д　・◉)◕
# new_gen  : l|(　Φ‘ノó・
# new_gen  : q('Cヘゞ≧^`σ
# new_gen  : (【ლ)ゝロ)ノ!
# new_gen  : ・　】(‘A゚
# new_gen  : Ю┐。^゚#
# new_gen  : ゚<(@◎∀、)!
# new_gen  : ?　Σo·)・・`)
# new_gen  : Ю∀ˇฅΦ◕▽)
# new_gen  : [┃([óo])
# new_gen  : ゞ‘・)•๑─゚・