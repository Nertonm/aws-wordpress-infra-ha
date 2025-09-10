#!/bin/bash -ex
    # -e: sai imediatamente se um comando falhar
    # -x: imprime cada comando antes de executar

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
    # tee: grava a saída em um arquivo e também a envia para o logger
    # logger: envia mensagens para o syslog
    # 2>/dev/console: envia mensagens de erro para o console

echo "$(date) Início do script user-data"
echo "Atualizando o sistema e instalando dependências..."
yum update -y
yum install -y docker amazon-efs-utils 
    # Instala Docker e o utils do EFS

echo "$(date) Iniciando e habilitando o serviço Docker..."
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user 
    # Habilita o Docker para iniciar na inicialização do sistema e inicia o serviço Docker
    # Adiciona o usuário ec2-user ao grupo docker 

echo "$(date) Instalando o Docker Compose..."
curl -SL https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
    # Baixa e instala o Docker Compose
    # Define permissões executáveis para o binário do Docker Compose
    
echo "$(date) Definindo ponto de montagem para o EFS em ${efs_mount_point}..."
mkdir -p ${efs_mount_point}
chown ec2-user:ec2-user ${efs_mount_point}
    # Cria o diretório de montagem do EFS e ajusta a propriedade para o usuário ec2-user

echo "$(date) Montando o EFS (${efs_dns_name}) em ${efs_mount_point}..."
mount -t efs -o tls ${efs_dns_name}:/ ${efs_mount_point}
    # Monta o sistema de arquivos EFS no ponto de montagem especificado
    # -t efs: especifica o tipo de sistema de arquivos
    # -o tls: habilita a criptografia TLS para a conexão
    # Adiciona a entrada ao /etc/fstab para montagem automática na reinicialização

echo "${efs_dns_name}:/ ${efs_mount_point} efs _netdev,tls 0 0" >> /etc/fstab
    # _netdev: indica que o sistema de arquivos depende da rede
    # tls: habilita a criptografia TLS para a conexão
    # 0 0: opções de dump e fsck

mkdir -p ${compose_dir}
compose_file="${compose_dir}/docker-compose.yml"
echo "$(date) Criando o diretório para o Docker Compose em ${compose_dir}..."

chown ec2-user:ec2-user ${compose_dir}
    # Cria o diretório para o arquivo docker-compose.yml e ajusta a propriedade para o usuário ec2-user

echo "$(date) Criando o arquivo compose..."
cat << EOF > ${compose_file}
services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: "${db_endpoint}"       # Injetado pelo Terraform
      WORDPRESS_DB_USER: "${db_username}"           # Injetado pelo Terraform
      WORDPRESS_DB_PASSWORD: "${db_password}"   # Injetado pelo Terraform
      WORDPRESS_DB_NAME: "${db_name}"
    volumes:
      - ${efs_mount_point}:/var/www/html
EOF

echo "$(date) Iniciando WordPress via Docker Compose..."
docker-compose -f ${compose_file} up -d
echo "$(date) Final do script user-data"
