# Integração de Worktrees com Agentes - Projeto BIA

## Visão Geral

O projeto BIA usa **git worktrees** para isolamento de trabalho paralelo. Cada task deve ser desenvolvida em sua própria worktree, permitindo que múltiplos agentes trabalhem simultaneamente sem conflitos.

## Quando Usar Worktrees

### ✅ Sempre use worktree para:
- Implementar uma nova task (feature, fix, refactor)
- Trabalhar em múltiplas tasks ao mesmo tempo
- Isolar mudanças de diferentes agentes
- Testar código sem afetar o checkout principal

### ❌ Não use worktree para:
- Operações simples de leitura
- Explorações rápidas do código
- Consultas ao histórico Git
- Comandos que não modificam arquivos

---

## Fluxo de Trabalho para Agentes

### 1. Ao Receber uma Task

**Antes de começar a implementar:**

```bash
# Verificar branch atual
git branch --show-current  # Deve estar em ia_main

# Se não estiver, trocar para ia_main
git checkout ia_main
git pull origin ia_main

# Criar worktree para a task
./scripts/worktree-create.sh <task_number> <task_name_simples>

# Exemplo para task 007:
./scripts/worktree-create.sh 007 feat-date-picker-calendario
```

**Nomenclatura da task_name:**
- Usar kebab-case (palavras separadas por hífen)
- Máximo 50 caracteres
- Prefixo do tipo: `feat-`, `fix-`, `refactor-`, `docs-`, `test-`
- Descritivo mas conciso
- Sem caracteres especiais além de hífen

**Exemplos válidos:**
- `007 feat-date-picker-calendario`
- `008 feat-grafico-tarefas-prioridade`
- `009 fix-bug-login`
- `010 refactor-api-tarefas`
- `011 docs-worktree-workflow`

### 2. Trabalhar na Worktree

```bash
# Entrar na worktree
cd .worktrees/<task_number>-<task_name>/

# Verificar que está na branch correta
git branch --show-current  # feat/<task_number>-<task_name>

# Implementar a task normalmente
# ... fazer modificações ...

# Commitar progressivamente (boas práticas)
git add <arquivos_modificados>
git commit -m "tipo(task-XXX): descrição concisa"

# Exemplos de commits:
# git commit -m "feat(task-007): adiciona date picker ao formulário"
# git commit -m "test(task-007): adiciona testes para conversão de data"
# git commit -m "docs(task-007): atualiza README com date picker"
```

**Tipos de commit:**
- `feat`: nova funcionalidade
- `fix`: correção de bug
- `refactor`: refatoração sem mudar comportamento
- `test`: adicionar ou modificar testes
- `docs`: documentação
- `style`: formatação, espaços, ponto e vírgula
- `chore`: tarefas de manutenção

### 3. Push e Pull Request

```bash
# Push da branch (primeira vez)
git push -u origin feat/<task_number>-<task_name>

# Push subsequente
git push

# Criar PR usando GitHub CLI
gh pr create \
  --base ia_main \
  --title "feat(task-007): adiciona date picker no formulário" \
  --body "Resolve task 007 - Date Picker no campo de data/prazo

## Mudanças
- Substitui input text por input date
- Adiciona conversão de formato YYYY-MM-DD para DD/MM/YYYY
- Mantém compatibilidade com formato atual do banco

## Testes
- [x] Formulário renderiza date picker
- [x] Data é convertida corretamente
- [x] Tarefas são criadas com formato correto
- [x] Testes unitários passam"
```

### 4. Após Merge da PR

**Quando o PR for mergeado (você será notificado):**

```bash
# Voltar para o checkout principal
cd /Users/jonathanestefani/programacao/bia

# Atualizar ia_main
git pull origin ia_main

# Remover a worktree
./scripts/worktree-remove.sh <task_number>

# Exemplo:
./scripts/worktree-remove.sh 007

# O script perguntará:
# 1. Se deseja remover (confirmar com 'y')
# 2. Se deseja deletar a branch também (confirmar com 'y' se PR foi mergeado)

# Mover task de doing/ para done/
mv .amazonq/tasks/doing/007-feat-date-picker-calendario.md \
   .amazonq/tasks/done/007-feat-date-picker-calendario.md
```

