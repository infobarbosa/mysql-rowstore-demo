#!/usr/bin/env bash
# ==============================================================================
# Script de Provisionamento Automático - Laboratório MySQL Rowstore Demo
# Autor: Prof. Barbosa (infobarbosa@gmail.com)
# Repositório: https://github.com/infobarbosa/mysql-rowstore-demo
# ==============================================================================

set -euo pipefail

# Desabilitar o pager padrao da AWS CLI (evita que comandos travem no less/END)
export AWS_PAGER=""

# Cores para output formatado
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "==================================================================="
echo "   LABORATÓRIO MYSQL ROWSTORE DEMO - AWS EC2 + CODE-SERVER         "
echo "   Provisionamento Automatizado via AWS CloudShell                 "
echo "==================================================================="
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. Validação de Região e Descoberta de Rede
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/5] Identificando região e infraestrutura de rede...${NC}"

# Identificar a região atual
AWS_REGION=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text 2>/dev/null || echo "${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}")
echo -e "  -> Região detectada: ${BOLD}${AWS_REGION}${NC}"

if [ "${AWS_REGION}" != "us-east-1" ]; then
    echo -e "${YELLOW}  [AVISO] Recomenda-se a utilização da região Norte da Virgínia (us-east-1) no AWS Academy.${NC}"
fi

# Localizar VPC Padrão (isDefault=true)
VPC_ID=$(aws ec2 describe-vpcs \
    --region "${AWS_REGION}" \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text)

if [ -z "${VPC_ID}" ] || [ "${VPC_ID}" == "None" ]; then
    echo -e "${RED}[ERRO] Nenhuma VPC padrão encontrada na região ${AWS_REGION}.${NC}"
    exit 1
fi
echo -e "  -> VPC Padrão: ${BOLD}${VPC_ID}${NC}"

# Tipo de instância do laboratório e alternativa de mesmo porte (geração anterior).
# A alternativa só é usada se nenhuma zona da região oferecer o tipo principal.
INSTANCE_TYPE="t3.medium"
FALLBACK_INSTANCE_TYPE="t2.medium"

# Zonas de disponibilidade que oferecem um tipo de instância (separadas por vírgula)
zonas_com_oferta() {
    aws ec2 describe-instance-type-offerings \
        --region "${AWS_REGION}" \
        --location-type availability-zone \
        --filters "Name=instance-type,Values=$1" \
        --query "InstanceTypeOfferings[].Location" \
        --output text | tr '\t' ','
}

# Nem toda zona oferece todos os tipos (ex.: a us-east-1e não oferece t3 nem m5).
# Por isso a Subnet é escolhida apenas entre as zonas que oferecem o tipo.
AZS=$(zonas_com_oferta "${INSTANCE_TYPE}")
if [ -z "${AZS}" ]; then
    echo -e "${YELLOW}  [AVISO] Nenhuma zona da região oferece ${INSTANCE_TYPE}; usando ${FALLBACK_INSTANCE_TYPE}.${NC}"
    INSTANCE_TYPE="${FALLBACK_INSTANCE_TYPE}"
    AZS=$(zonas_com_oferta "${INSTANCE_TYPE}")
fi
if [ -z "${AZS}" ]; then
    echo -e "${RED}[ERRO] Nenhuma zona da região ${AWS_REGION} oferece ${INSTANCE_TYPE}.${NC}"
    exit 1
fi
echo -e "  -> Zonas que oferecem ${BOLD}${INSTANCE_TYPE}${NC}: ${AZS}"

