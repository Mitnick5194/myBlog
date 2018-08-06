#! /bin/bash
reason=$1
git add .
if test -z $reason
then
	git commit -m "脚本自动提交，无提交理由"
else
	git commit -m $reason
fi
git push
