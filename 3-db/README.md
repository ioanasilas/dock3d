# 3-DB

## Creation, queries, automation (bullets 1-5)
We need to pull the official PostgreSQL image:


```bash
docker pull postgres:latest
```

- For $1.$ I looked up the port Postgres uses which is 5432. And looked into the documentation on Dockerhub to find out how to create a new user etc.

```bash
docker run --name some-postgres \
  -e POSTGRES_DB=company_db \
  -e POSTGRES_USER=ituser \
  -e POSTGRES_PASSWORD=123 \
  -p 5432:5432 \
  -d postgres
```

- For $2.$ I copied the populating script inside the container:
```bash
docker cp populatedb.sql some-postgres:/populatedb.sql
Successfully copied 5.63kB to some-postgres:/populatedb.sql
docker exec -u postgres some-postgres psql -U ituser -d company_db -f /populatedb.sql
psql:/populatedb.sql:2: ERROR:  syntax error at or near "USE"
LINE 1: USE company_db;
        ^
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 8
INSERT 0 53
psql:/populatedb.sql:185: ERROR:  insert or update on table "salaries" violates foreign key constraint "salaries_employee_id_fkey"
DETAIL:  Key (employee_id)=(54) is not present in table "employees".
```
Problems:
- `USE company_db;` is SQL syntax -- we comment it out
- there are 0 to 53 employees -- trying to insert salaries for employees with IDs over 53 will fail; we comment those lines out

We remove the container, start over and now we have a populated DB with no errors:
```bash
docker rm -f some-postgres
docker run --name some-postgres   -e POSTGRES_DB=company_db   -e POSTGRES_USER=ituser   -e POSTGRES_PASSWORD=123   -p 5432:5432   -d postgres
A18404dcebcb8a2062aa2a380bc4688a740ce8b724695bec4be9b81a60f7a4a1b
docker cp populatedb.sql some-postgres:/populatedb.sql
Successfully copied 5.63kB to some-postgres:/populatedb.sql
docker exec -u postgres some-postgres psql -U ituser -d company_db -f /populatedb.sql
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 8
INSERT 0 53
INSERT 0 53

```
- For $3.$ we need to go inside the container:
```bash
docker exec -it some-postgres sh
```
and open `psql`:
```bash
psql -U ituser -d company_db
```

### Queries
**First:**
```sql
company_db=# select count(*) from employees;
 count 
-------
    53
(1 row)

```

**Second:**

Here we need to do two things:
- prompt for user input
- perform a join on two tables to be able to associate employees with departments based on the department ID and then retrieve the names
```sql
company_db=# \prompt 'Enter dept name: ' dept
Enter dept name: Finance
company_db=# select e.first_name, e.last_name from employees e join departments d on e.department_id = d.department_id where d.department_name = :'dept';
 first_name | last_name 
------------+-----------
 David      | Williams
 Isaac      | Thomas
 Jack       | White
 Grace      | Robinson
 Daniel     | Scott
 Victoria   | Lopez
(6 rows)
```

**Third:**

Here we will do a join on three tables since we need data from `employees`, `departments` and `salaries`.

```sql
select 
    d.department_name, 
    MAX(s.salary) as max_sal, 
    MIN(s.salary) as min_sal 
from departments d 
join employees e on d.department_id = e.department_id 
join salaries s on e.employee_id = s.employee_id 
group by d.department_name;
```

and we get:
```sql
 department_name  |  max_sal  |  min_sal  
------------------+-----------+-----------
 Customer Support | 119000.00 | 109000.00
 Marketing        |  91000.00 |  78000.00
 Operations       | 131000.00 | 121000.00
 Sales            | 107000.00 |  93000.00
 Legal            | 143000.00 |  91000.00
 IT               |  94000.00 |  67000.00
 Finance          |  76000.00 |  62000.00
 HR               |  60000.00 |  50000.00
```

- For $4.$, we need to run `pg_dump` inside the container and get it locally. We do this from our machine:
```bash
docker exec some-postgres pg_dump -U ituser -d company_db > dump.sql
```
and we get the dump in `dump.sql`.

- For $5.$ we create the bash script in `bash_script.sh`. The output file is `output4queries.log`.

After creating it, I modified the permissions and ran it.
```bash
chmod +x bash_script.sh 
./bash_script.sh 
some-postgres
2278f4e54ef53b6a43377fa9688358d5b8e15fdd845d9df9dbecf885b4266877
Waiting for container to start
Successfully copied 5.63kB to some-postgres:/populatedb.sql
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 8
INSERT 0 53
INSERT 0 53
CREATE ROLE
Enter dept name: Finance
All done, logs are in output4queries.log.
```

## Bonus - PV
We need to modify our `docker run` command for this to include the `-v` flag, a volume name (that will get created since it does not already exist on my machine) and the container where `PostgreSQL` reads/writes to (which is `/var/lib/postgresql/data`):


```bash
docker run --name some-postgres \
  -e POSTGRES_DB=company_db \
  -e POSTGRES_USER=ituser \
  -e POSTGRES_PASSWORD=123 \
  -p 5432:5432 \
  -v pd_db_data:/var/lib/postgresql/data \
  -d postgres
```

We then check to see if the volume exists with `docker volume ls` and then we can do `docker volume inspect pd_db_data`.

```bash
docker volume inspect pd_db_data 
[
    {
        "CreatedAt": "2025-03-22T14:21:47+02:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pd_db_data/_data",
        "Name": "pd_db_data",
        "Options": null,
        "Scope": "local"
    }
]
```