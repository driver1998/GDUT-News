#!/bin/bash

echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />'
descs[4]='校内通知'
descs[5]='公示公告'
descs[6]='校内简讯'

for category in 4 5 6
do
    echo "<h1>"${descs[category]}"</h1>"
    content=$(curl -s "http://news.gdut.edu.cn/ArticleList.aspx?category=$category")
    titles=(`echo "$content" | grep -o '[^an2] title=".*"' | awk -F '"' '{print $2}' | sed 's/\s/\&nbsp;/g'`)
    depts=(`echo "$content" | grep -o 'span title=".*"' | awk -F '"' '{print $2}'| sed 's/\s/\&nbsp;/g'`)
    links=(`echo "$content" | grep '<a href="\./view.*"'  | awk -F '"' '{print $2}' | sed 's/.\//http:\/\/news.gdut.edu.cn\//g'`) 
    
    count=${#titles[@]}
    if [[ count -eq 0 ]]
    then
        echo "今日无新事<br>"
    else
        for (( i=0; i<count; i++ ))
        do
            echo '<a href="'${links[i]}'">'${titles[i]}'</a> ['${depts[i]}']<br>'
        done
    fi  
done
echo "<br><br>GDUT News Tracker<br>"
echo "更新时间 "$(date +'%Y/%m/%d %H:%m:%S')"<br>"