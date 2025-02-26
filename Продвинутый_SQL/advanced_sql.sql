-- Первая часть

-- 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT COUNT(id)
FROM stackoverflow.posts
WHERE post_type_id=1 
   AND (score>300 OR favorites_count >= 100)
GROUP BY post_type_id;

-- 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

WITH cnt AS (SELECT COUNT(id),
                     creation_date::date AS dt
              FROM stackoverflow.posts
              WHERE post_type_id = 1
              GROUP BY dt
              HAVING creation_date::date BETWEEN '2008-11-01' AND '2008-11-18')

SELECT ROUND(AVG(cnt.count))
FROM cnt;

-- 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.badges b
JOIN stackoverflow.users u ON b.user_id=u.id
WHERE b.creation_date::date=u.creation_date::date;

-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

WITH us AS (SELECT p.id
           FROM stackoverflow.posts p
           JOIN stackoverflow.votes v ON p.id = v.user_id
           JOIN stackoverflow.users u ON p.user_id = u.id
           WHERE u.display_name = 'Joel Coehoorn'
                 AND v.id>=1
            )

SELECT COUNT(DISTINCT us.id)
FROM us;

-- 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id.

SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

-- 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT v.user_id,
       COUNT(vt.id)
FROM stackoverflow.votes v
JOIN stackoverflow.vote_types vt ON v.vote_type_id=vt.id
JOIN stackoverflow.users u ON v.user_id=u.id
WHERE vt.name = 'Close'
GROUP BY v.user_id 
ORDER BY COUNT(vt.id) DESC, v.user_id DESC
LIMIT 10;
 
-- 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT user_id,
       COUNT(id),
       DENSE_RANK() OVER (ORDER BY COUNT(id) DESC)
FROM stackoverflow.badges 
WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15' 
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id
LIMIT 10;

-- 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.

SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL  
      AND score <> 0
GROUP BY title, user_id, score;

-- 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список.

WITH badges_cnt AS (SELECT b.user_id
                    FROM stackoverflow.badges b 
                    JOIN stackoverflow.users u ON b.user_id=u.id
                    GROUP BY b.user_id
                    HAVING COUNT(b.id) > 1000
                    )
SELECT p.title
FROM badges_cnt bc
JOIN stackoverflow.posts p ON bc.user_id=p.user_id
WHERE p.title IS NOT NULL;

-- 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
   -- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
   -- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
   -- пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.

SELECT id,
       views,
       CASE 
           WHEN views >= 350 THEN 1
           WHEN views < 100 THEN 3
           ELSE 2
       END AS group_number
FROM stackoverflow.users 
WHERE location LIKE '%Canada%'
      AND views > 0;

-- 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH group_us AS (SELECT id,
                         views,
                         CASE 
                             WHEN views >= 350 THEN 1
                             WHEN views < 100 THEN 3
                             ELSE 2
                         END AS group_number
                    FROM stackoverflow.users 
                    WHERE location LIKE '%Canada%'
                          AND views > 0),
    lider AS (SELECT *,
                   MAX(views) OVER(PARTITION BY group_number) AS max
            FROM group_us)
SELECT id,
       group_number,
       views
FROM lider
WHERE views = max
ORDER BY views DESC, id;

-- 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.

WITH new_user AS (SELECT EXTRACT(DAY FROM creation_date::date) AS day,
                         COUNT(id) AS us_cnt
                FROM stackoverflow.users
                WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
                GROUP BY day)
SELECT *,
       SUM(us_cnt) OVER (ORDER BY day)
FROM new_user;

-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.

WITH us_p AS (SELECT DISTINCT user_id,
                     MIN(creation_date) OVER(PARTITION BY user_id) AS min_date
              FROM stackoverflow.posts p)
SELECT u.id,
       (min_date - u.creation_date) AS result
FROM stackoverflow.users u
JOIN us_p ON u.id=us_p.user_id

-- Вторая часть

-- 1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров.

SELECT SUM(views_count),
       DATE_TRUNC('month', creation_date)::date AS month
FROM stackoverflow.posts
WHERE EXTRACT (YEAR FROM creation_date) = '2008'
GROUP BY month
ORDER BY SUM(views_count) DESC;

-- 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке.

SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id = u.id
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month')
      AND pt.type LIKE '%Answer%'
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name;

-- 3. Выведите количество постов за 2008 год по месяцам. 
Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию.

WITH us_p AS (SELECT u.id
            FROM stackoverflow.users u 
            JOIN stackoverflow.posts p ON u.id=p.user_id
            WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'
                  AND DATE_TRUNC('month', p.creation_date)::date = '2008-12-01'
          GROUP BY u.id)

SELECT COUNT(p.user_id),
       DATE_TRUNC('month', p.creation_date)::date AS month
FROM stackoverflow.posts p
WHERE EXTRACT (YEAR FROM p.creation_date) = '2008'
      AND p.user_id IN (SELECT *
                        FROM us_p)
GROUP BY month
ORDER BY month DESC;

-- 4. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts;

-- 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число.

WITH activ AS (SELECT user_id,
                      COUNT(DISTINCT creation_date::date) AS p_cnt
              FROM stackoverflow.posts
              WHERE creation_date BETWEEN '2008-12-01' AND '2008-12-07'
              GROUP BY user_id
              )
SELECT ROUND(AVG(p_cnt))
FROM activ;

-- 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.

WITH m_cnt AS (SELECT EXTRACT(MONTH FROM creation_date::date) AS month,
                      COUNT(id) AS count
                FROM stackoverflow.posts
                WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
                GROUP BY month)

SELECT *,
       ROUND(((count::numeric / LAG (count) OVER (ORDER BY month)) - 1) * 100,2)
FROM m_cnt;

-- 7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.

  WITH lid AS (SELECT user_id,
                    COUNT(DISTINCT id) AS p_cnt
            FROM stackoverflow.posts
            GROUP BY user_id
            ORDER BY p_cnt DESC
            LIMIT 1),
      p_dt AS (SELECT p.user_id,
                      p.creation_date,
                      EXTRACT(WEEK FROM p.creation_date) AS week
               FROM stackoverflow.posts p
               JOIN lid ON p.user_id=lid.user_id
               WHERE p.creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
              )

SELECT DISTINCT week,
       MAX(creation_date) OVER (PARTITION BY week)
FROM p_dt
ORDER BY week;
