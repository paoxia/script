# Script

开发常用脚本和 Docker 配置集合。

## 目录结构

```
script/
├── cli/                          # 命令行工具
│   ├── ai_project_clone.sh       # AI 项目克隆脚本 (Linux/Mac)
│   ├── ai_project_clone.bat      # AI 项目克隆脚本 (Windows)
│   ├── git_pull_all.sh           # 批量拉取 Git 仓库 (Linux/Mac)
│   ├── git_pull_all.bat          # 批量拉取 Git 仓库 (Windows)
│   ├── kill_process.sh           # 杀死进程脚本 (Linux/Mac)
│   ├── kill_process.bat          # 杀死进程脚本 (Windows)
│   ├── mac_dev_init.sh           # Mac 开发环境初始化
│   └── linux_dev_init.sh         # Linux 开发环境初始化
└── docker/                       # Docker 配置
    ├── redis/                    # Redis
    ├── mysql/                    # MySQL 8.0
    ├── postgres/                 # PostgreSQL 15
    ├── mongodb/                  # MongoDB 7 + Mongo Express
    ├── elasticsearch/            # Elasticsearch 8 + Kibana
    ├── rabbitmq/                 # RabbitMQ + 管理界面
    ├── nginx/                    # Nginx 反向代理
    └── docker-compose.all.yml    # 一键启动所有服务
```

## CLI 工具

### 开发环境初始化

#### Mac

```bash
chmod +x cli/mac_dev_init.sh
./cli/mac_dev_init.sh
```

支持安装：
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

#### Linux

```bash
chmod +x cli/linux_dev_init.sh
./cli/linux_dev_init.sh
```

支持发行版：Debian/Ubuntu, Fedora/RHEL/CentOS, Arch Linux, openSUSE

### Git 批量操作

```bash
# 批量拉取所有仓库
./cli/git_pull_all.sh

# 克隆 AI 项目
./cli/ai_project_clone.sh
```

## Docker 服务

### 单独启动

```bash
# Redis
cd docker/redis && docker-compose up -d

# MySQL
cd docker/mysql && docker-compose up -d

# PostgreSQL
cd docker/postgres && docker-compose up -d

# MongoDB
cd docker/mongodb && docker-compose up -d

# Elasticsearch + Kibana
cd docker/elasticsearch && docker-compose up -d

# RabbitMQ
cd docker/rabbitmq && docker-compose up -d

# Nginx
cd docker/nginx && docker-compose up -d
```

### 一键启动所有服务

```bash
cd docker && docker-compose -f docker-compose.all.yml up -d
```

### 端口映射

| 服务 | 端口 | 管理界面 |
|------|------|----------|
| Redis | 6379 | RedisInsight: 5540 |
| MySQL | 3306 | - |
| PostgreSQL | 5432 | - |
| MongoDB | 27017 | Mongo Express: 8081 |
| RabbitMQ | 5672 | Management: 15672 |
| Elasticsearch | 9200 | Kibana: 5601 |
| Nginx | 80, 443 | - |

### 默认密码

| 服务 | 用户名 | 密码 |
|------|--------|------|
| MySQL root | root | root123456 |
| MySQL app | app_user | app123456 |
| PostgreSQL | postgres | postgres123456 |
| MongoDB | admin | admin123456 |
| RabbitMQ | admin | admin123456 |
| Mongo Express | admin | admin |

> ⚠️ 生产环境请务必修改默认密码！

## License

[MIT](LICENSE)
