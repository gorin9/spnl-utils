# spnl-utils

[matz/spinel](https://github.com/matz/spinel) 用の **汎用ユーティリティ + HTTP 関連の Ruby ライブラリ集**。

「**標準ライブラリが補充されるまでの暫定置き場**」という位置付け。
matz が Spinel 本体に JSON 等を追加したら、対応する file を本 repo から削除する想定。

[gorin9/spinel-packer](https://github.com/gorin9/spinel-packer) で `install` する想定:

```sh
spinel-packer install gorin9/spnl-utils
```

## 設計方針

- **NPM 化しない**: 1 機能 1 repo に分けない、関連機能は集約
- **dead-code-elimination 前提**: Spinel は使ってない関数を最終バイナリに入れないので、
  bundle で配って unused module はバイナリに入らない (22KB 哲学を壊さない)
- **「暫定」を明示**: 本家 stdlib が追ったら本 repo は徐々に痩せる

## 含まれるライブラリ

| ファイル | 行数 | 役割 |
|---|---|---|
| `lib/json.rb`     | 401 | JSON encoder / decoder (pure Spinel) |
| `lib/url.rb`      | 145 | URL parse / build / query string / percent-encoding |
| `lib/cookie.rb`   | 112 | HTTP Cookie parse / serialize |
| `lib/request.rb`  | 173 | HTTP Request 表現 (Rack 風) |
| `lib/response.rb` | 116 | HTTP Response builder |
| `lib/router.rb`   |  61 | URL routing (簡易) |
| `lib/form.rb`     |  19 | x-www-form-urlencoded parser (URL の薄いラッパ) |
| **計** | **1027** | |

## 使い方

```sh
# 取得
$ spinel-packer install gorin9/spnl-utils
  resolving gorin9/spnl-utils@main ...
  resolved → <sha>
  fetched into vendor/gorin9__spnl-utils (N files)
done.
```

```ruby
# app.rb
require_relative "vendor/gorin9__spnl-utils/lib/json"
require_relative "vendor/gorin9__spnl-utils/lib/url"

class App
  def index
    body = JSON.encode({ hello: "world" })
    # ...
  end
end
```

`vendor/` は `.gitignore` 推奨、`Spinelfile.lock` でロックして再現性を担保。

## 関連プロジェクト

- [matz/spinel](https://github.com/matz/spinel) — 本家 Spinel コンパイラ
- [gorin9/spinel-packer](https://github.com/gorin9/spinel-packer) — install / upgrade / lock / check / pack ツール
- [gorin9/spnl-web](https://github.com/gorin9/spnl-web) — Web フレームワーク ライブラリ集 (本 utils と相補的)
- [gorin9/spinel-demo](https://github.com/gorin9/spinel-demo) — Spinel 製 async HTTP サーバの実戦デモ

## ライセンス

MIT
