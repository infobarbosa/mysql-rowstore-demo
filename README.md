# MySQL - Rowstore Demo
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

Checando:
```
mysql -u root -e \
"SELECT * FROM ecommerce.cliente;"
```

Output:
```
"SELECT * FROM ecommerce.cliente;"
+----+-------------+----------------------+
| id | cpf         | nome                 |
+----+-------------+----------------------+
| 10 | 11111111111 | marcelo barbosa      |
| 11 | 22222222222 | Juscelino Kubitschek |
+----+-------------+----------------------+
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

##### `hexdump`
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
0000fff0  00 00 00 00 00 70 00 63  5b 84 e1 ae 01 38 36 f5  |.....p.c[....86.|
00010000  c6 27 2d 18 00 00 00 04  ff ff ff ff ff ff ff ff  |.'-.............|
00010010  00 00 00 00 01 38 3c 7a  45 bf 00 00 00 00 00 00  |.....8<zE.......|
00010020  00 00 00 00 00 02 00 02  00 e3 80 04 00 00 00 00  |................|
00010030  00 b3 00 02 00 01 00 02  00 00 00 00 00 00 00 00  |................|
00010040  00 00 00 00 00 00 00 00  00 99 00 00 00 02 00 00  |................|
00010050  00 02 02 72 00 00 00 02  00 00 00 02 01 b2 01 00  |...r............|
00010060  02 00 1d 69 6e 66 69 6d  75 6d 00 03 00 0b 00 00  |...infimum......|
00010070  73 75 70 72 65 6d 75 6d  0f 0b 00 00 00 10 00 33  |supremum.......3|
00010080  80 00 00 0a 00 00 00 00  09 19 81 00 00 01 07 01  |................|
00010090  10 31 31 31 31 31 31 31  31 31 31 31 6d 61 72 63  |.11111111111marc|
000100a0  65 6c 6f 20 62 61 72 62  6f 73 61 14 0b 00 00 00  |elo barbosa.....|
000100b0  18 ff bd 80 00 00 0b 00  00 00 00 09 1a 82 00 00  |................|
000100c0  01 0d 01 10 32 32 32 32  32 32 32 32 32 32 32 4a  |....22222222222J|
000100d0  75 73 63 65 6c 69 6e 6f  20 4b 75 62 69 74 73 63  |uscelino Kubitsc|
000100e0  68 65 6b 00 00 00 00 00  00 00 00 00 00 00 00 00  |hek.............|
000100f0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
```

##### `grep`
```
grep --text Juscelino /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
	�11111111111marcelo barbosa
                                   ���
22222222222Juscelino Kubitschekpc�'-8<z
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
                                                            %�p7���0�_�֐mmp��U�R	��'�$�K��L��(�l
t��e�d1��qP/Ɓ[?������ॺ����zH�z0����ק�좈�"~�"nޑ��_�����=���T�E>��E�D�Wߠ�$��/�|��|�[������B��@|C(��^�?pR��e}�T����[!�ͻ�p_�>�{(�J*��kEK8�t��Z���d/0lE��NM�q�9ܓ�}h��%@�vk�Q7�@�t�c Z�1 %�����������Q79��r�oo��$�-�(��t��;�XR�������iሞ�N9o���Y�̺��(�|-3��5��#в�tHj�;�?e�y��i�!\���]�@��
}У�w�#�K��zJ��tr�N�!�>���,�1;�c��1	{��1�#�Q�Sk0��8�l�e�z�\;��ώ!�rB
Y;[9=wD~|�ݒpc[��86��ߔW��������8_�E�}�
                                      H �r�infimum
                                                  supremum
                                                          3�
	�11111111111marcelo barbosa
                                   8�
22222222222Juscelino Kubitschek      	�
                                6��	�98753936060MARIVALDA KANAMARY
                                                                      (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                  0:��	%�
                                                                                                                          32487300051GRACIMAR BRASIL GUERRA
                                                                                                                                                           8:��	&�59813133074ALDENORA VIANA MOREIRA
                @=��	'�
                          79739952003VERA LUCIA RODRIGUES SENA
                                                              H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
```

