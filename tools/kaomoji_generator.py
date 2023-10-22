import numpy as np


# パラメータファイルのパス
PATH = '../data/parameter/decimal/'


N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元


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
      param.append(float(line.replace('\n', '')))
  return np.array(param)


# エンコーダの順伝播
def encoder(x):
  W_emb = read_param(PATH + 'encoder_W_emb.txt').reshape(char_num, hid_dim)
  W_1   = read_param(PATH + 'encoder_W_1.txt').reshape(emb_dim, N, hid_dim)
  b_1   = read_param(PATH + 'encoder_b_1.txt').reshape(emb_dim, 1, hid_dim)
  W_2   = read_param(PATH + 'encoder_W_2.txt').reshape(hid_dim, emb_dim, 1)
  b_2   = read_param(PATH + 'encoder_b_2.txt').reshape(hid_dim, 1, 1)

  x = np.dot(x, W_emb)

  x = x.T
  x = x.reshape(emb_dim, 1, N)
  temp = []
  for i in range(emb_dim):
    temp.append(np.dot(x[i], W_1[i]) + b_1[i])
  x = np.array(temp)
  x = x.reshape(emb_dim, hid_dim)

  x = x.T
  x = x.reshape(hid_dim, 1, emb_dim)
  temp = []
  for i in range(hid_dim):
    temp.append(np.dot(x[i], W_2[i]) + b_2[i])
  x = np.array(temp)
  x = x.reshape(hid_dim, 1)

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
    temp.append(np.dot(x, W_1[i]) + b_1[i])
  x = np.array(temp)
  x = x.reshape(N, hid_dim)

  x = np.matmul(x, W_out) + b_out

  return x


def convert_str(x):
  x = np.array(char_list)[x.argmax(axis=1)]
  x = [c for c in x if c not in ['<PAD>', '<UNK>']]

  return ''.join(x)


if __name__ == '__main__':
  kmj_sample = ['(　́ω`)ノ', 'ヾ(*　∀́　*)ノ', '(*　̄∇　̄)ノ']

  # データの前処理
  kmj_onehot = preprocess(kmj_sample)

  # 順伝播
  for x in kmj_onehot:
    z = encoder(x)
    y = decoder(z)
    print('base     :', convert_str(x))
    print('generate :', convert_str(y))