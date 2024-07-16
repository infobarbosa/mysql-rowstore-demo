# Rowstore
Author: Prof. Barbosa<br>
Contact: infobarbosa@gmail.com<br>
Github: [infobarbosa](https://github.com/infobarbosa)

## Objetivo
Avaliar de forma rudimentar o comportamento do modelo de linha.

>### Atenção! 
> Os comandos desse tutorial presumem que você está no diretório raiz do projeto.

## Configurações
No diretório `server/mysql/etc/` encontra-se um arquivo `my.cnf` que contém os parâmetros de configuração do MySQL.<br>
Embora não seja escopo deste laboratório o entendimento detalhado do MySQL, recomendo o estudo do arquivo `my.cnf`.

```
ls -latr server/mysql/etc/my.cnf
```

Output esperado:
```
barbosa@brubeck:~/labs/mysql8$ ls -latr server/mysql/etc/my.cnf
-rw-r--r-- 1 barbosa barbosa 581 jul 16 14:46 server/mysql/etc/my.cnf
```
## Docker
Por simplicidade, vamos utilizar o MySQL em um container baseado em *Docker*.<br>
Na raiz do projeto está disponível um arquivo `compose.yaml` que contém os parâmetros de inicialização do container Docker.<br>
Embora não seja escopo deste laboratório o entendimento detalhado do Docker, recomendo o estudo do arquivo `compose.yaml`.

```
ls -la compose.yaml
```

Output esperado:
```
barbosa@brubeck:~/labs/mysql8$ ls -la compose.yaml
-rw-r--r-- 1 barbosa barbosa 589 jul 16 14:48 compose.yaml
```

### Inicialização
```
docker compose up -d
```

Para verificar se está tudo correto:
```
docker compose logs -f
```

## Diretório de dados
Perceba que após a inicialização serão criados alguns novos diretórios abaixo da pasta `./server/mysql/`
```
ls -la ./server/mysql/
```

Output esperado:
```
barbosa@brubeck:~/labs/mysql8$ ls -la ./server/mysql/
total 24
drwxr-xr-x 6 barbosa barbosa 4096 jul 16 14:51 .
drwxr-xr-x 3 barbosa barbosa 4096 jul 15 19:48 ..
drwxr-xr-x 9     999 root    4096 jul 16 14:52 data
drwxr-xr-x 2 barbosa barbosa 4096 jul 15 19:48 etc
drwxr-xr-x 2 root    root    4096 jul 16 14:51 logs
drwxr-xr-x 2 root    root    4096 jul 16 14:51 sql
barbosa@brubeck:~/labs/mysql8$
```

O diretório `./server/mysql/data` representa o diretório `/var/lib/mysql/`.<br>
O objetivo aqui é facilitar a inspeção dos arquivos de dados durante o laboratório.

## A base de dados

### Database `ecommerce`
```
docker exec -it mysql8 \
    mysql -u root -e \
    "CREATE DATABASE IF NOT EXISTS ecommerce;"
```

### Tabela `cliente`
```
docker exec -it mysql8 \
    mysql -u root -e \
    "CREATE TABLE ecommerce.cliente(
        id int PRIMARY KEY,
        cpf text,
        nome text
    );"
```

Verificando se deu certo
```
docker exec -it mysql8 \
    mysql -u root -e \
    "DESCRIBE ecommerce.cliente;"
```

Output esperado:
```

```

## Operações em linhas (ou registros)

### 1. 1o. Insert
```
docker exec -it mysql8 \
    mysql -u root -e \
    "INSERT INTO ecommerce.cliente(id, cpf, nome)
     VALUES (10, '11111111111', 'marcelo barbosa');"

```

Verificando:
```
docker exec -it mysql8 \
    mysql -u root -e \
    "SELECT * FROM ecommerce.cliente;"
```

Output:
```

```

### 2. FLUSH TABLES

Vamos forçar o flush dos dados da memória para o disco de forma a verificar o arquivo de dados.
```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

Verificando o conteúdo do arquivo `cliente.ibd`
```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

### 3. 2o. Insert
```
docker exec -it mysql8 \
    mysql -u root -e \
   "INSERT INTO ecommerce.cliente(id, cpf, nome)
    VALUES (11, '22222222222', 'Juscelino Kubitschek');"
```

Faça o flush novamente e verifique o arquivo:
```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

### 4. Insert em lote
```
docker exec -it mysql8 \
    mysql -u root -Bse \
    "INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1001, '98753936060', 'MARIVALDA KANAMARY');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1002, '12455426050', 'JUCILENE MOREIRA CRUZ');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1003, '32487300051', 'GRACIMAR BRASIL GUERRA');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1004, '59813133074', 'ALDENORA VIANA MOREIRA');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1005, '79739952003', 'VERA LUCIA RODRIGUES SENA');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1006, '66142806000', 'IVONE GLAUCIA VIANA DUTRA');
    INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1007, '19052330000', 'LUCILIA ROSA LIMA PEREIRA');"
```

Verificando se os inserts ocorreram como esperado:
```
docker exec -it mysql8 \
    mysql -u root -e \
    "SELECT * FROM ecommerce.cliente;"
```

Output esperado:
```

```

Faça o flush novamente e verifique o arquivo:
```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```


### 5. Delete
```
docker exec -it mysql8 \
    mysql -u root -e \
    "DELETE FROM ecommerce.cliente WHERE id = 11;"
```

Faça o flush novamente e verifique o arquivo:
```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

> Perceba o espaço vazio entre o registro `marcelo` e `MARIVALDA`.

### 6. Update
```
docker exec -it mysql8 \
    mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARI K.' WHERE id = 1001"

```

```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

> Perceba que o update praticamente não alterou o layout do arquivo.

```
docker exec -it mysql8 \
    mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARIVALDA DE ALCÂNTARA FRANCISCO ANTÔNIO JOÃO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÉ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÇA E BOURBON KANAMARY' WHERE id = 1001;"
```

```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
docker exec -it mysql8 \
    cat /var/lib/mysql/ecommerce/cliente.ibd
```

> Perceba agora que, em razão do tamanho do nome, o banco de dados realocou o registro para um novo bloco (ou, possivelmente, outra posição no mesmo bloco)

## Parabéns
