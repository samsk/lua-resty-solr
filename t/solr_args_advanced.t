use Test::Nginx::Socket 'no_plan';
use strict;

run_tests();

__DATA__

=== TEST 1:
--- main_config

--- http_config
    init_worker_by_lua_block {
	solr_args = require "resty.solr.args.advanced"
    }

--- config
    location /search {
	content_by_lua_block {
		local args = solr_args.new()
			:query('arg_q', ngx.var.arg_q)
			:start(ngx.var.arg_start)
			:output_json(ngx.var.arg_o == 'json')
			:filter_raw('arg_fy', '{!tag=YEAR}year', tonumber(ngx.var.arg_fy))
			:filter_raw('arg_fm', '{!tag=MONTH}month', tonumber(ngx.var.arg_fm))
			:build(1);
		ngx.say(args);
        }
    }

    location = /test {
        content_by_lua_block {
            ngx.say("OK")
        }
    }

--- request
GET /search?q=x
--- response_body
arg_q=x&q=x&start=0&wt=xml
