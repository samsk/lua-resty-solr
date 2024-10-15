# Name
lua-resty-solr - OpenResty library for working with SOLR

### resty.solr
Library for working with SOLR API

### resty.solr.sort
Library for build SOLR sort argument

  ```
  # build $sort
  set_by_lua_block $sort {
	local sort = require("resty.solr.sort").new({
		'year', 'month'
	}, args = ngx.req.get_uri_args())
	:build('sort');

	return sort;
  }
  ```

### resty.solr.args
Base library for easy SOLR query building from HTTP GET args.
  
  **Example usage (nginx config):**

  ```
  # build $args
  set_by_lua_block $args {

        return require("resty.solr.args")
                .new()
                :wildcard_query(ngx.var.arg_q)
                :start(ngx.var.arg_start)
                :filter_raw('fy', '{!tag=YEAR}year', tonumber(ngx.var.arg_fy))
                :filter_raw('fm', '{!tag=MONTH}month', tonumber(ngx.var.arg_fm))
                :output_json(ngx.var.arg_o == 'json')
                :build();
  }

  # rewrite path
  rewrite ^ /solr/code1/select break;

  # proxy request
  proxy_pass http://solr_server;
  ```

### resty.solr.args.advanced
Library for SOLR query building from HTTP GET args. Compared to `resty.solr.args` provides
argument type checking and passes user arguments back via solr as `arg*_`.

  
  **Example usage (nginx config):**

  ```
  # build $args
  set_by_lua_block $args {
        local args = ngx.req.get_uri_args()

        return require("resty.solr.args.advanced")
                .new({
                  sort = {
                    fields = {'year', 'month'},
                    default = {'year+', 'month+'},
                  },
                })
                :wildcard_query(ngx.var.arg_q)
                :start(ngx.var.arg_start)
                :filter_integer('fy', '{!tag=YEAR}year', ngx.var.arg_fy)
                :filter_integer('fm', '{!tag=MONTH}month', ngx.var.arg_fm)
                :sort('sort', $args['sort'])
                :output_json(ngx.var.arg_o == 'json')
                :build();
  }

  # rewrite path
  rewrite ^ /solr/code1/select break;

  # proxy request
  proxy_pass http://solr_server;
  ```


### resty.solr.http.args
Library for building url argument string

# Installation
* Download & unpack as needed
* Specify lua package path, i.e.:
    ``lua_package_path '/www/_lib/lua/?.lua';``

# How-To
* [Proxying SOLR with NGINX and Lua](https://blog.dob.sk/2019/03/15/exposing-solr-search-api-securely-with-nginx-and-lua/)