---

## Comandos Essenciais

### Verificar Status

```bash
# Listar todas as worktrees ativas
./scripts/worktree-list.sh

# Ver status detalhado de uma worktree
cd .worktrees/<task_number>-<task_name>/
git status
git log --oneline -5
```

### Navegação

```bash
# Entrar em uma worktree
cd .worktrees/007-feat-date-picker-calendario/

# Voltar para checkout principal
cd /Users/jonathanestefani/programacao/bia

# Ir para outra worktree
cd .worktrees/008-feat-grafico-tarefas-prioridade/
```

### Sincronização

```bash
# Dentro de uma worktree, pegar mudanças da ia_main
git fetch origin
git merge origin/ia_main

# Ou rebase (se preferir histórico linear)
git fetch origin
git rebase origin/ia_main
```

---

## Resolução de Problemas

### Problema: Worktree ficou "locked"

**Sintoma:** `git worktree remove` falha com erro "locked"

**Solução:**
```bash
git worktree unlock .worktrees/<task_number>-<task_name>
git worktree remove .worktrees/<task_number>-<task_name>
```

### Problema: Branch já existe

**Sintoma:** Script falha dizendo que a branch já existe

**Solução 1 (usar branch existente):**
```bash
# O script perguntará se deseja usar a branch existente
# Confirme com 'y'
```

**Solução 2 (recriar do zero):**
```bash
# Deletar branch existente
git branch -D feat/<task_number>-<task_name>

# Executar script novamente
./scripts/worktree-create.sh <task_number> <task_name>
```

### Problema: Mudanças não commitadas ao remover

**Sintoma:** Script avisa sobre mudanças não commitadas

**Solução 1 (salvar mudanças):**
```bash
cd .worktrees/<task_number>-<task_name>/
git add .
git commit -m "WIP: salvar progresso"
git push
cd /Users/jonathanestefani/programacao/bia
./scripts/worktree-remove.sh <task_number>
```

**Solução 2 (descartar mudanças):**
```bash
# O script perguntará se deseja continuar e PERDER as mudanças
# Confirme com 'y' apenas se tiver certeza
```

### Problema: Erro "Cannot remove a locked working tree"

**Sintoma:** Git se recusa a remover worktree

**Solução:**
```bash
# Desbloquear
git worktree unlock .worktrees/<task_number>-<task_name>

# Remover com força
git worktree remove .worktrees/<task_number>-<task_name> --force

# Limpar referências
git worktree prune
```

---

## Boas Práticas para Agentes

### ✅ DO (Faça)

1. **Sempre crie worktree antes de implementar**
   - Isolamento evita conflitos
   - Permite trabalho paralelo

2. **Use nomes descritivos**
   - Facilita identificação
   - Documentação automática

3. **Commit frequentemente**
   - Histórico granular
   - Fácil de reverter

4. **Push regularmente**
   - Backup automático
   - Visibilidade do progresso

5. **Remova worktrees após merge**
   - Mantém repositório limpo
   - Evita confusão

6. **Verifique status antes de sair**
   ```bash
   git status
   git log --oneline -3
   ```

### ❌ DON'T (Não Faça)

1. **Não trabalhe direto na ia_main**
   - Sempre use worktree
   - Protege branch principal

2. **Não delete `.worktrees/` manualmente**
   - Use o script `worktree-remove.sh`
   - Git precisa limpar metadados

3. **Não force checkout de branch em uso**
   - Git impedirá, mas respeite o erro
   - Pode corromper trabalho de outro agente

4. **Não acumule worktrees antigas**
   - Remova após merge
   - Usa espaço em disco desnecessariamente

