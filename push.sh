#! /bin/bash
reason=$1
echo "$reason"
git add .
if test -z $reason
then
	git commit -m "$reason"
else
	git commit -m '脚本自动提交'
fi
git push