# Localizar uma Subnet Pública da VPC Padrão numa dessas zonas
read -r SUBNET_ID SUBNET_AZ < <(aws ec2 describe-subnets \
    --region "${AWS_REGION}" \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=availability-zone,Values=${AZS}" \
    --query "Subnets[0].[SubnetId,AvailabilityZone]" \
    --output text)

if [ -z "${SUBNET_ID}" ] || [ "${SUBNET_ID}" == "None" ]; then
    echo -e "${RED}[ERRO] Nenhuma Subnet da VPC ${VPC_ID} está numa zona que oferece ${INSTANCE_TYPE}.${NC}"
    exit 1
fi
echo -e "  -> Subnet selecionada: ${BOLD}${SUBNET_ID}${NC} (${SUBNET_AZ})"

# ------------------------------------------------------------------------------
# 2. Configuração do Security Group (lab-mysql-sg)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[2/5] Configurando Security Group...${NC}"
SG_NAME="lab-mysql-sg"

# Verificar se o Security Group já existe
SG_ID=$(aws ec2 describe-security-groups \
    --region "${AWS_REGION}" \
    --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
    --query "SecurityGroups[0].GroupId" \
    --output text 2>/dev/null || true)

if [ -z "${SG_ID}" ] || [ "${SG_ID}" == "None" ]; then
    echo -e "  -> Criando Security Group '${SG_NAME}'..."
    SG_ID=$(aws ec2 create-security-group \
        --region "${AWS_REGION}" \
        --group-name "${SG_NAME}" \
        --description "Security group para Laboratorio MySQL Rowstore Demo (code-server e SSH)" \
        --vpc-id "${VPC_ID}" \
        --query "GroupId" \
        --output text)
    echo -e "  -> Security Group criado: ${BOLD}${SG_ID}${NC}"
else
    echo -e "  -> Security Group existente encontrado: ${BOLD}${SG_ID}${NC}"
fi

# Regras de Entrada (Inbound): Porta 8080 (IDE) e Porta 22 (SSH)
echo -e "  -> Assegurando regras de entrada (Portas 8080 e 22)..."
aws ec2 authorize-security-group-ingress \
    --region "${AWS_REGION}" \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 >/dev/null 2>&1 || true

aws ec2 authorize-security-group-ingress \
    --region "${AWS_REGION}" \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 >/dev/null 2>&1 || true
# Nota: A porta 3306 (MySQL) nao e exposta; o banco escuta apenas dentro do container.

# ------------------------------------------------------------------------------
# 3. Resolução da AMI (Ubuntu Server 24.04 LTS amd64)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[3/5] Consultando AMI mais recente do Ubuntu Server 24.04 LTS...${NC}"
SSM_PARAM="/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"

AMI_ID=$(aws ssm get-parameter \
    --region "${AWS_REGION}" \
    --name "${SSM_PARAM}" \
    --query "Parameter.Value" \
    --output text 2>/dev/null || true)

if [ -z "${AMI_ID}" ] || [ "${AMI_ID}" == "None" ]; then
    echo -e "${RED}[ERRO] Falha ao recuperar o ID da AMI via SSM Parameter Store.${NC}"
    exit 1
fi
echo -e "  -> AMI Ubuntu 24.04 LTS: ${BOLD}${AMI_ID}${NC}"

# ------------------------------------------------------------------------------
# 4. Lançamento da Instância EC2 (sempre uma nova, com data e hora no nome)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[4/5] Lançando a instância EC2...${NC}"
# Cada execução cria uma instância NOVA, com data e hora (de Brasília) no nome,
# para não colidir com instâncias de execuções anteriores.
INSTANCE_PREFIX="lab-mysql-rowstore"
INSTANCE_TAG_NAME="${INSTANCE_PREFIX}-$(TZ=America/Sao_Paulo date +%Y-%m-%d_%H_%M_%S)"

# Instâncias de execuções anteriores não são alteradas, mas consomem créditos enquanto existirem
PREVIOUS_INSTANCES=$(aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --filters "Name=tag:Name,Values=${INSTANCE_PREFIX}*" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name']|[0].Value,InstanceId,State.Name]" \
    --output text 2>/dev/null || true)

if [ -n "${PREVIOUS_INSTANCES}" ]; then
    echo -e "${YELLOW}  [AVISO] Instâncias de execuções anteriores deste laboratório (não serão alteradas):${NC}"
    echo "${PREVIOUS_INSTANCES}" | sed 's/^/       /'
    echo -e "${YELLOW}  Este script não religa instâncias anteriores. Para continuar numa delas, siga 'Retomando o laboratório' no README.${NC}"
    echo -e "${YELLOW}  Se não for mais usá-las, encerre-as no Console EC2 (Instance state > Terminate instance).${NC}"
fi

echo -e "  -> Provisionando nova instância EC2 ${BOLD}${INSTANCE_TAG_NAME}${NC} (${BOLD}${INSTANCE_TYPE}${NC})..."

# Script de User Data executado no boot da maquina
USER_DATA_SCRIPT='#!/bin/bash
export HOME=/root
export DEBIAN_FRONTEND=noninteractive

# Atualizacao dos repositorios e instalacao do docker
apt-get update -y
apt-get install -y docker.io

# Inicializacao e habilitacao do servico docker
systemctl start docker
systemctl enable docker

# Adicionar usuario padrao do ubuntu ao grupo docker
usermod -aG docker ubuntu

# Criar pasta persistente do workspace com permissoes para UID/GID 1000 (usuario barbosa do container)
mkdir -p /home/ubuntu/workspace
chown -R 1000:1000 /home/ubuntu/workspace
chmod -R 775 /home/ubuntu/workspace

# Execucao do container (code-server em modo passwordless + MySQL)
docker run -d \
  --name mysql-lab \
  --restart always \
  -p 8080:8080 \
  -v /home/ubuntu/workspace:/home/barbosa/project \
  ghcr.io/infobarbosa/mysql-lab-docker-image:latest
'

# Lancamento da instancia
INSTANCE_ID=$(aws ec2 run-instances \
    --region "${AWS_REGION}" \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --iam-instance-profile Name="LabInstanceProfile" \
    --subnet-id "${SUBNET_ID}" \
    --security-group-ids "${SG_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_TAG_NAME}}]" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
    --user-data "${USER_DATA_SCRIPT}" \
    --query "Instances[0].InstanceId" \
    --output text)

echo -e "  -> Instância criada com sucesso: ${BOLD}${INSTANCE_ID}${NC}"

# ------------------------------------------------------------------------------
# 5. Polling de Estado e Retorno Ergonômico ao Usuário
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}[5/5] Aguardando a instância atingir o estado 'running'...${NC}"

while true; do
    CURRENT_STATE=$(aws ec2 describe-instances \
        --region "${AWS_REGION}" \
        --instance-ids "${INSTANCE_ID}" \
        --query "Reservations[0].Instances[0].State.Name" \
        --output text 2>/dev/null || echo "unknown")
    
    if [ "${CURRENT_STATE}" == "running" ]; then
        echo -e "  -> Estado atual: ${GREEN}${BOLD}running${NC}"
        break
    elif [ "${CURRENT_STATE}" == "terminated" ] || [ "${CURRENT_STATE}" == "shutting-down" ]; then
        echo -e "${RED}[ERRO] A instância foi encerrada inesperadamente (${CURRENT_STATE}).${NC}"
        exit 1
    fi
    echo -e "  -> Estado atual: ${YELLOW}${CURRENT_STATE}${NC} (aguardando 5 segundos...)"
    sleep 5
done

# Obter o Endereço IP Público da Instância
PUBLIC_IP=$(aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --instance-ids "${INSTANCE_ID}" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "${PUBLIC_IP}" ] || [ "${PUBLIC_IP}" == "None" ]; then
    echo -e "${YELLOW}[AVISO] O IP público ainda não está disponível. Consulte o console EC2.${NC}"
    PUBLIC_IP="<IP_PUBLICO_NO_CONSOLE_EC2>"
fi

# Painel de Conclusao e Instrucoes de Acesso
echo -e "\n${GREEN}${BOLD}===================================================================${NC}"
echo -e "${GREEN}${BOLD}            AMBIENTE DE LABORATÓRIO PRONTO PARA USO!              ${NC}"
echo -e "${GREEN}${BOLD}===================================================================${NC}"
echo -e " ${BOLD}Instância:${NC}        ${INSTANCE_TAG_NAME}"
echo -e " ${BOLD}Instância ID:${NC}     ${INSTANCE_ID}"
echo -e " ${BOLD}IP Público:${NC}       ${PUBLIC_IP}"
echo -e " ${BOLD}Link de Acesso:${NC}   ${CYAN}${BOLD}http://${PUBLIC_IP}:8080${NC}"
echo -e " ${BOLD}Autenticação:${NC}     ${YELLOW}${BOLD}Passwordless (Acesso Direto - Sem Senha)${NC}"
echo -e "-------------------------------------------------------------------"
echo -e " ${BOLD}IMPORTANTE - TEMPO DE INICIALIZAÇÃO:${NC}"
echo -e " O script User Data está instalando o Docker e baixando a imagem"
echo -e " com o code-server e o MySQL em segundo plano."
echo -e " -> ${BOLD}Tempo estimado de inicialização do container: 3 a 5 minutos.${NC}"
echo -e " Se a página web não responder imediatamente, aguarde 2 minutos e"
echo -e " atualize o seu navegador (Ctrl+F5 ou Cmd+Shift+R)."
echo -e "${GREEN}${BOLD}===================================================================${NC}\n"
