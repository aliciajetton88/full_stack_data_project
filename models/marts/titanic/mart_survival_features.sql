with age_median as 
    (
    select
    passenger_id
    , PERCENTILE_CONT(age, 0.5) OVER() AS median
    from {{ref ('stg_titanic_training')}}
    limit 1
    )
, embarked_mode as 
    (
    select
    embarked
    , count(*) as total
    from {{ref ('stg_titanic_training')}}
    where embarked is not null
    group by 1
    qualify row_number() over (order by total desc) = 1
    )  

SELECT 
t.passenger_id
, t.survived
, t.pclass
, t.name
, t.sex
, coalesce(t.age, am.median) as age
, t.sibsp
, t.parch
, t.ticket
, t.fare
-- , t.cabin # drop because too many nulls
, coalesce(t.embarked, em.embarked) as embarked
FROM {{ref ('stg_titanic_training')}} t
CROSS JOIN age_median am
CROSS JOIN embarked_mode em
where t.passenger_id is not null 