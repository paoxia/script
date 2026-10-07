# Script

开发常用脚本和 Docker 配置集合。

## 目录结构

```
script/
├── cli/                              # 命令行工具
│   ├── shell/                        # Linux / macOS (bash)
│   │   ├── mac_dev_init.sh           # macOS 开发环境初始化
│   │   ├── linux_dev_init.sh         # Linux 开发环境初始化
│   │   ├── env_setup.sh              # .env 环境变量管理
│   │   ├── git_pull_all.sh           # 批量拉取 Git 仓库
│   │   ├── ai_repos.sh               # 批量克隆 AI 项目
│   │   ├── paoxia_repos.sh           # 批量克隆 paoxia 用户仓库
│   │   └── kill_process.sh           # 按端口/名称结束进程
│   └── bat/                          # Windows (cmd)
│       ├── env_setup.bat
│       ├── git_pull_all.bat
│       ├── ai_repos.bat
│       ├── paoxia_repos.bat
│       └── kill_process.bat
└── docker/                           # Docker 配置
    ├── redis/                        # Redis
    ├── mysql/                        # MySQL 8.0
    ├── postgres/                     # PostgreSQL 15
    ├── mongodb/                      # MongoDB 7 + Mongo Express
    ├── elasticsearch/                # Elasticsearch 8 + Kibana
    ├── rabbitmq/                     # RabbitMQ + 管理界面
    ├── nginx/                        # Nginx 反向代理
    └── docker-compose.all.yml        # 一键启动所有服务
```

## CLI 工具

### 开发环境初始化

#### macOS

```bash
chmod +x cli/shell/mac_dev_init.sh
./cli/shell/mac_dev_init.sh
```

可选安装：
- Git + SSH 密钥配置
- Java (JDK 21) + Maven + Gradle
- Go
- Node.js (nvm)
- Docker Desktop
- Database Tools (MySQL, PostgreSQL, Redis, DBeaver)
- Development Tools (curl, wget, jq, tree, htop, tmux 等)
- IDE (IntelliJ IDEA CE)
- Terminal Tools (Oh My Zsh, Starship, zoxide)
- Python Tools (pyenv, poetry, uv, conda, pipenv)
- Cloud Tools (AWS CLI, kubectl, helm, terraform)
- 前端工具 (pnpm, yarn, Vite 等)
- GitHub CLI (`gh`)
- 钉钉 DWS CLI (`dws`)
- 飞书官方 CLI (`lark-cli`)
- OpenAI Codex CLI (`codex`)

#### Linux

```bash
chmod +x cli/shell/linux_dev_init.sh
./cli/shell/linux_dev_init.sh
```

支持发行版：Debian/Ubuntu、Fedora/RHEL/CentOS、Arch Linux、openSUSE。

macOS 和 Linux 的初始化菜单均提供以下独立安装选项，选择 `a`（全部安装）也会包含这些工具：

| 菜单选项 | 工具 | 安装方式 |
|----------|------|----------|
| 13 | GitHub CLI (`gh`) | macOS 使用 Homebrew；Linux 使用 GitHub 官方软件源（Arch 使用 `github-cli`） |
| 14 | 钉钉 DWS CLI (`dws`) | `npm install -g dingtalk-workspace-cli` |
| 15 | 飞书 CLI (`lark-cli`) | `npm install -g @larksuite/cli` |
| 16 | Codex CLI (`codex`) | `npm install -g @openai/codex` |

已在 PATH 中的工具会跳过安装。npm 安装项会先加载已有 nvm；若缺少 Node.js 16+ 或 npm，会自动调用 Node.js 初始化步骤安装 LTS 版本。全局 npm 安装使用当前用户权限，建议使用脚本提供的 nvm 环境。

安装完成后，按需执行首次登录或配置：

```bash
gh auth login
dws auth login
lark-cli config init
lark-cli auth login --recommend
codex
```

安装参考：[GitHub CLI](https://github.com/cli/cli#installation)、[钉钉 DWS](https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli/blob/main/README_zh.md)、[飞书 CLI](https://github.com/larksuite/cli)、[OpenAI Codex CLI](https://developers.openai.com/codex/cli/)。

### 环境变量管理

管理项目下的 `.env` 文件，支持从 `.env.example` 同步、查看、编辑等操作。

```bash
# Linux / macOS
./cli/shell/env_setup.sh

# Windows
cli\bat\env_setup.bat
```

### Git 批量操作

```bash
# 批量拉取当前目录下所有 git 仓库
./cli/shell/git_pull_all.sh

# 克隆 AI 相关项目
./cli/shell/ai_repos.sh

# 批量克隆 paoxia 用户的所有 GitHub 仓库
./cli/shell/paoxia_repos.sh [target_dir]
```

Windows 用户在 `cli/bat/` 下使用对应的 `.bat` 脚本。

### 进程管理

```bash
# Linux / macOS
./cli/shell/kill_process.sh

# Windows
cli\bat\kill_process.bat
```

## Docker 服务

### 单独启动

```bash
cd docker/redis          && docker-compose up -d
cd docker/mysql          && docker-compose up -d
cd docker/postgres       && docker-compose up -d
cd docker/mongodb        && docker-compose up -d
cd docker/elasticsearch  && docker-compose up -d
cd docker/rabbitmq       && docker-compose up -d
cd docker/nginx          && docker-compose up -d
```

### 一键启动所有服务

```bash
cd docker && docker-compose -f docker-compose.all.yml up -d
```

### 端口映射

| 服务          | 端口     | 管理界面             |
|---------------|----------|----------------------|
| Redis         | 6379     | RedisInsight: 5540   |
| MySQL         | 3306     | -                    |
| PostgreSQL    | 5432     | -                    |
| MongoDB       | 27017    | Mongo Express: 8081  |
| RabbitMQ      | 5672     | Management: 15672    |
| Elasticsearch | 9200     | Kibana: 5601         |
| Nginx         | 80, 443  | -                    |

### 默认账号

| 服务          | 用户名     | 密码            |
|---------------|------------|-----------------|
| MySQL root    | root       | root123456      |
| MySQL app     | app_user   | app123456       |
| PostgreSQL    | postgres   | postgres123456  |
| MongoDB       | admin      | admin123456     |
| RabbitMQ      | admin      | admin123456     |
| Mongo Express | admin      | admin           |

> ⚠️ 生产环境请务必修改默认密码！

## License

[MIT](LICENSE)
