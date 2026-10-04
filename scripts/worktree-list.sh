#!/bin/bash

# Script para listar todas as worktrees e suas informações
# Uso: ./scripts/worktree-list.sh

echo "🌳 Worktrees do projeto BIA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar worktrees do git
git worktree list

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar worktrees em .worktrees/ com metadados
if [ -d ".worktrees" ]; then
  WORKTREE_COUNT=$(find .worktrees -maxdepth 1 -type d ! -path .worktrees | wc -l | tr -d ' ')
  
  if [ "$WORKTREE_COUNT" -eq 0 ]; then
    echo "📭 Nenhuma worktree ativa no momento"
  else
    echo "📊 Detalhes das worktrees ($WORKTREE_COUNT):"
    echo ""
    
    for WORKTREE_PATH in .worktrees/*/; do
      if [ -d "$WORKTREE_PATH" ]; then
        WORKTREE_NAME=$(basename "$WORKTREE_PATH")
        
        echo "📂 $WORKTREE_NAME"
        
        # Ler metadados se existirem
        if [ -f "$WORKTREE_PATH/.task-meta.json" ]; then
          TASK_NUMBER=$(jq -r '.taskNumber' "$WORKTREE_PATH/.task-meta.json" 2>/dev/null || echo "N/A")
          BRANCH_NAME=$(jq -r '.branchName' "$WORKTREE_PATH/.task-meta.json" 2>/dev/null || echo "N/A")
          CREATED_AT=$(jq -r '.createdAt' "$WORKTREE_PATH/.task-meta.json" 2>/dev/null || echo "N/A")
          
          echo "   Task: #$TASK_NUMBER"
          echo "   Branch: $BRANCH_NAME"
          echo "   Criada: $CREATED_AT"
        fi
        
        # Status do Git
        if [ -d "$WORKTREE_PATH/.git" ] || [ -f "$WORKTREE_PATH/.git" ]; then
          cd "$WORKTREE_PATH"
          
          CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
          COMMITS_AHEAD=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
          
          echo "   Status: $CURRENT_BRANCH ($COMMITS_AHEAD commits ahead)"
          
          # Verificar mudanças pendentes
          if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            CHANGED_FILES=$(git status --short | wc -l | tr -d ' ')
            echo "   ⚠️  $CHANGED_FILES arquivo(s) modificado(s)"
          fi
          
          cd - > /dev/null
        fi
        
        echo ""
      fi
    done
  fi
else
  echo "📭 Diretório .worktrees/ não existe"
fi

echo ""
echo "💡 Comandos úteis:"
echo "   Criar: ./scripts/worktree-create.sh <task_number> <task_name>"
echo "   Remover: ./scripts/worktree-remove.sh <task_number>"
echo "   Entrar: cd .worktrees/<task_number>-<task_name>"
echo ""
