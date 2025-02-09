-- Завершаем все соединения с базой, если она существует

SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'bookstore';

-- Удаляем базу, если она существует    

DROP DATABASE IF EXISTS bookstore;

-- Создаем базу

CREATE DATABASE bookstore;

-- Подключаемся (pgsql)

\c bookstore;


-- Создаем схему 

CREATE SCHEMA bookstore;

-- Изменяем путь поиска на уровне подключения
--SET search_path TO bookstore;
--ALTER DATABASE bookstore SET search_path = bookstore, public;
ALTER ROLE ag SET search_path TO bookstore;

SHOW search_path;


-- Создаем таблицы и ограничения

-- DROP TABLE IF EXISTS authors CASCADE;
-- DROP TABLE IF EXISTS books CASCADE;
-- DROP TABLE IF EXISTS authorship CASCADE;
-- DROP TABLE IF EXISTS operations CASCADE;

CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    middle_name TEXT
);
-- CREATE TABLE authors(
--     author_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
--     last_name text NOT NULL,
--     first_name text NOT NULL,
--     middle_name text
-- );

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL
);
-- CREATE TABLE books(
--     book_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
--     title text NOT NULL
-- );

CREATE TABLE authorship (
    book_id INT REFERENCES books(book_id) ON DELETE CASCADE,
    author_id INT REFERENCES authors(author_id) ON DELETE CASCADE,
    seq_num INT NOT NULL,
    PRIMARY KEY (book_id, author_id)
);
-- CREATE TABLE authorship(
--     book_id integer REFERENCES books,
--     author_id integer REFERENCES authors,
--     seq_num integer NOT NULL,
--     PRIMARY KEY (book_id,author_id)
-- );

CREATE TABLE operations (
    operation_id SERIAL PRIMARY KEY,
    book_id INT REFERENCES books(book_id) ON DELETE CASCADE,
    qty_change INT NOT NULL,
    date_created TIMESTAMP DEFAULT NOW()
);
-- CREATE TABLE operations(
--     operation_id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
--     book_id integer NOT NULL REFERENCES books,
--     qty_change integer NOT NULL,
--     date_created date NOT NULL DEFAULT current_date
-- );


-- Заполняем таблицы данными

INSERT INTO authors (last_name, first_name, middle_name) VALUES
('Пушкин', 'Александр', 'Сергеевич'),
('Тургенев', 'Иван', 'Сергеевич'),
('Толстой', 'Лев', 'Николаевич'),
('Достоевский', 'Федор', 'Михайлович'),
('Стругацкий', 'Борис', 'Натанович'),
('Стругацкий', 'Аркадий', 'Натанович'),
('Булгаков', 'Михаил', 'Афанасьевич'),
('Свифт', 'Джонатан', NULL);
-- INSERT INTO authors(last_name, first_name, middle_name)
-- VALUES 
--     ('Пушкин', 'Александр', 'Сергеевич'),
--     ('Тургенев', 'Иван', 'Сергеевич'),
--     ('Стругацкий', 'Борис', 'Натанович'),
--     ('Стругацкий', 'Аркадий', 'Натанович'),
--     ('Толстой', 'Лев', 'Николаевич'),
--     ('Свифт', 'Джонатан', NULL);

INSERT INTO books (title) VALUES
('Евгений Онегин'),
('Сказка о царе Салтане'),
('Война и мир'),
('Муму'),
('Преступление и наказание'),
('Трудно быть богом'),
('Хрестоматия'),
('Мастер и Маргарита'),
('Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей');
-- INSERT INTO books(title)
-- VALUES
--     ('Сказка о царе Салтане'),
--     ('Муму'),
--     ('Трудно быть богом'),
--     ('Война и мир'),
--     ('Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'),
--     ('Хрестоматия');

INSERT INTO authorship (book_id, author_id, seq_num) VALUES 
(1, 1, 1),
(2, 2, 1),
(3, 3, 2),
(3, 4, 1),
(4, 5, 1),
(5, 6, 1),
(6, 1, 1),
(6, 5, 2),
(6, 2, 3);
-- INSERT INTO authorship(book_id, author_id, seq_num) 
-- VALUES
--     (1, 1, 1),
--     (2, 2, 1),
--     (3, 3, 2),
--     (3, 4, 1),
--     (4, 5, 1),
--     (5, 6, 1),
--     (6, 1, 1),
--     (6, 5, 2),
--     (6, 2, 3);

INSERT INTO operations (book_id, qty_change) VALUES 
(1, 10),
(2, 5),
(3, 7),
(4, 8),
(1, -2),
(2, -1),
(3, -3),
(4, -2);