##### `hexdump`
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
0000fff0  00 00 00 00 00 70 00 63  5b 84 e1 ae 01 38 36 f5  |.....p.c[....86.|
00010000  ec df 94 57 00 00 00 04  ff ff ff ff ff ff ff ff  |...W............|
00010010  00 00 00 00 01 38 5f 8a  45 bf 00 00 00 00 00 00  |.....8_.E.......|
00010020  00 00 00 00 00 02 00 03  02 7d 80 0b 00 00 00 00  |.........}......|
00010030  02 48 00 02 00 08 00 09  00 00 00 00 00 00 00 00  |.H..............|
00010040  00 00 00 00 00 00 00 00  00 99 00 00 00 02 00 00  |................|
00010050  00 02 02 72 00 00 00 02  00 00 00 02 01 b2 01 00  |...r............|
00010060  02 00 1d 69 6e 66 69 6d  75 6d 00 06 00 0b 00 00  |...infimum......|
00010070  73 75 70 72 65 6d 75 6d  0f 0b 00 00 00 10 00 33  |supremum.......3|
00010080  80 00 00 0a 00 00 00 00  09 19 81 00 00 01 07 01  |................|
00010090  10 31 31 31 31 31 31 31  31 31 31 31 6d 61 72 63  |.11111111111marc|
000100a0  65 6c 6f 20 62 61 72 62  6f 73 61 14 0b 00 00 00  |elo barbosa.....|
000100b0  18 00 38 80 00 00 0b 00  00 00 00 09 1a 82 00 00  |..8.............|
000100c0  01 0d 01 10 32 32 32 32  32 32 32 32 32 32 32 4a  |....22222222222J|
000100d0  75 73 63 65 6c 69 6e 6f  20 4b 75 62 69 74 73 63  |uscelino Kubitsc|
000100e0  68 65 6b 12 0b 00 00 00  20 00 36 80 00 03 e9 00  |hek..... .6.....|
000100f0  00 00 00 09 1f 81 00 00  01 1b 01 10 39 38 37 35  |............9875|
00010100  33 39 33 36 30 36 30 4d  41 52 49 56 41 4c 44 41  |3936060MARIVALDA|
00010110  20 4b 41 4e 41 4d 41 52  59 15 0b 00 04 00 28 00  | KANAMARY.....(.|
00010120  39 80 00 03 ea 00 00 00  00 09 20 82 00 00 01 0f  |9......... .....|
00010130  01 10 31 32 34 35 35 34  32 36 30 35 30 4a 55 43  |..12455426050JUC|
00010140  49 4c 45 4e 45 20 4d 4f  52 45 49 52 41 20 43 52  |ILENE MOREIRA CR|
00010150  55 5a 16 0b 00 00 00 30  00 3a 80 00 03 eb 00 00  |UZ.....0.:......|
00010160  00 00 09 25 81 00 00 01  0b 01 10 33 32 34 38 37  |...%.......32487|
00010170  33 30 30 30 35 31 47 52  41 43 49 4d 41 52 20 42  |300051GRACIMAR B|
00010180  52 41 53 49 4c 20 47 55  45 52 52 41 16 0b 00 00  |RASIL GUERRA....|
00010190  00 38 00 3a 80 00 03 ec  00 00 00 00 09 26 82 00  |.8.:.........&..|
000101a0  00 01 11 01 10 35 39 38  31 33 31 33 33 30 37 34  |.....59813133074|
000101b0  41 4c 44 45 4e 4f 52 41  20 56 49 41 4e 41 20 4d  |ALDENORA VIANA M|
000101c0  4f 52 45 49 52 41 19 0b  00 00 00 40 00 3d 80 00  |OREIRA.....@.=..|
000101d0  03 ed 00 00 00 00 09 27  81 00 00 01 0c 01 10 37  |.......'.......7|
000101e0  39 37 33 39 39 35 32 30  30 33 56 45 52 41 20 4c  |9739952003VERA L|
000101f0  55 43 49 41 20 52 4f 44  52 49 47 55 45 53 20 53  |UCIA RODRIGUES S|
00010200  45 4e 41 19 0b 00 00 00  48 00 3d 80 00 03 ee 00  |ENA.....H.=.....|
00010210  00 00 00 09 28 82 00 00  01 12 01 10 36 36 31 34  |....(.......6614|
00010220  32 38 30 36 30 30 30 49  56 4f 4e 45 20 47 4c 41  |2806000IVONE GLA|
00010230  55 43 49 41 20 56 49 41  4e 41 20 44 55 54 52 41  |UCIA VIANA DUTRA|
00010240  19 0b 00 00 00 50 fe 28  80 00 03 ef 00 00 00 00  |.....P.(........|
00010250  09 29 81 00 00 01 0d 01  10 31 39 30 35 32 33 33  |.).......1905233|
00010260  30 30 30 30 4c 55 43 49  4c 49 41 20 52 4f 53 41  |0000LUCILIA ROSA|
00010270  20 4c 49 4d 41 20 50 45  52 45 49 52 41 00 00 00  | LIMA PEREIRA...|
00010280  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
```

##### `grep`
```
grep --text MARIVALDA /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
root@428066f4c64c:/# grep --text MARIVALDA /var/lib/mysql/ecommerce/cliente.ibd
	�11111111111marcelo barbosa
                                   8�
22222222222Juscelino Kubitschek      	�
                                6��	�98753936060MARIVALDA KANAMARY
                                                                      (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                  0:��	%�
                                                                                                                          32487300051GRACIMAR BRASIL GUERRA
                                                                                                                                                           8:��	&�59813133074ALDENORA VIANA MOREIRA
                @=��	'�
                          79739952003VERA LUCIA RODRIGUES SENA
                                                              H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRAp!c�ߔW8_�                                                                 P�(��	)�
```

### 5. Delete

Removendo o registro 11 (Juscelino Kubitschek):
```
mysql -u root -e \
"DELETE FROM ecommerce.cliente WHERE id = 11;"
```

Checando:
```
mysql -u root -e "SELECT * FROM ecommerce.cliente;"
```

Output:
```
root@83b236affb4d:/# mysql -u root -e "SELECT * FROM ecommerce.cliente;"
+------+-------------+---------------------------+
| id   | cpf         | nome                      |
+------+-------------+---------------------------+
|   10 | 11111111111 | marcelo barbosa           |
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
t��e�d1��qP/Ɓ[?������ॺ����zH�z0����ק�좈�"~�"nޑ��_�����=���T�E>��E�D�Wߠ�$��/�|��|�[������B��@|C(��^�?pR��e}�T����[!�ͻ�p_�>�{(�J*��kEK8�t��Z���d/0lE��NM�q�9ܓ�}h��%@�vk�Q7�@�t�c Z�1 %�����������Q79��r�oo��$�-�(��t��;�XR�������iሞ�N9o���Y�̺��(�|-3��5��#в�tHj�;�?e�y��i�!\���]�@��
}У�w�#�K��zJ��tr�N�!�>���,�1;�c��1	{��1�#�Q�Sk0��8�l�e�z�\;��ώ!�rB
Y;[9=wD~|�ݒpc[��86�:�ɛ��������8p�E�}�
                                      �r�infimum
                                                supremum
                                                        k�
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           6��	�98753936060MARIVALDA KANAMARY
                                                                                                              (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                           @=��	'�
                                                                  79739952003VERA LUCIA RODRIGUES SENA
                                                                                                      H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRApZc:�ɛ8p�root@428066f4c64c:/#
```

##### `hexdump`
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
*
0000fff0  00 00 00 00 00 70 00 63  5b 84 e1 ae 01 38 36 f5  |.....p.c[....86.|
00010000  3a 93 c9 9b 00 00 00 04  ff ff ff ff ff ff ff ff  |:...............|
00010010  00 00 00 00 01 38 70 c5  45 bf 00 00 00 00 00 00  |.....8p.E.......|
00010020  00 00 00 00 00 02 00 03  02 7d 80 0b 00 b3 00 38  |.........}.....8|
00010030  00 00 00 02 00 08 00 08  00 00 00 00 00 00 00 00  |................|
00010040  00 00 00 00 00 00 00 00  00 99 00 00 00 02 00 00  |................|
00010050  00 02 02 72 00 00 00 02  00 00 00 02 01 b2 01 00  |...r............|
00010060  02 00 1d 69 6e 66 69 6d  75 6d 00 05 00 0b 00 00  |...infimum......|
00010070  73 75 70 72 65 6d 75 6d  0f 0b 00 00 00 10 00 6b  |supremum.......k|
00010080  80 00 00 0a 00 00 00 00  09 19 81 00 00 01 07 01  |................|
00010090  10 31 31 31 31 31 31 31  31 31 31 31 6d 61 72 63  |.11111111111marc|
000100a0  65 6c 6f 20 62 61 72 62  6f 73 61 14 0b 00 20 00  |elo barbosa... .|
000100b0  18 00 00 80 00 00 0b 00  00 00 00 09 2e 02 00 00  |................|
000100c0  01 20 01 51 32 32 32 32  32 32 32 32 32 32 32 4a  |. .Q22222222222J|
000100d0  75 73 63 65 6c 69 6e 6f  20 4b 75 62 69 74 73 63  |uscelino Kubitsc|
000100e0  68 65 6b 12 0b 00 00 00  20 00 36 80 00 03 e9 00  |hek..... .6.....|
000100f0  00 00 00 09 1f 81 00 00  01 1b 01 10 39 38 37 35  |............9875|
00010100  33 39 33 36 30 36 30 4d  41 52 49 56 41 4c 44 41  |3936060MARIVALDA|
00010110  20 4b 41 4e 41 4d 41 52  59 15 0b 00 00 00 28 00  | KANAMARY.....(.|
00010120  39 80 00 03 ea 00 00 00  00 09 20 82 00 00 01 0f  |9......... .....|
00010130  01 10 31 32 34 35 35 34  32 36 30 35 30 4a 55 43  |..12455426050JUC|
00010140  49 4c 45 4e 45 20 4d 4f  52 45 49 52 41 20 43 52  |ILENE MOREIRA CR|
00010150  55 5a 16 0b 00 04 00 30  00 3a 80 00 03 eb 00 00  |UZ.....0.:......|
00010160  00 00 09 25 81 00 00 01  0b 01 10 33 32 34 38 37  |...%.......32487|
00010170  33 30 30 30 35 31 47 52  41 43 49 4d 41 52 20 42  |300051GRACIMAR B|
00010180  52 41 53 49 4c 20 47 55  45 52 52 41 16 0b 00 00  |RASIL GUERRA....|
00010190  00 38 00 3a 80 00 03 ec  00 00 00 00 09 26 82 00  |.8.:.........&..|
000101a0  00 01 11 01 10 35 39 38  31 33 31 33 33 30 37 34  |.....59813133074|
000101b0  41 4c 44 45 4e 4f 52 41  20 56 49 41 4e 41 20 4d  |ALDENORA VIANA M|
000101c0  4f 52 45 49 52 41 19 0b  00 00 00 40 00 3d 80 00  |OREIRA.....@.=..|
000101d0  03 ed 00 00 00 00 09 27  81 00 00 01 0c 01 10 37  |.......'.......7|
000101e0  39 37 33 39 39 35 32 30  30 33 56 45 52 41 20 4c  |9739952003VERA L|
000101f0  55 43 49 41 20 52 4f 44  52 49 47 55 45 53 20 53  |UCIA RODRIGUES S|
00010200  45 4e 41 19 0b 00 00 00  48 00 3d 80 00 03 ee 00  |ENA.....H.=.....|
00010210  00 00 00 09 28 82 00 00  01 12 01 10 36 36 31 34  |....(.......6614|
00010220  32 38 30 36 30 30 30 49  56 4f 4e 45 20 47 4c 41  |2806000IVONE GLA|
00010230  55 43 49 41 20 56 49 41  4e 41 20 44 55 54 52 41  |UCIA VIANA DUTRA|
00010240  19 0b 00 00 00 50 fe 28  80 00 03 ef 00 00 00 00  |.....P.(........|
00010250  09 29 81 00 00 01 0d 01  10 31 39 30 35 32 33 33  |.).......1905233|
00010260  30 30 30 30 4c 55 43 49  4c 49 41 20 52 4f 53 41  |0000LUCILIA ROSA|
00010270  20 4c 49 4d 41 20 50 45  52 45 49 52 41 00 00 00  | LIMA PEREIRA...|
00010280  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
00013ff0  00 00 00 70 01 5a 00 63  3a 93 c9 9b 01 38 70 c5  |...p.Z.c:....8p.|
00014000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
```

##### `grep`
```
grep --text Juscelino /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
root@428066f4c64c:/# grep --text Juscelino /var/lib/mysql/ecommerce/cliente.ibd
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           6��	�98753936060MARIVALDA KANAMARY
                                                                                                              (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                           @=��	'�
                                                                  79739952003VERA LUCIA RODRIGUES SENA
                                                                                                      H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRApZc:�ɛ8p�                                                                                                         P�(��	)�
root@428066f4c64c:/#
```

### 6. Update
```
mysql -u root -e \
"UPDATE ecommerce.cliente SET nome='MARI K.' WHERE id = 1001"

```

Checando:
```
mysql -e \
"SELECT * FROM ecommerce.cliente WHERE id = 1001"

```

Output:
```
"SELECT * FROM ecommerce.cliente WHERE id = 1001"
+------+-------------+---------+
| id   | cpf         | nome    |
+------+-------------+---------+
| 1001 | 98753936060 | MARI K. |
+------+-------------+---------+
```


##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
t��e�d1��qP/Ɓ[?������ॺ����zH�z0����ק�좈�"~�"nޑ��_�����=���T�E>��E�D�Wߠ�$��/�|��|�[������B��@|C(��^�?pR��e}�T����[!�ͻ�p_�>�{(�J*��kEK8�t��Z���d/0lE��NM�q�9ܓ�}h��%@�vk�Q7�@�t�c Z�1 %�����������Q79��r�oo��$�-�(��t��;�XR�������iሞ�N9o���Y�̺��(�|-3��5��#в�tHj�;�?e�y��i�!\���]�@��
}У�w�#�K��zJ��tr�N�!�>���,�1;�c��1	{��1�#�Q�Sk0��8�l�e�z�\;��ώ!�rB
Y;[9=wD~|�ݒpc[��86��6R��������8q�E�}�
                                      �C�r�infimum
                                                  supremum
                                                          k�
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           6��	0g98753936060MARI K.DA KANAMARY
                                                                                                               (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                           @=��	'�
                                                                  79739952003VERA LUCIA RODRIGUES SENA
                                                                                                      H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRAp�c�6R8q�root@428066f4c64c:/#
```

##### `hexdump`
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd

```

Output:
```
000100f0  00 00 00 09 30 01 00 00  01 10 06 67 39 38 37 35  |....0......g9875|
00010100  33 39 33 36 30 36 30 4d  41 52 49 20 4b 2e 44 41  |3936060MARI K.DA|
00010110  20 4b 41 4e 41 4d 41 52  59 15 0b 00 00 00 28 00  | KANAMARY.....(.|
00010120  39 80 00 03 ea 00 00 00  00 09 20 82 00 00 01 0f  |9......... .....|
```

##### `grep`
```
grep --text MARI /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
root@428066f4c64c:/# grep --text MARI /var/lib/mysql/ecommerce/cliente.ibd
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           6��	0g98753936060MARI K.DA KANAMARY
                                                                                                               (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                           @=��	'�
                                                                  79739952003VERA LUCIA RODRIGUES SENA
                                                                                                      H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRAp�c�6R8q�
```


> Perceba que o update praticamente não alterou o layout do arquivo.

### 2o. update
```
mysql -u root -e \
"UPDATE ecommerce.cliente SET nome='MARIVALDA DE ALCÂNTARA FRANCISCO ANTÔNIO JOÃO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÉ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÇA E BOURBON KANAMARY' WHERE id = 1001;"
```

Checando:
```
mysql -e "SELECT * FROM ecommerce.cliente WHERE id = 1001"

```

Output:
```
root@428066f4c64c:/# mysql -e "SELECT * FROM ecommerce.cliente WHERE id = 1001"
+------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| id   | cpf         | nome                                                                                                                                                                 |
+------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| 1001 | 98753936060 | MARIVALDA DE ALCÂNTARA FRANCISCO ANTÔNIO JOÃO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÉ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÇA E BOURBON KANAMARY |
+------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

##### `cat`
```
cat /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
ǌ�j�#�H��7�Zi$��=�C�_��u��<�l��͉��f|���ǚڦt��-�k��5�a�Z�낦^����ņ�C���T�XAjL��^'qk��<D\6m�{hX}'>�f;H�"����
                                                            %�p7���0�_�֐mmp��U�R	��'�$�K��L��(�l
t��e�d1��qP/Ɓ[?������ॺ����zH�z0����ק�좈�"~�"nޑ��_�����=���T�E>��E�D�Wߠ�$��/�|��|�[������B��@|C(��^�?pR��e}�T����[!�ͻ�p_�>�{(�J*��kEK8�t��Z���d/0lE��NM�q�9ܓ�}h��%@�vk�Q7�@�t�c Z�1 %�����������Q79��r�oo��$�-�(��t��;�XR�������iሞ�N9o���Y�̺��(�|-3��5��#в�tHj�;�?e�y��i�!\���]�@��
}У�w�#�K��zJ��tr�N�!�>���,�1;�c��1	{��1�#�Q�Sk0��8�l�e�z�\;��ώ!�rB
Y;[9=wD~|�ݒpc[��86�	���������8wE�T�
                                       �n�r�infimum
                                                   supremum
                                                           �
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           �Ȁ�	0g98753936060MARI K.DA KANAMARY
                                                                                                               (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                                                                                                                                                                                                   8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                                                                                                                                                                                                           @=��	'�
                                                                                                                                                                                                                                                  79739952003VERA LUCIA RODRIGUES SENA
                           H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRA��                                P�(��	)�
                                      X����	2!Q98753936060MARIVALDA DE ALCÃ‚NTARA FRANCISCO ANTÃ”NIO JOÃƒO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÃ‰ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÃ‡A E BOURBON KANAMARYp�c�	�8wroot@428066f4c64c:/#
```

##### `hexdump`
```
hd -C /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
0000fff0  00 00 00 00 00 70 00 63  5b 84 e1 ae 01 38 36 f5  |.....p.c[....86.|
00010000  b7 09 04 84 00 00 00 04  ff ff ff ff ff ff ff ff  |................|
00010010  00 00 00 00 01 38 77 1d  45 bf 00 00 00 00 00 00  |.....8w.E.......|
00010020  00 00 00 00 00 02 00 03  03 54 80 0c 00 eb 00 6e  |.........T.....n|
00010030  02 86 00 05 00 00 00 08  00 00 00 00 00 00 00 00  |................|
00010040  00 00 00 00 00 00 00 00  00 99 00 00 00 02 00 00  |................|
00010050  00 02 02 72 00 00 00 02  00 00 00 02 01 b2 01 00  |...r............|
00010060  02 00 1d 69 6e 66 69 6d  75 6d 00 04 00 0b 00 00  |...infimum......|
00010070  73 75 70 72 65 6d 75 6d  0f 0b 00 00 00 10 02 06  |supremum........|
00010080  80 00 00 0a 00 00 00 00  09 19 81 00 00 01 07 01  |................|
00010090  10 31 31 31 31 31 31 31  31 31 31 31 6d 61 72 63  |.11111111111marc|
000100a0  65 6c 6f 20 62 61 72 62  6f 73 61 14 0b 00 20 00  |elo barbosa... .|
000100b0  18 00 00 80 00 00 0b 00  00 00 00 09 2e 02 00 00  |................|
000100c0  01 20 01 51 32 32 32 32  32 32 32 32 32 32 32 4a  |. .Q22222222222J|
000100d0  75 73 63 65 6c 69 6e 6f  20 4b 75 62 69 74 73 63  |uscelino Kubitsc|
000100e0  68 65 6b 07 0b 00 00 00  20 ff c8 80 00 03 e9 00  |hek..... .......|
000100f0  00 00 00 09 30 01 00 00  01 10 06 67 39 38 37 35  |....0......g9875|
00010100  33 39 33 36 30 36 30 4d  41 52 49 20 4b 2e 44 41  |3936060MARI K.DA|
00010110  20 4b 41 4e 41 4d 41 52  59 15 0b 00 00 00 28 00  | KANAMARY.....(.|
00010120  39 80 00 03 ea 00 00 00  00 09 20 82 00 00 01 0f  |9......... .....|
00010130  01 10 31 32 34 35 35 34  32 36 30 35 30 4a 55 43  |..12455426050JUC|
00010140  49 4c 45 4e 45 20 4d 4f  52 45 49 52 41 20 43 52  |ILENE MOREIRA CR|
00010150  55 5a 16 0b 00 00 00 30  00 3a 80 00 03 eb 00 00  |UZ.....0.:......|
00010160  00 00 09 25 81 00 00 01  0b 01 10 33 32 34 38 37  |...%.......32487|
00010170  33 30 30 30 35 31 47 52  41 43 49 4d 41 52 20 42  |300051GRACIMAR B|
00010180  52 41 53 49 4c 20 47 55  45 52 52 41 16 0b 00 05  |RASIL GUERRA....|
00010190  00 38 00 3a 80 00 03 ec  00 00 00 00 09 26 82 00  |.8.:.........&..|
000101a0  00 01 11 01 10 35 39 38  31 33 31 33 33 30 37 34  |.....59813133074|
000101b0  41 4c 44 45 4e 4f 52 41  20 56 49 41 4e 41 20 4d  |ALDENORA VIANA M|
000101c0  4f 52 45 49 52 41 19 0b  00 00 00 40 00 3d 80 00  |OREIRA.....@.=..|
000101d0  03 ed 00 00 00 00 09 27  81 00 00 01 0c 01 10 37  |.......'.......7|
000101e0  39 37 33 39 39 35 32 30  30 33 56 45 52 41 20 4c  |9739952003VERA L|
000101f0  55 43 49 41 20 52 4f 44  52 49 47 55 45 53 20 53  |UCIA RODRIGUES S|
00010200  45 4e 41 19 0b 00 00 00  48 00 3d 80 00 03 ee 00  |ENA.....H.=.....|
00010210  00 00 00 09 28 82 00 00  01 12 01 10 36 36 31 34  |....(.......6614|
00010220  32 38 30 36 30 30 30 49  56 4f 4e 45 20 47 4c 41  |2806000IVONE GLA|
00010230  55 43 49 41 20 56 49 41  4e 41 20 44 55 54 52 41  |UCIA VIANA DUTRA|
00010240  19 0b 00 00 00 50 fe 28  80 00 03 ef 00 00 00 00  |.....P.(........|
00010250  09 29 81 00 00 01 0d 01  10 31 39 30 35 32 33 33  |.).......1905233|
00010260  30 30 30 30 4c 55 43 49  4c 49 41 20 52 4f 53 41  |0000LUCILIA ROSA|
00010270  20 4c 49 4d 41 20 50 45  52 45 49 52 41 b2 80 0b  | LIMA PEREIRA...|
00010280  00 00 00 58 fe 9b 80 00  03 e9 00 00 00 00 09 32  |...X...........2|
00010290  02 00 00 01 21 01 51 39  38 37 35 33 39 33 36 30  |....!.Q987539360|
000102a0  36 30 4d 41 52 49 56 41  4c 44 41 20 44 45 20 41  |60MARIVALDA DE A|
000102b0  4c 43 c3 83 e2 80 9a 4e  54 41 52 41 20 46 52 41  |LC.....NTARA FRA|
000102c0  4e 43 49 53 43 4f 20 41  4e 54 c3 83 e2 80 9d 4e  |NCISCO ANT.....N|
000102d0  49 4f 20 4a 4f c3 83 c6  92 4f 20 43 41 52 4c 4f  |IO JO....O CARLO|
000102e0  53 20 58 41 56 49 45 52  20 44 45 20 50 41 55 4c  |S XAVIER DE PAUL|
000102f0  41 20 4d 49 47 55 45 4c  20 52 41 46 41 45 4c 20  |A MIGUEL RAFAEL |
00010300  4a 4f 41 51 55 49 4d 20  4a 4f 53 c3 83 e2 80 b0  |JOAQUIM JOS.....|
00010310  20 47 4f 4e 5a 41 47 41  20 50 41 53 43 4f 41 4c  | GONZAGA PASCOAL|
00010320  20 43 49 50 52 49 41 4e  4f 20 53 45 52 41 46 49  | CIPRIANO SERAFI|
00010330  4d 20 44 45 20 42 52 41  47 41 4e c3 83 e2 80 a1  |M DE BRAGAN.....|
00010340  41 20 45 20 42 4f 55 52  42 4f 4e 20 4b 41 4e 41  |A E BOURBON KANA|
00010350  4d 41 52 59 00 00 00 00  00 00 00 00 00 00 00 00  |MARY............|
00010360  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
```

##### `grep`
```
grep --text MARI /var/lib/mysql/ecommerce/cliente.ibd
```

Output:
```
root@428066f4c64c:/# grep --text MARI /var/lib/mysql/ecommerce/cliente.ibd
	�11111111111marcelo barbosa
                                    �
                                     	. Q22222222222Juscelino Kubitschek
                                                                           �Ȁ�	0g98753936060MARI K.DA KANAMARY
                                                                                                               (9��	 �12455426050JUCILENE MOREIRA CRUZ
                                                                                                                                                          0:��	%�
                                                                                                                                                                  32487300051GRACIMAR BRASIL GUERRA
                                                                                                                                                                                                   8:��	&�59813133074ALDENORA VIANA MOREIRA
                                                                                                                                                                                                                                           @=��	'�
                                                                                                                                                                                                                                                  79739952003VERA LUCIA RODRIGUES SENA
                           H=��	(�66142806000IVONE GLAUCIA VIANA DUTRA
19052330000LUCILIA ROSA LIMA PEREIRA��                                P�(��	)�
                                      X����	2!Q98753936060MARIVALDA DE ALCÃ‚NTARA FRANCISCO ANTÃ”NIO JOÃƒO CARLOS XAVIER DE PAULA MIGUEL RAFAEL JOAQUIM JOSÃ‰ GONZAGA PASCOAL CIPRIANO SERAFIM DE BRAGANÃ‡A E BOURBON KANAMARYp�c�	�8w
root@428066f4c64c:/#
```

> Perceba agora que, em razão do tamanho do nome, o banco de dados realocou o registro para um novo bloco (ou, possivelmente, outra posição no mesmo bloco)


## Parabéns!

Você concluiu com sucesso o laboratório de armazenamento em linha com MySQL! 🎉

Espero que este exercício tenha proporcionado uma compreensão prática sobre o funcionamento do modelo de armazenamento baseado em linha e como o MySQL gerencia os dados. 

## Flush

Caso necessário, é possível forçar o flush dos dados da memória para o disco de forma a verificar o arquivo de dados.
```
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

