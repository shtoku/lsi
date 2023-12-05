import kmj_gen as kg
import kmj_gen_sim as kgs

# パラメータファイルのパス
DEC_PATH  = '../data/parameter/soft/decimal/'
BIN_PATH  = '../data/parameter/soft/binary/'

HARD16_PATH = '../data/parameter/hard/binary16/'
HARD96_PATH = '../data/parameter/hard/binary96/'

N = 10              # 最大文字数
char_num = 200      # 文字種数
emb_dim = 24        # 文字ベクトルの次元
hid_dim = 24        # 潜在ベクトルの次元

# パラメータ名
param_names = {'encoder' : ['W_emb', 'W_1', 'b_1', 'W_2', 'b_2'],
               'decoder' : ['W_1', 'b_1', 'W_out', 'b_out']}


# 10進数のファイルから2進数(固定小数点)のファイルに変換する関数
def convert_dec_to_bin():
  for module_name in param_names.keys():
    for param_name in param_names[module_name]:
      filename = module_name + '_' + param_name + '.txt'
      param = kg.read_param(DEC_PATH + filename)
      with open(BIN_PATH + filename, 'w') as file:
        for value in param:
          file.write(value + '\n')


# mix_layerの重みを24に分割して,
# 1行1データ(16bit)から1行6データ(96bit)に変換する関数
def convert_16_to_96_mix(filename):
  PATH = HARD96_PATH + filename + '/'
  param = kgs.read_param(HARD16_PATH + filename + '.txt').reshape(hid_dim, hid_dim, hid_dim)
  for i, mat in enumerate(param):
    mat = mat.T.reshape(-1, 6)
    with open(PATH + filename + '_' + format(i, '02') + '.txt', 'w') as file:
      for data in mat:
        temp = ''.join(list(reversed(data)))
        file.write(temp + '\n')
    with open(PATH + filename + '_' + format(i) + '.txt', 'w') as file:
      for data in mat:
        temp = ''.join(list(reversed(data)))
        file.write(temp + '\n')


# mix_layerのバイアスを24個に分ける
def split_bias_24_mix(filename):
  PATH = HARD16_PATH + filename + '/'
  param = kgs.read_param(HARD16_PATH + filename + '.txt').reshape(hid_dim, hid_dim)
  for i, vec in enumerate(param):
    with open(PATH + filename + '_' + format(i, '02') + '.txt', 'w') as file:
      for data in vec:
        file.write(data + '\n')
    with open(PATH + filename + '_' + format(i) + '.txt', 'w') as file:
      for data in vec:
        file.write(data + '\n')



# dense_layerの重みを24に分割して,
# 1行1データ(16bit)から1行6データ(96bit)に変換する関数
def convert_16_to_96_dense(filename):
  param = kgs.read_param(HARD16_PATH + filename + '.txt').reshape(hid_dim, char_num)
  param = param.reshape(-1, 6)
  with open(HARD96_PATH + filename + '.txt', 'w') as file:
    for data in param:
      temp = ''.join(list(reversed(data)))
      file.write(temp + '\n')


if __name__ == '__main__':
  convert_dec_to_bin()

  for i in range(1, 4):
    convert_16_to_96_mix('mix_layer_W_' + str(i))
    split_bias_24_mix('mix_layer_b_' + str(i))
  
convert_16_to_96_dense('dense_layer_W_out')