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
    <picture><img src="./.github/imgs/databases/postgresql-name.png" alt="PostgreSQL" height="45"></picture>
  </summary>



  #### Required permissions for installing UDFs
  The database user used to install the UDFs needs the following privileges:
  * `CREATE SCHEMA` on the target database.
    * [Command reference.](https://www.postgresql.org/docs/current/sql-createschema.html)
  * `GRANT`, to allow grant usage to different users. 
    * [Command reference.](https://www.postgresql.org/docs/current/sql-grant.html)

  #### Install commands

  1. **Connect to the database using your client application of choice, e.g. `psql`:**
```
psql -h ${SIDECAR_ENDPOINT} -p 5432 -d ${DATABASE_NAME} -U ${USER_NAME}

psql (14.5, server 14.7)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

finance=> 
```
`finance` is the name of our database entity inside this PostgreSQL instance. <br>

  2. **Optionally, create a new schema for storing all your user-defined functions:**
```
finance=> create schema if not exists cyral;
CREATE SCHEMA
```
`cyral` is the name for the new schema we created. It could be any other name of your choice.
It's not mandatory to create a new schema. However, it is recommended to have a dedicated schema for organizing all of your functions, as it facilitates when writing Cyral Policies that refer to them.

  3. **Create the user defined function for transforming the desirable data:**
```SQL
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
```
Above we have a simplistic UDF example that receives a column entry of type `text` and returns another `text` value with all characters of the input columns replaced by `*`. 

To install it, you can save it to a file, for example `mask_string.sql`, and run the following command:
`psql -h ${SIDECAR_HOST} -p 5432 -d ${DATABASE} -U ${USER} -f ./mask_string.sql`
The expected output from the server is: 
`CREATE FUNCTION`


  4. **Grant execute permissions for all users on this function:**
```SQL
GRANT EXECUTE ON FUNCTION cyral.mask_string(text) TO PUBLIC;
```
On **PostgreSQL**, we can grant permissions to everyone by granting the desired priviledge to the `PUBLIC` role.

  5. **Test the UDF with the same and different users:**
```SQL
# Retrieving data without masking
finance=> SELECT name from CompBandTable LIMIT 3;
  name   
---------
 James
 Sophie
 Sylvester
(3 rows)

# Retrieving data masked with the newly installed UDF
finance=> SELECT cyral.mask_string(name) from CompBandTable LIMIT 3;
 mask_string 
-------------
 *****
 ******
 *********
(3 rows)

```

  #### Notes


  * PostgreSQL does not easily allow cross-database references. As a result, user-defined functions **must be individually installed** in each database where you want to use them.



  ---
</details>
<br>




<details>
  <summary>
     <picture><img src="./.github/imgs/databases/redshift-name.png" alt="Redshift" height="45"></picture>
  </summary>

```
    TODO
```

  ---
</details>
<br>



<details>
  <summary>
     <picture><img src="./.github/imgs/databases/snowflake-name.png" alt="Snowflake" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>



<details>
  <summary>
     <picture><img src="./.github/imgs/databases/mysql-name.png" alt="MySQL" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>




<details>
  <summary>
     <picture><img src="./.github/imgs/databases/sqlserver-name.png" alt="SQL Server" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>


<details>
  <summary>
     <picture><img src="./.github/imgs/databases/oracle-name.png" alt="Oracle" height="45"></picture>
  </summary>


```
    TODO
```

  ---
</details>
<br>
