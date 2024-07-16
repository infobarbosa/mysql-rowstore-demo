docker exec -it mysql8 mysql -u root -e "CREATE DATABASE ecommerce;"

docker exec -it mysql8 mysql -u root -e "
    CREATE TABLE ecommerce.cliente(
        id int PRIMARY KEY,
        cpf text,
        nome text
    );"

docker exec -it mysql8 mysql -u root -e "DESCRIBE ecommerce.cliente;"

docker exec -it mysql8 mysql -u root -Bse \
"INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1001, '98753936060', 'MARIVALDA KANAMARY');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1002, '12455426050', 'JUCILENE MOREIRA CRUZ');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1003, '32487300051', 'GRACIMAR BRASIL GUERRA');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1004, '59813133074', 'ALDENORA VIANA MOREIRA');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1005, '79739952003', 'VERA LUCIA RODRIGUES SENA');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1006, '66142806000', 'IVONE GLAUCIA VIANA DUTRA');
INSERT INTO ecommerce.cliente (id, cpf, nome) VALUES (1007, '19052330000', 'LUCILIA ROSA LIMA PEREIRA');"

docker exec -it mysql8 mysql -u root -e "SELECT * FROM ecommerce.cliente;"

sudo cat server/mysql/data/ecommerce/cliente.ibd

docker exec -it mysql8 mysql -u root -e "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"

sudo cat server/mysql/data/ecommerce/cliente.ibd

docker exec -it mysql8 mysql -u root -e "UPDATE ecommerce.cliente SET nome = 'MARI K.' WHERE id = 1001;"

sudo cat server/mysql/data/ecommerce/cliente.ibd

docker exec -it mysql8 mysql -u root -e "FLUSH LOCAL TABLES ecommerce.cliente FOR EXPORT;"

sudo cat server/mysql/data/ecommerce/cliente.ibd
