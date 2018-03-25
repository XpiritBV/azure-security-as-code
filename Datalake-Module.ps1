az dls fs access set-entry --account accountdls1 --path /dir/subdir --acl-spec 'user:username@domain.com:rwx'

az dls fs access set-entry --acl-spec 'other:ecf90874-b567-4c39-9f1a-8e57ee3a8b8a:rwx' --account accountdls1 --path /aap/aapsub1

az dls fs list --account accountdls1 --path \aap

az dls fs list --account rvodls1 --path /