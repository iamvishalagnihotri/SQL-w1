-- Week 1 SQL practice: schema, sample data, and solutions.
-- Dialect: SQLite 3.25+ (window functions are used in problem 4).

PRAGMA foreign_keys = ON;

CREATE TABLE Employee (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    salary INTEGER NOT NULL,
    managerId INTEGER REFERENCES Employee(id)
);

INSERT INTO Employee (id, name, salary, managerId) VALUES
    (1, 'Ava', 120000, NULL),
    (2, 'Ben', 90000, 1),
    (3, 'Cara', 85000, 1),
    (4, 'Dan', 80000, 1),
    (5, 'Eli', 75000, 1),
    (6, 'Faye', 70000, 1),
    (7, 'Gus', 90000, 2),
    (8, 'Hana', 60000, 2);

CREATE TABLE Request (
    requester_id INTEGER NOT NULL,
    accepter_id INTEGER NOT NULL,
    accept_date TEXT NOT NULL,
    PRIMARY KEY (requester_id, accepter_id)
);

INSERT INTO Request (requester_id, accepter_id, accept_date) VALUES
    (1, 2, '2020-01-01'),
    (1, 3, '2020-01-02'),
    (2, 3, '2020-01-03'),
    (3, 4, '2020-01-04'),
    (4, 1, '2020-01-05'),
    (5, 1, '2020-01-06');

CREATE TABLE Seat (
    id INTEGER PRIMARY KEY,
    student TEXT NOT NULL
);

INSERT INTO Seat (id, student) VALUES
    (1, 'Abbot'),
    (2, 'Doris'),
    (3, 'Emerson'),
    (4, 'Green'),
    (5, 'Jeames');

CREATE TABLE Product (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL
);

INSERT INTO Product (product_id, product_name) VALUES
    (1, 'Phone'),
    (2, 'Laptop'),
    (3, 'Headphones');

CREATE TABLE Customer (
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    PRIMARY KEY (customer_id, product_id)
);

INSERT INTO Customer (customer_id, product_id) VALUES
    (101, 1), (101, 2), (101, 3),
    (102, 1), (102, 2),
    (103, 1), (103, 2), (103, 3),
    (104, 3);

CREATE TABLE Users (
    user_id INTEGER PRIMARY KEY,
    join_date TEXT NOT NULL
);

INSERT INTO Users (user_id, join_date) VALUES
    (1, '2018-01-01'),
    (2, '2018-02-01'),
    (3, '2019-01-01'),
    (4, '2019-05-01');

CREATE TABLE Orders (
    order_id INTEGER PRIMARY KEY,
    buyer_id INTEGER NOT NULL REFERENCES Users(user_id),
    order_date TEXT NOT NULL
);

INSERT INTO Orders (order_id, buyer_id, order_date) VALUES
    (1, 1, '2019-01-15'),
    (2, 1, '2019-02-20'),
    (3, 2, '2018-12-31'),
    (4, 2, '2019-06-10'),
    (5, 3, '2020-01-01');

CREATE TABLE Login (
    user_id INTEGER NOT NULL,
    login_date TEXT NOT NULL
);

INSERT INTO Login (user_id, login_date) VALUES
    (1, '2020-06-30'),
    (1, '2020-07-01'),
    (2, '2020-06-29'),
    (2, '2020-07-10'),
    (3, '2020-04-01'),
    (4, '2020-03-31');

CREATE TABLE PriceChanges (
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    change_date TEXT NOT NULL,
    new_price INTEGER NOT NULL,
    PRIMARY KEY (product_id, change_date)
);

INSERT INTO PriceChanges (product_id, change_date, new_price) VALUES
    (1, '2019-08-14', 20),
    (1, '2019-08-16', 25),
    (2, '2019-08-17', 50),
    (3, '2019-08-10', 15);

CREATE TABLE Transactions (
    trans_id INTEGER PRIMARY KEY,
    country TEXT NOT NULL,
    state TEXT NOT NULL,
    amount INTEGER NOT NULL,
    trans_date TEXT NOT NULL
);

INSERT INTO Transactions (trans_id, country, state, amount, trans_date) VALUES
    (1, 'US', 'approved', 1000, '2019-01-01'),
    (2, 'US', 'declined', 2000, '2019-01-05'),
    (3, 'US', 'approved', 500, '2019-02-10'),
    (4, 'CA', 'approved', 700, '2019-01-15');

CREATE TABLE Chargebacks (
    chargeback_id INTEGER PRIMARY KEY,
    trans_id INTEGER NOT NULL REFERENCES Transactions(trans_id),
    chargeback_date TEXT NOT NULL
);

INSERT INTO Chargebacks (chargeback_id, trans_id, chargeback_date) VALUES
    (1, 1, '2019-01-10'),
    (2, 2, '2019-02-01');

CREATE TABLE Teams (
    team_id INTEGER PRIMARY KEY,
    team_name TEXT NOT NULL
);

INSERT INTO Teams (team_id, team_name) VALUES
    (10, 'Wolves'),
    (20, 'Falcons'),
    (30, 'Tigers'),
    (40, 'Bears');

CREATE TABLE Matches (
    match_id INTEGER PRIMARY KEY,
    host_team INTEGER NOT NULL REFERENCES Teams(team_id),
    guest_team INTEGER NOT NULL REFERENCES Teams(team_id),
    host_goals INTEGER NOT NULL,
    guest_goals INTEGER NOT NULL
);

INSERT INTO Matches (match_id, host_team, guest_team, host_goals, guest_goals) VALUES
    (1, 10, 20, 3, 0),
    (2, 30, 10, 1, 1),
    (3, 20, 30, 2, 2);

