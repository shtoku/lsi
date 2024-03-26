# Kaomoji Generator with Autoencoder
LSI Design Contest 2024<br>
チーム「Kaomoji Fan Club」の共有リポジトリ
<br><br>

## 概要
潜在ベクトルに対して，乱数を加算もしくは乱数に置換することで新たな顔文字を生成する．<br>
<img src="https://github.com/shtoku/lsi/assets/147356273/ad871e0e-1029-4b55-b518-c28968e918d5" width="650px">

<br>

## スケジュール
| 月 | 内容 |
| ---: | ------------- |
| 10月 | アイデアを考え，それが可能かサンプルを作る．モデルの性能向上もやりたい． |
| 11月 | VerilogHDLで回路設計．シミュレーションしてちゃんと動くか確認． |
| 12月 | FPGAを用いた動作確認．動かなければ再設計→動作確認の繰り返し． |
|  1月 | 提出用レポート作成 |

<br>

## ディレクトリ構造
```
.                                     # .
├─data                                # ├─データセットやパラメータなどの雑多なデータ
│  ├─bitstream                        # │  ├─bitstreamファイル(FPGAに書き込むファイル) v5_3が最新
│  ├─dataset                          # │  ├─作成したデータセット kaomoji_MAX=10_DA.txtを使用
│  ├─model                            # │  ├─Pytorchで学習したモデル(使用していない)
│  ├─parameter                        # │  ├─学習前と学習後のパラメータデータ
│  │  ├─train                         # │  │  ├─学習前のパラメータデータ (FPGA用)
│  │  │  ├─binary108                  # │  │  │  ├─2進数 108bit
│  │  │  │  ├─mix_layer_W_1           # │  │  │  │  ├─Mix1層用 重み
│  │  │  │  ├─mix_layer_W_2           # │  │  │  │  ├─Mix2層用 重み
│  │  │  │  └─mix_layer_W_3           # │  │  │  │  └─Mix3層用 重み
│  │  │  ├─binary144                  # │  │  │  ├─2進数 144bit
│  │  │  ├─binary18                   # │  │  │  ├─2進数 18bit
│  │  │  │  ├─mix_layer_b_1           # │  │  │  │  ├─Mix1層用 バイアス
│  │  │  │  ├─mix_layer_b_2           # │  │  │  │  ├─Mix2層用 バイアス
│  │  │  │  └─mix_layer_b_3           # │  │  │  │  └─Mix3層用 バイアス
│  │  │  ├─binary192                  # │  │  │  ├─2進数 192bit
│  │  │  └─decimal                    # │  │  │  └─10進数 (これだけソフトウェア用)
│  │  └─trained                       # │  │  └─学習後のパラメータデータ
│  │      ├─hard                      # │  │      ├─ハードウェア用
│  │      │  ├─binary16               # │  │      │  ├─2進数 108bit
│  │      │  │  ├─mix_layer_b_1       # │  │      │  │  ├─Mix1層用 バイアス
│  │      │  │  ├─mix_layer_b_2       # │  │      │  │  ├─Mix2層用 バイアス
│  │      │  │  └─mix_layer_b_3       # │  │      │  │  └─Mix3層用 バイアス
│  │      │  └─binary96               # │  │      │  └─2進数 108bit
│  │      │      ├─mix_layer_W_1      # │  │      │      ├─mMix1層用 重み
│  │      │      ├─mix_layer_W_2      # │  │      │      ├─mMix2層用 重み
│  │      │      └─mix_layer_W_3      # │  │      │      └─Mix3層用 重み
│  │      └─soft                      # │  │      └─ソフトウェア用
│  │          ├─binary                # │  │          ├─2進数
│  │          └─decimal               # │  │          └─10進数
│  ├─result                           # │  ├─実機における計算時間や正解率の測定結果
│  └─tb                               # │  └─テストベンチ用の入出力サンプル
│      ├─train                        # │      ├─学習前のモデル用
│      │  ├─comp_layer                # │      │  ├─compare_layer用
│      │  ├─dense_layer               # │      │  ├─dense_layer用
│      │  ├─emb_layer                 # │      │  ├─embeddeding_layer用
│      │  ├─generate                  # │      │  ├─生成モード時のサンプル
│      │  ├─mix_layer                 # │      │  ├─mix_layer用
│      │  ├─softmax_layer             # │      │  ├─softmax_layer用
│      │  └─tanh_layer                # │      │  └─tanh_layer用
│      └─trained                      # │      └─学習後のモデル用
├─demo                                # ├─シリアル通信のみを利用したローカル環境デモ用(使用していない)
├─include                             # ├─Verilogのヘッダファイル
├─notebooks                           # ├─juptyer notebook形式のファイル
│  ├─controller                       # │  ├─Zynq制御用 v5_0が最新
│  ├─etc                              # │  ├─顔文字のデータセットを作成したときに使用したファイルなど
│  └─network                          # │  └─Pytorchを用いた学習 _complin が決定版
├─pdf                                 # ├─PDF形式ファイル(使用していない)
│  └─pptx                             # │  └─パワーポイント
├─src                                 # ├─Verilogソースコード
│  ├─train                            # │  ├─学習前バージョン
│  │  ├─comp_layer                    # │  │  ├─compare_layer用
│  │  ├─dense_layer                   # │  │  ├─dense_layer用
│  │  ├─emb_layer                     # │  │  ├─embeddeding_layer用
│  │  ├─mix_layer                     # │  │  ├─mix_layer用
│  │  ├─rand_layer                    # │  │  ├─rand_layer用
│  │  ├─softmax_layer                 # │  │  ├─sofmax_layer用
│  │  ├─state_machine                 # │  │  ├─ステートマシン
│  │  └─tanh_layer                    # │  │  └─tanh_layer用
│  └─trained                          # │  └─学習後バージョン
│      ├─comp_layer                   # │      ├─compare_layer用
│      ├─dense_layer                  # │      ├─dense_layer用
│      ├─emb_layer                    # │      ├─embeddeding_layer用
│      ├─mix_layer                    # │      ├─mix_layer用
│      └─rand_layer                   # │      └─rand_layer用
├─tb                                  # ├─テストベンチ
│  ├─train                            # │  ├─学習前バージョン用
│  └─trained                          # │  └─学習後バージョン用
└─tools                               # └─Pythonソースコード
                                      #   重要なものをピックアップ
                                      #   kmj_gen_np_train.py : Numpyを用いた浮動小数点精度の学習シミュレーション
                                      #   kmj_gen_train.py    : Numpyを用いた固定小数点精度の学習シミュレーション
```

