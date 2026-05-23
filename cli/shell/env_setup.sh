#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ENV_DIR="${ENV_DIR:-.}"
ENV_FILE="${ENV_DIR}/.env"
ENV_EXAMPLE="${ENV_DIR}/.env.example"

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$*"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$*"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

show_usage() {
    cat <<'EOF'
Environment Variables Management Tool

Usage:
  source env_setup.sh load [env]    Load environment variables (dev/staging/prod)
  ./env_setup.sh show               Show current environment variables
  ./env_setup.sh init               Create .env.example template
  ./env_setup.sh check              Check required environment variables
  ./env_setup.sh export [file]      Export variables to file
  ./env_setup.sh help               Show this help message

Examples:
  source env_setup.sh load          Load from .env
  source env_setup.sh load dev      Load from .env.dev
  source env_setup.sh load prod     Load from .env.prod
  ./env_setup.sh show               Display all env vars
  ./env_setup.sh init               Generate .env.example template

Environment Files:
  .env           Default environment
  .env.dev       Development environment
  .env.staging   Staging environment
  .env.prod      Production environment
EOF
}

load_env() {
    local env_name="${1:-}"
    local env_file

    if [[ -n "$env_name" ]]; then
        env_file="${ENV_DIR}/.env.${env_name}"
    else
        env_file="$ENV_FILE"
    fi

    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file not found: $env_file"
        return 1
    fi

    log_info "Loading environment from: $env_file"

    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            
            export "$key"="$value"
        else
            log_warn "Invalid format at line $line_num: $line"
        fi
    done < "$env_file"

    log_info "Environment loaded successfully"
}

show_env() {
    printf "${CYAN}Current Environment Variables:${NC}\n"
    echo "----------------------------------------"

    if [[ -f "$ENV_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            
            if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)= ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${!key:-<not set>}"
                
                if [[ "$key" =~ (PASSWORD|SECRET|KEY|TOKEN) ]]; then
                    value="********"
                fi
                
                printf "  ${GREEN}%-25s${NC} = %s\n" "$key" "$value"
            fi
        done < "$ENV_FILE"
    else
        log_warn "No .env file found"
    fi

    echo "----------------------------------------"
}

init_env() {
    local template='
# Application
APP_NAME=myapp
APP_ENV=development
APP_PORT=3000
APP_DEBUG=true

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=dbname
DATABASE_USER=user
DATABASE_PASSWORD=password

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

# API Keys
OPENAI_API_KEY=sk-your-api-key
ANTHROPIC_API_KEY=sk-ant-your-api-key

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=my-bucket

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# Email
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_PASSWORD=password

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
'

    if [[ -f "$ENV_EXAMPLE" ]]; then
        log_warn ".env.example already exists"
        read -rp "Overwrite? (y/n): " confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return 0
    fi

    echo "$template" > "$ENV_EXAMPLE"
    log_info "Created .env.example template"
    log_info "Copy it to .env and fill in your values: cp .env.example .env"
}

check_env() {
    local required_vars=(
        "APP_NAME"
        "DATABASE_URL"
    )

    printf "${CYAN}Checking required environment variables:${NC}\n"
    echo "----------------------------------------"

    local missing=0
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            printf "  ${RED}✗${NC} %s (missing)\n" "$var"
            ((missing++))
        else
            printf "  ${GREEN}✓${NC} %s\n" "$var"
        fi
    done

    echo "----------------------------------------"

    if [[ $missing -gt 0 ]]; then
        log_error "$missing required variable(s) missing"
        return 1
    else
        log_info "All required variables are set"
    fi
}

export_env() {
    local output_file="${1:-env_export.sh}"

    printf "${CYAN}Exporting environment variables to: %s${NC}\n" "$output_file"

    {
        echo "# Generated by env_setup.sh on $(date)"
        echo ""
        
        if [[ -f "$ENV_FILE" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)= ]]; then
                    local key="${BASH_REMATCH[1]}"
                    local value="${!key:-}"
                    echo "export ${key}=\"${value}\""
                fi
            done < "$ENV_FILE"
        fi
    } > "$output_file"

    log_info "Exported to $output_file"
}

main() {
    local command="${1:-help}"

    case "$command" in
        load)
            load_env "${2:-}"
            ;;
        show)
            show_env
            ;;
        init)
            init_env
            ;;
        check)
            check_env
            ;;
        export)
            export_env "${2:-}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
