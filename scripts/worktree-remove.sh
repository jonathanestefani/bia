#!/bin/bash

# Script para remover worktree após merge da PR
# Uso: ./scripts/worktree-remove.sh 007

set -e

TASK_NUMBER="$1"

if [ -z "$TASK_NUMBER" ]; then
  echo "❌ Uso: $0 <task_number>"
  echo "   Exemplo: $0 007"
  exit 1
fi

# Buscar worktree pelo número da task
WORKTREE_PATH=$(find .worktrees -maxdepth 1 -type d -name "${TASK_NUMBER}-*" 2>/dev/null | head -n 1)

if [ -z "$WORKTREE_PATH" ]; then
  echo "❌ Nenhuma worktree encontrada para task $TASK_NUMBER"
  echo ""
  echo "📋 Worktrees disponíveis:"
  git worktree list
  exit 1
fi

# Extrair informações
TASK_NAME=$(basename "$WORKTREE_PATH" | sed "s/^${TASK_NUMBER}-//")
BRANCH_NAME="feat/${TASK_NUMBER}-${TASK_NAME}"

echo "🔍 Worktree encontrada:"
echo "   Caminho: $WORKTREE_PATH"
echo "   Branch: $BRANCH_NAME"
echo ""

# Verificar se há mudanças não commitadas
if [ -d "$WORKTREE_PATH/.git" ] || [ -f "$WORKTREE_PATH/.git" ]; then
  cd "$WORKTREE_PATH"
  
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  ATENÇÃO: A worktree contém mudanças não commitadas!"
    git status --short
    echo ""
    echo "   Deseja continuar e PERDER essas mudanças? (y/n)"
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then
      echo "❌ Operação cancelada"
      exit 1
    fi
  fi
  
  cd - > /dev/null
fi

# Confirmar remoção
echo "❓ Deseja remover a worktree? (y/n)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "❌ Operação cancelada"
  exit 1
fi

# Desbloquear worktree se estiver locked
git worktree unlock "$WORKTREE_PATH" 2>/dev/null || true

# Remover worktree
echo "🗑️  Removendo worktree..."
git worktree remove "$WORKTREE_PATH" --force

# Perguntar se deseja deletar a branch também
echo ""
echo "❓ Deseja deletar a branch '$BRANCH_NAME' também? (y/n)"
echo "   (Só delete se o PR já foi mergeado)"
read -r CONFIRM_BRANCH

if [ "$CONFIRM_BRANCH" = "y" ]; then
  echo "🗑️  Deletando branch local..."
  git branch -D "$BRANCH_NAME" 2>/dev/null || true
  
  echo "🗑️  Deletando branch remota..."
  git push origin --delete "$BRANCH_NAME" 2>/dev/null || echo "   (Branch remota já foi deletada ou não existe)"
fi

# Limpar referências órfãs
echo "🧹 Limpando referências..."
git worktree prune

echo ""
echo "✅ Worktree removida com sucesso!"
echo ""
echo "📋 Worktrees restantes:"
git worktree list
echo ""
