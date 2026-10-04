# Workflow de Worktrees - Projeto BIA

## Visão Geral

O projeto BIA usa **git worktrees** para permitir que múltiplos agentes (ou desenvolvedores) trabalhem em tasks diferentes simultaneamente, sem conflitos. Esse é o mesmo mecanismo usado pelo Claude Code, GitHub Codex e outras ferramentas de AI coding agents.

## O que é um Worktree?

Um **worktree** é um diretório de trabalho separado que compartilha o mesmo repositório Git. Cada worktree tem:
- ✅ Seus próprios arquivos (working directory isolado)
- ✅ Seu próprio index Git
- ✅ Sua própria branch
- ✅ Compartilha o histórico Git e o repositório `.git/` com o checkout principal

## Estrutura do Projeto

```
/bia                          # Checkout principal (branch ia_main)
├── .worktrees/               # Diretório de worktrees (gitignored)
│   ├── 007-feat-date-picker-calendario/
│   │   ├── .task-meta.json   # Metadados da task
│   │   └── ... (código da task 007)
│   ├── 008-feat-grafico-tarefas-prioridade/
│   │   ├── .task-meta.json
│   │   └── ... (código da task 008)
│   └── 009-fix-bug-login/
│       └── ... (código da task 009)
├── .gitignore                # Contém /.worktrees/
└── scripts/
    ├── worktree-create.sh    # Cria worktree para task
    ├── worktree-remove.sh    # Remove worktree após merge
    └── worktree-list.sh      # Lista worktrees ativas
```

## Workflow Completo

### 1. Criar Task + Worktree

Quando uma nova task é criada:

```bash
# Criar a task (arquivo .md em .amazonq/tasks/doing/)
# Depois criar a worktree automaticamente

./scripts/worktree-create.sh 007 feat-date-picker-calendario
```

**O que acontece:**
- ✅ Cria branch `feat/007-feat-date-picker-calendario` a partir de `ia_main`
- ✅ Cria worktree em `.worktrees/007-feat-date-picker-calendario/`
- ✅ Copia arquivos `.env` para a worktree
- ✅ Cria arquivo `.task-meta.json` com metadados
- ✅ Pronto para trabalhar de forma isolada

### 2. Trabalhar na Task

```bash
# Entrar na worktree
cd .worktrees/007-feat-date-picker-calendario/

# Trabalhar normalmente
# ... fazer modificações ...

# Commitar
git add .
git commit -m "feat(task-007): adiciona date picker no formulário"

# Push
git push -u origin feat/007-feat-date-picker-calendario
```

### 3. Criar Pull Request

```bash
# Criar PR usando GitHub CLI
gh pr create --base ia_main --title "feat: date picker no campo de data" --body "Resolve #007"

# Ou deixar o agente criar o PR
```

### 4. Após Merge da PR

Quando o PR for mergeado em `ia_main`:

```bash
# Voltar para o checkout principal
cd /Users/jonathanestefani/programacao/bia

# Remover a worktree
./scripts/worktree-remove.sh 007
```

**O que acontece:**
- ✅ Verifica se há mudanças não commitadas
- ✅ Remove o diretório `.worktrees/007-feat-date-picker-calendario/`
- ✅ Opcionalmente deleta a branch local e remota
- ✅ Limpa referências órfãs com `git worktree prune`

## Comandos Úteis

### Listar Worktrees

```bash
./scripts/worktree-list.sh
```

Mostra:
- Todas as worktrees ativas
- Task number, branch, data de criação
- Status do Git (commits ahead, mudanças pendentes)

### Criar Worktree Manualmente

```bash
./scripts/worktree-create.sh <task_number> <task_name>

# Exemplo:
./scripts/worktree-create.sh 009 fix-bug-login
```

### Remover Worktree Manualmente

```bash
./scripts/worktree-remove.sh <task_number>

# Exemplo:
./scripts/worktree-remove.sh 009
```

### Comandos Git Nativos

```bash
# Listar worktrees (nativo)
git worktree list

# Remover worktree (nativo)
git worktree remove .worktrees/007-feat-date-picker-calendario

# Limpar referências órfãs
git worktree prune

# Desbloquear worktree locked
git worktree unlock .worktrees/007-feat-date-picker-calendario
```

## Isolamento e Segurança

### O que é isolado?

✅ **Arquivos** — Cada worktree tem seus próprios arquivos  
✅ **Commits** — Commits afetam apenas a branch da worktree  
✅ **Branches** — Git impede checkout de branches em uso por outra worktree  

### O que é compartilhado?

✅ **Repositório Git** — Todas as worktrees compartilham o mesmo `.git/`  
✅ **Histórico** — Todas veem o mesmo histórico de commits  
✅ **Remote** — Todas fazem push/pull do mesmo remote  

### Proteção Automática

