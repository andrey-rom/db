UPDATE film
SET rental_duration = 21, rental_rate = 9.99
WHERE title = 'The Silence of the Lambs';

WITH eligible_customers AS (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 10 AND COUNT(p.payment_id) >= 10
    LIMIT 1
)

UPDATE customer
SET first_name = 'Andrei', 
    last_name = 'Ramanenka', 
    email = 'ramanenka.andrei@student.ehu.lt', 
    address_id = (SELECT address_id FROM address LIMIT 1)
WHERE customer_id = (SELECT customer_id FROM eligible_customers);

UPDATE customer
SET create_date = CURRENT_DATE
WHERE email = 'ramanenka.andrei@student.ehu.lt';
