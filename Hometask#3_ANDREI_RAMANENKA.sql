-- Write a query that will return for each year the most popular in rental film among films released in one year.
	
WITH film_rentals AS (
    SELECT
        f.film_id,
        f.release_year,
        COUNT(r.rental_id) AS rental_count
    FROM
        film f
    JOIN
        inventory i ON f.film_id = i.film_id
    JOIN
        rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id,
        f.release_year
),
yearly_ranked_films AS (
    SELECT
        release_year,
        film_id,
        rental_count,
        RANK() OVER (PARTITION BY release_year ORDER BY rental_count DESC) AS rank
    FROM
        film_rentals
)
SELECT
    f.release_year,
    f.title,
    yrf.rental_count
FROM
    yearly_ranked_films yrf
JOIN
    film f ON yrf.film_id = f.film_id
WHERE
    yrf.rank = 1
ORDER BY
    f.release_year;


-- Write a query that will return the Top-5 actors who have appeared in Comedies more than anyone else.

WITH comedy_films AS (
    SELECT f.film_id
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Comedy'
),
actor_comedy_counts AS (
    SELECT
        fa.actor_id,
        COUNT(fa.film_id) AS comedy_count
    FROM
        film_actor fa
    JOIN
        comedy_films cf ON fa.film_id = cf.film_id
    GROUP BY
        fa.actor_id
),
ranked_actors AS (
    SELECT
        ac.actor_id,
        ac.comedy_count,
        ROW_NUMBER() OVER (ORDER BY ac.comedy_count DESC) AS rank
    FROM
        actor_comedy_counts ac
)
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    ra.comedy_count
FROM
    ranked_actors ra
JOIN
    actor a ON ra.actor_id = a.actor_id
WHERE
    ra.rank <= 5
ORDER BY
    ra.comedy_count DESC;


-- Write a query that will return the names of actors who have not starred in “Action” films.

WITH action_films AS (
    SELECT f.film_id
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Action'
),
actors_in_action_films AS (
    SELECT DISTINCT fa.actor_id
    FROM film_actor fa
    JOIN action_films af ON fa.film_id = af.film_id
)
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
LEFT JOIN actors_in_action_films aa ON a.actor_id = aa.actor_id
WHERE aa.actor_id IS NULL;


-- Write a query that will return the three most popular in rental films by each genre

WITH genre_rentals AS (
    SELECT
        c.name AS genre,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM
        film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        c.name, f.film_id, f.title
),
ranked_genre_rentals AS (
    SELECT
        genre,
        film_id,
        title,
        rental_count,
        ROW_NUMBER() OVER (PARTITION BY genre ORDER BY rental_count DESC) AS rank
    FROM
        genre_rentals
)
SELECT
    genre,
    film_id,
    title,
    rental_count
FROM
    ranked_genre_rentals
WHERE
    rank <= 3
ORDER BY
    genre;

-- Calculate the number of films released each year and cumulative total by the number of films. 

-- 1
SELECT
    release_year,
    COUNT(*) AS films_released,
    SUM(COUNT(*)) OVER (ORDER BY release_year) AS cumulative_total
FROM
    film
GROUP BY
    release_year
ORDER BY
    release_year;

-- 2
SELECT
    f1.release_year,
    COUNT(*) AS films_released,
    (SELECT COUNT(*)
     FROM film f2
     WHERE f2.release_year <= f1.release_year) AS cumulative_total
FROM
    film f1
GROUP BY
    f1.release_year
ORDER BY
    f1.release_year;


-- Calculate a monthly statistics based on “rental_date” field from “Rental” table that for each month will show the percentage of “Animation” films from the total number of rentals.

-- 1
WITH monthly_rentals AS (
    SELECT
        DATE_TRUNC('month', rental_date) AS rental_month,
        COUNT(*) AS total_rentals
    FROM
        rental
    GROUP BY
        DATE_TRUNC('month', rental_date)
),
monthly_animation_rentals AS (
    SELECT
        DATE_TRUNC('month', r.rental_date) AS rental_month,
        COUNT(*) AS animation_rentals
    FROM
        rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Animation'
    GROUP BY
        DATE_TRUNC('month', r.rental_date)
)
SELECT
    mr.rental_month,
    mr.total_rentals,
    mar.animation_rentals,
    COALESCE((mar.animation_rentals::decimal / mr.total_rentals) * 100, 0) AS animation_percentage
