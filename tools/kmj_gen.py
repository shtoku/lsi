import numpy as np


# パラメータファイルのパス
PATH = '../data/parameter/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


# 固定小数点の桁数
i_len = 6           # 整数部の桁数
f_len = 10          # 小数部の桁数
n_len = 16          # 整数部 + 小数部 の桁数


# 使用できる文字のリストを読み込み
char_list = []
with open('../data/char_list.txt' , 'r', encoding='utf-8') as file:
  for line in file:
    char_list.append(line.replace('\n', ''))



# データの前処理を行う関数
# 顔文字を文字ごとに分解 -> 番号付け -> One-hotベクトル
def preprocess(kmj_data):

  # 文字リストの番号を顔文字中の番号を対応付け
  kmj_index = []
  for kmj in kmj_data:
    kmj = list(kmj)
    kmj += ['<PAD>' for _ in range(N - len(kmj))]
    temp = []
    for c in kmj:
      try:
        temp.append(char_list.index(c))
      except:
        temp.append(char_list.index('<UNK>'))
    kmj_index.append(temp)

  # 付けた番号をOne-hotベクトル化
  kmj_num = len(kmj_index)                        # 顔文字数
  char_num = len(char_list)                       # 文字の種類数
  kmj_onehot = np.zeros((kmj_num, N, char_num))   # One-hotベクトルリスト
  for i, index in enumerate(kmj_index):
    mask = range(char_num) == np.array(index).reshape((N, 1))
    kmj_onehot[i][mask] = 1
  
  return kmj_onehot


