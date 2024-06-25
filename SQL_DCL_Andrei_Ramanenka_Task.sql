-- 1) Create a new user with the username "rentaluser" and the password "rentalpassword".
-- Give the user the ability to connect to the database but no other permissions.

SET ROLE postgres;

DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser') THEN
     CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
   END IF;
END
$$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

-- 2) Grant "rentaluser" SELECT permission for the "customer" table.
-- Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON customer TO rentaluser;

SET ROLE rentaluser;
SELECT * FROM customer;

-- 3) Create a new user group called "rental" and add "rentaluser" to the group. 

RESET ROLE;

DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental') THEN
     CREATE ROLE rental;
   END IF;
END
$$;

GRANT rental TO rentaluser;

-- 4) Grant the "rental" group INSERT and UPDATE permissions for the "rental" table.
-- Insert a new row and update one existing row in the "rental" table under that role. 

SET ROLE postgres;
ALTER TABLE rental DISABLE ROW LEVEL SECURITY;

GRANT USAGE ON SEQUENCE rental_rental_id_seq TO rental;
GRANT UPDATE, INSERT, SELECT ON TABLE rental TO rental;

 
SET ROLE rentaluser;

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1525, 459, CURRENT_DATE + 14, 1);

UPDATE rental
SET staff_id = 2,
    customer_id = 222
WHERE rental_id = (
    SELECT rental_id
    FROM (
        SELECT rental_id
        FROM rental
        ORDER BY rental_id ASC
        LIMIT 3
    ) AS subq
    ORDER BY rental_id DESC
    LIMIT 1
);


-- 5) Revoke the "rental" group's INSERT permission for the "rental" table.
-- Try to insert new rows into the "rental" table make sure this action is denied.

SET ROLE postgres;

REVOKE INSERT ON TABLE rental FROM rental;

SET ROLE rentaluser;

SELECT CURRENT_USER;

DO $$ 
BEGIN
  INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
  VALUES (NOW(), 1325, 459, CURRENT_DATE + 10, 1);

  INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
  VALUES (NOW(), 1127, 459, CURRENT_DATE + 5, 2);
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'permission denied for table rental. role: %', CURRENT_USER;
END $$;

-- 6) Create a personalized role for any customer already existing in the dvd_rental database.
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets).
-- The customer's payment and rental history must not be empty.
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables.
-- Write a query to make sure this user sees only their own data.

SET ROLE postgres;

DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'client_rose_howard') THEN
     CREATE ROLE client_ROSE_HOWARD WITH PASSWORD '1234';
   END IF;
END
$$;

GRANT CONNECT ON DATABASE dvdrental TO client_ROSE_HOWARD;

GRANT SELECT ON rental TO client_ROSE_HOWARD;
GRANT SELECT ON payment TO client_ROSE_HOWARD;

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS policy_rental ON rental;
DROP POLICY IF EXISTS policy_payment ON payment;

CREATE POLICY policy_rental
ON rental
FOR SELECT
TO client_ROSE_HOWARD
USING (customer_id = 65);

CREATE POLICY policy_payment
ON payment
FOR SELECT
TO client_ROSE_HOWARD
USING (customer_id = 65);

RESET ROLE;

SET ROLE client_ROSE_HOWARD;

SELECT CURRENT_USER;
SELECT * FROM payment;
SELECT * FROM rental;
