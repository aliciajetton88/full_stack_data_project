select user_id, date, churned
from user_activity
where churned = true
order by date desc
limit 100;