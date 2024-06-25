
-- 1) Create a view called "sales_revenue_by_category_qtr" that shows the film category and total sales revenue for the current quarter.
-- The view should only display categories with at least one sale in the current quarter. The current quarter should be determined dynamically.

DROP VIEW IF EXISTS sales_revenue_by_category_qtr;

CREATE VIEW sales_revenue_by_category_qtr AS

SELECT
    category.name AS category,
  (SELECT EXTRACT(QUARTER FROM CURRENT_DATE))::integer AS current_quarter,
  SUM(payment.amount)::integer AS  total_sales_revenue
FROM
    payment
JOIN
    rental ON payment.rental_id = rental.rental_id
JOIN
    inventory ON rental.inventory_id = inventory.inventory_id
JOIN
    film ON inventory.film_id = film.film_id
JOIN
    film_category ON film.film_id = film_category.film_id
JOIN
    category ON film_category.category_id = category.category_id
WHERE
  EXTRACT(QUARTER FROM payment.payment_date) =  EXTRACT(QUARTER FROM CURRENT_DATE)
GROUP BY
    category.name
HAVING
    SUM(payment.amount) > 0;

SELECT * FROM sales_revenue_by_category_qtr;

-- 2) Create a query language function called "get_sales_revenue_by_category_qtr" that accepts one parameter representing
-- the current quarter and returns the same result as the "sales_revenue_by_category_qtr" view.

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(quarter_param INT)
RETURNS TABLE(category TEXT, current_quarter INT, total_sales_revenue INTEGER)
   LANGUAGE plpgsql
  AS
$$
BEGIN
    -- Validate parameter
    IF quarter_param < 1 OR quarter_param > 4 THEN
        RAISE EXCEPTION 'Invalid quarter parameter: %. Quarter must be between 1 and 4.', quarter_param;
    END IF;
  
  RETURN QUERY
  WITH max_payment_year AS (SELECT EXTRACT(YEAR FROM (MAX(payment_date)))::integer AS p_year FROM payment),

--   months_list AS (
--     SELECT 
--       generate_series(
--        EXTRACT(month from (MAKE_DATE((SELECT p_year FROM max_payment_year), EXTRACT(month FROM CURRENT_DATE)::integer - 2, 1))), 
--        EXTRACT(month from (MAKE_DATE((SELECT p_year FROM max_payment_year), EXTRACT(month FROM CURRENT_DATE)::integer, 1)))
--       ) AS month
--   ),

  months AS (
    SELECT generate_series(1, 12) AS month
  ),

  quarters_list AS (
    SELECT month,
      CASE
        WHEN month BETWEEN 1 AND 3 THEN 1
        WHEN month BETWEEN 4 AND 6 THEN 2
        WHEN month BETWEEN 7 AND 9 THEN 3
        WHEN month BETWEEN 10 AND 12 THEN 4
      END AS quarter
    FROM months
  ),
  
  filtered_quarter AS (
        SELECT month 
        FROM quarters_list 
        WHERE quarter = quarter_param
    )

  SELECT
    category.name AS category,
    quarter_param AS current_quarter,
    SUM(payment.amount)::integer AS  total_sales_revenue
  FROM
    payment
  JOIN
    rental ON payment.rental_id = rental.rental_id
  JOIN
    inventory ON rental.inventory_id = inventory.inventory_id
  JOIN
    film ON inventory.film_id = film.film_id
  JOIN
    film_category ON film.film_id = film_category.film_id
  JOIN
    category ON film_category.category_id = category.category_id
  WHERE
    EXTRACT(YEAR FROM payment.payment_date) = (SELECT p_year FROM max_payment_year)
    AND EXTRACT(MONTH FROM payment.payment_date) IN (SELECT month FROM filtered_quarter)
  GROUP BY
    category.name
  HAVING
    SUM(payment.amount) > 0;
  END;
$$;

SELECT * FROM get_sales_revenue_by_category_qtr(2);



-- 3) Create a procedure language function called "new_movie" that takes a movie title as a parameter and inserts a new movie with the given title in the film table.
-- The function should generate a new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99, the release year to the current year, and "language" as Klingon.
-- The function should also verify that the language exists in the "language" table. Then, ensure that no such function has been created before; if so, replace it.


CREATE OR REPLACE FUNCTION new_movie(movie_title VARCHAR)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM language WHERE name = 'Klingon') THEN
      RAISE NOTICE 'Language "Klingon" does not exist. Creating...';
        INSERT INTO language (name) VALUES ('Klingon');
    END IF;

    INSERT INTO film (film_id, title, release_year, language_id, rental_duration,rental_rate, replacement_cost)

    VALUES (
        (SELECT MAX(film_id) + 1 FROM film),
        movie_title,
        EXTRACT(YEAR FROM CURRENT_DATE),
        (SELECT language_id FROM language WHERE name = 'Klingon'),
        3,
        4.99,
        19.99
    );
END;
$$ LANGUAGE plpgsql;


SELECT new_movie('Den of Thieves');

SELECT * FROM language WHERE name = 'Klingon';

SELECT * FROM film WHERE title = 'Den of Thieves';
