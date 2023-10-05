# Installing User-Defined Functions


<br>

### Overview

User-defined functions (UDFs) are key components for enforcing Cyral masking policies with specialized behaviors. These functions are usually installed within a database/schema entity inside your Database system. Users can refer to these functions in their query by specifying the function name, with an optional schema/database qualifier. 

This guide provides the required information on how to install user defined functions in different Database Systems.


<br>

### Requirements

* Database administrator with enough permissions to create UDFs and to grant the execute permission on these UDFs to other database users. Specific instructions are provided on a per database level.
* A Database instance.

<br>

### Installing UDFs

Click on the desirable Database System below to see specific requirements and commands:

<details>
  <summary>
    <picture><img src="../.github/imgs/databases/postgresql-name.png" alt="PostgreSQL" height="45"></picture>
  </summary>



  #### Required permissions for installing UDFs
  The database user used to install the UDFs needs the following privileges:
  * `CREATE SCHEMA` on the target database.
    * [Command reference.](https://www.postgresql.org/docs/current/sql-createschema.html)
  * `GRANT`, to allow grant usage to different users. 
    * [Command reference.](https://www.postgresql.org/docs/current/sql-grant.html)

  #### Install script

```sql
# 1. Create a new (optional) schema for storing the desired UDFs:

CREATE SCHEMA IF NOT EXISTS cyral;


# 2. Create the new function in the target schema:

CREATE OR REPLACE FUNCTION cyral.mask_string(input_string text)
RETURNS text AS
$$
DECLARE
    masked_string text := '';
    i integer := 1;
BEGIN
    -- Iterate through each character of the input string and replace with '*'
    WHILE i <= length(input_string) LOOP
        masked_string := masked_string || '*';
        i := i + 1;
    END LOOP;
    
    -- Return the masked string
    RETURN masked_string;
END;
$$
LANGUAGE PLPGSQL;


# 3. Grant the execution privilege to everyone, through the PUBLIC role

GRANT EXECUTE ON FUNCTION cyral.mask_string(text) TO PUBLIC;
```

The above script can be saved to a file, e.g. `example-udf-postgresql.sql`, and can be copied as is and executed in your application of choice. In `psql`, it can be installed with the following command: <br>

`psql -h ${SIDECAR_HOST} -p 5432 -d ${DATABASE} -U ${USER} -f ./example-udf-postgresql.sql`

where: <br>
    - `SIDECAR_HOST` points to the sidecar being used to protect your PostgreSQL database. <br>
    - `DATABASE` refers to the underlying database entity, which contains a collection of schemas and tables. <br>
    - `USER` is the specific database user, which has the the required permissions to executed the above SQL commands. <br>


#### Notes
 1. The above script creates a new optional schema, named `cyral`. Any other schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#add-section) for a complete understanding on how the schema name impacts on how you refer to UDFs in policies.

 2. Above we have a simplistic UDF example that receives a column entry of type `text` and returns another `text` value with all characters of the input columns replaced by `*`.
    a. For a list of real-world example UDFs, please refer to: *[masking-examples](./masking-examples/)*. <br>


 3. PostgreSQL does not easily allow cross-database references. As a result, user-defined functions **must be individually installed** in each database where you want to use them.




#### Testing the UDF
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
# Retrieving data without masking
finance=> SELECT name from CompBandTable LIMIT 3;
  name   
---------
 James
 Sophie
 Sylvester
(3 rows)
```

<br> and <br>
```SQL
# Retrieving data masked with the newly installed UDF
finance=> SELECT cyral.mask_string(name) from CompBandTable LIMIT 3;
 mask_string 
-------------
 *****
 ******
 *********
(3 rows)

```


  ---
</details>
<br>




<details>
  <summary>
     <picture><img src="../.github/imgs/databases/redshift-name.png" alt="Redshift" height="45"></picture>
  </summary>

```
    TODO
```

  ---
</details>
<br>



<details>
  <summary>
     <picture><img src="../.github/imgs/databases/snowflake-name.png" alt="Snowflake" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>



<details>
  <summary>
     <picture><img src="../.github/imgs/databases/mysql-name.png" alt="MySQL" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>




<details>
  <summary>
     <picture><img src="../.github/imgs/databases/sqlserver-name.png" alt="SQL Server" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>


<details>
  <summary>
     <picture><img src="../.github/imgs/databases/oracle-name.png" alt="Oracle" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>
