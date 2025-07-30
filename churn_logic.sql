select user_id, date, churned
from user_activity a
left join users b on a.user_id = b.id
where churned = true
order by date desc
limit 100;