<br>

## Gitについて
### 用語の説明
| 用語 | 説明 |
| ---- | ------------- |
| リモートリポジトリ | ネットワーク上のリポジトリ．https://github.com/shtoku/lsi |
| ローカルリポジトリ | パソコン上にあるリポジトリ．ファイルの追加，修正とかできる． |
| コミット | ファイルの履歴をタイトル付けして記録すること． |
| プッシュ | ローカルリポジトリで行った変更をリモートリポジトリに反映． |
| ブランチ | あるコミットから分岐したもの． |

<br>

### 主要コマンド
| コマンド | 内容 |
| ---- | ------------- |
| `git clone <URL+.git>` | ローカルリポジトリの作成． |
| `git branch` | 今いるブランチを確認．ブランチを新たに作ることもできる． |
| `git checkout <branch>` | 指定したブランチへ移動． |
| `git status` | まだコミットされていないファイルを表示． |
| `git add <file>` | 追加，修正したファイルを追加． |
| `git commit` | コミットする．（行った作業にタイトルを付ける） |
| `git push` | コミットをリモートリポジトリに反映． |

<br>

### 便利コマンド
| コマンド | 内容 |
| ---- | ------------- |
| `git add -A` | 追加，修正したファイル全てを追加． |
| `git diff` | 前のコミットとの変更点を表示． |
| `git log` | コミット履歴を表示． |
| `git pull` | 今のリモートリポジトリの状態をローカルリポジトリに反映． |
| `git reset --soft HEAD^` | プッシュする前ならば，コミット前まで戻る． |
| `git reset HEAD^` | プッシュする前ならば，ファイル追加前まで戻る． |
| `git reset --hard HEAD^` | プッシュする前ならば，前のコミットまで戻る．前のコミット後に行ったファイル変更を全て削除． |

<br>

### 禁忌コマンド
| コマンド | 内容 |
| ---- | ------------- |
| `git branch -D` | ブランチ削除．履歴が全て吹き飛ぶ． |
| `git push -f` | 強制プッシュ．だいたい何かしらの履歴が飛ぶ． |

<br>

### その他コマンド
| コマンド | 内容 |
| ---- | ------------- |
| `git config -global --list` | 今のユーザ名，メールアドレスを確認． |
| `git config user.name "username"` | ユーザ名の変更．emailにするとメールアドレスを変更． |
| `git push -u <branch1> <branch2>` | --set-upstream と同じ．branch1をbranch2の上流ブランチ（派生元）に設定． |
| `git remote -v` | 今のプッシュ先URLを確認． |
| `git remote set-url origin <URL>` | プッシュ先URLを変更． |
