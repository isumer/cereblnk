CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  customer_id BIGINT,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);

EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 7;
EXPLAIN PLAN FOR SELECT * FROM orders;
SELECT * FROM pg_stat_user_tables;

-- PL/SQL block used by the legacy Oracle job
BEGIN NULL; END;
