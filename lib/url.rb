# URL utilities for Spinel.
#
# - URL.decode("hello%20world")        => "hello world"
# - URL.encode("hello world")          => "hello%20world"
# - URL.parse_query("a=1&b=2")         => Hash{"a"=>"1", "b"=>"2"}
# - URL.build_query({"a"=>"1"})        => "a=1"
#
# percent-decoding は + を space として扱う (form-encoded 規約)。
# UTF-8 バイト列はそのまま透過させる (デコード結果に %XX のバイトを直接埋める)。

module URL
  # ---- hex helpers ----
  # "0".."9", "a".."f", "A".."F" → 0..15。それ以外は -1。
  def self.hex_val(c)
    if c >= "0" && c <= "9"
      return c.ord - 48        # '0' = 48
    end
    if c >= "a" && c <= "f"
      return c.ord - 87        # 'a' = 97, want 10
    end
    if c >= "A" && c <= "F"
      return c.ord - 55        # 'A' = 65, want 10
    end
    -1
  end

  HEX_CHARS = "0123456789ABCDEF"

  def self.byte_to_hex2(byte)
    hi = (byte >> 4) & 0x0F
    lo = byte & 0x0F
    HEX_CHARS.slice(hi, 1) + HEX_CHARS.slice(lo, 1)
  end

  # 安全とみなす文字: A-Z a-z 0-9 - _ . ~
  def self.safe_byte?(byte)
    if byte >= 65 && byte <= 90      # A-Z
      return true
    end
    if byte >= 97 && byte <= 122     # a-z
      return true
    end
    if byte >= 48 && byte <= 57      # 0-9
      return true
    end
    if byte == 45 || byte == 95 || byte == 46 || byte == 126  # - _ . ~
      return true
    end
    false
  end

  # ---- decode ----
  def self.decode(s)
    out = ""
    n = s.bytesize
    i = 0
    while i < n
      c = s.slice(i, 1)
      if c == "%" && i + 2 < n
        h1 = URL.hex_val(s.slice(i + 1, 1))
        h2 = URL.hex_val(s.slice(i + 2, 1))
        if h1 >= 0 && h2 >= 0
          out = out + (h1 * 16 + h2).chr
          i += 3
        else
          out = out + c
          i += 1
        end
      elsif c == "+"
        out = out + " "
        i += 1
      else
        out = out + c
        i += 1
      end
    end
    out
  end

  # ---- encode ----
  def self.encode(s)
    out = ""
    n = s.bytesize
    i = 0
    while i < n
      byte = s.slice(i, 1).ord
      if URL.safe_byte?(byte)
        out = out + s.slice(i, 1)
      elsif byte == 32   # space
        out = out + "+"
      else
        out = out + "%" + URL.byte_to_hex2(byte)
      end
      i += 1
    end
    out
  end

  # ---- query parse ----
  # "a=1&b=2&c" → {"a"=>"1", "b"=>"2", "c"=>""}
  #
  # Spinel の str_str_hash には clear がないので "_seed" を入れた直後に
  # delete する。これで型確定 + 空ハッシュが手に入る。
  def self.parse_query(qs)
    h = { "_seed" => "x" }
    h.delete("_seed")
    n = qs.bytesize
    i = 0
    key_start = 0
    val_start = -1
    while i <= n
      if i == n || qs.slice(i, 1) == "&"
        if val_start < 0
          k = URL.decode(qs.slice(key_start, i - key_start))
          if k.bytesize > 0
            h[k] = ""
          end
        else
          k = URL.decode(qs.slice(key_start, val_start - key_start - 1))
          v = URL.decode(qs.slice(val_start, i - val_start))
          if k.bytesize > 0
            h[k] = v
          end
        end
        key_start = i + 1
        val_start = -1
      elsif qs.slice(i, 1) == "=" && val_start < 0
        val_start = i + 1
      end
      i += 1
    end
    h
  end

  # ---- query build ----
  # {"a"=>"1", "b"=>"2"} → "a=1&b=2"
  def self.build_query(h)
    parts = ["seed"]
    parts.clear
    h.each do |k, v|
      parts.push(URL.encode(k) + "=" + URL.encode(v))
    end
    parts.join("&")
  end
end
