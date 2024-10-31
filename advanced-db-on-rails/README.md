# Run SQL from rails console

```ruby
connection = ActiveRecord::Base.connection
sql = 'SELECT * FROM employees'
esql = "EXPLAIN(ANALYZE, VERBOSE, BUFFERS) #{sql}"
connection.exec_query(esql)
```

---

not all method user Method chaining
 `Employee.average(:salary)`
execute the query and return a result, while other methods implement Method Chaining,

```ruby
# bad - executes average
Employee.where('salary > :avg', avg: Employee.average(:salary))
# "SELECT \"employees\".* FROM \"employees\" WHERE (salary > 97422.02)"
# good
Employee.where('salary > (:avg)', avg: Employee.select('avg(salary)'))
# "SELECT \"employees\".* FROM \"employees\" WHERE (salary > (SELECT avg(salary) FROM \"employees\"))"
```

---

We would like to encourage employees to have a
healthy work-life balance, and were hoping you
could provide us with a list of all the employees
who have yet to take any vacation time.

```ruby
Employee.where(
  'NOT EXISTS (:vacations)',
  vacations: Vacation.select('1').where('employees.id = vacations.employee_id')
)
```

---

Could you please provide us with a list of
employees, including the average salary of a
BCE employee, and how much this employee‘s
salary differs from the average?

```ruby

avg_sql = Employee.select('avg(salary)').to_sql

Employee.select(
  '*',
  "(#{avg_sql}) avg_salary",
  "salary - (#{avg_sql}) avg_difference"
)
# SELECT *, 
# (SELECT avg(salary) FROM \"employees\") avg_salary,
# salary - (SELECT avg(salary) FROM \"employees\") avg_difference
# FROM \"employees\"
```

## window functions

```ruby
Employee.select(
 '*',
 "avg(salary) OVER () avg_salary",
 "salary - avg(salary) OVER () avg_difference"
)
```

---

We‘d like to know the average performance
review score given across all our managers.
(average of those averages) =>  aggregate of aggregates

```ruby


```
