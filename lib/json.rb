# JSON encoder/decoder for Spinel.
#
# Spinel の型推論制約のため、JSON 値は JsonValue 型でラップする。
# 直接 Ruby のネイティブ Hash/Array を JSON にできないが、
# 構造を持つ API レスポンス等は十分扱える。
#
# Usage:
#   v = JSON.parse('{"name":"Alice","age":30,"items":[1,2,3]}')
#   v.kind                       # 6 (OBJ)
#   v.get_field("name").s        # "Alice"
#   v.get_field("age").i         # 30
#   v.get_field("items").arr[0].i  # 1
#
#   o = JSON.gen_obj
#   o.set_field("hello", JSON.gen_str("world"))
#   JSON.generate(o)             # => '{"hello":"world"}'

class JsonValue
  KIND_NIL  = 0
  KIND_BOOL = 1
  KIND_INT  = 2
  KIND_FLT  = 3
  KIND_STR  = 4
  KIND_ARR  = 5
  KIND_OBJ  = 6

  def initialize
    @kind = 0
    @b = false
    @i = 0
    @f = 0.0
    @s = ""
    # 配列の要素型確定: [self].clear で obj_JsonValue_ptr_array に。
    @arr = [self]
    @arr.clear
    # 文字列キー配列: ["seed"].clear で str_array に。
    @obj_keys = ["seed"]
    @obj_keys.clear
    @obj_vals = [self]
    @obj_vals.clear
  end

  def kind; @kind; end
  def b; @b; end
  def i; @i; end
  def f; @f; end
  def s; @s; end
  def arr; @arr; end
  def obj_keys; @obj_keys; end
  def obj_vals; @obj_vals; end

  def set_nil
    @kind = 0
  end
  def set_bool(b)
    @kind = 1
    @b = b
  end
  def set_int(i)
    @kind = 2
    @i = i
  end
  def set_flt(f)
    @kind = 3
    @f = f
  end
  def set_str(s)
    @kind = 4
    @s = s
  end
  def set_arr
    @kind = 5
    @arr.clear
  end
  def set_obj
    @kind = 6
    @obj_keys.clear
    @obj_vals.clear
  end

  def push_arr(v)
    @arr.push(v)
  end

  def set_field(k, v)
    @obj_keys.push(k)
    @obj_vals.push(v)
  end

  def get_field(k)
    i = @obj_keys.index(k)
    return JSON.gen_nil if i < 0
    @obj_vals[i]
  end
end

module JSON
  # ---- builders ----
  def self.gen_nil
    v = JsonValue.new
    v.set_nil
    v
  end
  def self.gen_bool(b)
    v = JsonValue.new
    v.set_bool(b)
    v
  end
  def self.gen_int(i)
    v = JsonValue.new
    v.set_int(i)
    v
  end
  def self.gen_flt(f)
    v = JsonValue.new
    v.set_flt(f)
    v
  end
  def self.gen_str(s)
    v = JsonValue.new
    v.set_str(s)
    v
  end
  def self.gen_arr
    v = JsonValue.new
    v.set_arr
    v
  end
  def self.gen_obj
    v = JsonValue.new
    v.set_obj
    v
  end

  # ---- encoder ----
  def self.generate(v)
    parts = ["seed"]
    parts.clear
    JSON.encode_value(v, parts)
    parts.join("")
  end

  def self.encode_value(v, parts)
    k = v.kind
    if k == 0
      parts.push("null")
    elsif k == 1
      parts.push(v.b ? "true" : "false")
    elsif k == 2
      parts.push(v.i.to_s)
    elsif k == 3
      parts.push(v.f.to_s)
    elsif k == 4
      parts.push("\"")
      parts.push(JSON.escape_str(v.s))
      parts.push("\"")
    elsif k == 5
      parts.push("[")
      a = v.arr
      i = 0
      while i < a.length
        parts.push(",") if i > 0
        JSON.encode_value(a[i], parts)
        i += 1
      end
      parts.push("]")
    elsif k == 6
      parts.push("{")
      ks = v.obj_keys
      vs = v.obj_vals
      i = 0
      while i < ks.length
        parts.push(",") if i > 0
        parts.push("\"")
        parts.push(JSON.escape_str(ks[i]))
        parts.push("\":")
        JSON.encode_value(vs[i], parts)
        i += 1
      end
      parts.push("}")
    end
  end

  def self.escape_str(s)
    out = ""
    n = s.bytesize
    i = 0
    while i < n
      c = s.slice(i, 1)
      if c == "\""
        out = out + "\\\""
      elsif c == "\\"
        out = out + "\\\\"
      elsif c == "\n"
        out = out + "\\n"
      elsif c == "\r"
        out = out + "\\r"
      elsif c == "\t"
        out = out + "\\t"
      else
        out = out + c
      end
      i += 1
    end
    out
  end

  # ---- parser ----
  def self.parse(src)
    p = JsonParser.new(src)
    p.parse_value
  end