5. **Não modifique arquivos fora da worktree**
   - Cada agente deve respeitar seu isolamento
   - Evita conflitos silenciosos

---

## Exemplo Completo de Fluxo

### Cenário: @dev implementando task 007

```bash
# 1. PREPARAÇÃO
cd /Users/jonathanestefani/programacao/bia
git checkout ia_main
git pull origin ia_main

# 2. CRIAR WORKTREE
./scripts/worktree-create.sh 007 feat-date-picker-calendario
# ✅ Worktree criada: .worktrees/007-feat-date-picker-calendario/
# ✅ Branch: feat/007-feat-date-picker-calendario

# 3. ENTRAR E TRABALHAR
cd .worktrees/007-feat-date-picker-calendario/

# Verificar task
cat .amazonq/tasks/doing/007-feat-date-picker-calendario.md

# Implementar
# ... modificar client/src/components/AddTask.jsx ...

# 4. TESTAR
docker compose up -d
npm test
# Validar manualmente em http://localhost:3000

# 5. COMMITAR
git add client/src/components/AddTask.jsx
git commit -m "feat(task-007): adiciona date picker ao formulário"

git add client/src/components/AddTask.jsx
git commit -m "feat(task-007): adiciona conversão de formato de data"

git add tests/unit/components/AddTask.test.js
git commit -m "test(task-007): adiciona testes para date picker"

# 6. PUSH
git push -u origin feat/007-feat-date-picker-calendario

# 7. CRIAR PR
gh pr create \
  --base ia_main \
  --title "feat(task-007): date picker no campo de data" \
  --body "Implementa task 007 conforme especificação"

# 8. AGUARDAR MERGE
# ... PR é revisado e mergeado ...

# 9. LIMPAR
cd /Users/jonathanestefani/programacao/bia
git pull origin ia_main
./scripts/worktree-remove.sh 007

# Confirmar remoção: y
# Deletar branch: y

# Mover task para done/
mv .amazonq/tasks/doing/007-feat-date-picker-calendario.md \
   .amazonq/tasks/done/007-feat-date-picker-calendario.md

# ✅ Task concluída!
```

---

## Checklist para Cada Task

Antes de começar:
- [ ] Estou em `ia_main` atualizada?
- [ ] Li o arquivo da task em `.amazonq/tasks/doing/`?
- [ ] Criei worktree com `worktree-create.sh`?

Durante desenvolvimento:
- [ ] Estou trabalhando dentro da worktree?
- [ ] Estou commitando progressivamente?
- [ ] Estou fazendo push regularmente?
- [ ] Estou testando as mudanças?

Antes do PR:
- [ ] Todos os testes passam?
- [ ] Todos os critérios de aceitação foram atendidos?
- [ ] Código segue os padrões do projeto?
- [ ] Removi logs de debug?

Após merge:
- [ ] Atualizei `ia_main` local?
- [ ] Removi a worktree com `worktree-remove.sh`?
- [ ] Movi task para `done/`?

---

## Integração com .kiro/agents/

Cada agente especializado deve seguir este workflow:

**@dev** — Desenvolvimento
- Cria worktree ao receber task
- Implementa dentro da worktree
- Remove worktree após merge

**@devops** — Infraestrutura
- Cria worktree para mudanças em scripts/, Dockerfile, etc.
- Testa isoladamente
- Remove após merge

**@qa** — Quality Assurance
- Pode criar worktree para testar PR
- Ou validar direto na worktree do @dev
- Remove após validação

**@po** — Product Owner
- Não cria worktrees
- Gerencia tasks em `.amazonq/tasks/`
- Valida que PRs foram mergeados

---

## Referências

- [Documentação Completa de Worktrees](../.amazonq/docs/worktree-workflow.md)
- [Testes de Isolamento](../.amazonq/docs/worktree-test-results.md)
- [Git Worktree Official Docs](https://git-scm.com/docs/git-worktree)

---

**Última atualização:** 2026-10-04
