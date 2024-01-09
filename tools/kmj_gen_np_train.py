import numpy as np
import kmj_gen_np as kgn
from layers_np import *
from collections import OrderedDict
from time import time


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 72       # 文字種数
emb_dim = 12        # 文字ベクトルの次元
hid_dim = 12        # 潜在ベクトルの次元



batch_size = 32     # ミニバッチサイズ
n_epochs = 100      # エポック数
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

  learning_time = 0
  for epoch in range(n_epochs):
    losses_train = []
    losses_valid = []
    acc_train = 0
    acc_valid = 0

    start = time()

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
    
    end = time()
    learning_time += end - start    
      
    if (epoch+1) % 1 == 0:
      print('EPOCH: {:>3}, Train Loss: {:>8.5f}  Acc: {:>.3f}, Valid Loss: {:>8.5f}  Acc: {:>.3f}, Time: {:>6.3f}'.format(
          epoch+1,
          np.mean(losses_train),
          acc_train / (train_size * N),
          np.mean(losses_valid),
          acc_valid / (valid_size * N),
          learning_time
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
# EPOCH:   1, Train Loss: 35.71628  Acc: 0.236, Valid Loss: 29.14088  Acc: 0.334, Time:  0.586
# EPOCH:   2, Train Loss: 27.92831  Acc: 0.345, Valid Loss: 26.88671  Acc: 0.373, Time:  1.179
# EPOCH:   3, Train Loss: 25.94903  Acc: 0.396, Valid Loss: 25.42030  Acc: 0.408, Time:  1.773
# EPOCH:   4, Train Loss: 24.78276  Acc: 0.424, Valid Loss: 24.35855  Acc: 0.432, Time:  2.367
# EPOCH:   5, Train Loss: 23.66027  Acc: 0.447, Valid Loss: 23.17865  Acc: 0.454, Time:  2.965
# EPOCH:   6, Train Loss: 22.57292  Acc: 0.471, Valid Loss: 22.17912  Acc: 0.475, Time:  3.560
# EPOCH:   7, Train Loss: 21.69875  Acc: 0.487, Valid Loss: 21.40326  Acc: 0.488, Time:  4.157
# EPOCH:   8, Train Loss: 21.00769  Acc: 0.499, Valid Loss: 20.78649  Acc: 0.499, Time:  4.753
# EPOCH:   9, Train Loss: 20.41628  Acc: 0.511, Valid Loss: 20.24228  Acc: 0.511, Time:  5.350
# EPOCH:  10, Train Loss: 19.87379  Acc: 0.522, Valid Loss: 19.74805  Acc: 0.521, Time:  5.946
# EPOCH:  11, Train Loss: 19.38288  Acc: 0.530, Valid Loss: 19.30690  Acc: 0.528, Time:  6.541
# EPOCH:  12, Train Loss: 18.94537  Acc: 0.537, Valid Loss: 18.90922  Acc: 0.535, Time:  7.131
# EPOCH:  13, Train Loss: 18.54953  Acc: 0.544, Valid Loss: 18.54322  Acc: 0.542, Time:  7.727
# EPOCH:  14, Train Loss: 18.18408  Acc: 0.549, Valid Loss: 18.20133  Acc: 0.549, Time:  8.323
# EPOCH:  15, Train Loss: 17.84080  Acc: 0.555, Valid Loss: 17.87744  Acc: 0.555, Time:  8.920
# EPOCH:  16, Train Loss: 17.51401  Acc: 0.563, Valid Loss: 17.56712  Acc: 0.559, Time:  9.518
# EPOCH:  17, Train Loss: 17.20117  Acc: 0.569, Valid Loss: 17.26898  Acc: 0.565, Time: 10.113
# EPOCH:  18, Train Loss: 16.90201  Acc: 0.575, Valid Loss: 16.98355  Acc: 0.570, Time: 10.711
# EPOCH:  19, Train Loss: 16.61640  Acc: 0.581, Valid Loss: 16.71143  Acc: 0.578, Time: 11.305
# EPOCH:  20, Train Loss: 16.34398  Acc: 0.587, Valid Loss: 16.45315  Acc: 0.583, Time: 11.900
# EPOCH:  21, Train Loss: 16.08485  Acc: 0.593, Valid Loss: 16.20941  Acc: 0.590, Time: 12.495
# EPOCH:  22, Train Loss: 15.83954  Acc: 0.599, Valid Loss: 15.98045  Acc: 0.595, Time: 13.090
# EPOCH:  23, Train Loss: 15.60819  Acc: 0.605, Valid Loss: 15.76549  Acc: 0.601, Time: 13.684
# EPOCH:  24, Train Loss: 15.39024  Acc: 0.611, Valid Loss: 15.56291  Acc: 0.605, Time: 14.280
# EPOCH:  25, Train Loss: 15.18457  Acc: 0.615, Valid Loss: 15.37076  Acc: 0.611, Time: 14.877
# EPOCH:  26, Train Loss: 14.98993  Acc: 0.620, Valid Loss: 15.18729  Acc: 0.613, Time: 15.476
# EPOCH:  27, Train Loss: 14.80508  Acc: 0.624, Valid Loss: 15.01107  Acc: 0.616, Time: 16.071
# EPOCH:  28, Train Loss: 14.62889  Acc: 0.628, Valid Loss: 14.84109  Acc: 0.619, Time: 16.666
# EPOCH:  29, Train Loss: 14.46037  Acc: 0.632, Valid Loss: 14.67666  Acc: 0.621, Time: 17.260
# EPOCH:  30, Train Loss: 14.29872  Acc: 0.635, Valid Loss: 14.51736  Acc: 0.624, Time: 17.855
# EPOCH:  31, Train Loss: 14.14324  Acc: 0.638, Valid Loss: 14.36296  Acc: 0.627, Time: 18.450
# EPOCH:  32, Train Loss: 13.99342  Acc: 0.641, Valid Loss: 14.21335  Acc: 0.631, Time: 19.047
# EPOCH:  33, Train Loss: 13.84881  Acc: 0.644, Valid Loss: 14.06849  Acc: 0.633, Time: 19.643
# EPOCH:  34, Train Loss: 13.70911  Acc: 0.646, Valid Loss: 13.92838  Acc: 0.635, Time: 20.239
# EPOCH:  35, Train Loss: 13.57404  Acc: 0.650, Valid Loss: 13.79302  Acc: 0.637, Time: 20.832
# EPOCH:  36, Train Loss: 13.44344  Acc: 0.652, Valid Loss: 13.66240  Acc: 0.640, Time: 21.430
# EPOCH:  37, Train Loss: 13.31717  Acc: 0.656, Valid Loss: 13.53650  Acc: 0.644, Time: 22.027
# EPOCH:  38, Train Loss: 13.19515  Acc: 0.659, Valid Loss: 13.41528  Acc: 0.648, Time: 22.623
# EPOCH:  39, Train Loss: 13.07730  Acc: 0.661, Valid Loss: 13.29868  Acc: 0.652, Time: 23.217
# EPOCH:  40, Train Loss: 12.96357  Acc: 0.664, Valid Loss: 13.18662  Acc: 0.655, Time: 23.812
# EPOCH:  41, Train Loss: 12.85390  Acc: 0.668, Valid Loss: 13.07900  Acc: 0.658, Time: 24.408
# EPOCH:  42, Train Loss: 12.74821  Acc: 0.670, Valid Loss: 12.97571  Acc: 0.661, Time: 25.002
# EPOCH:  43, Train Loss: 12.64643  Acc: 0.673, Valid Loss: 12.87661  Acc: 0.663, Time: 25.600
# EPOCH:  44, Train Loss: 12.54842  Acc: 0.676, Valid Loss: 12.78156  Acc: 0.666, Time: 26.195
# EPOCH:  45, Train Loss: 12.45404  Acc: 0.678, Valid Loss: 12.69039  Acc: 0.668, Time: 26.789
# EPOCH:  46, Train Loss: 12.36314  Acc: 0.681, Valid Loss: 12.60289  Acc: 0.671, Time: 27.383
# EPOCH:  47, Train Loss: 12.27555  Acc: 0.683, Valid Loss: 12.51887  Acc: 0.672, Time: 27.978
# EPOCH:  48, Train Loss: 12.19110  Acc: 0.686, Valid Loss: 12.43809  Acc: 0.675, Time: 28.576
# EPOCH:  49, Train Loss: 12.10962  Acc: 0.688, Valid Loss: 12.36033  Acc: 0.677, Time: 29.170
# EPOCH:  50, Train Loss: 12.03092  Acc: 0.690, Valid Loss: 12.28538  Acc: 0.679, Time: 29.765
# EPOCH:  51, Train Loss: 11.95486  Acc: 0.692, Valid Loss: 12.21303  Acc: 0.681, Time: 30.360
# EPOCH:  52, Train Loss: 11.88126  Acc: 0.693, Valid Loss: 12.14309  Acc: 0.684, Time: 30.955
# EPOCH:  53, Train Loss: 11.80998  Acc: 0.695, Valid Loss: 12.07540  Acc: 0.686, Time: 31.550
# EPOCH:  54, Train Loss: 11.74088  Acc: 0.697, Valid Loss: 12.00980  Acc: 0.688, Time: 32.146
# EPOCH:  55, Train Loss: 11.67383  Acc: 0.698, Valid Loss: 11.94614  Acc: 0.690, Time: 32.741
# EPOCH:  56, Train Loss: 11.60869  Acc: 0.700, Valid Loss: 11.88429  Acc: 0.691, Time: 33.337
# EPOCH:  57, Train Loss: 11.54535  Acc: 0.702, Valid Loss: 11.82414  Acc: 0.692, Time: 33.928
# EPOCH:  58, Train Loss: 11.48371  Acc: 0.704, Valid Loss: 11.76556  Acc: 0.694, Time: 34.523
# EPOCH:  59, Train Loss: 11.42366  Acc: 0.705, Valid Loss: 11.70846  Acc: 0.695, Time: 35.118
# EPOCH:  60, Train Loss: 11.36512  Acc: 0.706, Valid Loss: 11.65273  Acc: 0.696, Time: 35.712
# EPOCH:  61, Train Loss: 11.30799  Acc: 0.708, Valid Loss: 11.59829  Acc: 0.698, Time: 36.307
# EPOCH:  62, Train Loss: 11.25220  Acc: 0.709, Valid Loss: 11.54506  Acc: 0.698, Time: 36.902
# EPOCH:  63, Train Loss: 11.19767  Acc: 0.710, Valid Loss: 11.49296  Acc: 0.698, Time: 37.495
# EPOCH:  64, Train Loss: 11.14435  Acc: 0.712, Valid Loss: 11.44193  Acc: 0.699, Time: 38.089
# EPOCH:  65, Train Loss: 11.09216  Acc: 0.713, Valid Loss: 11.39190  Acc: 0.700, Time: 38.683
# EPOCH:  66, Train Loss: 11.04105  Acc: 0.714, Valid Loss: 11.34283  Acc: 0.702, Time: 39.276
# EPOCH:  67, Train Loss: 10.99097  Acc: 0.715, Valid Loss: 11.29466  Acc: 0.703, Time: 39.872
# EPOCH:  68, Train Loss: 10.94188  Acc: 0.717, Valid Loss: 11.24735  Acc: 0.704, Time: 40.468
# EPOCH:  69, Train Loss: 10.89372  Acc: 0.718, Valid Loss: 11.20087  Acc: 0.706, Time: 41.065
# EPOCH:  70, Train Loss: 10.84645  Acc: 0.719, Valid Loss: 11.15517  Acc: 0.706, Time: 41.661
# EPOCH:  71, Train Loss: 10.80005  Acc: 0.720, Valid Loss: 11.11023  Acc: 0.707, Time: 42.256
# EPOCH:  72, Train Loss: 10.75447  Acc: 0.721, Valid Loss: 11.06602  Acc: 0.709, Time: 42.852
# EPOCH:  73, Train Loss: 10.70968  Acc: 0.722, Valid Loss: 11.02251  Acc: 0.710, Time: 43.446
# EPOCH:  74, Train Loss: 10.66566  Acc: 0.723, Valid Loss: 10.97967  Acc: 0.711, Time: 44.042
# EPOCH:  75, Train Loss: 10.62239  Acc: 0.725, Valid Loss: 10.93750  Acc: 0.711, Time: 44.637
# EPOCH:  76, Train Loss: 10.57983  Acc: 0.725, Valid Loss: 10.89596  Acc: 0.713, Time: 45.229
# EPOCH:  77, Train Loss: 10.53797  Acc: 0.726, Valid Loss: 10.85503  Acc: 0.713, Time: 45.825
# EPOCH:  78, Train Loss: 10.49679  Acc: 0.727, Valid Loss: 10.81471  Acc: 0.715, Time: 46.418
# EPOCH:  79, Train Loss: 10.45626  Acc: 0.728, Valid Loss: 10.77497  Acc: 0.716, Time: 47.013
# EPOCH:  80, Train Loss: 10.41638  Acc: 0.729, Valid Loss: 10.73580  Acc: 0.717, Time: 47.605
# EPOCH:  81, Train Loss: 10.37712  Acc: 0.730, Valid Loss: 10.69718  Acc: 0.719, Time: 48.198
# EPOCH:  82, Train Loss: 10.33847  Acc: 0.731, Valid Loss: 10.65910  Acc: 0.719, Time: 48.792
# EPOCH:  83, Train Loss: 10.30041  Acc: 0.732, Valid Loss: 10.62155  Acc: 0.720, Time: 49.386
# EPOCH:  84, Train Loss: 10.26293  Acc: 0.733, Valid Loss: 10.58451  Acc: 0.721, Time: 49.978
# EPOCH:  85, Train Loss: 10.22601  Acc: 0.733, Valid Loss: 10.54796  Acc: 0.721, Time: 50.581
# EPOCH:  86, Train Loss: 10.18964  Acc: 0.734, Valid Loss: 10.51191  Acc: 0.722, Time: 51.186
# EPOCH:  87, Train Loss: 10.15380  Acc: 0.735, Valid Loss: 10.47633  Acc: 0.723, Time: 51.782
# EPOCH:  88, Train Loss: 10.11849  Acc: 0.736, Valid Loss: 10.44122  Acc: 0.723, Time: 52.377
# EPOCH:  89, Train Loss: 10.08368  Acc: 0.736, Valid Loss: 10.40658  Acc: 0.724, Time: 52.971
# EPOCH:  90, Train Loss: 10.04938  Acc: 0.737, Valid Loss: 10.37239  Acc: 0.725, Time: 53.563
# EPOCH:  91, Train Loss: 10.01557  Acc: 0.738, Valid Loss: 10.33864  Acc: 0.726, Time: 54.156
# EPOCH:  92, Train Loss:  9.98223  Acc: 0.739, Valid Loss: 10.30534  Acc: 0.726, Time: 54.749
# EPOCH:  93, Train Loss:  9.94938  Acc: 0.739, Valid Loss: 10.27248  Acc: 0.726, Time: 55.338
# EPOCH:  94, Train Loss:  9.91698  Acc: 0.740, Valid Loss: 10.24004  Acc: 0.727, Time: 55.933
# EPOCH:  95, Train Loss:  9.88505  Acc: 0.741, Valid Loss: 10.20803  Acc: 0.728, Time: 56.527
# EPOCH:  96, Train Loss:  9.85356  Acc: 0.742, Valid Loss: 10.17643  Acc: 0.728, Time: 57.117
# EPOCH:  97, Train Loss:  9.82252  Acc: 0.743, Valid Loss: 10.14525  Acc: 0.729, Time: 57.710
# EPOCH:  98, Train Loss:  9.79192  Acc: 0.744, Valid Loss: 10.11447  Acc: 0.729, Time: 58.304
# EPOCH:  99, Train Loss:  9.76174  Acc: 0.745, Valid Loss: 10.08410  Acc: 0.730, Time: 58.899
# EPOCH: 100, Train Loss:  9.73199  Acc: 0.745, Valid Loss: 10.05412  Acc: 0.731, Time: 59.492
# base     : (　・ー́　・　)
# generate : (　・̄́　・　)
# base     : (((*。_。)
# generate : ((-__)
# base     : (　　́_ゝ`)。。
# generate : (　　́_``))
# base     : ヽ(*　́∀`)ノ
# generate : ヾ(*　́̄*)ノ
# base     : (　́　)
# generate : (　́　)
# base     : (　゚Д゚)ノ
# generate : (　゚Д゚)ノ
# base     : _/(゚Д゚　)
# generate : (ヾ(゚Д゚　)
# base     : ||ヾ(　・ω|　
# generate : .!ヾ(　́ω・)
# base     : (　́　゚∀　゚`)
# generate : (　̄　゚̄　　　)
# base     : (゚Д゚ヾ　)
# generate : (゚(゚ω　)
# base     : !(。^。)
# generate : !(_^_)
# base     : (ω)
# generate : (ω)
# base     : (o)σ
# generate : (_)/
# base     : ヾ(*　▽́　*)
# generate : (*　▽́　　)
# base     : ヾ(=　▽́　=)ヽ
# generate : ヾ(̄　▽́　*)ノ
# base     : (__)
# generate : (・_)
# base     : (　*`ω　́)
# generate : (　́`ω　・)
# base     : ('-'*)ノ
# generate : (≧-'*)ノ
# base     : (-:-)
# generate : (*ω-)
# base     : o(　̄ー　̄;)ゞ
# generate : (　̄̄　̄*)
# new_gen  : (・・ω
# new_gen  : \(*^　▽!
# new_gen  : (`(　・)
# new_gen  : (　̄　　̄)!
# new_gen  : ☆!(\()*
# new_gen  : ♪!(・▽)
# new_gen  : (・・)
# new_gen  : (̄　▽゚)ノ
# new_gen  : ♪(*・　́　̄　)
# new_gen  : |^・((--)
# new_gen  : (・゚・゚́　̄　)
# new_gen  : (*-)ノ))!
# new_gen  : ヾ(　)
# new_gen  : (*゚　　)　
# new_gen  : (*・・)・)
# new_gen  : (・́_　
# new_gen  : (　゚́　́　)!
# new_gen  : !(-・ω)　)
# new_gen  : ~(́・))
# new_gen  : ♪(・_)≦/
# new_gen  : (・(・)))♪
# new_gen  : !((^ω_・(
# new_gen  : !(*^　)/
# new_gen  : (^^^*)))-!
# new_gen  : (・・_・
# new_gen  : (。<)-~)
# new_gen  : !!(・́・・)
# new_gen  : (　^　!
# new_gen  : ヾ(;-`)
# new_gen  : 　^)/!
# new_gen  : !(゚_^ω^*
# new_gen  : (゚　̄・(　　)
# new_gen  : (　(*(　ー)
# new_gen  : !((^　゚)o・
# new_gen  : |~。_∀　))
# new_gen  : !((゚^∇\^)
# new_gen  : (　(;　
# new_gen  : (*゚(^)゚)~♪
# new_gen  : ヾ(*・^ヾ゚)
# new_gen  : !~∀_
# new_gen  : ^(　̄　
# new_gen  : >!()ノ
# new_gen  : ヾ(。_)`)ノ
# new_gen  : !~(((^^)ノ
# new_gen  : ^(*/
# new_gen  : ・。))
# new_gen  : !(̄　▽)　
# new_gen  : )　))
# new_gen  : ・(　^`
# new_gen  : ♪(　・)`
# new_gen  : !(　^-)/~
# new_gen  : (・　゚)　
# new_gen  : (　ω^-　)
# new_gen  : .~(・　)　
# new_gen  : (・・)・・
# new_gen  : (・　_　;)ノ
# new_gen  : (　・・)
# new_gen  : /(　^)　)!
# new_gen  : (・́∀)・)
# new_gen  : !!~・
# new_gen  : (　__))ノ
# new_gen  : ヾ((゚)♪
# new_gen  : ☆!((-▽*)
# new_gen  : (　　́````)
# new_gen  : |^(^(-　̄)
# new_gen  : ́;)/^\
# new_gen  : ・・(ω-<))
# new_gen  : ♪(̄・゚　^
# new_gen  : (・^　　^*
# new_gen  : (*゚・　゚
# new_gen  : /^　▽)
# new_gen  : !!(・^o^=)
# new_gen  : !ヾ(|^▽^^*)
# new_gen  : ((　▽・　)
# new_gen  : !!('́　)
# new_gen  : ^̄　・(　^
# new_gen  : ̄(ω　)
# new_gen  : (゚̄^゚^)!
# new_gen  : (^_;)　!
# new_gen  : (*-▽;
# new_gen  : (　)!　
# new_gen  : ∀・́
# new_gen  : (*^<)
# new_gen  : ヾ(・・・)・)
# new_gen  : ・　)
# new_gen  : ♪(゚　　)
# new_gen  : ・((^)(
# new_gen  : (　　・　)ノ!
# new_gen  : (・^()▽　
# new_gen  : ヾ(゚　゚)/_・
# new_gen  : (*　・ω`^)
# new_gen  : (*-)(・　^)
# new_gen  : ・́_')`
# new_gen  : ヾ((^`　)
# new_gen  : ((　_・・))
# new_gen  : (♪(^ω_・　)
# new_gen  : (∀_・)
# new_gen  : 　　　(`|-)
# new_gen  : 　^∀　*)ノ
# new_gen  : ^　　)*)　!