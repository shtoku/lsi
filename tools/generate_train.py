import numpy as np


PATH_DEC = '../data/parameter/train/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


# 固定小数点の桁数
i_len = 6           # 整数部の桁数
f_len = 10          # 小数部の桁数
n_len = 16          # 整数部 + 小数部 の桁数


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



if __name__ == '__main__':
  generate_initial_value()