FROM
    monthly_rentals mr
LEFT JOIN
    monthly_animation_rentals mar ON mr.rental_month = mar.rental_month
ORDER BY
    mr.rental_month;



-- 2
WITH monthly_totals AS (
    SELECT
        DATE_TRUNC('month', rental_date) AS rental_month,
        COUNT(*) AS total_rentals
    FROM
        rental
    GROUP BY
        DATE_TRUNC('month', rental_date)
)
SELECT
    mt.rental_month,
    mt.total_rentals,
    (SELECT COUNT(*)
     FROM rental r
     JOIN inventory i ON r.inventory_id = i.inventory_id
     JOIN film f ON i.film_id = f.film_id
     JOIN film_category fc ON f.film_id = fc.film_id
     JOIN category c ON fc.category_id = c.category_id
     WHERE c.name = 'Animation'
       AND DATE_TRUNC('month', r.rental_date) = mt.rental_month
    ) AS animation_rentals,
    COALESCE(((
        SELECT COUNT(*)
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
        WHERE c.name = 'Animation'
          AND DATE_TRUNC('month', r.rental_date) = mt.rental_month
    )::decimal / mt.total_rentals) * 100, 0) AS animation_percentage
FROM
    monthly_totals mt
ORDER BY
    mt.rental_month;


-- Write a query that will return the names of actors who have starred in “Action” films more than in “Drama” film

WITH actor_film_counts AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        SUM(CASE WHEN c.name = 'Action' THEN 1 ELSE 0 END) AS action_count,
        SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS drama_count
    FROM
        actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
)
SELECT
    actor_id,
    first_name,
    last_name
FROM
    actor_film_counts
WHERE
    action_count > drama_count
ORDER BY
    first_name,
    last_name;


--  Write a query that will return the top-5 customers who spent the most money watching Comedies

WITH comedy_payments AS (
    SELECT
        p.customer_id,
        SUM(p.amount) AS total_spent
    FROM
        payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Comedy'
    GROUP BY
        p.customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        comedy_payments
)
SELECT
    rc.customer_id,
    c.first_name,
    c.last_name,
    rc.total_spent
FROM
    ranked_customers rc
JOIN
    customer c ON rc.customer_id = c.customer_id
WHERE
    rc.rank <= 5
ORDER BY
    rc.rank;


-- In the “Address” table, in the “address” field, the last word indicates the "type" of a street: Street, Lane, Way, etc. Write a query that will return all "types" of streets and the number of addresses related to this "type".

SELECT
    street_type,
    COUNT(*) AS address_count
FROM (
    SELECT
        REGEXP_REPLACE(address, '^.*\s(\S+)$', '\1') AS street_type
    FROM
        address
) AS extracted_types
GROUP BY
    street_type
ORDER BY
    address_count DESC;


-- Write a query that will return a list of movie ratings, indicate for each rating the total number of films with this rating, the top-3 categories by the number of films in this category and the number of film in this category with this rating.

WITH film_rating_totals AS (
    SELECT
        rating,
        COUNT(*) AS total
    FROM
        film
    GROUP BY
        rating
),
film_category_counts AS (
    SELECT
        f.rating,
        c.name AS category,
        COUNT(*) AS count
    FROM
        film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        f.rating,
        c.name
),
ranked_categories AS (
    SELECT
        rating,
        category,
        count,
        ROW_NUMBER() OVER (PARTITION BY rating ORDER BY count DESC) AS rank
    FROM
        film_category_counts
)
SELECT
    frt.rating,
    frt.total,
    MAX(CASE WHEN rc.rank = 1 THEN rc.category || ': ' || rc.count ELSE NULL END) AS category1,
    MAX(CASE WHEN rc.rank = 2 THEN rc.category || ': ' || rc.count ELSE NULL END) AS category2,
    MAX(CASE WHEN rc.rank = 3 THEN rc.category || ': ' || rc.count ELSE NULL END) AS category3
FROM
    film_rating_totals frt
LEFT JOIN
    ranked_categories rc ON frt.rating = rc.rating
GROUP BY
    frt.rating,
    frt.total
ORDER BY
    frt.total DESC;

