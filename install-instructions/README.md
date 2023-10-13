# Installing and Configuring User-Defined Functions


<br>

### Overview

User-defined functions (UDFs) are key components for enforcing Cyral masking policies with specialized behaviors. These functions are usually installed within a database/schema entity inside your Database system. Users can refer to these functions in their query by specifying the function name, with an optional schema/database qualifier. 

This guide provides the required information on how to install user defined functions in different Database Systems.


<br>

### Requirements

#### For installing the database functions:
* Database administrator with enough permissions to create UDFs and to grant the execute permission on these UDFs to other database users. Specific instructions are provided on a per database level.
* A Database instance.
#### For configuring Cyral Policies and Data repositories:
* Cyral admin.
* Sidecar instance (to validate the masking behavior).


<br>

### Installing UDFs and Adding to Cyral Policies

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
# 1. Create a new schema for storing the desired UDFs:

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

`psql -h ${SIDECAR_HOST} -p ${SIDECAR_PORT} -d ${DATABASE} -U ${USER} -f ./example-udf-postgresql.sql`

where:
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your PostgreSQL database.
- `DATABASE` refers to the underlying database entity, which contains a collection of schemas and tables.
- `USER` is the specific database user, which has the required permissions to execute the above SQL commands.


#### Notes
1. The above script creates a new schema, named `cyral`. Any other schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-postgresql) for a complete understanding on how the schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `text` and returns another `text` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. PostgreSQL does not easily allow cross-database references. As a result, user-defined functions **must be individually installed** in each database where you want to use them.
4. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
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

and <br>
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


#### Testing the UDF with Cyral Policies

Here we assume the following:
  * A PostgreSQL data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:<br>
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:mask_string(NAMES)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
# Every query that retrieves the contents of the field `name` will have the result payload masked
#
# Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
# are not even expected to be aware that such UDF exists.
finance=> SELECT name from CompBandTable LIMIT 3;
 mask_string 
-------------
 *****
 ******
 *********
(3 rows)
```

##### UDF install location in PostgreSQL

In the example above, the policy only refers to the UDF by its name. This is valid because in PostgreSQL, the schema `cyral` has a special meaning for the sidecar, as it is the default location where the sidecar looks for functions, when they are not fully qualified. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:cyral.mask_string(NAMES)
        rows: any
        severity: low
```

* note the `cyral.` prefix, which denotes the schema name.

---
</details>
<br>




<details>
  <summary>
     <picture><img src="../.github/imgs/databases/redshift-name.png" alt="Redshift" height="45"></picture>
  </summary>

