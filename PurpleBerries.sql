CREATE TABLE users (
id SERIAL PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
created_at TIMESTAMP
);

CREATE TABLE profiles (
id SERIAL PRIMARY KEY,
user_id INT,
email VARCHAR(120) NOT NULL UNIQUE,
phone VARCHAR(15) UNIQUE,
gender CHAR(1) check(gender in ('F','M')),
created_at TIMESTAMP,
birthdate DATE); 

/*CREATE EXTENSION chkpass;*/

CREATE TABLE security (
id SERIAL PRIMARY KEY,
user_id INT,
password VARCHAR(128)
);

CREATE TABLE pay_cards (
id SERIAL PRIMARY KEY,
user_id INT,
card_num VARCHAR(20),
created_at TIMESTAMP
);


/*
Пример использования расширения chkpass

CREATE EXTENSION chkpass;

CREATE TABLE accounts (username varchar(100), password chkpass);
INSERT INTO accounts(username, "password") VALUES ('user1', 'pass1');
INSERT INTO accounts(username, "password") VALUES ('user2', 'pass2');

select * from accounts where password='pass2';
*/

/*is_active показывает можно ли товар подавать. Например, по наличию на складе.*/
 
CREATE TABLE products (
id SERIAL PRIMARY KEY,
name VARCHAR(127),
description TEXT,
is_active BOOL,
created_at TIMESTAMP
);

CREATE TABLE products_prices (
id SERIAL PRIMARY KEY,
product_id INT,
price MONEY
);

CREATE TABLE products_photos (
id SERIAL PRIMARY KEY,
product_id INT,
photo_url VARCHAR(255),
created_at TIMESTAMP
);

CREATE TABLE baskets (
id SERIAL PRIMARY KEY,
is_ordered BOOL DEFAULT false,
created_at TIMESTAMP
);

CREATE TABLE baskets_users (
id SERIAL PRIMARY KEY,
user_id INT NOT NULL,
basket_id INT NOT NULL,
created_at TIMESTAMP
);

CREATE TABLE baskets_products (
id SERIAL PRIMARY KEY,
basket_id INT NOT NULL,
product_id INT NOT NULL,
product_count INT DEFAULT 0,
created_at TIMESTAMP
);

CREATE TABLE pickpoints (
id SERIAL PRIMARY KEY,
address VARCHAR(512),
created_at TIMESTAMP
);

CREATE TABLE orders (
id SERIAL PRIMARY KEY,
basket_id INT NOT NULL,
pickpoint_id INT,
created_at TIMESTAMP
);

CREATE TABLE products_prices_reduces (
id SERIAL PRIMARY KEY,
products_price_id INT NOT NULL UNIQUE,
percents DEC DEFAULT 0
);

CREATE TABLE products_prices_reduces_individual (
    user_id integer REFERENCES users,
	products_price_id INT REFERENCES products_prices,
    percents DEC DEFAULT 0,
    PRIMARY KEY (user_id, products_price_id)
);

/*Добавляем ключи*/

ALTER TABLE profiles 
  ADD CONSTRAINT profiles_user_id_fk 
  FOREIGN KEY (user_id) 
  REFERENCES users (id)
  ON DELETE CASCADE;

ALTER TABLE security 
  ADD CONSTRAINT security_user_id_fk 
  FOREIGN KEY (user_id) 
  REFERENCES users (id)
  ON DELETE CASCADE;
  
ALTER TABLE pay_cards 
  ADD CONSTRAINT pay_cards_user_id_fk 
  FOREIGN KEY (user_id) 
  REFERENCES users (id)
  ON DELETE CASCADE;
  
ALTER TABLE products_prices
  ADD CONSTRAINT products_prices_product_id_fk 
  FOREIGN KEY (product_id) 
  REFERENCES products (id)
  ON DELETE RESTRICT;
  
ALTER TABLE products_photos
  ADD CONSTRAINT products_photos_product_id_fk 
  FOREIGN KEY (product_id) 
  REFERENCES products (id)
  ON DELETE RESTRICT;
  
ALTER TABLE baskets_users
  ADD CONSTRAINT baskets_users_basket_id_fk 
  FOREIGN KEY (basket_id) 
  REFERENCES baskets (id)
  ON DELETE RESTRICT;

ALTER TABLE baskets_users
  ADD CONSTRAINT baskets_users_user_id_fk 
  FOREIGN KEY (user_id) 
  REFERENCES users (id)
  ON DELETE CASCADE;
  
ALTER TABLE baskets_products
  ADD CONSTRAINT baskets_products_basket_id_fk 
  FOREIGN KEY (basket_id) 
  REFERENCES baskets (id)
  ON DELETE RESTRICT;

ALTER TABLE baskets_products
  ADD CONSTRAINT baskets_products_product_id_fk 
  FOREIGN KEY (product_id) 
  REFERENCES products (id)
  ON DELETE RESTRICT;
  
ALTER TABLE orders
  ADD CONSTRAINT orders_basket_id_fk 
  FOREIGN KEY (basket_id) 
  REFERENCES baskets (id)
  ON DELETE RESTRICT;

ALTER TABLE orders
  ADD CONSTRAINT orders_pickpoint_id_fk 
  FOREIGN KEY (pickpoint_id) 
  REFERENCES pickpoints (id)
  ON DELETE RESTRICT;
  
ALTER TABLE products_prices_reduces
  ADD CONSTRAINT products_prices_reduces_products_price_id_fk 
  FOREIGN KEY (products_price_id) 
  REFERENCES products_prices (id)
  ON DELETE RESTRICT; 
  
 /*Триггер и функция на users*/
 
CREATE OR REPLACE FUNCTION add_create_at_data() 
RETURNS TRIGGER AS 
$$
BEGIN
      IF (NEW.created_at IS NULL) THEN
	  NEW.created_at := now();
	  END IF;
  RETURN NEW;
END
$$ 
LANGUAGE PLPGSQL;

DROP TRIGGER add_create_at_data_on_insert ON users;

CREATE TRIGGER add_create_at_data_on_insert BEFORE INSERT ON users 
  FOR EACH ROW 
  EXECUTE FUNCTION add_create_at_data();
