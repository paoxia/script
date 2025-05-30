# pip install requests
import requests
import subprocess
import os

# === 配置项 ===
GITHUB_TOKEN = "your_github_token_here"     # 🔐 GitHub Token（必须有 repo 权限）
SKIP_FORK = False                             # 是否跳过 fork 项目
TARGET_DIR = "./github_repos"                # ✅ 克隆仓库保存目录（会自动创建）
PER_PAGE = 100                               # 每页最大仓库数

# === API 请求设置 ===
headers = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json"
}

url = "https://api.github.com/user/repos"
params = {
    "per_page": PER_PAGE,
    "page": 1,
    "visibility": "all",
    "affiliation": "owner"
}

# === 创建目标目录 ===
os.makedirs(TARGET_DIR, exist_ok=True)

print(f"🚀 开始克隆仓库到目录：{TARGET_DIR}")
while True:
    response = requests.get(url, headers=headers, params=params)
    if response.status_code != 200:
        print(f"❌ 获取仓库失败: {response.status_code} - {response.text}")
        break

    repos = response.json()
    if not repos:
        print("✅ 所有仓库已处理完毕。")
        break

    for repo in repos:
        if SKIP_FORK and repo.get("fork"):
            continue
        clone_url = repo["clone_url"]
        repo_name = repo["name"]
        target_path = os.path.join(TARGET_DIR, repo_name)
        if os.path.exists(target_path):
            print(f"🔁 已存在，跳过：{repo_name}")
            continue
        print(f"🔄 克隆：{clone_url} → {target_path}")
        subprocess.run(["git", "clone", clone_url, target_path])

    params["page"] += 1
