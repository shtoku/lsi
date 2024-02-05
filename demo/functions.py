import numpy as np


# 文字リストの番号を顔文字中の番号を対応付け
def convert_str_int(kmj_data, N, char_list):
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
  
  return kmj_index


# 整数列を文字列に変換
def convert_int_str(kmj_index, char_list):
  kmj_data = np.array(char_list)[kmj_index]
  kmj_data = [c for c in kmj_data if c not in ['<PAD>', '<UNK>']]

  return ''.join(kmj_data)


# データセットを読み込む関数
def read_dataset(filename):
  kmj_dataset = []
  with open(filename, 'r', encoding='utf-8') as file:
    for line in file:
      kmj_dataset.append(line.replace('\n', ''))

  return kmj_dataset


# データの前処理を行う関数
# 顔文字を文字ごとに分解 -> 番号付け -> One-hotベクトル
def preprocess(kmj_data, N, char_list):

  # 文字リストの番号を顔文字中の番号を対応付け
  kmj_index = convert_str_int(kmj_data, N, char_list)

  # 付けた番号をOne-hotベクトル化
  kmj_num = len(kmj_index)                        # 顔文字数
  char_num = len(char_list)                       # 文字の種類数
  kmj_onehot = np.zeros((kmj_num, N, char_num))   # One-hotベクトルリスト
  for i, index in enumerate(kmj_index):
    mask = range(char_num) == np.array(index).reshape((N, 1))
    kmj_onehot[i][mask] = 1
  
  return kmj_onehot


# ミニバッチを作成する関数
def create_batch(batch_size, N, char_list):
  # データセットの読み込み
  kmj_dataset = read_dataset('dataset.txt')

  # データの前処理
  kmj_onehot = preprocess(kmj_dataset, N, char_list)
  kmj_int = kmj_onehot.argmax(axis=-1)

  # データセットを分割
  train_size = int(len(kmj_dataset) * 0.85)
  valid_size = int(len(kmj_dataset) * 0.10)
  test_size  = len(kmj_dataset) - train_size - valid_size

  dataset_train = kmj_int[:train_size]
  dataset_valid = kmj_int[train_size:train_size+valid_size]
  dataset_test  = kmj_int[train_size+valid_size:]

  # ミニバッチに分割
  n_train = int(train_size / batch_size)
  n_valid = int(valid_size / batch_size)
  n_test  = int( test_size / batch_size)

  dataloader_train = [dataset_train[i*batch_size:(i+1)*batch_size] for i in range(n_train)]
  dataloader_valid = [dataset_valid[i*batch_size:(i+1)*batch_size] for i in range(n_valid)]
  dataloader_test  = [ dataset_test[i*batch_size:(i+1)*batch_size] for i in range(n_test )]

  return dataloader_train, dataloader_valid, dataloader_test
