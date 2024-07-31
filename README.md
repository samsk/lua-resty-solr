# Name
lua-resty-solr - OpenResty library for working with SOLR

### resty.solr
Library for working with SOLR API

### resty.solr.args
Library for easy SOLR query building from HTTP GET args.
  
  **Example usage (nginx config):**

  ```
  # build $args
  set_by_lua_block $args {
        return require("solr_args")
                .new()
                .wildcard_query(ngx.var.arg_q)
                .start(ngx.var.arg_start)
                .output_json(ngx.var.arg_o == 'json')
                .filter('arg_fy', '{!tag=YEAR}year', tonumber(ngx.var.arg_fy))
                .filter('arg_fm', '{!tag=MONTH}month', tonumber(ngx.var.arg_fm))
                .build();
  }

  # rewrite path
  rewrite ^ /solr/code1/select break;

  # proxy request
  proxy_pass http://solr6_server;
  ```

### resty.solr.http.args
Library for building url argument string

# Installation
* Download & unpack as needed
* Specify lua package path, i.e.:
    ``lua_package_path '/www/_lib/lua/?.lua';``

# How-To
* [Proxying SOLR with NGINX and Lua](https://blog.dob.sk/2019/03/15/exposing-solr-search-api-securely-with-nginx-and-lua/)
