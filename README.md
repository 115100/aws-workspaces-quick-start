# aws-workspaces-quick-start

This module will spin up any number of aws workspaces, creating all necessary dependencies. 
Please note this is intended to be a quick start, and not for production use. 
Secrets are not handled with the care they should be, passwords are written to tf state (in user data) and will be in
cloud init logs as plain text. 
The terraform plan is split into two stages...

* 01_dependencies - creates a vpc, simple directory and an ec2 instance for managing users. 
* 02_workspaces - launches aws_workspace instances, separate as users must be created first.

## running terraform

This has been tested with terraform v1.2.2, suggest using the same or newer.
Configuration is in a file named `config.tfvars` in the repository root. Edit the file to suit your needs
There are wrapper scripts in each root directory (01_dependencies & 02_workspaces) that will import the required 
variables. You can run with the following.

```shell
cd 01_dependencies
./terraform init
./terraform apply
# take note of the output named registration_code
# wait until users have been created or create manually, see "creating users" section below
cd 02_workspaces
./terraform init
./terraform apply
```
wrapper scripts pass through any flags provided after the command, i.e. you can suffix `-auto-approve` or similar

## creating users

As part of the `01_dependencies` plan an ec2 instance will be provisioned that can be accessed by running a script that
will lookup the ip and private key from terraform state, just run `./ssh-user-management` from the same directory. 
Subsequent runs of apply will be needed to output the latest ip when a plan replaces the instance.
From this instance you can run the following commands to create a user and set a password...

```shell
adcli create-user ${USER} --domain ${DOMAIN} -U Administrator
adcli passwd-user ${USER} --domain ${DOMAIN} -U Administrator
```

Where USER is the user to create and DOMAIN is the `domain` value in config.tfvars with a `.com` suffix i.e. `example.com`.
Both commands will prompt for the Administrator password from config.tfvars, the latter will prompt for a password to set
for the user.

If `auto_create_users` is set there is some crude automation, that will setup users with the provided default password. 
When updating the directory with new users, expect to see failures in the cloud init logs as the create-user command 
is not idempotent and will fail for existing users, the script will however continue. SSH can be used to debug/fix if 
any issues.

## logging in
Follow the instructions on the following site for whichever client you're using.
https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-clients.html

You will need the registration code output from terraform as well as the user password to login.
