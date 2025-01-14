# Partial Redaction


Brief Description
-----------------
This redact function can be used to mask parts of a string value. The function retains the first N and last M characters of its input unmasked and masks the other characters with a given character, like `*`. Note that only alphanumeric characters are replaced while other characters (e.g., `-`) are left intact.

* **Example**: A mask declared as `{"function": "custom:redact", "args": [3, 3, "#"]}` in a Global Policy may replace a credit card number `1234-1234-1234-1234` with `123#-####-####-#234`.


Availability
------------

:white_check_mark: PostgreSQL <br> :white_check_mark: Amazon Redshift <br>  :white_check_mark: SQL Server <br> :white_check_mark: Oracle <br> :white_check_mark: MySQL/MariaDB <br> :white_check_mark: Snowflake

Installation
------------

This directory contains two `.sql` files for each supported repo type:
* `${repo_type}-complete-script.sql`
  * Contains a complete installation script that can be used to install the UDF in your desired database. It also includes codes to create the required *database, schema, and functions*, and also grants the required permissions to allow all users to execute the function. Default database and schema names are assumed in these scripts.
* `${repo_type}-udf-only.sql`
  * Contains only the function code with some placeholders, in the format `${PLAHOLDER_NAME}`, which should be updated before installing the function.

<br>

#### Installation examples using CLI tools for the supported databases
* PostgreSQL 
  ```sh
  psql -h ${SIDECAR_HOST} -p ${SIDECAR_PORT} -d ${DATABASE} -U ${USER} -f ./postgresql-complete-script.sql
  ```
* Amazon Redshift
  ```sh
  psql -h ${SIDECAR_HOST} -p ${SIDECAR_PORT} -d ${DATABASE} -U ${USER} -f ./redshift-complete-script.sql
  ```
* MySQL 5
  ```sh
  mysql -h ${SIDECAR_HOST} -P ${SIDECAR_PORT} -u ${USER} -p < mysql5-complete-script.sql
  ```
* MySQL >= 8
  ```sh
  mysql -h ${SIDECAR_HOST} -P ${SIDECAR_PORT} -u ${USER} -p < mysql8-complete-script.sql
  ```
* MariaDB <= 10.10
  ```sh
  mysql -h ${SIDECAR_HOST} -P ${SIDECAR_PORT} -u ${USER} -p < mariadb10.10-complete-script.sql
  ```
* MariaDB >= 10.11
  ```sh
  mysql -h ${SIDECAR_HOST} -P ${SIDECAR_PORT} -u ${USER} -p < mariadb10.11-complete-script.sql
  ```
* Oracle
  ```sh
  sqlplus ${USER}/${PASSWORD}@${SIDECAR_HOST}:${SIDECAR_PORT}/${DATABASE}

  SQL> @oracle-complete-script.sql
  ```
* Snowflake
  ```sh
  snowsql -a ${SNOWFLAKE_ACCOUNT} -u ${USER} -h ${SIDECAR_ENDPOINT} -p ${SIDECAR_PORT} -w ${WAREHOUSE} -f ./snowflake-complete-script.sql
  ```
* SQL Server
  ```sh
  sqlcmd -C -S ${SIDECAR_HOST},${SIDECAR_PORT} -U ${USER} -i ./sqlserver-complete-script.sql
  ```
<br>

#### Adding references to the custom mask function in Cyral Global Policies


Here we assume the following:
  * An associated data repository was already created in the Control Plane / Management Console.
  * The data repository has the masking policy enforcement option enabled.
  * The data repository has the appropriate Data Labels already configured.
  * The data repository is accessible through a sidecar.

If the above pre-conditions are not met, or you need further help in configuring them, please refer to:
* Cyral Docs :arrow_right: [Track repositories](https://cyral.com/docs/manage-repositories/repo-track).
* Cyral Docs :arrow_right: [Data Mapping](https://cyral.com/docs/policy/datamap).
* Cyral Docs :arrow_right: [Turning on masking for a repository](https://cyral.com/docs/using-cyral/masking/#turn-on-masking-for-the-repository-in-cyral).
* Cyral Docs :arrow_right: [Binding a repository to a sidecar](https://cyral.com/docs/sidecars/sidecar-bind-repo).

##### Example Global Policy that refers to the custom function

A single global policy will be used across the different repository types: 
```json
{
  "governedData": {
    "labels": ["CCN"]
  },
  "readRules": [
    {
      "conditions": [],
      "constraints": {
        "mask": {
          "function": "custom:redact",
          "args": [3, 3, "#"]
        }
      }
    }
  ]
}
```

##### Connecting and retrieving data

Every query that retrieves the contents of fields labeled as `CCN` will have the result payload masked. Note that the end-user is not expected to type the UDF name in their queries, and in fact, they are not even expected to be aware that such UDF exists.

```sql
SELECT * FROM credit_card_numbers;
     card_number     
---------------------
 411#-####-####-#111
 550#-####-####-#004
 340#-####-####-#090
```

In the example above, the policy only refers to the UDF by its name. This is valid because the `${repo-type}-complete-script.sql` scripts install the functions in a default location known by the sidecar. Per repo type, these are the default locations:
  * **Amazon Redshift**:  Database: `$current` | Schema: `cyral`
    * In Amazon Redshift, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **MySQL/MariaDB**: Database: `not applicable` | Schema: `cyral`
  * **PostgreSQL**:  Database: `$current` | Schema: `cyral`
    * In PostgreSQL, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **Oracle**:  Database: `$current` | User/Schema: `CYRAL`
    * In Oracle, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **SQL Server**:  Database: `cyral` | Schema: `cyral`
  * **Snowflake**:  Database: `CYRAL` | Schema: `CYRAL`

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```json
{
  "governedData": {
    "labels": ["CCN"]
  },
  "readRules": [
    {
      "conditions": [],
      "constraints": {
        "mask": {
          "function": "custom:${database_name}.${schema_name}.redact",
          "args": [3, 3, "#"]
        }
      }
    }
  ]
}
```

* `${database_name}` and `${schema_name}`, when applicable, must be replaced by the correct values representing the location where the custom masking function was installed.
