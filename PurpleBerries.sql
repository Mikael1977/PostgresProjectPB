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
user_id integer REFERENCES users,
basket_id INT REFERENCES baskets,
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
finish_date TIMESTAMP;
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
  
 /*Добавление индексов*/

CREATE UNIQUE INDEX users_id_uq ON users (id);
CREATE UNIQUE INDEX profiles_id_uq ON profiles (id);
CREATE INDEX profiles_user_id_idx ON profiles (user_id);
CREATE INDEX profiles_email_idx ON profiles (email);
CREATE INDEX baskets_user_id_idx ON baskets_users (user_id);
CREATE UNIQUE INDEX baskets_id_uq ON baskets (id);
CREATE INDEX baskets_basket_id_idx ON baskets_users (basket_id);
 
 
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
  EXECUTE FUNCTION add_create_at_data
  
/*Сложные запросы с использованием подзапросов*/

/*Вывод имени пользователя, адреса доставки и номера заказа за последний месяц с текущего момента с исключением тестовых данных из будущих периодов*/

SELECT 
id AS order_id, 
basket_id,
(SELECT CONCAT(first_name,' ',last_name) FROM users WHERE users.id = 
(SELECT baskets_users.user_id 
 FROM baskets_users 
 WHERE baskets_users.basket_id = orders.basket_id)) AS user_name,
(SELECT address FROM pickpoints WHERE pickpoints.id = orders.pickpoint_id) AS pickpoint_address
FROM ORDERS
WHERE created_at > (now() - interval '1 month') AND created_at <= (now()) AND finish_date IS NULL;

/*Запрос сортирует пункты выдачи по количеству позиций в заказах*/

SELECT 
address, 
(SELECT SUM(product_count) FROM baskets_products WHERE basket_id IN 
 	(SELECT basket_id FROM orders WHERE pickpoint_id = pickpoints.id)) AS products_count
FROM pickpoints
ORDER BY products_count DESC NULLS LAST;


/*Запрос выводит список пользователей корзин с email*/

SELECT 
baskets.id AS basket_id,
baskets_users.user_id,
profiles.email,
CONCAT (users.first_name, ' ', users.last_name)
FROM baskets
JOIN baskets_users ON baskets.id = baskets_users.basket_id
JOIN users ON users.id = baskets_users.user_id
JOIN profiles ON profiles.user_id = baskets_users.user_id
;

/*Вывод общей стоимости корзины с учетом НЕ индивидуальных скидок. 
В запросе идет обращение к представлению  baskets_products.product_count. 
Необходимо убедиться в его наличии*/

SELECT 
baskets.id,
SUM(prices_with_discounts.reduced_price * baskets_products.product_count) AS total_basket_cost
FROM baskets
JOIN baskets_products ON baskets_products.basket_id = baskets.id
JOIN prices_with_discounts ON prices_with_discounts.product_id = baskets_products.product_id
GROUP BY baskets.id
order by baskets.id;


/*Представления*/

/*Представление в том числе выводит информацию о сенах на товар с учетом скидки*/

DROP VIEW IF EXISTS prices_with_discounts; 

CREATE VIEW prices_with_discounts AS
SELECT 
products_prices.id AS products_price_id,
product_id, 
price, 
CASE
	WHEN (products_prices_reduces.percents IS NULL) THEN price
	ELSE price - price / 100 * products_prices_reduces.percents
END AS reduced_price,
products_prices_reduces.percents
FROM products_prices
LEFT JOIN products_prices_reduces ON products_prices.id = products_prices_reduces.products_price_id;

SELECT * FROM prices_with_discounts;


/*Представленгие для вывода общей стоимости корзины с учетом НЕ индивидуальных скидок. 
В запросе идет обращение к представлению  baskets_products.product_count. 
Необходимо убедиться в его наличии*/

DROP VIEW IF EXISTS baskets_costs_view; 

CREATE VIEW baskets_costs_view AS
SELECT 
baskets.id,
SUM(prices_with_discounts.reduced_price * baskets_products.product_count) AS total_basket_cost
FROM baskets
JOIN baskets_products ON baskets_products.basket_id = baskets.id
JOIN prices_with_discounts ON prices_with_discounts.product_id = baskets_products.product_id
GROUP BY baskets.id
order by baskets.id;


/*Функция выводит стоимость товара с учетом индивидуальной скидки. Проверка на существование данных не осуществляется, 
также заранее должно быть создано представление prices_with_discounts*/
DROP FUNCTION IF EXISTS get_product_price_with_all_reduces_by_user_id_product_price_id;

CREATE FUNCTION get_product_price_with_all_reduces_by_user_id_product_price_id (user_id INTEGER, product_price_id INTEGER) 
RETURNS MONEY AS 
$$
  SELECT 
CASE
	WHEN (prices_with_discounts.percents IS NULL) THEN reduced_price
	ELSE reduced_price - reduced_price / 100 * products_prices_reduces_individual.percents
	END
	FROM products_prices_reduces_individual
	LEFT JOIN prices_with_discounts ON prices_with_discounts.products_price_id = products_prices_reduces_individual.products_price_id
	WHERE user_id = user_id AND product_id = product_price_id;

$$ 
LANGUAGE SQL;


SELECT get_product_price_with_all_reduces_by_user_id_product_price_id(171,108);