end

class JsonParser
  def initialize(src)
    @src = src
    @pos = 0
    @len = src.bytesize
  end

  def peek
    return "" if @pos >= @len
    @src.slice(@pos, 1)
  end

  def skip_ws
    forever = true
    while forever
      if @pos >= @len
        forever = false
      else
        c = @src.slice(@pos, 1)
        if c == " " || c == "\n" || c == "\t" || c == "\r"
          @pos += 1
        else
          forever = false
        end
      end
    end
  end

  def parse_value
    skip_ws
    c = peek
    if c == "{"
      parse_object
    elsif c == "["
      parse_array
    elsif c == "\""
      v = JSON.gen_str(parse_string_chars)
      v
    elsif c == "t"
      @pos += 4
      JSON.gen_bool(true)
    elsif c == "f"
      @pos += 5
      JSON.gen_bool(false)
    elsif c == "n"
      @pos += 4
      JSON.gen_nil
    else
      parse_number
    end
  end

  def parse_string_chars
    @pos += 1
    out = ""
    forever = true
    while forever
      if @pos >= @len
        forever = false
      else
        c = @src.slice(@pos, 1)
        if c == "\""
          @pos += 1
          forever = false
        elsif c == "\\"
          @pos += 1
          e = @src.slice(@pos, 1)
          if e == "\""
            out = out + "\""
          elsif e == "\\"
            out = out + "\\"
          elsif e == "n"
            out = out + "\n"
          elsif e == "r"
            out = out + "\r"
          elsif e == "t"
            out = out + "\t"
          elsif e == "/"
            out = out + "/"
          else
            out = out + e
          end
          @pos += 1
        else
          out = out + c
          @pos += 1
        end
      end
    end
    out
  end

  def parse_number
    start = @pos
    if peek == "-"
      @pos += 1
    end
    has_dot = false
    forever = true
    while forever
      if @pos >= @len
        forever = false
      else
        c = @src.slice(@pos, 1)
        if c == "."
          has_dot = true
          @pos += 1
        elsif c == "e" || c == "E"
          has_dot = true
          @pos += 1
        elsif c == "+" || c == "-"
          @pos += 1
        elsif c >= "0" && c <= "9"
          @pos += 1
        else
          forever = false
        end
      end
    end
    chunk = @src.slice(start, @pos - start)
    if has_dot
      JSON.gen_flt(chunk.to_f)
    else
      JSON.gen_int(chunk.to_i)
    end
  end

  def parse_array
    arr = JSON.gen_arr
    @pos += 1
    skip_ws
    if peek == "]"
      @pos += 1
      return arr
    end
    forever = true
    while forever
      v = parse_value
      arr.push_arr(v)
      skip_ws
      c = peek
      if c == ","
        @pos += 1
        skip_ws
      elsif c == "]"
        @pos += 1
        forever = false
      else
        forever = false
      end
    end
    arr
  end

  def parse_object
    obj = JSON.gen_obj
    @pos += 1
    skip_ws
    if peek == "}"
      @pos += 1
      return obj
    end
    forever = true
    while forever
      skip_ws
      k = parse_string_chars
      skip_ws
      if peek == ":"
        @pos += 1
      end
      skip_ws
      v = parse_value
      obj.set_field(k, v)
      skip_ws
      c = peek
      if c == ","
        @pos += 1
      elsif c == "}"
        @pos += 1
        forever = false
      else
        forever = false
      end
    end
    obj
  end
end
