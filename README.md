n3r-abtest
==========

n3r-abtest������������ab����ʹ�õģ��ù���ʹ��lua�ű���д��Ƕ�뵽nginx��

��ʾ��:
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

��nginx����������"n3r.SplitFlow"������rotePage����(����Ϊ��ǰ��locationName)�����ɷ��ض�Ӧ��ҳ��
����ѡ��ʹ��lua�ű���ת����Ӧҳ�棬Ҳ����ʹ��nginx������ת��

����Ҫ��:
---------