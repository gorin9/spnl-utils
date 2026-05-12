# Cookie parser/builder for Spinel.
#
# RFC 6265 のうち実用上必要なサブセットだけ。
#   - 受信ヘッダ "Cookie: a=1; b=2" を Hash{str=>str} にパース
#   - "Set-Cookie" 用の文字列を組み立てる
#
# Cookie 値の percent-encoding はクライアント側責務だが、
# サーバー側で encode/decode を支援するヘルパも提供。
#
# Usage:
#   h = Cookie.parse("session=abc; theme=dark; lang=ja")
#   h["session"]    # => "abc"
#
#   Cookie.build("session", "abc", "/", 3600, true, true)
#   # => "session=abc; Path=/; Max-Age=3600; HttpOnly; SameSite=Lax"

module Cookie
  # ---- parse ----
  # "name=val; name2=val2" → Hash{str=>str}
  # 先頭/末尾の空白を許容。値が無い (name のみ) ならば "" を入れる。
  def self.parse(header)
    h = { "_seed" => "x" }
    h.delete("_seed")
    n = header.bytesize
    i = 0
    item_start = 0
    while i <= n
      if i == n || header.slice(i, 1) == ";"
        Cookie.add_pair(h, header.slice(item_start, i - item_start))
        item_start = i + 1
        # skip whitespace after ;
        if i < n
          j = i + 1
          while j < n && header.slice(j, 1) == " "
            j += 1
            item_start = j
          end
        end
      end
      i += 1
    end
    h
  end

  def self.add_pair(h, raw)
    s = Cookie.strip(raw)
    return if s.bytesize == 0
    eq = s.index("=")
    if eq == nil
      h[s] = ""
    else
      k = Cookie.strip(s.slice(0, eq))
      v = Cookie.strip(s.slice(eq + 1, s.bytesize - eq - 1))
      h[k] = v
    end
  end

  def self.strip(s)
    n = s.bytesize
    a = 0
    b = n
    while a < b
      c = s.slice(a, 1)
      if c == " " || c == "\t"
        a += 1
      else
        break
      end
    end
    while b > a
      c = s.slice(b - 1, 1)
      if c == " " || c == "\t"
        b -= 1
      else
        break
      end
    end
    s.slice(a, b - a)
  end

  # ---- build ----
  # Set-Cookie ヘッダ用の値を構築。
  #   name      : クッキー名
  #   value     : 値 (生文字列。必要なら呼び出し側で URL.encode)
  #   path      : "" なら省略
  #   max_age   : 0 以下なら省略
  #   http_only : true で HttpOnly 付与
  #   secure    : true で Secure 付与
  #   same_site : ""/"Lax"/"Strict"/"None" — "" で省略
  def self.build(name, value, path, max_age, http_only, secure, same_site)
    parts = ["seed"]
    parts.clear
    parts.push(name + "=" + value)
    if path.bytesize > 0
      parts.push("Path=" + path)
    end
    if max_age > 0
      parts.push("Max-Age=" + max_age.to_s)
    end
    if http_only
      parts.push("HttpOnly")
    end
    if secure
      parts.push("Secure")
    end
    if same_site.bytesize > 0
      parts.push("SameSite=" + same_site)
    end
    parts.join("; ")
  end

end