-- COPY operations (operation_id, book_id, qty_change) FROM stdin;
-- 1	1	10
-- 2	1	10
-- 3	1	-1
-- \.
-- SELECT pg_catalog.setval('operations_operation_id_seq', 3, true);


-- Создаем представление авторов и каталога книг

-- DROP VIEW IF EXISTS authors_v;
CREATE VIEW authors_v AS
SELECT 
    a.author_id, 
    a.last_name, 
    a.first_name, 
    a.middle_name
FROM authors a;
-- CREATE VIEW authors_v AS
-- SELECT a.author_id,
--        a.last_name || ' ' ||
--        a.first_name ||
--        coalesce(' ' || nullif(a.middle_name, ''), '') AS display_name
-- FROM   authors a;

-- DROP VIEW IF EXISTS catalog_v;
CREATE VIEW catalog_v AS
SELECT 
    b.book_id, 
    b.title, 
    json_agg(a.last_name || ' ' || a.first_name || COALESCE(' ' || a.middle_name, '')) AS authors
FROM books b
LEFT JOIN authorship au ON b.book_id = au.book_id
LEFT JOIN authors a ON au.author_id = a.author_id
GROUP BY b.book_id, b.title;
-- CREATE VIEW catalog_v AS
-- SELECT b.book_id,
--        b.title AS display_name
-- FROM   books b;

-- Создаем представление по операциям

-- DROP VIEW IF EXISTS operations_v;
CREATE VIEW operations_v AS
SELECT 
    o.operation_id, 
    o.book_id, 
    b.title,
    o.qty_change, 
    o.date_created
FROM operations o
JOIN books b ON o.book_id = b.book_id;
-- CREATE VIEW operations_v AS
-- SELECT book_id,
--        CASE
--            WHEN qty_change > 0 THEN 'Поступление'
--            ELSE 'Покупка'
--        END op_type, 
--        abs(qty_change) qty_change, 
--        to_char(date_created, 'DD.MM.YYYY') date_created
-- FROM   operations
-- ORDER BY operation_id;


-- Функция для формирования имени автора

