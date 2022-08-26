CREATE TABLE users (
id SERIAL PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
created_at TIMESTAMP
);

CREATE TABLE profiles (
id SERIAL PRIMARY KEY,
id_user INT,
email VARCHAR(120) NOT NULL UNIQUE,
phone VARCHAR(15) UNIQUE,
created_at TIMESTAMP,
gender CHAR(1) check(gender in ('F','M')),
birthdate DATE); 

CREATE EXTENSION chkpass;

CREATE TABLE security (
id SERIAL PRIMARY KEY,
id_user INT,
password chkpass
);

CREATE TABLE pay_cards (
id SERIAL PRIMARY KEY,
user_id INT
);


/*
CREATE EXTENSION chkpass;

CREATE TABLE accounts (username varchar(100), password chkpass);
INSERT INTO accounts(username, "password") VALUES ('user1', 'pass1');
INSERT INTO accounts(username, "password") VALUES ('user2', 'pass2');

select * from accounts where password='pass2';
*/

CREATE TABLE products (
id SERIAL PRIMARY KEY,
is_active BOOL
);

CREATE TABLE products_prices (
id SERIAL PRIMARY KEY,
id_product INT,
price MONEY
);

CREATE TABLE orders (
id SERIAL PRIMARY KEY,
id_basket INT NOT NULL,
created_at TIMESTAMP,
);

CREATE TABLE basket (
id SERIAL PRIMARY KEY,
created_at TIMESTAMP,
is_ordered BOOL DEFAULT false
);

CREATE TABLE basket_users (
id SERIAL PRIMARY KEY,
id_user INT NOT NULL,
id_basket INT NOT NULL,
);

CREATE TABLE basket_products (
id SERIAL PRIMARY KEY,
id_basket INT NOT NULL,
id_product INT NOT NULL,
product_count INT DEFAULT 0
);

CREATE TABLE favorites (
id SERIAL PRIMARY KEY,

);


CREATE TABLE pickpoints (
id SERIAL PRIMARY KEY,
address VARCHAR(512)
);

CREATE TABLE prices_reduces (
id SERIAL PRIMARY KEY,
id_price INT,
percents DEC DEFAULT 0
);

CREATE TABLE prices_reduces_individual (
id SERIAL PRIMARY KEY,
id_price INT
percents DEC DEFAULT 0
);




