# Masking Credit Card Number


Brief Description
-----------------
This example is a custom masking function used to mask part of a credit card number. The database is instructed to keep the last 4 digits of a credit card number field unmasked and mask the other initial digits with `*`. This behavior is particularly useful to protect customer's data and at the same time provide tailored access to the information.

* **Example**: A mask declared as `custom:mask_ccn(CCN)` in a Global Policy may replace a credit card number `1234-1234-1234-1234` with `****-****-****-1234`.


Availability
------------

:white_check_mark: SQL Server

Installation
------------

This directory contains two `.sql` files for each supported repo type:
* `${repo_type}-complete-script.sql`
  * Contains a complete installation script that can be used to install the UDF in your desired database. It also includes codes to create the required *database, schema, and functions*, and also grants the required permissions to allow all users to execute the function. Default database and schema names are assumed in these scripts.
* `${repo_type}-udf-only.sql`
  * Contains only the function code with some placeholders, in the format `${PLAHOLDER_NAME}`, which should be updated before installing the function.

<br>

#### Installation examples using CLI tools for the supported databases
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

For SQL Server:
```json
{
  "governedData": {
    "labels": [
      "CCN"
    ]
  },
  "readRules": [
    {
      "constraints": {
        "mask": {
          "function": "custom:mask_ccn(CCN)"
        }
      }
    }
  ]
}
```

##### Connecting and retrieving data

Every query that retrieves the contents of fields labeled as `CCN` will have the result payload masked. Note that the end-user is not expected to type the UDF name in their queries, and in fact, they are not even expected to be aware that such UDF exists.

```sql
SELECT ccn FROM my_table;

ccn
----------------------------
****-****-****-1234
****-****-****-4444
****-****-****-8888
```

In the example above, the policy only refers to the UDF by its name. This is valid because the `${repo-type}-complete.sql` scripts install the functions in a default location known by the sidecar. Per repo type, these are the default locations:
  * **SQL Server**:  Database: `cyral` | Schema: `cyral`

However, it is possible to install UDFs in any other schema, as long as Global Policies refer to them using qualified names. For the above example, a fully qualified table
reference would be:

```json
{
  "governedData": {
    "labels": [
      "CCN"
    ]
  },
  "readRules": [
    {
      "constraints": {
        "mask": {
          "function": "custom:${database_name}.${schema_name}.mask_ccn(CCN)"
        }
      }
    }
  ]
}
```

* `${database_name}` and `${schema_name}`, when applicable, must be replaced by the correct values representing the location where the custom masking function was installed.
