#!/bin/sh

# 新闻站地址、用户名和密码
# 请用学校提供的公用账号
site='http://news.gdut.edu.cn'
username='********'
password='********'

useragent='Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3837.0 Safari/537.36'

# 如果在外网，这个请求会被 302 重定向到登录页
content=$(curl $site -s -A $useragent -b cookies -c cookies | grep -o 'Object moved')
if [ -n "$content" ]
then
    # 确实被 302 了，获取登录需要的 cookies 和其它信息
    content=$(curl $site"/UserLogin.aspx" -A $useragent -s -b cookies -c cookies)

    # curl 的 encode 会炸，只能自己来...
    viewState=$(echo "$content" | grep -o 'id="__VIEWSTATE" value=".*"' | awk -F '"' '{print $4}')
    viewState=$(echo $viewState | sed 's/\//%2F/g' | sed 's/=/%3D/g')
    eventValidation=$(echo "$content" | grep -o 'id="__EVENTVALIDATION" value=".*"' | awk -F '"' '{print $4}')
    eventValidation=$(echo $eventValidation | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/+/%2B/g')

    # 将需要的所有数据拼接起来
    data='__VIEWSTATE='$viewState
    data=$data'&__EVENTVALIDATION='$eventValidation
    data=$data'&ctl00%24ContentPlaceHolder1%24userEmail='$username
    data=$data'&ctl00%24ContentPlaceHolder1%24userPassWord='$password
    data=$data'&ctl00%24ContentPlaceHolder1%24CheckBox1=on'
    data=$data'&ctl00%24ContentPlaceHolder1%24Button1=%E7%99%BB%E5%BD%95'

    # 发送登录请求
    curl $site"/UserLogin.aspx" -s -A $useragent -b cookies -c cookies --data $data -o /dev/null
fi

# 这个文件用来保存之前出现的前 500 条新闻
# 在这个文件中出现的，不会再重复发送
touch history.lst

echo '<!DOCTYPE html>'
echo '<html lang="zh-Hans-CN">'
echo '<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'
echo '<style>'
echo 'body { max-width: fit-content; }'
echo '#dept { float: right; margin-left: 2em; }'
echo '#item { display: block; margin: 0; margin-bottom: 0.5em;}'
echo '</style></head><body>'

# 栏目描述，每行一个栏目
descs=$(echo -e "\n\n\n校内通知\n公示公告\n校内简讯")

# 顺序获取每个栏目
for category in 4 5 6
do
    echo "<div><h1>$(echo "$descs" | sed -n $category'p')</h1>"

    # 下载该栏目的第一页
    content=$(curl "$site/ArticleList.aspx?category=$category" -A $useragent -s -b cookies -c cookies)

    # 标题、部门名称和新闻详情链接
    titles=$(echo "$content" | grep -o '[^an2] title=".*"' | sed 's/\s\+title="//g' | sed 's/"$//g' | sed 's/\s/\&nbsp;/g')
    depts=$(echo "$content" | grep -o 'span title=".*"' |  sed 's/span title="//g' | sed 's/"$//g' | sed 's/\s/\&nbsp;/g')
    links=$(echo "$content" | grep '<a href="\./view.*"' |  sed 's/\s\+<a href=".//g'  | sed 's/"$//g' )

    c=$(echo "$titles" | wc -l)    # 获取到的新闻条数
    count=0                        # 实际输出数（新的条目数）

    for i in $(seq $c)
    do
        title=$(echo "$titles" | sed -n $i'p')
        dept=$(echo "$depts" | sed -n $i'p')
        link=$(echo "$links" | sed -n $i'p')

        # 和 history.lst 中现有的条目比对，未出现的则输出
        match=$(grep "$link" history.lst)
        if [ -z "$match" ]
        then
            echo '<p id="item"><a href="'$site$link'">'$title'</a><span id="dept">['$dept']</span></p>'
            echo "$link" >> history.lst
            count=$(expr $count + 1)
        fi
    done

    if [ $count -eq 0 ]
    then
        echo "<li>今日无新事</li>"
    fi

    echo '</div><hr>'
done

# 只保留前 500 条记录（估计能保存一个星期了）
tail -n 500 history.lst > history.new
mv history.new history.lst

echo '<div>GDUT News Tracker<br/>'
echo '更新时间 '$(date +'%Y/%m/%d %H:%m:%S')'</div></body></html>'

