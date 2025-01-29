package = "lua-resty-solr"
version = "0.2.0-3"
source = {
  url = "https://github.com/samsk/lua-resty-solr/archive/refs/tags/v0.2.0-beta3.tar.gz",
  tag = "v0.2.0-beta3",
  dir = "lua-resty-solr-0.2.0-beta3",
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
    ["resty.solr"]	= "lib/resty/solr.lua",
    ["resty.solr.args"]	= "lib/resty/solr/args.lua",
    ["resty.solr.args.advanced"]	= "lib/resty/solr/args/advanced.lua",
    ["resty.solr.sort"]	= "lib/resty/solr/sort.lua",
    ["resty.solr.http.args"]	= "lib/resty/solr/http/args.lua",
  }
}