# パラメータファイルからデータを読む関数
def read_param(filename):
  param = []
  with open(filename, 'r') as file:
    for line in file:
      temp = int(float(line.replace('\n', '')) * 2**f_len)
      temp = format(temp & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
      param.append(temp)
  return np.array(param)


# strをintに変換
def str_to_int(a):
  return (int(a, 2) - int(int(a[0]) << n_len))


# strのかけ算
def mul(a, b):
  a = str_to_int(a)
  b = str_to_int(b)
  y = a * b
  y = format(y & ((1 << 2 * n_len) - 1), '0' + str(2 * n_len) + 'b')
  return y[i_len : 2 * i_len + f_len]


# strの足し算
def add(a, b):
  a = str_to_int(a)
  b = str_to_int(b)
  y = a + b
  y = format(y & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
  return y


# 内積演算
def inner(a, b):
  y = format(0, '0' + str(n_len) + 'b')
  for i in range(len(a)):
    y = add(y, mul(a[i], b[i]))
  return np.array(y)


# 行列積演算
def dot(a, b):
  y = []
  for i in range(len(a)):
    temp = []
    for j in range(len(b[0])):
      temp.append(inner(a[i], b[:, j]))
    y.append(temp)
  return np.array(y)


# tanh演算
def tanh(x):
  y = []
  for i in range(len(x)):
    rows = []
    for j in range(len(x[0])):
      temp = str_to_int(x[i][j]) / 2**f_len
      temp = np.tanh(temp) * 2**f_len
      temp = format(int(temp) & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
      rows.append(temp)
    y.append(rows)
  return np.array(y)



# エンコーダの順伝播
def encoder(x):
  W_emb = read_param(PATH + 'encoder_W_emb.txt').reshape(char_num, hid_dim)
  W_1   = read_param(PATH + 'encoder_W_1.txt').reshape(emb_dim, N, hid_dim)
  b_1   = read_param(PATH + 'encoder_b_1.txt').reshape(emb_dim, 1, hid_dim)
  W_2   = read_param(PATH + 'encoder_W_2.txt').reshape(hid_dim, emb_dim, 1)
  b_2   = read_param(PATH + 'encoder_b_2.txt').reshape(hid_dim, 1, 1)

  x = dot(x, W_emb)

  x = x.T
  x = x.reshape(emb_dim, 1, N)
  temp = []
  for i in range(emb_dim):
    rows = []
    mat = dot(x[i], W_1[i])
    for j in range(hid_dim):
      rows.append(add(mat[0][j], b_1[i][0][j]))
    temp.append(rows)
  x = np.array(temp)
  x = x.reshape(emb_dim, hid_dim)
  x = tanh(x)

  x = x.T
  x = x.reshape(hid_dim, 1, emb_dim)
  temp = []
  for i in range(hid_dim):
    rows = []
    mat = dot(x[i], W_2[i])
    for j in range(1):
      rows.append(add(mat[0][j], b_2[i][0][j]))
    temp.append(rows)
  x = np.array(temp)
  x = x.reshape(hid_dim, 1)
  x = tanh(x)

  return x


# デコーダの順伝播
def decoder(x):
  W_1   = read_param(PATH + 'decoder_W_1.txt').reshape(N, hid_dim, hid_dim)
  b_1   = read_param(PATH + 'decoder_b_1.txt').reshape(N, 1, hid_dim)
  W_out = read_param(PATH + 'decoder_W_out.txt').reshape(hid_dim, char_num)
  b_out = read_param(PATH + 'decoder_b_out.txt').reshape(N, char_num)

  x = x.T
  temp = []
  for i in range(N):
    rows = []
    mat = dot(x, W_1[i])
    for j in range(hid_dim):
      rows.append(add(mat[0][j], b_1[i][0][j]))
    temp.append(rows)
  x = np.array(temp)
  x = x.reshape(N, hid_dim)
  x = tanh(x)

  x = dot(x, W_out)
  for i in range(N):
    for j in range(char_num):
      x[i][j] = add(x[i][j], b_out[i][j])

  return x


# One-hotベクトルを文字列に変換する関数
def convert_str(x):
  x = np.array(char_list)[x.argmax(axis=1)]
  x = [c for c in x if c not in ['<PAD>', '<UNK>']]

  return ''.join(x)

# データセットを読み込む関数
def read_dataset(filename):
  kmj_dataset = []
  with open(filename, 'r', encoding='utf-8') as file:
    for line in file:
      kmj_dataset.append(line.replace('\n', ''))

  return kmj_dataset


if __name__ == '__main__':
  kmj_sample = ['(　́ω`)ノ', 'ヾ(*　∀́　*)ノ', '(*　̄∇　̄)ノ']

  # データの前処理
  kmj_onehot = preprocess(kmj_sample)

  # 順伝播
  for onehot in kmj_onehot:

    # 固定小数点に変換
    x = []
    for i in range(len(onehot)):
      rows = []
      for j in range(len(onehot[0])):
        temp = int(onehot[i][j] * 2**f_len)
        temp = format(temp & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
        rows.append(temp)
      x.append(rows)
    
    z = encoder(x)
    y = decoder(z)

    X = np.empty((N, char_num))
    Y = np.empty((N, char_num))
    for i in range(N):
      for j in range(char_num):        
        X[i][j] = str_to_int(x[i][j])
        Y[i][j] = str_to_int(y[i][j])
    print('base     :', convert_str(np.array(X)))
    print('generate :', convert_str(np.array(Y)))
  
  # データセットの読み込み
  kmj_dataset = read_dataset('../data/dataset/kaomoji_MAX=10_DA.txt')

  # データの前処理
  kmj_num = 100
  kmj_onehot = preprocess(kmj_dataset[:kmj_num])

  # 正解率計算
  acc_sum = 0
  for x in kmj_onehot:

    # 固定小数点に変換
    x = []
    for i in range(len(onehot)):
      rows = []
      for j in range(len(onehot[0])):
        temp = int(onehot[i][j] * 2**f_len)
        temp = format(temp & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
        rows.append(temp)
      x.append(rows)

    z = encoder(x)
    y = decoder(z)
    X = np.empty((N, char_num))
    Y = np.empty((N, char_num))
    for i in range(N):
      for j in range(char_num):        
        X[i][j] = str_to_int(x[i][j])
        Y[i][j] = str_to_int(y[i][j])
    acc_sum += (Y.argmax(axis=1) == X.argmax(axis=1)).sum()
  print('Acc :', acc_sum / (kmj_num * N))