Git **bloqueia** tentativas de:
- Fazer checkout de uma branch que já está em uso
- Sobrescrever trabalho de outra worktree
- Conflitos entre worktrees

```bash
# Exemplo de erro
$ git checkout feat/007-feat-date-picker-calendario
fatal: 'feat/007-feat-date-picker-calendario' is already used by worktree at
'/Users/jonathanestefani/programacao/bia/.worktrees/007-feat-date-picker-calendario'
```

## Casos de Uso Práticos

### Caso 1: Múltiplos Agentes Trabalhando Simultaneamente

```bash
# @dev trabalhando na task 007
cd .worktrees/007-feat-date-picker-calendario/

# @devops trabalhando na task 008
cd .worktrees/008-feat-grafico-tarefas-prioridade/

# @qa validando task 006 (já mergeada)
cd /Users/jonathanestefani/programacao/bia  # checkout principal
```

### Caso 2: Code Review Enquanto Desenvolve

```bash
# Continuar desenvolvendo task 008
cd .worktrees/008-feat-grafico-tarefas-prioridade/

# Em outro terminal, revisar PR da task 007
cd .worktrees/007-feat-date-picker-calendario/
git pull
# ... revisar código ...
```

### Caso 3: Hotfix Urgente Sem Perder Trabalho

```bash
# Trabalhando na task 009
cd .worktrees/009-refactor-api/

# Precisa fazer hotfix urgente
cd /Users/jonathanestefani/programacao/bia
./scripts/worktree-create.sh 010 hotfix-security-issue
cd .worktrees/010-hotfix-security-issue/

# Fix, commit, push, merge

# Voltar para task 009
cd .worktrees/009-refactor-api/
# Trabalho continua de onde parou, sem `git stash`
```

## Arquivo .task-meta.json

Cada worktree contém metadados em `.task-meta.json`:

```json
{
  "taskNumber": "007",
  "taskName": "feat-date-picker-calendario",
  "branchName": "feat/007-feat-date-picker-calendario",
  "createdAt": "2026-10-04T15:30:00Z",
  "baseBranch": "ia_main"
}
```

Usado por:
- Scripts de gerenciamento
- Agentes para contexto
- Ferramentas de automação

## Integração com Agentes

### Agente @dev

```bash
# Ao receber uma task, o @dev:
1. Verifica que está em ia_main
2. Cria worktree: ./scripts/worktree-create.sh 007 feat-date-picker-calendario
3. Entra na worktree: cd .worktrees/007-feat-date-picker-calendario/
4. Implementa a task
5. Commita e faz push
6. Cria PR: gh pr create --base ia_main
7. Aguarda merge
```

### Após Merge (Manual ou @po)

```bash
# Quando PR é mergeado:
1. cd /Users/jonathanestefani/programacao/bia
2. git pull origin ia_main
3. ./scripts/worktree-remove.sh 007
4. Mover task de doing/ para done/
```

## Troubleshooting

### Worktree ficou "locked"

```bash
git worktree unlock .worktrees/007-feat-date-picker-calendario
git worktree remove .worktrees/007-feat-date-picker-calendario
```

### Worktree com mudanças não commitadas

```bash
cd .worktrees/007-feat-date-picker-calendario/
git status
git add . && git commit -m "WIP: salvar progresso"
git push
```

### Branch já existe ao criar worktree

```bash
# Script perguntará se deseja usar a branch existente
# Ou deletar e recriar:
git branch -D feat/007-feat-date-picker-calendario
./scripts/worktree-create.sh 007 feat-date-picker-calendario
```

### Limpar worktrees órfãs

```bash
# Se worktrees foram deletadas manualmente sem git worktree remove
git worktree prune
```

## Boas Práticas

✅ **Sempre use os scripts** — `worktree-create.sh` e `worktree-remove.sh`  
✅ **Commit antes de sair** — Não deixe mudanças não commitadas  
✅ **Nome descritivo** — Use nomes claros para task_name  
✅ **Remova após merge** — Não acumule worktrees antigas  
✅ **Verifique status** — Use `worktree-list.sh` regularmente  

❌ **Não delete `.worktrees/` manualmente** — Use `worktree-remove.sh`  
❌ **Não faça checkout da mesma branch** — Git impedirá, mas não force  
❌ **Não trabalhe na main** — Use worktrees para tudo  

## Referências

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Claude Code Worktrees](https://code.claude.com/docs/en/worktrees)
- [banteg/agents](https://github.com/banteg/agents)
- [Nimbalyst - Git Worktrees for AI Agents](https://nimbalyst.com/blog/git-worktrees-for-ai-coding-agents-complete-guide/)

---

**Última atualização:** 2026-10-04  
**Testado e validado:** ✅ [Ver worktree-test-results.md](./worktree-test-results.md)
