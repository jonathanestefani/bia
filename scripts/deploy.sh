#!/bin/bash
set -e

# ─── Configurações ────────────────────────────────────────────────────────────
CLUSTER="cluster-dev"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
ECR_URI="793471733055.dkr.ecr.us-east-1.amazonaws.com/bia"
REGION="us-east-1"

# ─── Helpers ──────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Uso: $(basename "$0") <comando> [opções]

Comandos:
  deploy [commit-hash]        Registra nova task definition com a imagem da tag
                              informada e faz deploy no serviço ECS.
                              Se omitido, usa o hash do commit atual do git.

  rollback <task-def-arn>     Faz deploy de uma revisão específica da task
                              definition (ex: task-def-bia:2).

  list                        Lista todas as revisões registradas da task
                              definition com a imagem associada.

  history                     Exibe o histórico de deploys do serviço ECS.

Exemplos:
  $(basename "$0") deploy abc1234
  $(basename "$0") rollback task-def-bia:2
  $(basename "$0") list
  $(basename "$0") history
EOF
  exit 0
}

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
die()  { echo "ERRO: $*" >&2; exit 1; }

wait_stable() {
  log "Aguardando serviço estabilizar..."
  aws ecs wait services-stable \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION"
  log "Serviço estável."
}

# ─── Comandos ─────────────────────────────────────────────────────────────────
cmd_deploy() {
  local COMMIT_HASH="${1:-$(git -C "$(dirname "$0")/.." rev-parse --short HEAD 2>/dev/null)}"
  [[ -z "$COMMIT_HASH" ]] && die "Não foi possível obter o commit hash. Informe manualmente. Ex: deploy abc1234"
  log "Commit hash: $COMMIT_HASH"

  local IMAGE="${ECR_URI}:${COMMIT_HASH}"

  log "Verificando imagem no ECR: $IMAGE"
  aws ecr describe-images \
    --repository-name bia \
    --image-ids imageTag="$COMMIT_HASH" \
    --region "$REGION" > /dev/null 2>&1 \
    || die "Imagem com tag '$COMMIT_HASH' não encontrada no ECR."

  log "Obtendo task definition atual..."
  local TASK_DEF_JSON
  TASK_DEF_JSON=$(aws ecs describe-task-definition \
    --task-definition "$TASK_FAMILY" \
    --region "$REGION" \
    --query 'taskDefinition')

  log "Registrando nova task definition com imagem $IMAGE..."
  local TMP_FILE NEW_TASK_DEF_ARN
  TMP_FILE=$(mktemp /tmp/task-def-XXXXXX.json)
  echo "$TASK_DEF_JSON" | python3 -c "
import json, sys
td = json.load(sys.stdin)
td['containerDefinitions'][0]['image'] = '${IMAGE}'
for key in ['taskDefinitionArn','revision','status','requiresAttributes',
            'compatibilities','registeredAt','registeredBy']:
    td.pop(key, None)
print(json.dumps(td))
" > "$TMP_FILE"
  NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json "file://${TMP_FILE}" \
    --region "$REGION" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)
  rm -f "$TMP_FILE"

  log "Nova task definition: $NEW_TASK_DEF_ARN"

  log "Atualizando serviço $SERVICE..."
  aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$NEW_TASK_DEF_ARN" \
    --region "$REGION" > /dev/null

  wait_stable
  log "Deploy concluído! Commit: $COMMIT_HASH | Task: $NEW_TASK_DEF_ARN"
}

cmd_rollback() {
  local TARGET="$1"
  [[ -z "$TARGET" ]] && die "Informe a revisão. Ex: rollback task-def-bia:2"

  log "Verificando task definition: $TARGET"
  aws ecs describe-task-definition \
    --task-definition "$TARGET" \
    --region "$REGION" > /dev/null 2>&1 \
    || die "Task definition '$TARGET' não encontrada."

  log "Fazendo rollback para $TARGET..."
  aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --task-definition "$TARGET" \
    --region "$REGION" > /dev/null

  wait_stable
  log "Rollback concluído! Task definition ativa: $TARGET"
}

cmd_list() {
  log "Revisões da task definition '$TASK_FAMILY':"
  echo ""
  printf "%-45s %s\n" "TASK DEFINITION" "IMAGEM"
  printf "%-45s %s\n" "---------------" "------"

  aws ecs list-task-definitions \
    --family-prefix "$TASK_FAMILY" \
    --region "$REGION" \
    --query 'taskDefinitionArns[]' \
    --output text | tr '\t' '\n' | while read -r ARN; do
      local REV IMAGE
      REV=$(echo "$ARN" | awk -F: '{print $NF}')
      IMAGE=$(aws ecs describe-task-definition \
        --task-definition "$ARN" \
        --region "$REGION" \
        --query 'taskDefinition.containerDefinitions[0].image' \
        --output text)
      printf "%-45s %s\n" "${TASK_FAMILY}:${REV}" "$IMAGE"
  done
}

cmd_history() {
  log "Histórico de deploys do serviço '$SERVICE':"
  echo ""
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --region "$REGION" \
    --query 'services[0].events[0:10].[createdAt,message]' \
    --output table
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
[[ $# -eq 0 ]] && usage

case "$1" in
  deploy)   cmd_deploy   "$2" ;;
  rollback) cmd_rollback "$2" ;;
  list)     cmd_list          ;;
  history)  cmd_history       ;;
  -h|--help|help) usage       ;;
  *) die "Comando desconhecido: $1. Use --help para ver os comandos disponíveis." ;;
esac
