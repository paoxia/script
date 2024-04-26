#!/bin/bash

# 检查是否提供了命令行参数
if [ $# -eq 0 ]; then
     # 如果没有提供参数，则使用默认值 "update"
     commit_msg="update"
else
     # 如果提供了参数，则使用第一个参数作为输入
     commit_msg="$1"
fi

echo "commit_msg is $commit_msg"
current_branch=$(git rev-parse --abbrev-ref HEAD)

echo "current_branch is $current_branch"

git add .
git commit -m "$commit_msg"
git push origin $current_branch