# Path matching helpers for Spinel.
#
# Spinel は Method/Proc 配列を扱えないため Sinatra 風 DSL は無理。
# 代わりに「マッチング判定 + パラメータ抽出」だけ提供し、
# ユーザーは case / if 文で dispatch を書く。
#
# Usage:
#   m = Router.match_path("/users/:id/posts/:post_id", "/users/42/posts/7")
#   if m.matched?
#     id = m.params["id"]            # "42"
#     post_id = m.params["post_id"]  # "7"
#   end

class RouteMatch
  def initialize
    @matched = false
    @params = { "_seed" => "x" }
    @params.delete("_seed")
  end

  def matched?; @matched; end
  def params; @params; end

  def set_matched(b)
    @matched = b
  end
end

module Router
  # /a/:x/b と /a/123/b を比較。マッチすれば params に {x: "123"}。
  def self.match_path(pattern, path)
    m = RouteMatch.new
    p_parts = pattern.split("/")
    a_parts = path.split("/")
    if p_parts.length != a_parts.length
      return m
    end
    i = 0
    while i < p_parts.length
      pp = p_parts[i]
      ap = a_parts[i]
      if pp.bytesize > 0 && pp.slice(0, 1) == ":"
        # Spinel: set_param メソッド経由だと value 型が int に推論される。
        # accessor 経由の直接代入で回避。
        key = pp.slice(1, pp.bytesize - 1)
        h = m.params
        h[key] = ap
      elsif pp != ap
        return m
      end
      i += 1
    end
    m.set_matched(true)
    m
  end

  # 完全一致 (パラメータなし)
  def self.exact?(pattern, path)
    pattern == path
  end
end
