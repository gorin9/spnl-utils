module SpnlUtils
class RouteMatch
  def initialize
    @matched = false
    @params = {}
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
    p_parts = pattern.split("/", -1)
    a_parts = path.split("?", 2)[0].split("/", -1)
    if p_parts.length != a_parts.length
      return m
    end
    i = 0
    while i < p_parts.length
      pp = p_parts[i]
      ap = a_parts[i]
      if pp.bytesize > 0 && pp.slice(0, 1) == ":"
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

end
