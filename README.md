n3r-abtest
==========

n3r-abtest工程是用来做ab测试使用的，该工程使用lua脚本编写，嵌入到nginx。

简单示例:
---------

```nginx
   location /abtest {

    #content_by_lua_file conf/abcontroler.lua;
		content_by_lua '
		   ngx.header.content_type = "text/plain";
		   local splitFlow = require "n3r.SplitFlow";
		   local redirect = splitFlow.rotePage("abtest");
		   ngx.redirect(redirect);
		';
   }
```

在nginx配置中引入"n3r.SplitFlow"，调用rotePage方法(参数为当前的locationName)，即可返回对应的页面
可以选择使用lua脚本跳转到对应页面，也可以使用nginx自行跳转。

环境要求:
---------