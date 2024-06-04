WITH film_to_remove AS (
    SELECT film_id 
    FROM film 
    WHERE title = 'The Silence of the Lambs'
)
DELETE FROM inventory
WHERE inventory_id IN (
    SELECT inventory_id 
    FROM inventory 
    WHERE film_id IN (SELECT film_id FROM film_to_remove)
);

WITH your_customer AS (
    SELECT customer_id
    FROM customer
    WHERE first_name = 'Andrei' AND last_name = 'Ramanenka'
),
rental_ids AS (
    SELECT rental_id
    FROM rental
    WHERE customer_id = (SELECT customer_id FROM your_customer)
),
payment_ids AS (
    SELECT payment_id
    FROM payment
    WHERE customer_id = (SELECT customer_id FROM your_customer)
)

DELETE FROM payment
WHERE payment_id IN (SELECT payment_id FROM payment_ids);

DELETE FROM rental
WHERE rental_id IN (SELECT rental_id FROM rental_ids);
