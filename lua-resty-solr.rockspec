package = "lua-resty-rols"
version = "0.2.0"
source = {
  url = "https://github.com/samsk/lua-resty-solr",
  tag = "0.0.0"
}
description = {
  summary  = "SOLR api for OpenResty",
  detailed = [[
    Build SOLR queries without exposing full SOLR interface

    Features:

    - Translate HTTP args to SOLR query
  ]],
  homepage = "https://github.com/samsk/lua-resty-solr",
  license  = "AGPL-3.0"
}
dependencies = {
   "lua >= 5.1",
}
build = {
  type    = "builtin",
  modules = {
    ["resty.solr"]	= "lib/resty/solr.lua"
    ["resty.solr.args"]	= "lib/resty/solr/args.lua"
    ["resty.solr.http.args"]	= "lib/resty/solr/http/args.lua"
  }
}
