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
https://github.com/infobarbosa/mysql-rowstore-demo.git
```

>### Atenção! 
> Os comandos desse tutorial presumem que você está no diretório raiz do projeto.

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

## Conectando-se ao container
Conecte-se ao container `mysql-demo` com o seguinte comando:

```
docker exec -it mysql-demo /bin/bash

```

## A base de dados

### Database `ecommerce`

Criando a base de dados *ecommerce*:
```
mysql -u root -e \
"CREATE DATABASE IF NOT EXISTS ecommerce;"

```

### Tabela `cliente`

Criando a tabela *cliente*:
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
+-------+------+------+-----+---------+-------+
| Field | Type | Null | Key | Default | Extra |
+-------+------+------+-----+---------+-------+
| id    | int  | NO   | PRI | NULL    |       |
| cpf   | text | YES  |     | NULL    |       |
| nome  | text | YES  |     | NULL    |       |
+-------+------+------+-----+---------+-------+
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
+----+-------------+-----------------+
| id | cpf         | nome            |
+----+-------------+-----------------+
| 10 | 11111111111 | marcelo barbosa |
+----+-------------+-----------------+
```

### 2. O arquivo de dados

Verificando o conteúdo do arquivo `cliente.ibd`
```
cat /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
?I�[r��Ӎ~�rcA�gs%�Yds]��}:bި��N=����$�|#3��5�ȣ�C�pHjֻ�?G�y��q�1\���\�@��
��Q�{��%	���<��lvu���K�_��4�qz��,�1;�c��1�#�A�Ck4�~9�lZ3d=������g�N9�����^�"?=�
8̆������������8ХE�����r�infimum                                                        ����pc��
                              supremum
                                      ��
	D��11111111111marcelo barbosapc����8Хroot@31d82768e370:/#
```

Agora via utilitario `hexdump`:
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
0000fff0  00 00 00 00 00 70 00 63  b8 a5 0d 03 01 38 cc 86  |.....p.c.....8..|
00010000  98 98 a8 89 00 00 00 04  ff ff ff ff ff ff ff ff  |................|
00010010  00 00 00 00 01 38 d0 a5  45 bf 00 00 00 00 00 00  |.....8..E.......|
00010020  00 00 00 00 00 03 00 02  00 ab 80 03 00 00 00 00  |................|
00010030  00 80 00 05 00 00 00 01  00 00 00 00 00 00 00 00  |................|
00010040  00 00 00 00 00 00 00 00  00 9a 00 00 00 03 00 00  |................|
00010050  00 02 02 72 00 00 00 03  00 00 00 02 01 b2 01 00  |...r............|
00010060  02 00 1d 69 6e 66 69 6d  75 6d 00 02 00 0b 00 00  |...infimum......|
00010070  73 75 70 72 65 6d 75 6d  0f 0b 00 00 00 10 ff f0  |supremum........|
00010080  80 00 00 0a 00 00 00 00  09 44 82 00 00 00 8b 01  |.........D......|
00010090  10 31 31 31 31 31 31 31  31 31 31 31 6d 61 72 63  |.11111111111marc|
000100a0  65 6c 6f 20 62 61 72 62  6f 73 61 00 00 00 00 00  |elo barbosa.....|
000100b0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
```

Agora via utilitário `grep`:
```
grep --text barbosa /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
D��11111111111marcelo barbosapc����8Х
```


### 3. 2o. Insert
```
mysql -u root -e \
"INSERT INTO ecommerce.cliente(id, cpf, nome)
VALUES (11, '22222222222', 'Juscelino Kubitschek');"
```

Verificando o arquivo de dados:

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
              ��m�&��P�;Z��#^��xZ�#Z\��42���h���yqdX�}��>��I��ߓBV��1�0��Ĉ��~�;���ha�#?���x��yq���ϥ�7�5�/�_���#�|���?{+��G�����ܡ�-T�i�����iY_6�c"hy'������x����"M�Q����C<*��]$��a+jwj��#M�N�E�6�4PufLl�Gݬq�q���h}�c@&J�����������ir�fK
                                                                                                           ��(
?I�[r��Ӎ~�rcA�gs%�Yds]��}:bި��N=����$�|#3��5�ȣ�C�pHjֻ�?G�y��q�1\���\�@��
��Q�{��%	���<��lvu���K�_��4�qz��,�1;�c��1�#�A�Ck4�~9�lZ3d=������g�N9�����^�"?=�
8̆��                                                                                   ����pc��
   ���������8ҾE����r�infimum
                            supremum
                                    3�
	D��11111111111marcelo barbosa
                                     ���
                                        	E��22222222222Juscelino Kubitschekpc��
                                                                                      �8Ҿroot@31d82768e370:/#
```

##### `grep`
```
grep --text Juscelino /var/lib/mysql/ecommerce/cliente.ibd

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

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

##### `hexdump`
```
```

Output:
```
```

##### `grep`
```
```

Output:
```
```

### 5. Delete
```
mysql -u root -e \
"DELETE FROM ecommerce.cliente WHERE id = 11;"
```

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

##### `hexdump`
```
```

Output:
```
```

##### `grep`
```
```

Output:
```
```


> Perceba o espaço vazio entre o registro `marcelo` e `MARIVALDA`.

### 6. Update
```
docker exec -it mysql8 \
    mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARI K.' WHERE id = 1001"

```

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

##### `hexdump`
```
```

Output:
```
```

##### `grep`
```
```

Output:
```
```


> Perceba que o update praticamente não alterou o layout do arquivo.

### 2o. update
```
docker exec -it mysql8 \
    mysql -u root -e \
    "UPDATE ecommerce.cliente SET nome='MARIVALDA DE ALCÂNTARA FRANCISCO ANTÔNIO JOÃO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÉ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÇA E BOURBON KANAMARY' WHERE id = 1001;"
```

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```

```

##### `hexdump`
```
```

Output:
```
```

##### `grep`
```
```

Output:
```
```


> Perceba agora que, em razão do tamanho do nome, o banco de dados realocou o registro para um novo bloco (ou, possivelmente, outra posição no mesmo bloco)


## Parabéns!

Você concluiu com sucesso o laboratório de armazenamento em linha com MySQL! 🎉

Espero que este exercício tenha proporcionado uma compreensão prática sobre o funcionamento do modelo de armazenamento baseado em linha e como o MySQL gerencia os dados. Continue explorando e aprendendo mais sobre bancos de dados e suas diversas funcionalidades.

Bom trabalho e continue se dedicando aos estudos!

## Flush

Caso necessário, é possível forçar o flush dos dados da memória para o disco de forma a verificar o arquivo de dados.
```
docker exec -it mysql8 \
    mysql -u root -e \
    "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"
```

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

