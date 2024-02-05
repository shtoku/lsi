from time import time, sleep
from functions import *
from controller import Controller

N = 10
batch_size = 32

# 使用できる文字のリストを読み込み
char_list = []
with open('char_list.txt' , 'r', encoding='utf-8') as file:
  for line in file:
    char_list.append(line.replace('\n', ''))


# 学習用の関数（パイプラインでデータ送信）
def train(n_epochs, data_train, data_valid):
  learning_time = 0

  for epoch in range(n_epochs):
    acc_train = 0
    acc_valid = 0
      
    start = time()
    
    # Train
    pl.top_mmio.write(1*4, 0)    # slv_reg1[1:0] : mode (TRAIN)

    pl.send_data(dataloader_train[0])
    pl.top_mmio.write(0*4, 0b101)    # slv_reg0[2:0] : {next, run, rst_n}
    pl.top_mmio.write(0*4, 0b011)    # slv_reg0[2:0] : {next, run, rst_n}

    for i, batch in enumerate(data_train[1:]):
      pl.send_data(batch)
      
      while pl.top_mmio.read(2*4) != 1: # slv_reg2[0] : finish
        sleep(0.001)

      pl.top_mmio.write(0*4, 0b101)    # slv_reg0[2:0] : {next, run, rst_n}
      pl.top_mmio.write(0*4, 0b011)    # slv_reg0[2:0] : {next, run, rst_n}
        
      recv_data = pl.recv_data()
      acc_train += (recv_data == data_train[i]).sum()
    
    while pl.top_mmio.read(2*4) != 1: # slv_reg2[0] : finish
      sleep(0.001)
    
    recv_data = pl.recv_data()
    acc_train += (recv_data == data_train[-1]).sum()


    # Valid
    pl.top_mmio.write(1*4, 1)    # slv_reg1[1:0] : mode (FORWARD)

    pl.send_data(data_valid[0])
    pl.top_mmio.write(0*4, 0b101)    # slv_reg0[2:0] : {next, run, rst_n}
    pl.top_mmio.write(0*4, 0b011)    # slv_reg0[2:0] : {next, run, rst_n}

    for i, batch in enumerate(data_valid[1:]):
      pl.send_data(batch)
      
      while pl.top_mmio.read(2*4) != 1: # slv_reg2[0] : finish
        sleep(0.001)

      pl.top_mmio.write(0*4, 0b101)    # slv_reg0[2:0] : {next, run, rst_n}
      pl.top_mmio.write(0*4, 0b011)    # slv_reg0[2:0] : {next, run, rst_n}
        
      recv_data = pl.recv_data()
      acc_valid += (recv_data == data_valid[i]).sum()
    
    while pl.top_mmio.read(2*4) != 1: # slv_reg2[0] : finish
      sleep(0.001)
    
    recv_data = pl.recv_data()
    acc_valid += (recv_data == data_valid[-1]).sum()

    end = time()
    learning_time += end - start

    print('EPOCH: {:>3}, Train Acc: {:>.3f}, Valid Acc: {:>.3f}, Time: {:>6.3f}'.format(
            epoch+1,
            acc_train / (len(data_train) * batch_size * N),
            acc_valid / (len(data_valid) * batch_size * N),
            learning_time
        ))


if __name__ == '__main__':  

  # ミニバッチ作成
  dataloader_train, dataloader_valid, dataloader_test = create_batch(batch_size, N, char_list)

  # PL制御クラスのインスタンス
  pl = Controller('kaomoji_generator.bit', batch_size, N)

  mode_list = ['TRAIN', 'FORWARD', 'SIMILAR', 'NEW']

  while True:
    print('Select mode')
    print('TRAIN:0, FORWARD:1, SIMILAR:2, NEW:3  : ', end='')

    try:
      mode = int(input())
      print(mode_list[mode], 'mode')
    except:
      print('Invalid input : mode is int. (0, 1, 2, 3)')
      continue

    if mode == 0:
      print('epochs : ', end='')

      try:
        epochs = int(input())
      except:
        print('Invalid input : epochs is int.')
        continue

      train(epochs, dataloader_train, dataloader_valid)
    else:
      if mode == 1 or mode == 2:
        print('base     : ', end='')
        kmj_in = input()
        if N < len(kmj_in):
          print(f'Invalid input : max size is {N}. input size is {len(kmj_in)}.')
          continue
        kmj_in = preprocess([kmj_in], N, char_list).argmax(axis=-1)
      else:
        kmj_in = np.zeros((1, N))
      
      kmj_in = np.full((batch_size, N), kmj_in)
      pl.send_data(kmj_in)
      pl.run_mode(mode)
      recv_data = pl.recv_data()

      if mode == 1:
        print('generate :', convert_int_str(recv_data[0], char_list))
      else:
        for i in range(batch_size):
          print('generate :', convert_int_str(recv_data[i], char_list))
