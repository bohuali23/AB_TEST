-- calculate the average days that one takes from application to complete their first batch. average_days = 8.58 days
WITH pt AS (
  SELECT
    applicant_id,
    MAX(
      CASE
        WHEN event = 'application_date' THEN event_date :: date
      END
    ) AS application_date,
    MAX(
      CASE
        WHEN event = 'first_batch_completed_date' THEN event_date :: date
      END
    ) AS first_batch_completed_date
  FROM
    application_table
  GROUP BY
    applicant_id
)
SELECT
  AVG((first_batch_completed_date - application_date)) AS average_days
FROM
  pt
WHERE
  first_batch_completed_date IS NOT NULL;

-- count the total applicants who applied no later than 2018-11-2.
WITH t1 AS (
  SELECT
    groups,
    event,
    count (DISTINCT applicant_id) AS total_applicants
  FROM
    application_table
  WHERE
    event = 'application_date'
    AND event_date :: date <= '2018-11-2'
  GROUP BY
    event,
    groups
  ORDER BY
    groups,
    total_applicants DESC
),
--count the total applicants who completed their first batch.
t2 AS (
  SELECT
    groups,
    event,
    count(DISTINCT applicant_id) AS completed_applicants
  FROM
    application_table
  WHERE
    event = 'first_batch_completed_date'
  GROUP BY
    groups,
    event
) 
-- calculate the conversion rate 
SELECT
  t.groups,
  t.total_applicants,
  c.completed_applicants,
  (
    c.completed_applicants :: decimal / t.total_applicants
  ) AS conversion_rate
FROM
  t1 t
  LEFT JOIN t2 c ON t.groups = c.groups
ORDER BY
  t.groups;

-- application route breakdown through channel.
WITH t1 AS (
  SELECT
    groups,
    channel,
    event,
    COUNT(DISTINCT applicant_id) AS n_applicants_completed_first_batch
  FROM
    application_table
  GROUP BY
    groups,
    channel,
    event
  ORDER BY
    groups,
    channel,
    n_applicants_completed_first_batch DESC
),
t2 AS (
  SELECT
    *,
    MAX(n_applicants_completed_first_batch) OVER (PARTITION BY groups, channel) AS n_applicants,
    1.0 * n_applicants_completed_first_batch / MAX(n_applicants_completed_first_batch) OVER (PARTITION BY groups, channel) AS cvr
  FROM
    t1
)
SELECT
  *
FROM
  t2
WHERE
  event = 'first_batch_completed_date';

-- cost effectve?
WITH t1 AS (
  SELECT
    groups,
    event,
    count (DISTINCT applicant_id) AS total_applicants
  FROM
    application_table
  WHERE
    event = 'background_check_initiated_date'
  GROUP BY
    event,
    groups
  ORDER BY
    groups,
    total_applicants DESC
),
t2 AS (
  SELECT
    groups,
    event,
    count(DISTINCT applicant_id) AS completed_applicants
  FROM
    application_table
  WHERE
    event = 'first_batch_completed_date'
  GROUP BY
    groups,
    event
) 
-- calculate cost-effective conversion rate.
SELECT
  t.groups,
  t.total_applicants,
  c.completed_applicants,
  (
    c.completed_applicants :: decimal / t.total_applicants
  ) AS conversion_rate
FROM
  t1 t
  LEFT JOIN t2 c ON t.groups = c.groups
ORDER BY
  t.groups;