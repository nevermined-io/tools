# OpenLdap

Nevermined Tools allows the integration with OpenLdap for scenarios where it's necessary
to provide a user and groups access control using a directory service as backend for
the identities able to participate in the service agreements.

For doing that nevermined-tools can be started with the `--ldap` flag. This will start a
openldap container listening in the port `1389`. You can find more information about
the configuration used in the `constants.rc` file.

## Pre-loaded data

For testing purposes, the openldap instance pre-loads some data in the `dc=nevermined,dc=io` base.
The LDIFs of data preloaded can be found in the `ACL/ldap/` folder. This includes:

* An organization with a **People** `ou=People,ou=groups,dc=nevermined,dc=io` group where all the employees belong
* Within the **groups** group 2 different internal department groups (sales, finance)
* An external group where is included the Acme Corp. external company `ou=acme,ou=external,ou=groups,dc=nevermined,dc=io`
* Three users distributed in the following groups:
  - Alice is an internal employee working at **sales** department
  - Bob is an internal employee working at **finance** department
  - John is not an internal employee, he works at **acme** external company
* All the users have associated their ethereum public address in the `registeredAddress` attribute


## Interacting with OpenLdap

For loading some LDIF data:
```bash
ldapadd -h localhost -p 1389 -x -w nevermined -c  -D "cn=admin,dc=nevermined,dc=io" -f 100-group-sales.ldif

adding new entry "ou=groups,dc=nevermined,dc=io"

adding new entry "ou=sales,ou=groups,dc=nevermined,dc=io"

```

Running a search:
```bash
ldapsearch -h localhost -p 1389 -x -w nevermined -D "cn=admin,dc=nevermined,dc=io" -b "ou=People,ou=groups,dc=nevermined,dc=io" uid=* memberOf

# extended LDIF
#
# LDAPv3
# base <cn=People,ou=groups,dc=nevermined,dc=io> with scope subtree
# filter: uid=*
# requesting: memberOf
#

# alice, People, groups, nevermined.io
dn: uid=alice,cn=People,ou=groups,dc=nevermined,dc=io
memberOf: cn=sales,ou=groups,dc=nevermined,dc=io

# bob, People, groups, nevermined.io
dn: uid=bob,cn=People,ou=groups,dc=nevermined,dc=io
memberOf: cn=finance,ou=groups,dc=nevermined,dc=io

# search result
search: 2
result: 0 Success
```
