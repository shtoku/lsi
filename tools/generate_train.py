import numpy as np
import kmj_gen_np as kgn


PATH_DEC = '../data/parameter/train/decimal/'
PATH_BIN18 = '../data/parameter/train/binary18/'
PATH_BIN108 = '../data/parameter/train/binary108/'
PATH_BIN192 = '../data/parameter/train/binary192/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


# 固定小数点の桁数
i_len = 8           # 整数部の桁数
f_len = 16          # 小数部の桁数
n_len = 24          # 整数部 + 小数部 の桁数

i_len_w = 2         # W_out 以外の整数部の桁数


# ファイルに出力する関数
def output_file(filename, param):
  with open(filename, 'w') as file:
    for value in param:
      file.write(str(value) + '\n')


# 訓練用初期値を生成する関数
def generate_initial_value():
  W_emb = np.random.uniform(low=-np.sqrt(6 / (char_num + emb_dim)), high=np.sqrt(6 / (char_num + emb_dim)), size=(char_num, emb_dim))
  output_file(PATH_DEC + 'emb_layer_W_emb.txt', W_emb.flatten())

  W_1 = np.random.uniform(low=-np.sqrt(6 / (N + hid_dim)), high=np.sqrt(6 / (N + hid_dim)), size=(emb_dim, N, hid_dim))
  output_file(PATH_DEC + 'mix_layer_W_1.txt', W_1.flatten())

  b_1 = np.zeros((emb_dim, 1, hid_dim))
  output_file(PATH_DEC + 'mix_layer_b_1.txt', b_1.flatten())

  W_2 = np.random.uniform(low=-np.sqrt(6 / (emb_dim + 1)), high=np.sqrt(6 / (emb_dim + 1)), size=(hid_dim, emb_dim, 1))
  output_file(PATH_DEC + 'mix_layer_W_2.txt', W_2.flatten())

  b_2 = np.zeros((hid_dim, 1, 1))
  output_file(PATH_DEC + 'mix_layer_b_2.txt', b_2.flatten())

  W_3 = np.random.uniform(low=-np.sqrt(6 / (hid_dim + N)), high=np.sqrt(6 / (hid_dim + N)), size=(N, hid_dim, hid_dim))
  output_file(PATH_DEC + 'mix_layer_W_3.txt', W_3.flatten())

  b_3 = np.zeros((N, 1, hid_dim))
  output_file(PATH_DEC + 'mix_layer_b_3.txt', b_3.flatten())

  W_out = np.random.uniform(low=-np.sqrt(6 / (hid_dim + char_num)), high=np.sqrt(6 / (hid_dim + char_num)), size=(hid_dim, char_num))
  output_file(PATH_DEC + 'dense_layer_W_out.txt', W_out.flatten())


# 10進数を2進数(文字列)に変換する関数
def convert_dec_to_bin(x, i_len, f_len):
  n_len = i_len + f_len
  temp = []
  for value in x:
    value = int(np.floor(value * 2**f_len))
    value = format(value & ((1 << n_len) - 1), '0' + str(n_len) + 'b')
    temp.append(value)
  return np.array(temp)


# 値を6個並べてファイルに出力する関数
def output_param_6(filename, param, num=6):
  with open(filename, 'w') as file:
    for data in param.reshape(-1, num):
      temp = ''.join(list(reversed(data)))
      file.write(temp + '\n')


