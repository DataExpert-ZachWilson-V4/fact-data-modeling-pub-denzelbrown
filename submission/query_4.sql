WITH
  today AS ( 
    SELECT
      *
    FROM
      denzelbrown.user_devices_cumulated
    WHERE
      DATE = DATE('2023-01-07')
  ),
 date_list_int AS (
    SELECT
      user_id, browser_type,
      CAST(
        SUM(
          CASE
            WHEN CONTAINS(dates_active, sequence_date) THEN POW(2, 31 - DATE_DIFF('day', sequence_date, DATE))
            
            ELSE 0
          END
        ) AS BIGINT
      ) AS history_int
    FROM
      today
      CROSS JOIN UNNEST (SEQUENCE(DATE('2023-01-01'), DATE('2023-01-07'))) AS t (sequence_date) 
      
    GROUP BY
      user_id, browser_type
  )
SELECT
  *,
  TO_BASE(history_int, 2) AS history_in_binary, --convert the history_int to base 2 
  TO_BASE(
    FROM_BASE('11111110000000000000000000000000', 2), 
    2
  ) AS weekly_base,
  BIT_COUNT(
    BITWISE_AND(  --using bitwise AND function to compare history_int and the sequence. If the user is active, then that position will have 1 else 0
      history_int,
      FROM_BASE('11111110000000000000000000000000', 2) -- the user is active for a week 
    ),
    64
  ) > 0 AS is_weekly_active -- if the user is active at all during the week then they are weekly active
FROM
  date_list_int
