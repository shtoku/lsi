import numpy as np
import kmj_gen_sim as kgs

# パラメータファイルのパス
BIN_PATH  = '../data/parameter/soft/binary/'
HARD_PATH = '../data/parameter/hard/binary16/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元

# 固定小数点の桁数
i_len = 6           # 整数部の桁数
f_len = 10          # 小数部の桁数
n_len = 16          # 整数部 + 小数部 の桁数


# mix_layer1用のパラメータファイルを生成する関数
def generate_mix1():
  en_W_1 = kgs.read_param(BIN_PATH + 'encoder_W_1.txt').reshape(emb_dim, N, hid_dim)
  en_b_1 = kgs.read_param(BIN_PATH + 'encoder_b_1.txt').reshape(emb_dim, 1, hid_dim)

  z_W_1 = np.full((hid_dim, hid_dim-N, hid_dim), format(0, '0' + str(n_len) + 'b'))
  
  mix_W_1 = np.concatenate([en_W_1, z_W_1], axis=1)
  mix_b_1 = en_b_1
  
  with open(HARD_PATH + 'mix_layer_W_1.txt', 'w') as file:
    for value in mix_W_1.flatten():
      file.write(value + '\n')
  
  with open(HARD_PATH + 'mix_layer_b_1.txt', 'w') as file:
    for value in mix_b_1.flatten():
      file.write(value + '\n')


# mix_layer2用のパラメータファイルを生成する関数
def generate_mix2():
  en_W_2 = kgs.read_param(BIN_PATH + 'encoder_W_2.txt').reshape(hid_dim, emb_dim, 1)
  en_b_2 = kgs.read_param(BIN_PATH + 'encoder_b_2.txt').reshape(hid_dim, 1, 1)

  z_W_2 = np.full((hid_dim, hid_dim, hid_dim-1), format(0, '0' + str(n_len) + 'b'))
  z_b_2 = np.full((hid_dim, 1, hid_dim-1), format(0, '0' + str(n_len) + 'b'))
  
  mix_W_2 = np.concatenate([en_W_2, z_W_2], axis=2)
  mix_b_2 = np.concatenate([en_b_2, z_b_2], axis=2)
  
  with open(HARD_PATH + 'mix_layer_W_2.txt', 'w') as file:
    for value in mix_W_2.flatten():
      file.write(value + '\n')
  
  with open(HARD_PATH + 'mix_layer_b_2.txt', 'w') as file:
    for value in mix_b_2.flatten():
      file.write(value + '\n')


# mix_layer3用のパラメータファイルを生成する関数
def generate_mix3():
  de_W_1 = kgs.read_param(BIN_PATH + 'decoder_W_1.txt').reshape(N, hid_dim, hid_dim)
  de_b_1 = kgs.read_param(BIN_PATH + 'decoder_b_1.txt').reshape(N, 1, hid_dim)

  z_W_3 = np.full((hid_dim-N, hid_dim, hid_dim), format(0, '0' + str(n_len) + 'b'))
  z_b_3 = np.full((hid_dim-N, 1, hid_dim), format(0, '0' + str(n_len) + 'b'))
  
  mix_W_3 = np.concatenate([de_W_1, z_W_3], axis=0)
  mix_b_3 = np.concatenate([de_b_1, z_b_3], axis=0)
  
  with open(HARD_PATH + 'mix_layer_W_3.txt', 'w') as file:
    for value in mix_W_3.flatten():
      file.write(value + '\n')
  
  with open(HARD_PATH + 'mix_layer_b_3.txt', 'w') as file:
    for value in mix_b_3.flatten():
      file.write(value + '\n')


# FPGA用のパラメータファイルを生成する関数
def generate_hard():
  W_emb = kgs.read_param(BIN_PATH + 'encoder_W_emb.txt')
  with open(HARD_PATH + 'emb_layer_W_emb.txt', 'w') as file:
    for value in W_emb:
      file.write(value + '\n')

  generate_mix1()
  generate_mix2()
  generate_mix3()

  W_out = kgs.read_param(BIN_PATH + 'decoder_W_out.txt')
  with open(HARD_PATH + 'dense_layer_W_out.txt', 'w') as file:
    for value in W_out:
      file.write(value + '\n')
  
  b_out = kgs.read_param(BIN_PATH + 'decoder_b_out.txt')
  with open(HARD_PATH + 'dense_layer_b_out.txt', 'w') as file:
    for value in b_out:
      file.write(value + '\n')


if __name__ == '__main__':
  generate_hard()