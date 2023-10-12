import tensorflow as tf

# エンコーダの定義
class Encoder(tf.keras.Model):
    def __init__(self):
        super(Encoder, self).__init__()

        self.conv1 = tf.keras.layers.Conv2D(32, 3, padding='same', activation='relu')
        self.maxpool1 = tf.keras.layers.MaxPooling2D(2, 2)
        self.conv2 = tf.keras.layers.Conv2D(64, 3, padding='same', activation='relu')
        self.maxpool2 = tf.keras.layers.MaxPooling2D(2, 2)

    def call(self, x):
        x = self.conv1(x)
        x = self.maxpool1(x)
        x = self.conv2(x)
        x = self.maxpool2(x)
        return x

# デコーダの定義
class Decoder(tf.keras.Model):
    def __init__(self):
        super(Decoder, self).__init__()

        self.upconv1 = tf.keras.layers.Conv2DTranspose(32, 3, padding='same', activation='relu', strides=(2, 2))
        self.upconv2 = tf.keras.layers.Conv2DTranspose(1, 3, padding='same', activation='sigmoid', strides=(2, 2))

    def call(self, x):
        x = self.upconv1(x)
        x = self.upconv2(x)
        return x

# モデルの定義
class AutoEncoder(tf.keras.Model):
    def __init__(self):
        super(AutoEncoder, self).__init__()

        self.encoder = Encoder()
        self.decoder = Decoder()

    def call(self, x):
        x = self.encoder(x)
        x = self.decoder(x)
        return x

# モデルのコンパイル
model = AutoEncoder()
model.compile(optimizer='adam', loss='mse')

# データセットの読み込み
(x_train, _), (x_test, _) = tf.keras.datasets.mnist.load_data()
x_train = x_train.reshape(x_train.shape[0], 28, 28, 1)
x_test = x_test.reshape(x_test.shape[0], 28, 28, 1)

# モデルの学習
model.fit(x_train, x_train, epochs=10)

# モデルの評価
loss, acc = model.evaluate(x_test, x_test)
print(f'loss: {loss}')
print(f'acc: {acc}')

# モデルの出力
x_pred = model.predict(x_test)
