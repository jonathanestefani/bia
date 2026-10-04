#!/bin/bash

# Script para criar worktree automaticamente ao criar uma task
# Uso: ./scripts/worktree-create.sh 007 "feat-date-picker-calendario"

set -e

TASK_NUMBER="$1"
TASK_NAME="$2"

if [ -z "$TASK_NUMBER" ] || [ -z "$TASK_NAME" ]; then
  echo "❌ Uso: $0 <task_number> <task_name>"
  echo "   Exemplo: $0 007 feat-date-picker-calendario"
  exit 1
fi

# Validar que estamos na branch base correta
CURRENT_BRANCH=$(git branch --show-current)
BASE_BRANCH="ia_main"

if [ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]; then
  echo "⚠️  Você está em '$CURRENT_BRANCH', mas a base deveria ser '$BASE_BRANCH'"
  echo "   Deseja continuar mesmo assim? (y/n)"
  read -r CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "❌ Operação cancelada"
    exit 1
  fi
fi

# Nomes padronizados
BRANCH_NAME="feat/${TASK_NUMBER}-${TASK_NAME}"
WORKTREE_PATH=".worktrees/${TASK_NUMBER}-${TASK_NAME}"

# Verificar se a worktree já existe
if [ -d "$WORKTREE_PATH" ]; then
  echo "⚠️  Worktree '$WORKTREE_PATH' já existe"
  echo "   Deseja removê-la e recriar? (y/n)"
  read -r CONFIRM
  if [ "$CONFIRM" = "y" ]; then
    echo "🗑️  Removendo worktree existente..."
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
    git branch -D "$BRANCH_NAME" 2>/dev/null || true
  else
    echo "❌ Operação cancelada"
    exit 1
  fi
fi

# Verificar se a branch já existe
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo "⚠️  Branch '$BRANCH_NAME' já existe"
  echo "   Deseja usar a branch existente? (y/n)"
  read -r CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "❌ Operação cancelada"
    exit 1
  fi
  CREATE_BRANCH=""
else
  CREATE_BRANCH="-b"
fi

# Criar diretório .worktrees se não existir
mkdir -p .worktrees

# Criar worktree
echo "🌳 Criando worktree..."
if [ -n "$CREATE_BRANCH" ]; then
  git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"
else
  git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

# Copiar arquivos importantes não-versionados (.env, etc)
if [ -f ".env" ]; then
  echo "📄 Copiando .env para worktree..."
  cp .env "$WORKTREE_PATH/.env"
fi

if [ -f "client/.env" ]; then
  echo "📄 Copiando client/.env para worktree..."
  cp client/.env "$WORKTREE_PATH/client/.env"
fi

# Criar arquivo de metadados da task
cat > "$WORKTREE_PATH/.task-meta.json" <<EOF
{
  "taskNumber": "$TASK_NUMBER",
  "taskName": "$TASK_NAME",
  "branchName": "$BRANCH_NAME",
  "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "baseBranch": "$BASE_BRANCH"
}
EOF

echo ""
echo "✅ Worktree criada com sucesso!"
echo ""
echo "📂 Localização: $WORKTREE_PATH"
echo "🌿 Branch: $BRANCH_NAME"
echo "📋 Base: $BASE_BRANCH"
echo ""
echo "🚀 Próximos passos:"
echo "   1. cd $WORKTREE_PATH"
echo "   2. Trabalhe na task normalmente"
echo "   3. git add . && git commit -m \"feat: descrição\""
echo "   4. git push -u origin $BRANCH_NAME"
echo "   5. gh pr create --base $BASE_BRANCH"
echo ""
echo "💡 Quando o PR for mergeado, execute:"
echo "   ./scripts/worktree-remove.sh $TASK_NUMBER"
echo ""