-- (1) Managers with at least five direct reports.
SELECT manager.name AS name
FROM Employee AS manager
JOIN Employee AS report ON report.managerId = manager.id
GROUP BY manager.id, manager.name
HAVING COUNT(*) >= 5;

-- (2) Nth highest distinct salary. Change n in the params CTE as needed.
-- The scalar subquery returns NULL when that rank does not exist.
WITH params(n) AS (VALUES (2))
SELECT (
    SELECT salary
    FROM (SELECT DISTINCT salary FROM Employee ORDER BY salary DESC)
    LIMIT 1 OFFSET (SELECT n - 1 FROM params)
) AS getNthHighestSalary;

-- (3) Person with the most accepted friends; each accepted request is mutual.
WITH friendships(person_id, friend_id) AS (
    SELECT requester_id, accepter_id FROM Request
    UNION ALL
    SELECT accepter_id, requester_id FROM Request
),
friend_counts AS (
    SELECT person_id, COUNT(*) AS num_friends
    FROM friendships
    GROUP BY person_id
)
SELECT person_id, num_friends
FROM friend_counts
ORDER BY num_friends DESC, person_id ASC
LIMIT 1;

-- (4) Swap each pair of adjacent students in seat order; leave an odd last seat.
WITH numbered_seats AS (
    SELECT id, student, ROW_NUMBER() OVER (ORDER BY id) AS position
    FROM Seat
)
SELECT id,
       CASE
           WHEN position % 2 = 1 THEN COALESCE(LEAD(student) OVER (ORDER BY id), student)
           ELSE LAG(student) OVER (ORDER BY id)
       END AS student
FROM numbered_seats
ORDER BY id;

-- (5) Customers who bought every product.
SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM Product)
ORDER BY customer_id;

-- (6) Each user's join date and their 2019 buyer-order count (including zero).
SELECT u.user_id,
       u.join_date,
       COUNT(o.order_id) AS orders_in_2019
FROM Users AS u
LEFT JOIN Orders AS o
    ON o.buyer_id = u.user_id
   AND o.order_date >= '2019-01-01'
   AND o.order_date < '2020-01-01'
GROUP BY u.user_id, u.join_date
ORDER BY u.user_id;

-- (7) First-login user count for each of the 90 calendar dates ending on today.
-- Change today in params; this sample uses 2020-06-30.
WITH RECURSIVE
params(today) AS (VALUES ('2020-06-30')),
date_window(login_date) AS (
    SELECT date(today, '-89 days') FROM params
    UNION ALL
    SELECT date(login_date, '+1 day')
    FROM date_window, params
    WHERE login_date < today
),
first_logins AS (
    SELECT user_id, MIN(login_date) AS first_login
    FROM Login
    GROUP BY user_id
)
SELECT date_window.login_date,
       COUNT(first_logins.user_id) AS user_count
FROM date_window
LEFT JOIN first_logins ON first_logins.first_login = date_window.login_date
GROUP BY date_window.login_date
ORDER BY date_window.login_date;

-- (8) Product price on the given date; use 10 before its first price change.
-- Change as_of_date in params; this sample uses 2019-08-16.
WITH params(as_of_date) AS (VALUES ('2019-08-16'))
SELECT p.product_id,
       COALESCE((
           SELECT pc.new_price
           FROM PriceChanges AS pc, params
           WHERE pc.product_id = p.product_id
             AND pc.change_date <= params.as_of_date
           ORDER BY pc.change_date DESC
           LIMIT 1
       ), 10) AS price
FROM Product AS p
ORDER BY p.product_id;

-- (9) Monthly, per-country approved transaction and chargeback counts/amounts.
WITH monthly_totals AS (
    SELECT strftime('%Y-%m', trans_date) AS month,
           country,
           COUNT(*) AS approved_count,
           SUM(amount) AS approved_amount,
           0 AS chargeback_count,
           0 AS chargeback_amount
    FROM Transactions
    WHERE state = 'approved'
    GROUP BY strftime('%Y-%m', trans_date), country
    UNION ALL
    SELECT strftime('%Y-%m', cb.chargeback_date) AS month,
           t.country,
           0 AS approved_count,
           0 AS approved_amount,
           COUNT(*) AS chargeback_count,
           SUM(t.amount) AS chargeback_amount
    FROM Chargebacks AS cb
    JOIN Transactions AS t ON t.trans_id = cb.trans_id
    GROUP BY strftime('%Y-%m', cb.chargeback_date), t.country
)
SELECT month,
       country,
       SUM(approved_count) AS approved_count,
       SUM(approved_amount) AS approved_amount,
       SUM(chargeback_count) AS chargeback_count,
       SUM(chargeback_amount) AS chargeback_amount
FROM monthly_totals
GROUP BY month, country
HAVING SUM(approved_count) + SUM(approved_amount)
     + SUM(chargeback_count) + SUM(chargeback_amount) > 0
ORDER BY month, country;

-- (10) Tournament points per team (win = 3, draw = 1, loss = 0).
WITH team_points AS (
    SELECT host_team AS team_id,
           CASE
               WHEN host_goals > guest_goals THEN 3
               WHEN host_goals = guest_goals THEN 1
               ELSE 0
           END AS points
    FROM Matches
    UNION ALL
    SELECT guest_team AS team_id,
           CASE
               WHEN guest_goals > host_goals THEN 3
               WHEN guest_goals = host_goals THEN 1
               ELSE 0
           END AS points
    FROM Matches
)
SELECT t.team_id,
       t.team_name,
       COALESCE(SUM(tp.points), 0) AS points
FROM Teams AS t
LEFT JOIN team_points AS tp ON tp.team_id = t.team_id
GROUP BY t.team_id, t.team_name
ORDER BY points DESC, t.team_id ASC;
