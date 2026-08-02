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

#### Linux

```bash
chmod +x cli/shell/linux_dev_init.sh
./cli/shell/linux_dev_init.sh
```

支持发行版：Debian/Ubuntu、Fedora/RHEL/CentOS、Arch Linux、openSUSE。

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
