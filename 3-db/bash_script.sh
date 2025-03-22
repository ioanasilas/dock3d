#!/bin/bash

# CONFIG
CONTAINER_NAME="some-postgres"
DB_NAME="company_db"
USER="ituser"
PASS="123"
SQL_FILE="populatedb.sql"
LOG_FILE="output4queries.log"

# remove existing container if any
# redirect stderr to dev null
docker rm -f $CONTAINER_NAME 2>/dev/null

# run container
docker run -d --name $CONTAINER_NAME \
-e POSTGRES_DB=$DB_NAME \
-e POSTGRES_USER=$USER \
-e POSTGRES_PASSWORD=$PASS \
-p 5432:5432 postgres

# wait for it to start if necessary
echo "Waiting for container to start"
sleep 5

# copy sql file inside container
docker cp $SQL_FILE $CONTAINER_NAME:/$SQL_FILE

# import dataset
docker exec $CONTAINER_NAME psql -U $USER -d $DB_NAME -f /$SQL_FILE

# create second admin user
docker exec $CONTAINER_NAME psql -U $USER -d $DB_NAME -c "CREATE USER admin_cee WITH SUPERUSER;"

# run queries, get output
echo "First query output" > $LOG_FILE
docker exec $CONTAINER_NAME psql -U $USER -d $DB_NAME -c "select count(*) from employees;" >> $LOG_FILE

echo "Second query output" >> $LOG_FILE
read -p "Enter dept name: " dept_name
docker exec $CONTAINER_NAME psql -U $USER -d $DB_NAME -c "select e.first_name, e.last_name from employees e 
                                                            join departments d on e.department_id = d.department_id 
                                                            where d.department_name = 
                                                                    '$dept_name';" >> $LOG_FILE

echo "Third query output" >> $LOG_FILE
docker exec $CONTAINER_NAME psql -U $USER -d $DB_NAME -c "select 
    d.department_name, 
    MAX(s.salary) as max_sal, 
    MIN(s.salary) as min_sal 
from departments d 
join employees e on d.department_id = e.department_id 
join salaries s on e.employee_id = s.employee_id 
group by d.department_name;" >> $LOG_FILE

echo "All done, logs are in $LOG_FILE".