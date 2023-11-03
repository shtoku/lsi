import kmj_gen as kg

# パラメータファイルのパス
DEC_PATH  = '../data/parameter/soft/decimal/'
BIN_PATH  = '../data/parameter/soft/binary/'

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


if __name__ == '__main__':
  convert_dec_to_bin()