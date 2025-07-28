参考gzzd(https://github.com/pnboot/gzzd)

修改为单机版

部署参数可以参考standalone下start-all-stand-alone.sh

比如要在线debug的jar为demo-xx.jar

只需要将serverside-ui.jar与start-all-stand-alone.sh上传到服务器然后执行
``sh start-all-stand-alone.sh -a demo start``
调试完成后
``sh start-all-stand-alone.sh -a demo stop``

然后访问ip:9091,在线debug即可

完成的设置为
```
sh start-all-stand-alone.sh -a demo -w /tmp -u 9091 -p 9013 -g 9014 -i 192.168.233.129 start
```


备注:
首次进入页面先退出,然后再登录(admin/123456)


