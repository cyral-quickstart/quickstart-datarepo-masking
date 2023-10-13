# Consistent Format Preserve


Brief Description
-----------------
Consistent Format Preserve is a custom masking function used to ensure consistent randomization of your data. The database is instructed to replace the field's contents with a semi-randomized string that preserves all hyphens, dots, and other punctuation in the string. Numbers are replaced with randomly chosen numbers, and letters with randomly chosen letters. Letter case is preserved, meaning lowercase letters are replaced with random lowercase letters, and uppercase with random uppercase letters.

The data is consistently randomized, meaning that for a specific input value, the same randomized representation will be always generated. This behavior is particularly useful when different tables are subject to the same masking policy and you want to be able to find references of one table into the other.

* **Example**: A mask declared as `custom:consistent_mask(EMAIL)` in a Global Policy may replace an address of `MyEmail123@cyral.com` with `ZaFxbcd517@dzbxq.pqd`.


Availability
------------

:white_check_mark: PostgreSQL <br> :white_check_mark: Amazon Redshift <br>  :white_check_mark: SQL Server <br> :white_check_mark: Oracle <br> :white_check_mark: MySQL <br> :white_check_mark: Snowflake

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
* MySQL
  ```sh
  mysql -h ${SIDECAR_HOST} -P ${SIDECAR_PORT} -u ${USER} -p  < mysql-complete-script.sql
  ```
* Oracle
  ```sh
  sqlplus ${USER}/${PASSWORD}@${SIDECAR_HOST}:${SIDECAR_PORT}/${DATABASE}

  SQL> @oracle-complete-script.sql

       User created.

       Function created.

       Grant succeeded.
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

#### Adding references to the format preserve custom function in Cyral Global Policies


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

For PostgreSQL, Amazon Redshift and Snowflake:
```yaml
data:
  - EMAIL
rules:
  - reads:
      - data:
          - custom:consistent_mask(EMAIL)
        rows: any
        severity: low
```

For SQL Server, Oracle, and MySQL:
```yaml
data:
  - EMAIL
rules:
  - reads:
      - data:
          - custom:consistent_mask_${type}(EMAIL)
        rows: any
        severity: low
```
`${type}` must be replaced by the correct type according to the column type.

##### Connecting and retrieving data

Every query that retrieves the contents of fields labeled as `EMAIL` will have the result payload masked. Note that the end-user is not expected to type the UDF name in their queries, and in fact, they are not even expected to be aware that such UDF exists.

```sql
SELECT email FROM my_table;

email
----------------------------
oplaki.jsnns77@mmznoha.los
popnshc.kkajx.82uaj@sujhzzs.ysh
hhagbxpq@xpos.qlo
ZaFxbcd517@dzbxq.pqd
```

In the example above, the policy only refers to the UDF by its name. This is valid because the `${repo-type}-complete.sql` scripts install the functions in a default location known by the sidecar. Per repo type, these are the default locations:
  * **Amazon Redshift**:  Database: `$current` | Schema: `cyral`
    * In Amazon Redshift, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **MySQL**: Database: `not applicable` | Schema: `cyral`
  * **PostgreSQL**:  Database: `$current` | Schema: `cyral`
    * In PostgreSQL, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **Oracle**:  Database: `$current` | User/Schema: `CYRAL`
    * In Oracle, cross database references are not allowed, meaning the custom masking function must be installed in every target database.
  * **SQL Server**:  Database: `cyral` | Schema: `cyral`
  * **Snowflake**:  Database: `CYRAL` | Schema: `CYRAL`

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```yaml
data:
  - EMAIL
rules:
  - reads:
      - data:
          - custom:${database_name}.${schema_name}.consistent_mask(EMAIL)
        rows: any
        severity: low
```

* `${database_name}` and `${schema_name}`, when applicable, must be replaced by the correct values representing the location where the custom masking function was installed.
