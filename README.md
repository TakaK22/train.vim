# train.vim
電車遅延情報をただ表示するプラグイン

![](screenshots/late_info.png)

![](screenshots/train_route_search.png)


# 必須
- curl
- Vim 8.1.1407

# インストール
## dein.vim
```toml
[[plugins]]
repo = 'skanehira/train.vim'
```

## プラグインマネージャなしの場合
```sh
$ mkdir -p $HOME/.vim/pack/plugins/start/
$ cd $HOME/.vim/pack/plugins/start/
$ git clone https://github.com/skanehira/train.vim
```

# 使い方
```vim
" 遅延情報表示
:TrainLateInfo

" ルート検索
:TrainSearchRoute 秋葉原 東京
```
