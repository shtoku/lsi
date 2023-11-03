import numpy as np
import kmj_gen as kg

# パラメータファイルのパス
PATH = '../data/parameter/hard/binary/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元

# 固定小数点の桁数
i_len = 6           # 整数部の桁数
f_len = 10          # 小数部の桁数
n_len = 16          # 整数部 + 小数部 の桁数


# パラメータファイルからデータを読む関数
def read_param(filename):
  param = []
  with open(filename, 'r') as file:
    for line in file:
      temp = line.replace('\n', '')
      param.append(temp)
  return np.array(param)


# emb_layer
# 対応する重みを取り出すだけ
def emb_layer(x):
  W_emb = read_param(PATH + 'emb_layer_W_emb.txt').reshape(char_num, hid_dim)

  return W_emb[x]


# mix_layer
# ゼロパディングした入力を重み，バイアスを用いて常に同形上の計算を行う
def mix_layer(layer, x):
  W = read_param(PATH + 'mix_layer_W_' + str(layer) + '.txt').reshape(hid_dim, hid_dim, hid_dim)
  b = read_param(PATH + 'mix_layer_b_' + str(layer) + '.txt').reshape(hid_dim, 1, hid_dim)

  x = x.T
  x = x.reshape(hid_dim, 1, hid_dim)
  temp = []
  for i in range(hid_dim):
    rows = []
    mat = kg.dot(x[i], W[i])
    for j in range(hid_dim):
      rows.append(kg.add(mat[0][j], b[i][0][j]))
    temp.append(rows)
  x = np.array(temp)
  x = kg.tanh(x)

  return x


# dense_layer
# 行列積+バイアスのみ．バイアスは無くても良いかもしれない
def dense_layer(x):
  W_out = read_param(PATH + 'dense_layer_W_out.txt').reshape(hid_dim, char_num)
  b_out = read_param(PATH + 'dense_layer_b_out.txt').reshape(N, char_num)

  x = kg.dot(x, W_out)
  for i in range(N):
    for j in range(char_num):
      x[i][j] = kg.add(x[i][j], b_out[i][j])
  
  return x


# comp_layer
# 行ベクトルの要素の最大値の番号を取り出す
def comp_layer(x):
  X = np.empty((N, char_num))
  for i in range(N):
    for j in range(char_num):        
      X[i][j] = kg.str_to_int(x[i][j])
  
  return X.argmax(axis=1)


# 整数列を文字列に変換する関数
def convert_str(x):
  x = np.array(kg.char_list)[x]
  x = [c for c in x if c not in ['<PAD>', '<UNK>']]

  return ''.join(x)


if __name__ == '__main__':
  kmj = ['(　́ω`)ノ']

  # データの前処理
  kmj_onehot = kg.preprocess(kmj)

  # 入力データ
  x = kmj_onehot[0].argmax(axis=1)
  
  # emb_layer
  o_emb = emb_layer(x)

  # mix_layer1
  # 入力のゼロパディング
  z_mix1 = np.full((hid_dim-N, hid_dim), format(0, '0' + str(n_len) + 'b'))
  i_mix1 = np.concatenate([o_emb, z_mix1], axis=0)
  o_mix1 = mix_layer(1, i_mix1)

  # mix_layer2
  o_mix2 = mix_layer(2, o_mix1)
  
  # mix_layer3
  # 入力を複製
  i_mix3 = np.full((hid_dim, hid_dim), o_mix2[:, 0]).T
  o_mix3 = mix_layer(3, i_mix3)

  # dense_layer
  o_dens = dense_layer(o_mix3)

  # comp_layer
  o_comp = comp_layer(o_dens)

  print('base     :', convert_str(x))
  print('generate :', convert_str(o_comp))