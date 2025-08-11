select
  cast(PassengerId as int64) as passenger_id
  , cast(Survived as int64) as survived
  , cast(Pclass as int64) as pclass
  , Name as name
  , Sex as sex
  , cast(Age as float64)  as age
  , SibSp as sibsp
  , Parch as parch
  , Ticket as ticket
  , Fare as fare
  , Cabin as cabin
  , Embarked as embarked
from {{ source('raw_titanic', 'titanic_survival_training') }}
