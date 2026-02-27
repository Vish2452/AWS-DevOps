# Task 2 — Users, Groups & File Permissions

## Objective
Create users and groups, configure file permissions, and set up ACLs for fine-grained access control.

## Steps

### 1. User & Group Management
```bash
# Create groups
sudo groupadd developers
sudo groupadd devops
sudo groupadd readonly

# Create users with groups
sudo useradd -m -s /bin/bash -G developers alice
sudo useradd -m -s /bin/bash -G developers bob
sudo useradd -m -s /bin/bash -G devops charlie
sudo useradd -m -s /bin/bash -G readonly viewer

# Set passwords
sudo passwd alice
sudo passwd bob
sudo passwd charlie

# Verify
id alice
id charlie
cat /etc/group | grep -E "developers|devops|readonly"
getent passwd alice
```

### 2. File Permissions
```bash
# Create project directory structure
sudo mkdir -p /opt/project/{src,config,logs,secrets}

# Set ownership
sudo chown -R root:developers /opt/project/src
sudo chown -R root:devops /opt/project/config
sudo chown -R root:devops /opt/project/logs
sudo chown -R root:devops /opt/project/secrets

# Set permissions
sudo chmod 775 /opt/project/src        # rwxrwxr-x (devs can write)
sudo chmod 770 /opt/project/config     # rwxrwx--- (devops only)
sudo chmod 775 /opt/project/logs       # rwxrwxr-x (devops write, others read)
sudo chmod 700 /opt/project/secrets    # rwx------ (root only)

# Verify
ls -la /opt/project/
```

### 3. Special Permissions
```bash
# SUID — execute as file owner
sudo chmod u+s /opt/project/src/deploy.sh

# SGID — new files inherit group
sudo chmod g+s /opt/project/src

# Sticky Bit — only owner can delete their files
sudo chmod +t /opt/project/logs

# Verify special permissions
ls -la /opt/project/
stat /opt/project/src
```

### 4. ACLs (Access Control Lists)
```bash
# Give viewer read access to src (without changing group)
sudo setfacl -m u:viewer:rx /opt/project/src
sudo setfacl -m u:viewer:r /opt/project/config

# Default ACL for new files
sudo setfacl -d -m g:developers:rwx /opt/project/src

# Verify ACLs
getfacl /opt/project/src
getfacl /opt/project/config

# Remove ACL
sudo setfacl -x u:viewer /opt/project/config
```

### 5. Umask Configuration
```bash
# Check current umask
umask

# Set restrictive umask for a user
echo "umask 027" >> /home/charlie/.bashrc

# Test: create file and check permissions
touch /tmp/test-umask-file
ls -la /tmp/test-umask-file
```

## Validation Checklist
- [ ] Users alice, bob (developers) and charlie (devops) created
- [ ] Directory permissions correctly restrict access
- [ ] SGID set on src/ — new files inherit group
- [ ] Sticky bit set on logs/ — users can't delete others' files
- [ ] ACLs grant viewer read-only access without group membership
- [ ] Umask configured for restrictive defaults
