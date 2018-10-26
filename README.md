# GDUT News Tracker
广工新闻站抓取脚本

# 配置
打开 `news.sh` 脚本，将前部用户名和密码的占位符修改为实际值。建议使用学校提供的公用账户。

```bash
#!/bin/bash

# 新闻站地址、用户名和密码
# 请用学校提供的公用账号
site='http://news.gdut.edu.cn'
username='********'
password='********'
```

然后在当前目录下运行脚本即可。
```bash
# 注意：脚本目前会在当前目录，即 `pwd` 显示的路径下写出文件
$ ./news.sh
```

脚本会向 `stdout` 输出 html。

你可以通过重定向或者管道来利用这个输出，比如，把它作为邮件发送：
```bash
# 需要加入 Content-Type 行，否则 html 代码会被视为纯文本
$ ./news.sh | mail -s "$(echo -e "GDUT NEWS\nContent-Type: text/html")" someone@example.com
```

# 备注
脚本会在当前目录写出 `cookies` 和 `history.lst` 两个文件：
- `cookies` 即登录的 cookies
- `history.lst` 记录最近 500 条新闻的地址，在这里出现的条目，下次更新时不会重复推送。
