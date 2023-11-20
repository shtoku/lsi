import numpy as np
import kmj_gen as kg
import xorshift

# パラメータファイルのパス
HARD16_PATH = '../data/parameter/hard/binary16/'
HARD96_PATH = '../data/parameter/hard/binary96/'
TB_PATH     = '../data/tb/'


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
      temp = [temp[i:i+n_len] for i in range(0, len(temp), n_len)]
      param.extend(list(reversed(temp)))
  return np.array(param)


# emb_layer
# 対応する重みを取り出すだけ
def emb_layer(x):
  W_emb = read_param(HARD16_PATH + 'emb_layer_W_emb.txt').reshape(char_num, hid_dim)

  return W_emb[x]


# mix_layer
# ゼロパディングした入力を重み，バイアスを用いて常に同形上の計算を行う
def mix_layer(layer, x):
  W_PATH = HARD96_PATH + 'mix_layer_W_' + str(layer) + '/'
  B_PATH = HARD16_PATH + 'mix_layer_b_' + str(layer) + '/'
  W = []
  b = []
  for i in range(hid_dim):
    W_temp = read_param(W_PATH + 'mix_layer_W_' + str(layer) + '_' + format(i, '02') + '.txt').reshape(hid_dim, hid_dim).T
    b_temp = read_param(B_PATH + 'mix_layer_b_' + str(layer) + '_' + format(i, '02') + '.txt').reshape(1, hid_dim)
    W.append(W_temp)
    b.append(b_temp)
  W = np.array(W)
  b = np.array(b)

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
  # x = kg.tanh(x)

  return x


# dense_layer
# 行列積+バイアスのみ．バイアスは無くても良いかもしれない
def dense_layer(x):
  W_out = read_param(HARD16_PATH + 'dense_layer_W_out.txt').reshape(char_num, hid_dim).T
  # b_out = read_param(HARD16_PATH + 'dense_layer_b_out.txt').reshape(N, char_num)

  x = kg.dot(x, W_out)
  # for i in range(N):
  #   for j in range(char_num):
  #     x[i][j] = kg.add(x[i][j], b_out[i][j])
  
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


def output_file(x, filename):
  with open(filename, 'w') as file:
    for value in x.flatten():
      if isinstance(value, np.int64):
        value = format(value, '08b')
      file.write(value + '\n')


if __name__ == '__main__':
  kmj = ['(　́ω`)ノ']

  # データの前処理
  kmj_onehot = kg.preprocess(kmj)

  # 入力データ
  x = kmj_onehot[0].argmax(axis=1)
  
  # emb_layer
  output_file(x, TB_PATH + 'emb_layer_in_tb.txt')
  o_emb = emb_layer(x)
  output_file(o_emb, TB_PATH + 'emb_layer_out_tb.txt')

  # mix_layer1
  # 入力のゼロパディング
  z_mix1 = np.full((hid_dim-N, hid_dim), format(0, '0' + str(n_len) + 'b'))
  i_mix1 = np.concatenate([o_emb, z_mix1], axis=0)
  output_file(i_mix1, TB_PATH + 'mix_layer1_in_tb.txt')
  o_mix1 = mix_layer(1, i_mix1)
  output_file(o_mix1, TB_PATH + 'mix_layer1_out_tb.txt')

  # mix_layer2
  output_file(o_mix1, TB_PATH + 'mix_layer2_in_tb.txt')
  o_mix2 = mix_layer(2, o_mix1)
  output_file(o_mix2, TB_PATH + 'mix_layer2_out_tb.txt')
  
  # mix_layer3
  # 入力を複製
  i_mix3 = np.full((hid_dim, hid_dim), o_mix2[:, 0]).T
  output_file(i_mix3, TB_PATH + 'mix_layer3_in_tb.txt')
  o_mix3 = mix_layer(3, i_mix3)
  output_file(o_mix3, TB_PATH + 'mix_layer3_out_tb.txt')

  # dense_layer
  i_dens = o_mix3[:N, :]
  output_file(i_dens, TB_PATH + 'dense_layer_in_tb.txt')
  o_dens = dense_layer(i_dens)
  output_file(o_dens, TB_PATH + 'dense_layer_out_tb.txt')

  # comp_layer
  output_file(o_dens, TB_PATH + 'comp_layer_in_tb.txt')
  o_comp = comp_layer(o_dens)
  output_file(o_comp, TB_PATH + 'comp_layer_out_tb.txt')

  print('base     :', convert_str(x))
  print('generate :', convert_str(o_comp))


  # 類似生成・新規生成テスト
  xors = xorshift.XorShift(5671)
  
  for _ in range(10):
    z = np.empty_like(o_mix2[:, 0])
    for i in range(hid_dim):
      # z[i] = kg.add(o_mix2[:, 0][i], xors())  # 類似生成
      z[i] = xors()                           # 新規生成

    # mix_layer3
    # 入力を複製
    i_mix3 = np.full((hid_dim, hid_dim), z).T
    o_mix3 = mix_layer(3, i_mix3)

    # dense_layer
    i_dens = o_mix3[:N, :]
    o_dens = dense_layer(i_dens)

    # comp_layer
    o_comp = comp_layer(o_dens)

    print('generate :', convert_str(o_comp))