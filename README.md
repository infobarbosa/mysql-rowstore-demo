# MySQL Rowstore
Author: Prof. Barbosa<br>
Contact: infobarbosa@gmail.com<br>
Github: [infobarbosa](https://github.com/infobarbosa)

## Objetivo
Avaliar de forma rudimentar o comportamento do modelo de armazenamento baseado em linha.<br>
Para isso faremos uso do MySQL pela sua simplicidade e praticidade.

## Ambiente 
Este laborarório pode ser executado em qualquer estação de trabalho.<br>
Recomendo, porém, a execução em Linux.<br>
Caso você não tenha um à sua disposição, há duas opções:
1. AWS Cloud9: siga essas [instruções](Cloud9/README.md).
2. Killercoda: disponibiilizei o lab [aqui](https://killercoda.com/infobarbosa/scenario/mysql)

## Setup
Para começar, faça o clone deste repositório:
```
git clone https://github.com/infobarbosa/mysql-rowstore-demo.git
```

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

### Acesso ao docker
Para acessar o docker via terminal:
```
docker exec -it mysql8 /bin/bash
```

Output esperado:
```
```

## A base de dados

### Database `ecommerce`
```
mysql -u root -e \
    "CREATE DATABASE IF NOT EXISTS ecommerce;"
```

### Tabela `cliente`
```
mysql -u root -e \
    "CREATE TABLE ecommerce.cliente(
        id int PRIMARY KEY,
        cpf text,
        nome text
    );"
```

Verificando se deu certo
```
mysql -u root -e \
    "DESCRIBE ecommerce.cliente;"
```

Output esperado:
```
bash-5.1# mysql -u root -e \
>     "DESCRIBE ecommerce.cliente;"
+-------+------+------+-----+---------+-------+
| Field | Type | Null | Key | Default | Extra |
+-------+------+------+-----+---------+-------+
| id    | int  | NO   | PRI | NULL    |       |
| cpf   | text | YES  |     | NULL    |       |
| nome  | text | YES  |     | NULL    |       |
+-------+------+------+-----+---------+-------+
bash-5.1# 
```

## Operações em linhas (ou registros)

### 1. 1o. Insert
```
mysql -u root -e \
    "INSERT INTO ecommerce.cliente(id, cpf, nome)
    VALUES (10, '11111111111', 'marcelo barbosa');"

```

Verificando:
```
mysql -u root -e \
    "SELECT * FROM ecommerce.cliente;"
```

Output:
```
bash-5.1# mysql -u root -e \
>     "SELECT * FROM ecommerce.cliente;"
+----+-------------+-----------------+
| id | cpf         | nome            |
+----+-------------+-----------------+
| 10 | 11111111111 | marcelo barbosa |
+----+-------------+-----------------+
bash-5.1# 
```

### 2. FLUSH TABLES

Vamos forçar o flush dos dados da memória para o disco de forma a verificar o arquivo de dados.
```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

Verificando o conteúdo do arquivo `cliente.ibd`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

### 3. 2o. Insert
```
mysql -u root -e \
   "INSERT INTO ecommerce.cliente(id, cpf, nome)
    VALUES (11, '22222222222', 'Juscelino Kubitschek');"
```

Faça o flush novamente e verifique o arquivo:
```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

### 4. Insert em lote
```
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
mysql -u root -e \
    "SELECT * FROM ecommerce.cliente;"
```

Output esperado:
```
+------+-------------+---------------------------+
| id   | cpf         | nome                      |
+------+-------------+---------------------------+
|   10 | 11111111111 | marcelo barbosa           |
|   11 | 22222222222 | Juscelino Kubitschek      |
| 1001 | 98753936060 | MARIVALDA KANAMARY        |
| 1002 | 12455426050 | JUCILENE MOREIRA CRUZ     |
| 1003 | 32487300051 | GRACIMAR BRASIL GUERRA    |
| 1004 | 59813133074 | ALDENORA VIANA MOREIRA    |
| 1005 | 79739952003 | VERA LUCIA RODRIGUES SENA |
| 1006 | 66142806000 | IVONE GLAUCIA VIANA DUTRA |
| 1007 | 19052330000 | LUCILIA ROSA LIMA PEREIRA |
+------+-------------+---------------------------+
```

Faça o flush novamente e verifique o arquivo:
```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output esperado:<br>
![img/output-cliente.ibd.png](img/output-cliente.ibd.png)

### 5. Delete
```
mysql -u root -e \
    "DELETE FROM ecommerce.cliente WHERE id = 11;"
```

Faça o flush novamente e verifique o arquivo:
```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

### 6. Update
```
mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARI K.' WHERE id = 1001"

```

```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

> Perceba que o update praticamente não alterou o layout do arquivo.

![img/update-1-marivalda-short.png](img/update-1-marivalda-short.png)

```
mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARIVALDA DE ALCÂNTARA FRANCISCO ANTÔNIO JOÃO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÉ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÇA E BOURBON KANAMARY' WHERE id = 1001;"
```

```
mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

> Perceba agora que, em razão do tamanho do nome, o banco de dados realocou o registro para um novo bloco (ou, possivelmente, outra posição no mesmo bloco)

![img/update-2-marivalda-long.png](img/update-2-marivalda-long.png)

## Parabéns!
