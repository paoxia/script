import requests
import subprocess
import os

# === ✅ 可配置项 ===
CONFIG = {
    "GITHUB_TOKEN": "your_github_token_here",
    "TARGET_DIR": "./github_repos",
    "SKIP_FORK": False,
    "SKIP_ARCHIVED": True,
    "FILTER_LANGUAGES": [],  # 例如 ["Python", "Jupyter Notebook"]，空列表表示不过滤
    "PER_PAGE": 100,
}


def should_skip_repo(repo):
    if CONFIG["SKIP_FORK"] and repo.get("fork"):
        return True
    if CONFIG["SKIP_ARCHIVED"] and repo.get("archived"):
        return True
    if CONFIG["FILTER_LANGUAGES"]:
        lang = repo.get("language")
        if lang not in CONFIG["FILTER_LANGUAGES"]:
            return True
    return False


def clone_repositories():
    headers = {
        "Authorization": f"token {CONFIG['GITHUB_TOKEN']}",
        "Accept": "application/vnd.github+json"
    }

    url = "https://api.github.com/user/repos"
    params = {
        "per_page": CONFIG["PER_PAGE"],
        "page": 1,
        "visibility": "all",
        "affiliation": "owner"
    }

    os.makedirs(CONFIG["TARGET_DIR"], exist_ok=True)
    print(f"🚀 开始克隆仓库到目录：{CONFIG['TARGET_DIR']}")

    while True:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code != 200:
            print(f"❌ 请求失败: {response.status_code} - {response.text}")
            break

        repos = response.json()
        if not repos:
            print("✅ 所有仓库处理完毕。")
            break

        for repo in repos:
            if should_skip_repo(repo):
                print(f"⏭ 跳过：{repo['full_name']}")
                continue

            repo_name = repo["name"]
            clone_url = repo["clone_url"]
            target_path = os.path.join(CONFIG["TARGET_DIR"], repo_name)

            if os.path.exists(target_path):
                print(f"🔁 已存在，跳过：{repo_name}")
                continue

            print(f"🔄 克隆：{clone_url} → {target_path}")
            subprocess.run(["git", "clone", clone_url, target_path])

        params["page"] += 1


if __name__ == "__main__":
    if not CONFIG["GITHUB_TOKEN"].startswith("ghp_") and len(CONFIG["GITHUB_TOKEN"]) < 30:
        print("❗ 请正确填写 GITHUB_TOKEN。")
    else:
        clone_repositories()