#### Required permissions for installing UDFs
The database user used to install the UDFs needs the following privileges:
* `CREATE SCHEMA` on the target database.
  * [Command reference.](https://docs.aws.amazon.com/pt_br/redshift/latest/dg/r_CREATE_SCHEMA.html)
* `GRANT`, to allow grant usage to different users. 
  * [Command reference.](https://docs.aws.amazon.com/pt_br/redshift/latest/dg/r_GRANT.html)

#### Install script

```sql
-- 1. Create a new schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION cyral.mask_string(input_string TEXT)
RETURNS TEXT
STABLE
AS
$$
  return '*' * len(input_string)
$$ LANGUAGE plpythonu;

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON FUNCTION cyral.mask_string(input_string TEXT) TO PUBLIC;
```

The above script can be saved to a file, e.g. `example-udf-redshift.sql`, and can be copied as is and executed in your application of choice. In `psql`, it can be installed with the following command:

`psql -h ${SIDECAR_HOST} -p ${SIDECAR_PORT} -d ${DATABASE} -U ${USER} -f ./example-udf-redshift.sql`

where:
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your Redshift database.
- `DATABASE` refers to the underlying database entity, which contains a collection of schemas and tables.
- `USER` is the specific database user, which has the required permissions to execute the above SQL commands.


#### Notes
1. The above script creates a new schema, named `cyral`. Any other schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-redshift) for a complete understanding on how the schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `TEXT` and returns another `TEXT` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. Redshift does not easily allow cross-database references. As a result, user-defined functions **must be individually installed** in each database where you want to use them.
4. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
# Retrieving data without masking
dev=# SELECT name FROM comp_band_table;
   name    
-----------
 James
 Sophie
 Sylvester
(3 rows)
```

and
```SQL
# Retrieving data masked with the newly installed UDF
dev=# SELECT cyral.mask_string(name) FROM comp_band_table;
 mask_string 
-------------
 *****
 ******
 *********
(3 rows)
```


#### Testing the UDF with Cyral Policies

Here we assume the following:
  * A Redshift data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:mask_string(NAMES)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
# Every query that retrieves the contents of the field `name` will have the result payload masked
#
# Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
# are not even expected to be aware that such UDF exists.
dev=# SELECT name FROM comp_band_table;
   name    
-----------
 *****
 ******
 *********
(3 rows)
```

##### UDF install location in Redshift

In the example above, the policy only refers to the UDF by its name. This is valid because in Redshift, the schema `cyral` has a special meaning for the sidecar, as it is the default location where the sidecar looks for functions, when they are not fully qualified. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:cyral.mask_string(NAMES)
        rows: any
        severity: low
```

* note the `cyral.` prefix, which denotes the schema name.

---
</details>
<br>



<details>
  <summary>
     <picture><img src="../.github/imgs/databases/snowflake-name.png" alt="Snowflake" height="45"></picture>
  </summary>


  #### Required permissions for installing UDFs
  The database user used to install the UDFs needs the following privileges:
  * `CREATE DATABASE` on the target Snowflake warehouse.
    * [Command reference.](https://docs.snowflake.com/en/sql-reference/sql/create-database)
  * `CREATE SCHEMA` on the target database.
    * [Command reference.](https://docs.snowflake.com/en/sql-reference/sql/create-schema)
  * `GRANT`, to allow grant usage to different users. 
    * [Command reference.](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege)

  #### Install script

```sql
// 1. Create a new database for storing all your UDFs for custom masking
CREATE DATABASE IF NOT EXISTS CYRAL;

// 2. Allow everyone to access the new database
GRANT USAGE ON DATABASE CYRAL TO PUBLIC;

// 3. Create a new schema for holding the UDFs
CREATE SCHEMA IF NOT EXISTS CYRAL.CYRAL;

// 4. Allow everyone to access the new schema
GRANT USAGE ON SCHEMA CYRAL.CYRAL TO PUBLIC;

// 5. Create the new function in the target schema
CREATE OR REPLACE FUNCTION CYRAL.CYRAL."mask_string"(INPUT_STRING STRING)
  RETURNS STRING
  LANGUAGE JAVASCRIPT
AS
$$
function maskString(inputString) {
    var maskedString = '';
    for (var i = 0; i < inputString.length; i++) {
        maskedString += '*';
    }
    return maskedString;
}

return maskString(INPUT_STRING);
$$;


// 6. Grant the execution privilege to everyone, through the PUBLIC role
GRANT USAGE ON FUNCTION CYRAL.CYRAL."mask_string"(STRING) TO PUBLIC;

```

The above script can be saved to a file, e.g. `example-udf-snowflake.sql`, and can be copied as is and executed in your application of choice. In `snowsql`, it can be installed with the following command: <br>

`snowsql -a ${SNOWFLAKE_ACCOUNT} -u ${USER} -h ${SIDECAR_ENDPOINT} -p ${SIDECAR_PORT} -w ${WAREHOUSE} -f  ./example-udf-snowflake.sql`

where:
- `SNOWFLAKE_ACCOUNT` refers to the snowflake account ID.
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your Snowflake instance.
- `DATABASE` refers to the underlying database entity, which contains a collection of schemas and tables.
- `USER` is the specific database user, which has the required permissions to execute the above SQL commands.
- `WAREHOUSE` is the Snowflake Warehouse to be used.


#### Notes
1. The above script creates new database and schema, both named `CYRAL`. Any other database and schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-snowflake) for a complete understanding on how the database and schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `string` and returns another `string` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. Snowflake supports cross-database references. As a result, user-defined functions can be created once and shared across all your available databases.
4. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
# Retrieving data without masking
COMPUTE_WH@PLAYGROUND.FINANCE> SELECT CARD_FAMILY FROM CARDS LIMIT 2;
+-------------+                                                                 
| CARD_FAMILY |
|-------------|
| Gold        |
| Platinum    |
+-------------+
2 Row(s) produced. Time Elapsed: 0.253s

```

and <br>
```SQL
# Retrieving data masked with the newly installed UDF
COMPUTE_WH@PLAYGROUND.FINANCE> SELECT CYRAL.CYRAL."mask_string"(CARD_FAMILY) FROM CARDS LIMIT 2;
+--------------------------------------+                                        
| CYRAL.CYRAL.mask_string(CARD_FAMILY) |
|--------------------------------------|
| ****                                 |
| ********                             |
+--------------------------------------+
2 Row(s) produced. Time Elapsed: 0.854s

```


#### Testing the UDF with Cyral Policies

Here we assume the following:
  * A Snowflake data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:<br>
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - CARD_FAMILY
rules:
  - reads:
      - data:
          - custom:mask_string(CARD_FAMILY)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
// Every query that retrieves the contents of the field `CARD_FAMILY` will have the result payload masked
//
// Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
// are not even expected to be aware that such UDF exists.

COMPUTE_WH@PLAYGROUND.FINANCE> SELECT CARD_FAMILY FROM CARDS LIMIT 2;
+--------------------------------------+                                        
| CYRAL.CYRAL.mask_string(CARD_FAMILY) |
|--------------------------------------|
| ****                                 |
| ********                             |
+--------------------------------------+
2 Row(s) produced. Time Elapsed: 0.921s

```

##### UDF install location in Snowflake

In the example above, the policy only refers to the UDF by its name. This is valid because in Snowflake, the database and schema named `CYRAL` has special meanings for the sidecar, as it is the default location where the sidecar looks for unqualified functions. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:CYRAL.CYRAL.mask_string(CARD_FAMILY)
        rows: any
        severity: low
```

* note the `CYRAL.CYRAL` prefix, which denotes the database and the schema names.

---
</details>
<br>



<details>
  <summary>
     <picture><img src="../.github/imgs/databases/mysql-name.png" alt="MySQL" height="45"></picture>
  </summary>




#### Required permissions for installing UDFs
The database user used to install the UDFs needs the following privileges:
* `CREATE SCHEMA/DATABASE`
  * [Command reference.](https://dev.mysql.com/doc/refman/8.0/en/create-database.html)
* `CREATE ROLE` on the target database/schema.
  * [Command reference.](https://dev.mysql.com/doc/refman/8.0/en/create-role.html)
* `GRANT`, to allow grant usage to different roles. 
  * [Command reference.](https://dev.mysql.com/doc/refman/8.0/en/grant.html)

#### Install script

```sql
-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. MySQL>=8.1 requires to enable log_bin_trust_function_creators to create functions:
SET GLOBAL log_bin_trust_function_creators = 1;

-- 3. Create the new function in the target schema:
DELIMITER $
CREATE FUNCTION cyral.mask_string(input_string TEXT)
RETURNS TEXT
BEGIN
    DECLARE masked_string TEXT DEFAULT '';
    DECLARE i INT DEFAULT 1;
    DECLARE input_length INT;

    SET input_length = CHAR_LENGTH(input_string);

    -- Iterate through each character of the input string and replace with '*'
    WHILE i <= input_length DO
        SET masked_string = CONCAT(masked_string, '*');
        SET i = i + 1;
    END WHILE;

    -- Return the masked string
    RETURN masked_string;
END $
DELIMITER ;

-- 3.1. Create a masking Role:
CREATE ROLE IF NOT EXISTS CYRAL_MASKING_PERMISSIONS;
GRANT EXECUTE ON cyral.* TO CYRAL_MASKING_PERMISSIONS;

-- 3.1. Make CYRAL_MASKING_PERMISSIONS Role mandatory:
--      Only run the query below if SELECT INSTR(@@mandatory_roles, "CYRAL_MASKING_PERMISSIONS"); returns 0.
SET PERSIST mandatory_roles = CONCAT('CYRAL_MASKING_PERMISSIONS', COALESCE(CONCAT(',', NULLIF(TRIM(@@mandatory_roles), '')), ''));

-- 3.2. Enable CYRAL_MASKING_PERMISSIONS on login:
SET PERSIST activate_all_roles_on_login = 1;
```

The above script can be saved to a file, e.g. `example-udf-mysql.sql`, and can be copied as is and executed in your application of choice. In `mysql` client, it can be installed with the following command:

```
mysql --host=${SIDECAR_HOST} --port=${SIDECAR_PORT} --user=${USER} -p < example-udf-mysql.sql
```

where:
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your SQL Server database.
- `USER` is the specific database user, which has the required permissions to execute the above SQL commands.

#### Notes
1. The above script creates a new schema/database (synonyms), named `cyral`. Any other schema/database could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-mysql) for a complete understanding on how the schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `TEXT` and returns another `TEXT` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
# Retrieving data without masking
mysql> SELECT name FROM comp_band_table;
+-----------+
| name      |
+-----------+
| James     |
| Sophie    |
| Sylvester |
+-----------+
3 rows in set (0.00 sec)
```
and
```SQL
# Retrieving data masked with the newly installed UDF
mysql> SELECT cyral.mask_string(name) FROM comp_band_table;
+-------------------------+
| cyral.mask_string(name) |
+-------------------------+
| *****                   |
| ******                  |
| *********               |
+-------------------------+
3 rows in set (0.00 sec)
```

#### Testing the UDF with Cyral Policies

Here we assume the following:
  * A MySQL data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:mask_string(NAMES)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
# Every query that retrieves the contents of the field `name` will have the result payload masked
#
# Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
# are not even expected to be aware that such UDF exists.
mysql> select name from comp_band_table;
+-----------+
| name      |
+-----------+
| *****     |
| ******    |
| ********* |
+-----------+
3 rows in set (0.00 sec)
```

##### UDF install location in MySQL

In the example above, the policy only refers to the UDF by its name. This is valid because in SQL Server, the schema/database `cyral` has a special meaning for the sidecar, as it is the default location where the sidecar looks for functions, when they are not fully qualified. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:cyral.mask_string(NAMES)
        rows: any
        severity: low
```

* note the `cyral.` prefix, which denotes the schema/database name.

---
</details>
<br>




<details>
  <summary>
     <picture><img src="../.github/imgs/databases/sqlserver-name.png" alt="SQL Server" height="45"></picture>
  </summary>

#### Required permissions for installing UDFs
The database user used to install the UDFs needs the following privileges:
* `CREATE DATABASE`
  * [Command reference.](https://learn.microsoft.com/pt-br/sql/t-sql/statements/create-database-transact-sql)
* `CREATE SCHEMA` on the target database.
  * [Command reference.](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-database-schema)
* `GRANT`, to allow grant usage to different users. 
  * [Command reference.](https://learn.microsoft.com/pt-br/sql/t-sql/statements/grant-transact-sql)

#### Install script

```sql
-- 1. Create a new database and schema for storing the desired UDFs:
CREATE DATABASE cyral;
GO
USE cyral;
GO
CREATE SCHEMA cyral;
GO

-- 2. Create the new function in the target schema:
CREATE OR ALTER FUNCTION cyral.mask_string(@input_string NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @masked_string NVARCHAR(MAX) = '';
    DECLARE @i INT = 1;

    -- Iterate through each character of the input string and replace with '*'
    WHILE @i <= LEN(@input_string)
    BEGIN
        SET @masked_string = @masked_string + '*';
        SET @i = @i + 1;
    END;

    -- Return the masked string
    RETURN @masked_string;
END;
GO

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT CONNECT TO PUBLIC;
GRANT EXECUTE ON OBJECT::cyral.mask_string TO PUBLIC;
```

The above script can be saved to a file, e.g. `example-udf-sqlserver.sql`, and can be copied as is and executed in your application of choice. In `sqlcmd`, it can be installed with the following command:

```
sqlcmd -C -S ${SIDECAR_HOST},${SIDECAR_PORT} -U ${USER} -i example-udf-sqlserver.sql
```

where:
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your SQL Server database.
- `USER` is the specific database user, which has the required permissions to execute the above SQL commands.


#### Notes
1. The above script creates new database and schema, both named `cyral`. Any other database and schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-sql-server) for a complete understanding on how the database and schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `NVARCHAR` and returns another `NVARCHAR` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. SQL Server supports cross-database references. As a result, user-defined functions can be created once and shared across all your available databases.
4. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
1> SELECT name FROM band.comp_band_table;
2> GO
name
----------------------------
James
Sophie
Sylvester

(3 rows affected)
```
and
```SQL
# Retrieving data masked with the newly installed UDF
1> SELECT cyral.cyral.mask_string(name) FROM band.comp_band_table;
2> GO
----------------------------
*****
******
*********

(3 rows affected)
```

#### Testing the UDF with Cyral Policies

Here we assume the following:
  * A Oracle data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:mask_string(NAMES)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
# Every query that retrieves the contents of the field `name` will have the result payload masked
#
# Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
# are not even expected to be aware that such UDF exists.
1> SELECT name FROM band.comp_band_table;
2> GO
name
----------------------------
*****
******
*********

(3 rows affected)
```

##### UDF install location in SQL Server

In the example above, the policy only refers to the UDF by its name. This is valid because in SQL Server, both database and schema `cyral` have a special meaning for the sidecar, as it is the default location where the sidecar looks for functions, when they are not fully qualified. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other database or schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:cyral.cyral.mask_string(NAMES)
        rows: any
        severity: low
```

* note the `cyral.cyral.` prefix, which denotes the database and schema name.

---
</details>
<br>


<details>
  <summary>
     <picture><img src="../.github/imgs/databases/oracle-name.png" alt="Oracle" height="45"></picture>
  </summary>

#### Required permissions for installing UDFs
The database user used to install the UDFs needs the following privileges:
* `CREATE SCHEMA` on the target database.
  * [Command reference.](https://docs.oracle.com/en/cloud/paas/exadata-express-cloud/csdbp/create-database-schemas.html)
* `GRANT`, to allow grant usage to different users. 
  * [Command reference.](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/GRANT.html)

#### Install script

```sql
-- 1. Create a new user schema for storing the desired UDFs:
CREATE USER CYRAL identified by "<password>";

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION CYRAL."mask_string"(
  INPUT_STRING IN VARCHAR2
)
RETURN VARCHAR2
IS
    MASKED VARCHAR2(32767) := '';
    I NUMBER := 1;
BEGIN
    WHILE I <= LENGTH(INPUT_STRING) LOOP
        MASKED := MASKED || '*';
        I := I + 1;
    END LOOP;
    RETURN MASKED;
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON CYRAL."mask_string" TO PUBLIC;
```

The above script can be saved to a file, e.g. `example-udf-oracle.sql`, and can be copied as is and executed in your application of choice. In `sqlplus`, considering you are already connected, it can be installed with the following command:

```
sqlplus ${USER}/${PASSWORD}@${SIDECAR_HOST}:${SIDECAR_PORT}/${DATABASE}

SQL> @example-udf-oracle.sql

User created.

Function created.

Grant succeeded.
```

where:
- `SIDECAR_HOST` and `SIDECAR_PORT` point to the sidecar being used to protect your Oracle database.
- `DATABASE` refers to the underlying database entity, which contains a collection of schemas and tables.
- `USER` and `PASSWORD` are the specific database user and password, which has the required permissions to execute the above SQL commands.

#### Notes
1. The above script creates a new user schema, named `CYRAL`. Any other schema could be used, however we recommend reading the section on [target schemas and impacts on Cyral Policies](#udf-install-location-in-oracle) for a complete understanding on how the schema name impacts on how you refer to UDFs in policies.
2. Above we have a simplistic UDF example that receives a column entry of type `VARCHAR` and returns another `VARCHAR` value with all characters of the input columns replaced by `*`. **For a list of real-world example UDFs, please refer to: [masking-examples](../masking-examples)**.
3. The script installs the UDFs in the same location as the [Cyral mask helper](https://cyral.com/docs/using-cyral/masking/#install-the-cyral-mask-helper-in-your-database). [Uninstalling](https://cyral.com/docs/using-cyral/masking/#remove-the-cyral-mask-function) the Cyral mask helper will also remove the previous installed UDF;

#### Testing the UDF directly
We can easily test the newly created UDF by connecting to the database with your favorite application and executing the following queries:
```SQL
# Retrieving data without masking
SQL> SELECT NAME FROM COMP_BAND_TABLE;

NAME
----------------------------
James
Sophie
Sylvester
```
and
```SQL
# Retrieving data masked with the newly installed UDF
SQL> SELECT CYRAL."mask_string"(NAME) FROM COMP_BAND_TABLE;

CYRAL."mask_string"(NAME)
----------------------------
*****
******
*********
```

#### Testing the UDF with Cyral Policies

Here we assume the following:
  * An Oracle data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or your need further help in configuring them, please refer to:
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:mask_string(NAMES)
        rows: any
        severity: low
```

##### Connecting and retrieving data
```sql
# Every query that retrieves the contents of the field `name` will have the result payload masked
#
# Note that the end-user is not expected to type the UDF name in their queries, and in fact, they
# are not even expected to be aware that such UDF exists.
SQL> SELECT NAME FROM COMP_BAND_TABLE;

NAME
----------------------------
*****
******
*********
```

##### UDF install location in Oracle

In the example above, the policy only refers to the UDF by its name. This is valid because in Oracle, the user schema `CYRAL` has a special meaning for the sidecar, as it is the default location where the sidecar looks for functions, when they are not fully qualified. This behavior allows for the use of a single Global Policy for different databases or repository types.

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - NAMES
rules:
  - reads:
      - data:
          - custom:CYRAL.mask_string(NAMES)
        rows: any
        severity: low
```

* note the `CYRAL.` prefix, which denotes the user schema name.

---
</details>