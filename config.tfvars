region                = "eu-west-1"
domain                = "example"          # name of the user directory domain, will be suffixed with `.com`
admin_password        = "Secure_Password1" # password for the Administrator account used to manage users in AD
default_user_password = "Please_ch4nge"    # password that will be assigned to all newly created workspace users
#bundle_id = "wsb-xxx"  # the bundle id (including the image) - defaults to "wsb-clj85qzj1" amz linux 2
# terraform will create a workspace for each of the below users, it will attempt to create the users automatically if
# auto_create_users is set to true
users = [
  "testUser",
  "testUserTwo",
]
auto_create_users = true
