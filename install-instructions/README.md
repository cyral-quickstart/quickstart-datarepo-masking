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

<detailsx>
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
    **For a list of real-world example UDFs, please refer to: [masking-examples](./masking-examples/)**. <br>


 3. PostgreSQL does not easily allow cross-database references. As a result, user-defined functions **must be individually installed** in each database where you want to use them.




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
          - custom:cyral.mask_string(NAMES)
        rows: any
        severity: low
```

when the UDF is installed inside the [pre-defined schema names](#to-add), the schema prefix can be omitted in the policy definition, leading to the following alternative policy:

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
# are not even expected to be aware that such UDF exist.
finance=> SELECT name from CompBandTable LIMIT 3;
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
