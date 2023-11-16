import kmj_gen as kg
import kmj_gen_sim as kgs

# パラメータファイルのパス
DEC_PATH  = '../data/parameter/soft/decimal/'
BIN_PATH  = '../data/parameter/soft/binary/'

HARD16_PATH = '../data/parameter/hard/binary16/'
HARD96_PATH = '../data/parameter/hard/binary96/'

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


# 1行1データ(16bit)から1行6データ(96bit)に変換する関数
def convert_16_to_96(filename):
  param = kgs.read_param(HARD16_PATH + filename).reshape(-1, 6)
  with open(HARD96_PATH + filename, 'w') as file:
    for data in param:
      temp = ''.join(list(reversed(data)))
      file.write(temp + '\n')



if __name__ == '__main__':
  convert_dec_to_bin()

  file_list = ['mix_layer_W_1.txt', 'mix_layer_W_2.txt', 'mix_layer_W_3.txt', 'dense_layer_W_out.txt']
  for filename in file_list:
    convert_16_to_96(filename)