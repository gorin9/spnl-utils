# Form body parser for Spinel.
#
# `application/x-www-form-urlencoded` 形式は URL クエリ文字列と
# 完全に同じ仕様なので、URL.parse_query を呼ぶだけ。
#
# `multipart/form-data` (ファイルアップロード) は別途。
# 本ライブラリに含めるか、専用 lib/multipart.rb を作るかは未定。
#
# 想定される利用:
#   if request.header("content-type") == "application/x-www-form-urlencoded"
#     params = Form.parse(request.body)
#     name = params["name"]
#   end

module Form
  def self.parse(body)
    URL.parse_query(body)
  end
end
