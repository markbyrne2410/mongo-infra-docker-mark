## Information

This image uses osixia OpenLDAP[ https://github.com/osixia/docker-openldap ] and inspiration from om_ansible[ https://github.com/HenryGP/om_ansible ] to provision  predefined set of users and groups for quickly testing LDAP integration with MongoDB Enterprise and MongoDB Ops Manager. These can be found in `ldif/users.ldif` and `ldif/groups.ldif` respectively.

Testing has been done using LDAP/LDAPS and Native LDAP.

## User and groups structure

All users have the same password, `Password1!`. The following users have been predefined:
LDAP bind user `admin` has the password `admin`

### MongoDB database users
|User|MemberOf|
|-|-|
|uid=dba,ou=dbUsers,dc=tsdocker,dc=com|cn=dbAdmin,ou=dbRoles,dc=tsdocker,dc=com|
|uid=writer,ou=dbUsers,dc=tsdocker,dc=com|cn=readWriteAnyDatabase,ou=dbRoles,dc=tsdocker,dc=com|
|uid=reader,ou=DbUsers,dc=tsdocker,dc=com|cn=read,ou=dbRoles,dc=tsdocker,dc=com|

### Ops Manager Agents
|User|MemberOf|
|-|-|
|uid=mms-automation,ou=dbUsers,dc=tsdocker,dc=com|cn=automation,ou=dbRoles,dc=tsdocker,dc=com|
|uid=mms-monitoring,ou=dbUsers,dc=tsdocker,dc=com|cn=monitoring,ou=dbRoles,dc=tsdocker,dc=com|
|uid=mms-backup,ou=dbUsers,dc=tsdocker,dc=com|cn=backup,ou=dbRoles,dc=tsdocker,dc=com|

### Ops Manager users
|User|MemberOf|
|-|-|
|uid=owner,ou=omusers,dc=tsdocker,dc=com|cn=owners,ou=omgroups,dc=tsdocker,dc=com|
|uid=reader,ou=omusers,dc=tsdocker,dc=com|cn=readers,ou=omgroups,dc=tsdocker,dc=com|
|uid=admin,ou=omusers,dc=tsdocker,dc=com|cn=owners,ou=omgroups,dc=tsdocker,dc=com|


## Enabling TLS
 - The variable `LDAP_TLS: "false"` in the docker-compose.yml can be set to `true`
 - Provide the CA (`mongodb-ca.pem` in the /certs/ directory) via the  `TLS_CACERT` option in the `ldap.conf` file for each MDB node(`node1`,`node2`, etc)


## LDAP integrations
### LDAP + Native authentication for MongoDB

1. Define the pre-defined LDAP users from this image in `$external`:
   ```
   db.getSiblingDB("$external").createUser({
       user: "dba",
       roles: [ {role: "dbAdmin", db: "admin"} ]
   })

   db.getSiblingDB("$external").createUser({
       user: "writer",
       roles: [ {role: "readWriteAnyDatabase", db: "admin"} ]
   })

   db.getSiblingDB("$external").createUser({
       user: "reader",
       roles: [ {role: "readAnyDatabase", db: "admin"} ]
   })
   ```

### LDAP authorization with MongoDB
1. Check the membership of pre-defined users in LDAP:
   ```
   ldapsearch -x -LLL -D 'cn=admin,dc=tsdocker,dc=com' -w admin -b 'ou=dbUsers,dc=tsdocker,dc=com' memberOf -h ldap://ldap.om.internal:389
   ```
1. On the MongoDB instance, set the following parameters for the `mongod` configuration file:
   ```
   security:
     authorization: enabled
     ldap:
       servers: <ip_host_machine>
       bind:
         method: "simple"
         queryUser: "cn=admin,dc=tsdocker,dc=com"
         queryPassword: "admin"
       transportSecurity: "none"
       userToDNMapping:
         '[
           {
             match: "(.+)",
             substitution: "uid={0},ou=dbUsers,dc=tsdocker,dc=com"
           }
         ]'
       authz:
          queryTemplate: "{USER}?memberOf?base"
   setParameter:
     authenticationMechanisms: PLAIN
   ```
1. Verify the configuration by runnig `mongoldap`:
   ```
   mongoldap --config <mongod_config_file> --user <username> --password Password1! --ldapServers <ip_host_machine> --ldapTransportSecurity none
   ```
1. Define roles for pre-defined LDAP users in `admin`:
   ```
   db.getSiblingDB("admin").createRole({
       role: "cn=dbAdmin,ou=dbRoles,dc=tsdocker,dc=com",
       privileges: [],
       roles: [ "dbAdmin" ]
   })

   db.getSiblingDB("admin").createRole({
       role: "cn=readWriteAnyDatabase,ou=dbRoles,dc=tsdocker,dc=com",
       privileges: [],
       roles: [ "readWriteAnyDatabase" ]
   })

   db.getSiblingDB("admin").createRole({
       role: "cn=read,ou=dbRoles,dc=tsdocker,dc=com",
       privileges: [],
       roles: [ "readAnyDatabase" ]
   })
   ```
1. Authenticate with an LDAP user:
   * When connecting with the mongo shell:
      ```
      mongo --username <username> --password Password1! --authenticationDatabase '$external' --authenticationMechanism PLAIN
      ```
   * Once connected with the mongo shell:
      ```
      db.getSiblingDB("$external").auth({mechanism: "PLAIN", user: <username>, pwd: <password>})
      ``` 
Refer to the MongoDB documentation on [LDAP authorisation](https://docs.mongodb.com/manual/core/security-ldap-external/) for further details.

### Ops Manager users authentication and authorisation
1. Create a user in the Application Database. The name for this user should be either `owner` or `admin` to match the already existant user in LDAP.
1. Follow the procedure described in the documentation on [Configure Ops Manager Users for LDAP Authentication and Authorization](https://docs.opsmanager.mongodb.com/current/tutorial/configure-for-ldap-authentication/). Providing the following values:
   - LDAP URI: ldap://<ip_host_machine>
   - LDAP Bind Dn: cn=admin,dc=tsdocker,dc=com
   - LDAP Bind Password: admin
   - LDAP User Base Dn: dc=tsdocker,dc=com
   - LDAP User Search Attribute: uid
   - LDAP Group Member Attribute (only 3.6): member
   - LDAP Global Role Owner: cn=owners,ou=omgroups,dc=tsdocker,dc=com
   - LDAP Global Role Read Only: cn=readers,ou=omgroups,dc=tsdocker,dc=com