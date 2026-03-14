-- Sample product data for WiredBrain Coffee
-- This file is automatically executed by Spring Boot on application startup

INSERT INTO products (id, name, price, stock)
VALUES (1, 'Espresso', 4.00, 600)
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, price, stock)
VALUES (2, 'Americano', 5.00, 400)
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, name, price, stock)
VALUES (3, 'Flat White', 6.50, 750)
ON CONFLICT (id) DO NOTHING;
