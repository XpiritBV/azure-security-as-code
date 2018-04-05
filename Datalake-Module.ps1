az dls fs access set-entry --account accountdls1 --path /dir/subdir --acl-spec 'user:username@domain.com:rwx'

az dls fs access set-entry --acl-spec 'other:ecf90874-b567-4c39-9f1a-8e57ee3a8b8a:rwx' --account rvodls1 --path /aap/aapsub1

az dls fs list --account accountdls1 --path \aap

az dls fs list --account rvodls1 --path /

#https://docs.microsoft.com/en-us/azure/data-lake-store/data-lake-store-get-started-cli-2.0#work-with-permissions-and-acls-for-a-data-lake-store-account


#We need to use set-entry. We need to add it manually to all the subfolders . The apply to all children in the UI is also doing that. There is no
#setting for recurse. So when a new folder is created, it needs to be reapplied. So creating the folder, should read the setting from its parent
#and then reapply