import kmj_gen

# パラメータファイルのパス
IN_PATH  = '../data/parameter/decimal/'
OUT_PATH = '../data/parameter/binary/'

# パラメータ名
param_names = {'encoder' : ['W_emb', 'W_1', 'b_1', 'W_2', 'b_2'],
               'decoder' : ['W_1', 'b_1', 'W_out', 'b_out']}

if __name__ == '__main__':
  for module_name in param_names.keys():
    for param_name in param_names[module_name]:
      filename = module_name + '_' + param_name + '.txt'
      param = kmj_gen.read_param(IN_PATH + filename)
      with open(OUT_PATH + filename, 'w') as file:
        for value in param:
          file.write(value + '\n')