# 訓練用のFPGA用のテキストファイルを生成する関数
def generate_hard():
  W_emb = kgn.read_param(PATH_DEC + 'emb_layer_W_emb.txt')
  W_emb = convert_dec_to_bin(W_emb, i_len_w, f_len).reshape(char_num, emb_dim)
  output_param_6(PATH_BIN108 + 'emb_layer_W_emb.txt', W_emb)

  W_1 = kgn.read_param(PATH_DEC + 'mix_layer_W_1.txt')
  b_1 = kgn.read_param(PATH_DEC + 'mix_layer_b_1.txt')
  W_1 = convert_dec_to_bin(W_1, i_len_w, f_len).reshape(emb_dim, N, hid_dim)
  b_1 = convert_dec_to_bin(b_1, i_len_w, f_len).reshape(emb_dim, hid_dim)
  z_W_1 = np.full((hid_dim, hid_dim-N, hid_dim), format(0, '0' + str(i_len_w + f_len) + 'b'))  
  W_1 = np.concatenate([W_1, z_W_1], axis=1)
  for i in range(emb_dim):
    output_param_6(PATH_BIN108 + 'mix_layer_W_1/mix_layer_W_1_' + format(i, '02') + '.txt', W_1[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_1/mix_layer_W_1_' + format(i) + '.txt', W_1[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_1/mix_layer_W_1_T_' + format(i, '02') + '.txt', W_1[i].T)
    output_param_6(PATH_BIN108 + 'mix_layer_W_1/mix_layer_W_1_T_' + format(i) + '.txt', W_1[i].T)
    output_file(PATH_BIN18 + 'mix_layer_b_1/mix_layer_b_1_' + format(i, '02') + '.txt', b_1[i])
    output_file(PATH_BIN18 + 'mix_layer_b_1/mix_layer_b_1_' + format(i) + '.txt', b_1[i])
  
  W_2 = kgn.read_param(PATH_DEC + 'mix_layer_W_2.txt')
  b_2 = kgn.read_param(PATH_DEC + 'mix_layer_b_2.txt')
  W_2 = convert_dec_to_bin(W_2, i_len_w, f_len).reshape(hid_dim, emb_dim, 1)
  b_2 = convert_dec_to_bin(b_2, i_len_w, f_len).reshape(hid_dim, 1)
  z_W_2 = np.full((hid_dim, hid_dim, hid_dim-1), format(0, '0' + str(i_len_w + f_len) + 'b'))
  z_b_2 = np.full((hid_dim, hid_dim-1), format(0, '0' + str(i_len_w + f_len) + 'b'))
  W_2 = np.concatenate([W_2, z_W_2], axis=2)
  b_2 = np.concatenate([b_2, z_b_2], axis=1)
  for i in range(hid_dim):
    output_param_6(PATH_BIN108 + 'mix_layer_W_2/mix_layer_W_2_' + format(i, '02') + '.txt', W_2[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_2/mix_layer_W_2_' + format(i) + '.txt', W_2[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_2/mix_layer_W_2_T_' + format(i, '02') + '.txt', W_2[i].T)
    output_param_6(PATH_BIN108 + 'mix_layer_W_2/mix_layer_W_2_T_' + format(i) + '.txt', W_2[i].T)
    output_file(PATH_BIN18 + 'mix_layer_b_2/mix_layer_b_2_' + format(i, '02') + '.txt', b_2[i])
    output_file(PATH_BIN18 + 'mix_layer_b_2/mix_layer_b_2_' + format(i) + '.txt', b_2[i])
  
  W_3 = kgn.read_param(PATH_DEC + 'mix_layer_W_3.txt')
  b_3 = kgn.read_param(PATH_DEC + 'mix_layer_b_3.txt')
  W_3 = convert_dec_to_bin(W_3, i_len_w, f_len).reshape(N, hid_dim, hid_dim)
  b_3 = convert_dec_to_bin(b_3, i_len_w, f_len).reshape(N, hid_dim)
  z_W_3 = np.full((hid_dim-N, hid_dim, hid_dim), format(0, '0' + str(i_len_w + f_len) + 'b'))
  z_b_3 = np.full((hid_dim-N, hid_dim), format(0, '0' + str(i_len_w + f_len) + 'b'))  
  W_3 = np.concatenate([W_3, z_W_3], axis=0)
  b_3 = np.concatenate([b_3, z_b_3], axis=0)
  for i in range(hid_dim):
    output_param_6(PATH_BIN108 + 'mix_layer_W_3/mix_layer_W_3_' + format(i, '02') + '.txt', W_3[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_3/mix_layer_W_3_' + format(i) + '.txt', W_3[i])
    output_param_6(PATH_BIN108 + 'mix_layer_W_3/mix_layer_W_3_T_' + format(i, '02') + '.txt', W_3[i].T)
    output_param_6(PATH_BIN108 + 'mix_layer_W_3/mix_layer_W_3_T_' + format(i) + '.txt', W_3[i].T)
    output_file(PATH_BIN18 + 'mix_layer_b_3/mix_layer_b_3_' + format(i, '02') + '.txt', b_3[i])
    output_file(PATH_BIN18 + 'mix_layer_b_3/mix_layer_b_3_' + format(i) + '.txt', b_3[i])

  W_out = kgn.read_param(PATH_DEC + 'dense_layer_W_out.txt')
  W_out = convert_dec_to_bin(W_out, i_len, f_len).reshape(hid_dim, char_num)
  output_param_6(PATH_BIN192 + 'dense_layer_W_out.txt', W_out, num=8)
  output_param_6(PATH_BIN192 + 'dense_layer_W_out_T.txt', W_out.T, num=8)


# 初期値用のゼロファイルを作成する関数
def generate_zeros():
  W_emb = np.zeros((char_num, emb_dim))
  W_emb = convert_dec_to_bin(W_emb.flatten(), i_len_w, f_len)
  output_param_6(PATH_BIN108 + 'zeros_like_W_emb.txt', W_emb)

  W_mix = np.zeros((3, hid_dim, hid_dim))
  W_mix = convert_dec_to_bin(W_mix.flatten(), i_len_w, f_len)
  output_param_6(PATH_BIN108 + 'zeros_like_W_mix.txt', W_mix)

  b_mix = np.zeros((3, 1, hid_dim))
  b_mix = convert_dec_to_bin(b_mix.flatten(), i_len_w, f_len)
  output_file(PATH_BIN18 + 'zeros_like_b_mix.txt', b_mix)
  
  W_out = np.zeros((hid_dim, char_num))
  W_out = convert_dec_to_bin(W_out.flatten(), i_len, f_len)
  output_param_6(PATH_BIN192 + 'zeros_like_W_out.txt', W_out, num=8)


# テーブル用のファイルの作成する関数
def generate_table():
  # tanh
  x = np.arange(-8, 8, 2**(-6))   # 入力値 (整数：4bit 小数：6bit)
  y = np.tanh(x)
  output_file(PATH_BIN18 + 'tanh_table.txt', convert_dec_to_bin(y, 2, 16))

  # exp
  x = np.arange(-16, 0, 2**(-6))   # 入力値 (整数：4bit 小数：6bit)
  y = np.exp(x)
  output_file(PATH_BIN18 + 'exp_table.txt', convert_dec_to_bin(y, 2, 16))

  # inverse
  x = np.arange(0, 2**10 / 2**2, 2**(-2))   # 入力値 (整数：8bit 小数：2bit)
  x[0] = x[1]
  y = 1 / x
  mask = (y > 2**2 - 2**(-16))
  y[mask] = 2**2 - 2**(-16)
  output_file(PATH_BIN18 + 'inverse_table.txt', convert_dec_to_bin(y, 2, 16))


if __name__ == '__main__':
  # generate_initial_value()
  generate_hard()
  generate_zeros()

  generate_table()