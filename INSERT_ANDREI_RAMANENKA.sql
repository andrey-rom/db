INSERT INTO film (
    title, 
    description, 
    release_year, 
    language_id, 
    rental_duration, 
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    special_features, 
    last_update
)
VALUES (
    'The Silence of the Lambs', 
    'A young FBI cadet must confide in an incarcerated and manipulative killer to receive his help on catching another serial killer who skins his victims.', 
    1991, 
    1, 
    14, 
    4.99, 
    118, 
    19.99, 
    'R', 
    '{"Behind the Scenes","Deleted Scenes","Commentaries"}', 
    NOW()
);


INSERT INTO actor (first_name, last_name, last_update)
VALUES
('Jodie', 'Foster', NOW()),
('Anthony', 'Hopkins', NOW());

INSERT INTO film_actor (actor_id, film_id, last_update)
VALUES
((SELECT actor_id FROM actor WHERE first_name = 'Jodie' AND last_name = 'Foster'), 
 (SELECT film_id FROM film WHERE title = 'The Silence of the Lambs'), 
 NOW()),
((SELECT actor_id FROM actor WHERE first_name = 'Anthony' AND last_name = 'Hopkins'), 
 (SELECT film_id FROM film WHERE title = 'The Silence of the Lambs'), 
 NOW());
