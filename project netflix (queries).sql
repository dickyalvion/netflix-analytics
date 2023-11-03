SELECT *
FROM titles;

SELECT genres, production_countries
FROM titles;

--Genres and production_countries columns have JSON-like data types
--Need to remove the marks ([ ]) and (') to make the data look more neat

--Update genres and production_countries data
UPDATE titles
SET genres = REPLACE(REPLACE(REPLACE(genres, '[', ''), ']', ''), '''', '');

UPDATE titles
SET production_countries = REPLACE(REPLACE(REPLACE(production_countries, '[', ''), ']', ''), '''', '');

--Genres and production_countries columns after updating
SELECT genres, production_countries
FROM titles;

--Joining titles dan credits tables
SELECT
	titles.id,
	titles.title,
	titles.type,
	credits.name,
	credits.character,
	credits.role,
	titles.release_year,
	titles.age_certification,
	titles.runtime,
	titles.genres,
	titles.production_countries,
	titles.seasons,
	titles.imdb_score,
	titles.tmdb_score
FROM titles
LEFT JOIN credits
	ON titles.id = credits.id;

--Movies with highest IMBD rating
SELECT
	title,
	genres,
	imdb_score
FROM titles
WHERE 
	imdb_score = (SELECT MAX(imdb_score) FROM titles WHERE type = 'MOVIE');

--Movie and Show with highest IMBD score
WITH imdb_rank AS (
SELECT
	title,
	type,
	genres,
	imdb_score,
	DENSE_RANK() OVER(PARTITION BY type ORDER BY imdb_score DESC) AS imdb_score_rank
FROM titles
)
SELECT
	title,
	type,
	genres,
	imdb_score
FROM imdb_rank
WHERE imdb_score_rank = 1
ORDER BY imdb_score DESC, type;


--Movies with the highest IMBD rating by year of release
WITH movie_year_rank AS (
SELECT
	title,
	release_year,
	genres,
	imdb_score,
	DENSE_RANK () OVER(PARTITION BY release_year ORDER BY imdb_score DESC) AS movie_rank
FROM titles
WHERE type = 'MOVIE'
)
SELECT
	title,
	release_year,
	genres,
	imdb_score
FROM movie_year_rank
WHERE movie_rank = 1
ORDER BY release_year DESC, movie_rank;

--Shows with the highest IMBD rating by year of release
WITH show_year_rank AS (
SELECT
	title,
	release_year,
	genres,
	imdb_score,
	DENSE_RANK () OVER(PARTITION BY release_year ORDER BY imdb_score DESC) AS show_rank
FROM titles
WHERE type = 'Show'
)
SELECT
	title,
	release_year,
	genres,
	imdb_score
FROM show_year_rank
WHERE show_rank = 1
ORDER BY release_year DESC, show_rank;

--Highest IMDB Score movies by genre
--One Movie or Show here consists of several genres
--In the 'genres' column there are several genres for 1 Movie or Show
--The first genre that appears in the 'genres' column will be used as the main genre of the Movie or Show
--Need to create a new column, i.e. 'main_genre'
--Then you can see the highest-rated Movies by genre
WITH new_genre AS (
SELECT
	title,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre,
    imdb_score
FROM titles
WHERE type = 'MOVIE'
)
SELECT
	title,
	main_genre,
	imdb_score
FROM new_genre AS ng
WHERE 
	(main_genre != '') AND
	(imdb_score = 
		(SELECT MAX(imdb_score)
		FROM new_genre
		WHERE main_genre = ng.main_genre)
	)
ORDER BY imdb_score DESC, main_genre;

--Highest IMDB Score Show by genre
--One Movie or Show here consists of several genres
--In the 'genres' column there are several genres for 1 Movie or Show
--The first genre that appears in the 'genres' column will be used as the main genre of the Movie or Show
--Need to create a new column, i.e. 'main_genre'
--Then you can see the highest-rated Movies by genre
WITH new_genre AS (
SELECT
	title,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre,
    imdb_score
FROM titles
WHERE type = 'SHOW'
)
SELECT
	title,
	main_genre,
	imdb_score
FROM new_genre AS ng
WHERE 
	(main_genre != '') AND
	(imdb_score = 
		(SELECT MAX(imdb_score)
		FROM new_genre
		WHERE main_genre = ng.main_genre)
	)
ORDER BY imdb_score DESC, main_genre;

--Actor with most movie and show
SELECT
	credits.name,
	COUNT(titles.title) AS total_movie
FROM titles
JOIN credits
	ON titles.id = credits.id
WHERE credits.role = 'ACTOR'
GROUP BY credits.name
ORDER BY COUNT(titles.title) DESC

--Director with most movie and show
SELECT
	credits.name,
	COUNT(titles.title) AS total_movie_director
FROM titles
JOIN credits
	ON titles.id = credits.id
WHERE credits.role = 'DIRECTOR'
GROUP BY credits.name
ORDER BY COUNT(titles.title) DESC


--Actors who have played the most MOVIES or TV Shows of a particular genre
WITH actor_genre AS (
SELECT
	title,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre,
    credits.name
FROM titles
JOIN credits
	ON titles.id = credits.id
WHERE credits.role = 'ACTOR'
),
total_movie_rank AS (
SELECT
	name,
	main_genre,
	COUNT(main_genre) total_movie,
	DENSE_RANK() OVER(PARTITION BY main_genre ORDER BY COUNT(main_genre) DESC) AS ranking
FROM actor_genre
WHERE main_genre != ''
GROUP BY name, main_genre
)
SELECT
	name,
	main_genre,
	total_movie
FROM total_movie_rank
WHERE ranking = 1
ORDER BY total_movie DESC, ranking;

--DIRECTOR who have played the most MOVIES or TV Shows of a particular genre
WITH actor_genre AS (
SELECT
	title,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre,
    credits.name
FROM titles
JOIN credits
	ON titles.id = credits.id
WHERE credits.role = 'DIRECTOR'
),
total_movie_rank AS (
SELECT
	name,
	main_genre,
	COUNT(main_genre) total_movie,
	DENSE_RANK() OVER(PARTITION BY main_genre ORDER BY COUNT(main_genre) DESC) AS ranking
FROM actor_genre
WHERE main_genre != ''
GROUP BY name, main_genre
)
SELECT
	name,
	main_genre,
	total_movie
FROM total_movie_rank
WHERE ranking = 1
ORDER BY total_movie DESC, ranking;

--Longest running movies and show
SELECT 
	title,
	runtime
FROM titles
--WHERE type = 'MOVIE'
WHERE type = 'SHOW'
ORDER BY runtime DESC;

--Longest running films and shows by genre
WITH genre AS (
SELECT
	title,
	type,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre,
    runtime
FROM titles
--WHERE type = 'MOVIE'
WHERE type = 'SHOW'
),
rank_runtime AS (
SELECT
	title,
	main_genre,
	runtime,
	DENSE_RANK() OVER(PARTITION BY main_genre ORDER by runtime DESC) AS runtime_ranking
FROM genre
)
SELECT
	title,
	main_genre,
	runtime
FROM rank_runtime
WHERE runtime_ranking = 1 AND main_genre != ''
ORDER BY runtime DESC;

--Movies and shows in what year are the most entered on Netflix
--Whether on Netflix more of the latest movies and shows or movies with years old
SELECT
	release_year,
	COUNT(title) AS total_movie
FROM titles
--WHERE type = 'MOVIE'
WHERE type = 'SHOW'
GROUP BY release_year
ORDER BY COUNT(title) DESC;

--Percentage Total Movie dan Show
WITH total_movie_and_show AS (
SELECT
	type,
	COUNT(title) AS total
FROM titles
GROUP BY type
),
total_all AS (
SELECT
	type,
	CONVERT(FLOAT, total) AS total,
	SUM(total) OVER() AS total_movie_show
FROM total_movie_and_show
)
SELECT
	type,
	total,
	ROUND(total / total_movie_show * 100, 2) total_percentage
FROM total_all;

--Number of Movies and Shows on Netflix by genre
WITH all_genre AS (
SELECT
	title,
	type,
    genres,
    CASE
      WHEN CHARINDEX(',', genres) > 0 THEN
        LEFT(genres, CHARINDEX(',', genres) - 1)
      ELSE genres
    END AS main_genre
    FROM titles
)
SELECT
	main_genre,
	SUM(CASE WHEN type = 'MOVIE' THEN 1 ELSE 0 END) AS total_movie,
    SUM(CASE WHEN type = 'SHOW' THEN 1 ELSE 0 END) AS total_show, 
	COUNT(title) AS total_movie_show
FROM all_genre
GROUP BY main_genre
ORDER BY COUNT(title) DESC;