CREATE OR REPLACE FUNCTION author_name(last_name TEXT, first_name TEXT, middle_name TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN last_name || ' ' || upper(left(first_name, 1)) || '.' ||
           CASE WHEN middle_name IS NOT NULL 
                THEN upper(left(middle_name, 1)) || '.' 
                ELSE '' 
           END;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION author_name(
--     last_name text,
--     first_name text,
--     middle_name text
-- ) RETURNS text
-- AS $$
-- SELECT last_name || ' ' ||
--        left(first_name, 1) || '.' ||
--        CASE WHEN middle_name != '' -- подразумевает NOT NULL
--            THEN ' ' || left(middle_name, 1) || '.'
--            ELSE ''
--        END;
-- $$ IMMUTABLE LANGUAGE sql;

-- Функция для формирования названия книги с авторами

CREATE OR REPLACE FUNCTION book_name(book_id INT, title TEXT)
RETURNS TEXT AS $$
DECLARE
    authors_list TEXT;
BEGIN
    SELECT string_agg(author_name(a.last_name, a.first_name, a.middle_name), ', ' ORDER BY ba.seq_num)
    INTO authors_list
    FROM authors AS a
    JOIN authorship AS ba ON a.author_id = ba.author_id
    WHERE ba.book_id = book_id;

    RETURN title || ' (' || COALESCE(authors_list, 'Нет авторов') || ')';
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION book_name(book_id integer, title text)
-- RETURNS text
-- AS $$
-- SELECT title || '. ' ||
--        string_agg(
--            author_name(a.last_name, a.first_name, a.middle_name), ', '
--            ORDER BY ash.seq_num
--        )
-- FROM   authors a
--        JOIN authorship ash ON a.author_id = ash.author_id
-- WHERE  ash.book_id = book_name.book_id;
-- $$ STABLE LANGUAGE sql;


-- Создание представления authors_v с использованием author_name

-- DROP VIEW IF EXISTS authors_v;
CREATE VIEW authors_v AS
SELECT author_id, author_name(last_name, first_name, middle_name) AS display_name
FROM authors
ORDER BY display_name;
-- CREATE OR REPLACE VIEW authors_v AS
-- SELECT a.author_id,
--        author_name(a.last_name, a.first_name, a.middle_name) AS display_name
-- FROM   authors a
-- ORDER BY display_name;

-- Создание представления catalog_v с использованием book_name

-- DROP VIEW IF EXISTS catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id, book_name(b.book_id, b.title) AS display_name
FROM books b
ORDER BY display_name;
-- CREATE VIEW catalog_v AS
-- SELECT b.book_id,
--        book_name(b.book_id, b.title) AS display_name
-- FROM   books b
-- ORDER BY display_name;


-- Тест

-- INSERT INTO authors(last_name, first_name, middle_name) 
--     VALUES ('Пушкин', 'Александр', 'Сергеевич');

-- SELECT last_name, first_name, middle_name, count(*)
-- FROM authors
-- GROUP BY last_name, first_name, middle_name;
 

-- Продецура для устранения возможных дубликатов авторов

CREATE OR REPLACE PROCEDURE authors_dedup()
AS $$
    DELETE FROM authors
    WHERE author_id IN (
        SELECT author_id 
        FROM (
            SELECT author_id,
                   row_number() OVER (
                    PARTITION BY first_name, last_name, middle_name
                    ORDER BY author_id
                   ) AS rn
            FROM authors
        ) t
        WHERE t.rn > 1
    );
$$ LANGUAGE sql;

-- Тест

-- CALL authors_dedup();

-- SELECT last_name, first_name, middle_name, count(*)
-- FROM authors
-- GROUP BY last_name, first_name, middle_name;


-- Индекс как ограничение целостности (отчество может быть неопределенным), вместо процедуры authors_dedup

CREATE UNIQUE INDEX authors_full_name_idx ON authors(
    last_name, first_name, coalesce(middle_name,'')
);

-- Тест

-- INSERT INTO authors(last_name, first_name)
--     VALUES ('Свифт', 'Джонатан');

-- INSERT INTO authors(last_name, first_name, middle_name)
--     VALUES ('Пушкин', 'Александр', 'Сергеевич');


-- Функция для подсчета имеющихся в наличии книг

CREATE OR REPLACE FUNCTION onhand_qty(book books)
RETURNS INT AS $$
    SELECT coalesce(sum(o.qty_change),0)::integer
    FROM operations o
    WHERE o.book_id = book.book_id
$$ LANGUAGE sql;
-- CREATE OR REPLACE FUNCTION onhand_qty(book books) RETURNS integer
-- AS $$
--     SELECT coalesce(sum(o.qty_change),0)::integer
--     FROM operations o
--     WHERE o.book_id = book.book_id;
-- $$ STABLE LANGUAGE sql;


-- Создание представления catalog_v с использованием onhand_qty

-- DROP VIEW IF EXISTS catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       book_name(b.book_id, b.title) AS display_name,
       b.onhand_qty
FROM books b
ORDER BY display_name;


-- Функция для поиска авторов

CREATE OR REPLACE FUNCTION authors(book books) 
RETURNS TEXT AS $$
    SELECT string_agg(
        a.last_name || ' ' ||
        a.first_name ||
        coalesce(' ' || nullif(a.middle_name,''), ''), ', '
        ORDER BY ba.seq_num
    )
    FROM authors a
    JOIN authorship ba ON a.author_id = ba.author_id
    WHERE ba.book_id = book.book_id;
$$ LANGUAGE sql;
-- CREATE OR REPLACE FUNCTION authors(book books) RETURNS text
-- AS $$
--     SELECT string_agg(
--                a.last_name ||
--                ' ' ||
--                a.first_name ||
--                coalesce(' ' || nullif(a.middle_name,''), ''),
--                ', ' 
--                ORDER BY ash.seq_num
--            )
--     FROM   authors a
--            JOIN authorship ash ON a.author_id = ash.author_id
--     WHERE  ash.book_id = book.book_id;
-- $$ STABLE LANGUAGE sql;

-- Создание представления catalog_v с использованием полного списка авторов

-- DROP VIEW catalog_v;
CREATE VIEW catalog_v AS
SELECT b.book_id,
       b.title,
       onhand_qty,
       book_name(b.book_id, b.title) AS display_name,
       authors
FROM   books b
ORDER BY display_name;


-- Функция для поиска книг get_catalog теперь использует расширенное представление

CREATE OR REPLACE FUNCTION get_catalog(author_name TEXT, book_title TEXT, in_stock BOOLEAN)
RETURNS TABLE(book_id INT, display_name TEXT, onhand_qty INT)
AS $$
    SELECT cv.book_id, 
           cv.display_name,
           cv.onhand_qty
    FROM   catalog_v cv
    WHERE  cv.title   ILIKE '%'||coalesce(book_title,'')||'%'
        AND cv.authors ILIKE '%'||coalesce(author_name,'')||'%'
        AND (in_stock AND cv.onhand_qty > 0 OR in_stock IS NOT TRUE)
    ORDER BY display_name;
$$ LANGUAGE sql;
-- CREATE OR REPLACE FUNCTION get_catalog(
--     author_name text, 
--     book_title text, 
--     in_stock boolean
-- )
-- RETURNS TABLE(book_id integer, display_name text, onhand_qty integer)
-- AS $$
--     SELECT cv.book_id, 
--            cv.display_name,
--            cv.onhand_qty
--     FROM   catalog_v cv
--     WHERE  cv.title   ILIKE '%'||coalesce(book_title,'')||'%'
--     AND    cv.authors ILIKE '%'||coalesce(author_name,'')||'%'
--     AND    (in_stock AND cv.onhand_qty > 0 OR in_stock IS NOT TRUE)
--     ORDER BY display_name;
-- $$ STABLE LANGUAGE sql;


-- Функция для укорачивания названия

CREATE OR REPLACE FUNCTION shorten(
    s TEXT,
    max_len INT DEFAULT 45,
    suffix TEXT DEFAULT '...'
)
RETURNS TEXT AS $$
DECLARE
    suffix_len INT := length(suffix);
BEGIN
    RETURN CASE WHEN length(s) > max_len
           THEN left(s, max_len - suffix_len) || suffix
           ELSE s
    END;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION shorten(
--     s text,
--     max_len integer DEFAULT 45,
--     suffix text DEFAULT '...'
-- )
-- RETURNS text AS $$
-- DECLARE
--     suffix_len integer := length(suffix);
-- BEGIN
--     RETURN CASE WHEN length(s) > max_len
--         THEN left(s, max_len - suffix_len) || suffix
--         ELSE s
--     END;
-- END;
-- $$ IMMUTABLE LANGUAGE plpgsql;

-- Тест

-- SELECT shorten(
--     'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'
-- );


-- Функция для формирования названия книги с авторами

CREATE OR REPLACE FUNCTION book_name(book_id INT, title TEXT)
RETURNS TEXT AS $$
    SELECT shorten(book_name.title) || '. ' ||
        string_agg(
            author_name(a.last_name, a.first_name, a.middle_name), ', '
            ORDER BY ba.seq_num
        )
    FROM   authors a
    JOIN authorship ba ON a.author_id = ba.author_id
    WHERE  ba.book_id = book_name.book_id;
$$ LANGUAGE sql;
-- CREATE OR REPLACE FUNCTION book_name(book_id integer, title text)
-- RETURNS text
-- AS $$
-- SELECT shorten(book_name.title) || 
--        '. ' ||
--        string_agg(
--            author_name(a.last_name, a.first_name, a.middle_name), ', '
--            ORDER BY ash.seq_num
--        )
-- FROM   authors a
--        JOIN authorship ash ON a.author_id = ash.author_id
-- WHERE  ash.book_id = book_name.book_id;
-- $$ STABLE LANGUAGE sql;


-- Функция для укорачивания названия по словам

CREATE OR REPLACE FUNCTION shorten(
    s TEXT,
    max_len INT DEFAULT 45,
    suffix TEXT DEFAULT '...'
)
RETURNS TEXT AS $$
DECLARE
    suffix_len INT := length(suffix);
    short TEXT := suffix;
    pos INT;
BEGIN
    IF length(s) < max_len 
    THEN RETURN s;
    END IF;
    FOR pos in 1 .. least(max_len-suffix_len+1, length(s))
    LOOP
        IF substr(s,pos-1,1) != ' ' AND substr(s,pos,1) = ' ' 
        THEN short := left(s, pos-1) || suffix;
        END IF;
    END LOOP;
    RETURN short;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION shorten(
--     s text,
--     max_len integer DEFAULT 45,
--     suffix text DEFAULT '...'
-- )
-- RETURNS text
-- AS $$
-- DECLARE
--     suffix_len integer := length(suffix);
--     short text := suffix;
--     pos integer;
-- BEGIN
--     IF length(s) < max_len THEN
--         RETURN s;
--     END IF;
--     FOR pos in 1 .. least(max_len-suffix_len+1, length(s))
--     LOOP
--         IF substr(s,pos-1,1) != ' ' AND substr(s,pos,1) = ' ' THEN
--             short := left(s, pos-1) || suffix;
--         END IF;
--     END LOOP;
--     RETURN short;
-- END;
-- $$ IMMUTABLE LANGUAGE plpgsql;

-- Тест

-- SELECT shorten(
--     'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей'
-- );

-- SELECT shorten(
--     'Путешествия в некоторые удаленные страны мира в четырех частях: сочинение Лемюэля Гулливера, сначала хирурга, а затем капитана нескольких кораблей',
--     30
-- );


-- Функция для добавления новых авторов

CREATE OR REPLACE FUNCTION add_author(last_name TEXT, first_name TEXT, middle_name TEXT) 
RETURNS INT AS $$
DECLARE
    author_id INT;
BEGIN
    INSERT INTO authors(last_name, first_name, middle_name)
        VALUES (last_name, first_name, middle_name)
        RETURNING authors.author_id INTO author_id;
    RETURN author_id;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION add_author(
--     last_name text, 
--     first_name text, 
--     middle_name text
-- ) RETURNS integer
-- AS $$
-- DECLARE
--     author_id integer;
-- BEGIN
--     INSERT INTO authors(last_name, first_name, middle_name)
--         VALUES (last_name, first_name, middle_name)
--         RETURNING authors.author_id INTO author_id;
--     RETURN author_id;
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;


-- Функция для для покупки книги

CREATE OR REPLACE FUNCTION buy_book(book_id INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO operations(book_id, qty_change)
        VALUES (book_id, -1);
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION buy_book(book_id integer)
-- RETURNS void
-- AS $$
-- BEGIN
--     INSERT INTO operations(book_id, qty_change)
--         VALUES (book_id, -1);
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;


-- Функция для формирования названия книги только с первыми двумя авторами

--функция меняет сигнатуру, необходимо удалить
DROP FUNCTION book_name(INT,TEXT) CASCADE;

--функция
CREATE OR REPLACE FUNCTION book_name(book_id INT, title TEXT, maxauthors INT DEFAULT 2)
RETURNS TEXT AS $$
DECLARE
    r record;
    res TEXT;
BEGIN
    res := shorten(title) || '. ';
    FOR r IN (
        SELECT a.last_name, a.first_name, a.middle_name, ba.seq_num
        FROM   authors a
        JOIN authorship ba ON a.author_id = ba.author_id
        WHERE  ba.book_id = book_name.book_id
        ORDER BY ba.seq_num
    )
    LOOP
        EXIT WHEN r.seq_num > maxauthors;
        res := res || author_name(r.last_name, r.first_name, r.middle_name) || ', ';
    END LOOP;
    res := rtrim(res, ', ');
    IF r.seq_num > maxauthors 
    THEN res := res || ' и др.';
    END IF;
    RETURN res;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION book_name(
--     book_id integer, 
--     title text, 
--     maxauthors integer DEFAULT 2
-- )
-- RETURNS text
-- AS $$
-- DECLARE
--     r record;
--     res text;
-- BEGIN
--     res := shorten(title) || '. ';
--     FOR r IN (
--         SELECT a.last_name, a.first_name, a.middle_name, ash.seq_num
--         FROM   authors a
--                JOIN authorship ash ON a.author_id = ash.author_id
--         WHERE  ash.book_id = book_name.book_id
--         ORDER BY ash.seq_num
--     )
--     LOOP
--         EXIT WHEN r.seq_num > maxauthors;
--         res := res || author_name(r.last_name, r.first_name, r.middle_name) || ', ';
--     END LOOP;
--     res := rtrim(res, ', ');
--     IF r.seq_num > maxauthors THEN
--         res := res || ' и др.';
--     END IF;
--     RETURN res;
-- END;
-- $$ STABLE LANGUAGE plpgsql;


-- необходимо пересоздать
CREATE VIEW catalog_v AS
SELECT b.book_id,
       b.title,
       b.onhand_qty,
       book_name(b.book_id, b.title) AS display_name,
       b.authors
FROM   books b
ORDER BY display_name;


-- (для справки) Функция book_name на декларативном SQL

-- CREATE OR REPLACE FUNCTION book_name(
--     book_id integer, 
--     title text, 
--     maxauthors integer DEFAULT 2
-- )
-- RETURNS text 
-- AS $$
-- SELECT shorten(book_name.title) ||
--        '. ' || 
--        string_agg(
--            author_name(a.last_name, a.first_name, a.middle_name), ', '
--            ORDER BY ash.seq_num
--        ) FILTER (WHERE ash.seq_num <= maxauthors) ||
--        CASE
--            WHEN max(ash.seq_num) > maxauthors THEN ' и др.'
--            ELSE ''
--        END
-- FROM   authors a
--        JOIN authorship ash ON a.author_id = ash.author_id
-- WHERE  ash.book_id = book_name.book_id;
-- $$ STABLE LANGUAGE sql;

-- Тест

--SELECT book_id, display_name FROM catalog_v;


-- Функция для поиска книг get_catalog теперь использует динамический запрос в catalog_v

CREATE OR REPLACE FUNCTION get_catalog(author_name TEXT, book_title TEXT, in_stock BOOLEAN)
RETURNS 
    TABLE(book_id INT, display_name TEXT, onhand_qty INT) AS $$
DECLARE
    title_cond TEXT := '';
    author_cond TEXT := '';
    qty_cond TEXT := '';
BEGIN
    IF book_title != '' 
    THEN title_cond := format(
                    ' AND cv.title ILIKE %L', '%'||book_title||'%'
                    );
    END IF;
    IF author_name != '' 
    THEN author_cond := format(
                    ' AND cv.authors ILIKE %L', '%'||author_name||'%'
                    );
    END IF;
    IF in_stock 
    THEN qty_cond := ' AND cv.onhand_qty > 0';
    END IF;
    RETURN QUERY EXECUTE 'SELECT cv.book_id, cv.display_name, cv.onhand_qty
                          FROM catalog_v cv
                          WHERE true
                          '|| title_cond || author_cond || qty_cond || '
                          ORDER BY display_name';
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION get_catalog(
--     author_name text, 
--     book_title text,
--     in_stock boolean
-- )
-- RETURNS TABLE(book_id integer, display_name text, onhand_qty integer)
-- AS $$
-- DECLARE
--     title_cond text := '';
--     author_cond text := '';
--     qty_cond text := '';
-- BEGIN
--     IF book_title != '' THEN
--         title_cond := format(
--             ' AND cv.title ILIKE %L', '%'||book_title||'%'
--         );
--     END IF;
--     IF author_name != '' THEN
--         author_cond := format(
--             ' AND cv.authors ILIKE %L', '%'||author_name||'%'
--         );
--     END IF;
--     IF in_stock THEN
--         qty_cond := ' AND cv.onhand_qty > 0';
--     END IF;
--     RETURN QUERY EXECUTE '
--         SELECT cv.book_id, 
--                cv.display_name,
--                cv.onhand_qty
--         FROM   catalog_v cv
--         WHERE  true'
--         || title_cond || author_cond || qty_cond || '
--         ORDER BY display_name';
-- END;
-- $$ STABLE LANGUAGE plpgsql;


-- Функция для добавления новой книги

CREATE OR REPLACE FUNCTION add_book(title TEXT, authors INT[])
RETURNS INT AS $$
DECLARE
    book_id INT;
    id INT;
    seq_num INT := 1;
BEGIN
    INSERT INTO books(title) VALUES(title)
        RETURNING books.book_id INTO book_id;
    FOREACH id IN ARRAY authors 
    LOOP
        INSERT INTO authorship(book_id, author_id, seq_num) VALUES (book_id, id, seq_num);
        seq_num := seq_num + 1;
    END LOOP;
    RETURN book_id;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION add_book(title text, authors integer[])
-- RETURNS integer
-- AS $$
-- DECLARE
--     book_id integer;
--     id integer;
--     seq_num integer := 1;
-- BEGIN
--     INSERT INTO books(title)
--         VALUES(title)
--         RETURNING books.book_id INTO book_id;
--     FOREACH id IN ARRAY authors LOOP
--         INSERT INTO authorship(book_id, author_id, seq_num)
--             VALUES (book_id, id, seq_num);
--         seq_num := seq_num + 1;
--     END LOOP;
--     RETURN book_id;
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;


-- Функция для добавления новой книги c обработкой ошибки уникальности

CREATE OR REPLACE FUNCTION add_book(title TEXT, authors INT[])
RETURNS INT AS $$
DECLARE
    book_id INT;
    id INT;
    seq_num INT := 1;
BEGIN
    INSERT INTO books(title) VALUES(title)
        RETURNING books.book_id INTO book_id;
    FOREACH id IN ARRAY authors 
    LOOP
        INSERT INTO authorship(book_id, author_id, seq_num) VALUES (book_id, id, seq_num);
        seq_num := seq_num + 1;
    END LOOP;
    RETURN book_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Один и тот же автор не может быть указан дважды';
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION add_book(title text, authors integer[])
-- RETURNS integer
-- AS $$
-- DECLARE
--     book_id integer;
--     id integer;
--     seq_num integer := 1;
-- BEGIN
--     INSERT INTO books(title)
--         VALUES(title)
--         RETURNING books.book_id INTO book_id;
--     FOREACH id IN ARRAY authors LOOP
--         INSERT INTO authorship(book_id, author_id, seq_num)
--             VALUES (book_id, id, seq_num);
--         seq_num := seq_num + 1;
--     END LOOP;
--     RETURN book_id;
-- EXCEPTION
--     WHEN unique_violation THEN
--         RAISE EXCEPTION 'Один и тот же автор не может быть указан дважды';
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;

-- Тест

-- SELECT bookstore.add_book('PostgreSQL for Developers', ARRAY[1, 3]);

-- SELECT bookstore.add_book('Database Design', ARRAY[4]);


-- Триггер для обновления каталога

CREATE OR REPLACE FUNCTION update_catalog() 
RETURNS trigger AS $$
BEGIN
    INSERT INTO operations(book_id, qty_change) 
    VALUES (OLD.book_id, NEW.onhand_qty - coalesce(OLD.onhand_qty,0));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_catalog_trigger
INSTEAD OF UPDATE ON catalog_v
FOR EACH ROW
EXECUTE FUNCTION update_catalog();

-- CREATE OR REPLACE FUNCTION update_catalog() RETURNS trigger
-- AS $$
-- BEGIN
--     INSERT INTO operations(book_id, qty_change) VALUES
--         (OLD.book_id, NEW.onhand_qty - coalesce(OLD.onhand_qty,0));
--     RETURN NEW;
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;

-- CREATE TRIGGER update_catalog_trigger
-- INSTEAD OF UPDATE ON catalog_v
-- FOR EACH ROW
-- EXECUTE FUNCTION update_catalog();


-- Исправляем количество книг на складе (не может быть отрицательным)

-- добавим поле наличного количества

ALTER TABLE books ADD COLUMN onhand_qty integer;

-- триггер на вставку для обновления количества

CREATE OR REPLACE FUNCTION update_onhand_qty() 
RETURNS trigger AS $$
BEGIN
    UPDATE books
    SET onhand_qty = onhand_qty + NEW.qty_change
    WHERE book_id = NEW.book_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION update_onhand_qty() RETURNS trigger
-- AS $$
-- BEGIN
--     UPDATE books
--     SET onhand_qty = onhand_qty + NEW.qty_change
--     WHERE book_id = NEW.book_id;
--     RETURN NULL;
-- END;
-- $$ VOLATILE LANGUAGE plpgsql;

-- добавим ограничения на поле наличного количества и триггер

BEGIN;
LOCK TABLE operations;

UPDATE books b
SET onhand_qty = (
    SELECT coalesce(sum(qty_change),0)
    FROM operations o
    WHERE o.book_id = b.book_id
);

ALTER TABLE books ALTER COLUMN onhand_qty SET DEFAULT 0;
ALTER TABLE books ALTER COLUMN onhand_qty SET NOT NULL;

COMMIT;

UPDATE bookstore.books
SET onhand_qty=1
WHERE onhand_qty IS NULL;

BEGIN;
LOCK TABLE operations;

ALTER TABLE books ADD CHECK(onhand_qty >= 0);

CREATE TRIGGER update_onhand_qty_trigger
AFTER INSERT ON operations
FOR EACH ROW
EXECUTE FUNCTION update_onhand_qty();

COMMIT;

-- необходимо пересоздать представление catalog_v

-- DROP VIEW catalog_v;
CREATE OR REPLACE VIEW catalog_v AS
SELECT b.book_id,
       b.title,
       b.onhand_qty,
       book_name(b.book_id, b.title) AS display_name,
       b.authors
FROM   books b
ORDER BY display_name;

-- удалить функцию 

DROP FUNCTION onhand_qty(books);

-- Тест

--SELECT * FROM catalog_v WHERE book_id = 1;
--INSERT INTO operations(book_id, qty_change) VALUES (1,+10);

--SELECT * FROM catalog_v WHERE book_id = 1;
--INSERT INTO operations(book_id, qty_change) VALUES (1,-100);


-- Функция записывает текст запроса в журнал сообщений сервера

CREATE OR REPLACE FUNCTION get_catalog(author_name TEXT, book_title TEXT, in_stock BOOLEAN)
RETURNS TABLE(book_id INT, display_name TEXT, onhand_qty INT) AS $$
DECLARE
    title_cond TEXT := '';
    author_cond TEXT := '';
    qty_cond TEXT := '';
    cmd TEXT := '';
BEGIN
    IF book_title != '' 
    THEN title_cond := format(' AND cv.title ILIKE %L', '%'||book_title||'%');
    END IF;
    IF author_name != '' 
    THEN author_cond := format(' AND cv.authors ILIKE %L', '%'||author_name||'%');
    END IF;
    IF in_stock 
    THEN qty_cond := ' AND cv.onhand_qty > 0';
    END IF;
    cmd := 'SELECT cv.book_id, cv.display_name, cv.onhand_qty
            FROM catalog_v cv
            WHERE true' || title_cond || author_cond || qty_cond || '
            ORDER BY display_name';
    RAISE LOG 'DEBUG get_catalog (%, %, %): %', author_name, book_title, in_stock, cmd;
    RETURN QUERY 
      EXECUTE cmd;
END;
$$ LANGUAGE plpgsql;
-- CREATE OR REPLACE FUNCTION get_catalog(
--     author_name text,
--     book_title text,
--     in_stock boolean
-- )
-- RETURNS TABLE(book_id integer, display_name text, onhand_qty integer)
-- AS $$
-- DECLARE
--     title_cond text := '';
--     author_cond text := '';
--     qty_cond text := '';
--     cmd text := '';
-- BEGIN
--     IF book_title != '' THEN
--         title_cond := format(
--             ' AND cv.title ILIKE %L', '%'||book_title||'%'
--         );
--     END IF;
--     IF author_name != '' THEN
--         author_cond := format(
--             ' AND cv.authors ILIKE %L', '%'||author_name||'%'
--         );
--     END IF;
--     IF in_stock THEN
--         qty_cond := ' AND cv.onhand_qty > 0';
--     END IF;
--     cmd := '
--         SELECT cv.book_id, 
--                cv.display_name,
--                cv.onhand_qty
--         FROM   catalog_v cv
--         WHERE  true'
--         || title_cond || author_cond || qty_cond || '
--         ORDER BY display_name';

--     RAISE LOG 'DEBUG get_catalog (%, %, %): %',
--         author_name, book_title, in_stock, cmd;
--     RETURN QUERY EXECUTE cmd;
-- END;
-- $$ STABLE LANGUAGE plpgsql;


-- (для справки) включить трассировку всех запросов на уровне сервера

-- ALTER SYSTEM SET log_min_duration_statement = 0;
-- SELECT pg_reload_conf();

-- ALTER SYSTEM RESET log_min_duration_statement;
-- SELECT pg_reload_conf();


-- Роль сотрудник магазина

CREATE ROLE employee LOGIN PASSWORD 'employee';

-- Роль покупатель

CREATE ROLE buyer LOGIN PASSWORD 'buyer';

-- Разграничение доступа

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA bookstore FROM public;

REVOKE CONNECT ON DATABASE bookstore FROM public;

-- владелец

ALTER FUNCTION get_catalog(text,text,boolean) SECURITY DEFINER;

ALTER FUNCTION update_catalog() SECURITY DEFINER;

ALTER FUNCTION add_author(text,text,text) SECURITY DEFINER;

ALTER FUNCTION add_book(text,integer[]) SECURITY DEFINER;

ALTER FUNCTION buy_book(integer) SECURITY DEFINER;

ALTER FUNCTION book_name(integer,text,integer) SECURITY DEFINER;

ALTER FUNCTION authors(books) SECURITY DEFINER;

-- сотрудник

GRANT CONNECT ON DATABASE bookstore TO employee;

GRANT USAGE ON SCHEMA bookstore TO employee;

GRANT SELECT,UPDATE(onhand_qty) ON catalog_v TO employee;

GRANT SELECT ON authors_v TO employee;

GRANT EXECUTE ON FUNCTION book_name(integer,text,integer) TO employee;

GRANT EXECUTE ON FUNCTION authors(books) TO employee;

GRANT EXECUTE ON FUNCTION author_name(text,text,text) TO employee;

GRANT EXECUTE ON FUNCTION add_book(text,integer[]) TO employee;

GRANT EXECUTE ON FUNCTION add_author(text,text,text) TO employee;

-- покупатель 

GRANT CONNECT ON DATABASE bookstore TO buyer;

GRANT USAGE ON SCHEMA bookstore TO buyer;

GRANT EXECUTE ON FUNCTION get_catalog(text,text,boolean) TO buyer;

GRANT EXECUTE ON FUNCTION buy_book(integer) TO buyer;


-- Резервная копия базы данных (shell)

./pg_dump --format=custom -d bookstore > /tmp/bookstore.custom

-- Тест

-- DELETE FROM authorship;

-- Восстановление данных таблицы authorship (shell)

./pg_restore -t authorship --data-only -d bookstore /tmp/bookstore.custom

-- Тест

-- SELECT count(*) FROM authorship;




