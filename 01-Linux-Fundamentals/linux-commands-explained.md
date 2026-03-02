# Linux Commands Explained — Simple Guide with Examples

> Every command is explained like you're teaching a friend. No jargon, just plain English + real examples you can copy-paste.

---

## Table of Contents

1. [File & Directory Commands](#1--file--directory-commands)
2. [Permissions Commands](#2--permissions-commands)
3. [Text Processing Commands](#3--text-processing-commands)
4. [Process Management Commands](#4--process-management-commands)
5. [Disk & Storage Commands](#5--disk--storage-commands)
6. [Networking Commands](#6--networking-commands)
7. [User Management Commands](#7--user-management-commands)
8. [Package Management Commands](#8--package-management-commands)
9. [Archives & Compression Commands](#9--archives--compression-commands)
10. [System Info Commands](#10--system-info-commands)
11. [Cron & Scheduling Commands](#11--cron--scheduling-commands)
12. [SSH & Security Commands](#12--ssh--security-commands)

---

## 1 — File & Directory Commands

These commands help you move around the file system, create files/folders, copy, delete, and search for things — basically like using File Explorer, but with text commands.

---

### `ls` — List files and folders

> **Think of it as:** Opening a folder to see what's inside.

```bash
ls              # Show files in current folder
ls -l           # Show files with details (size, date, permissions)
ls -la          # Show ALL files including hidden ones (files starting with .)
ls -lh          # Show files with human-readable sizes (KB, MB, GB)
ls /var/log     # Show files in a specific folder
```

---

### `cd` — Change directory (move into a folder)

> **Think of it as:** Walking into a different room.

```bash
cd /home/ubuntu         # Go to /home/ubuntu folder
cd ..                   # Go back one folder (parent folder)
cd ~                    # Go to your home folder
cd -                    # Go back to the last folder you were in
cd /var/log             # Go to the log folder
```

---

### `pwd` — Print working directory (where am I?)

> **Think of it as:** Checking the sign on the door — "You are here."

```bash
pwd
# Output: /home/ubuntu
```

---

### `cp` — Copy files or folders

> **Think of it as:** Making a photocopy of a document.

```bash
cp file.txt backup.txt              # Copy file.txt and name the copy backup.txt
cp file.txt /tmp/                   # Copy file.txt into the /tmp folder
cp -r myfolder/ /backup/            # Copy an entire folder (-r = recursive, means "everything inside too")
```

---

### `mv` — Move or rename files

> **Think of it as:** Picking up a file and putting it somewhere else. Also used to rename.

```bash
mv file.txt /tmp/                   # Move file.txt to /tmp folder
mv oldname.txt newname.txt          # Rename a file
mv myfolder/ /backup/               # Move an entire folder
```

---

### `rm` — Remove (delete) files or folders

> **Think of it as:** Throwing something in the trash — permanently. No recycling bin!

```bash
rm file.txt                         # Delete a file
rm -r myfolder/                     # Delete a folder and everything inside it
rm -rf myfolder/                    # Force delete without asking (be VERY careful!)
rm -i file.txt                      # Ask for confirmation before deleting
```

⚠️ **Warning:** `rm -rf /` will delete EVERYTHING on the server. Never run this!

---

### `mkdir` — Make a new directory (folder)

> **Think of it as:** Creating a new empty folder.

```bash
mkdir projects                      # Create a folder called "projects"
mkdir -p /home/ubuntu/a/b/c         # Create nested folders (all levels at once)
```

---

### `touch` — Create an empty file (or update timestamp)

> **Think of it as:** Creating a blank sheet of paper.

```bash
touch notes.txt                     # Create an empty file called notes.txt
touch file1.txt file2.txt file3.txt # Create multiple files at once
```

---

### `find` — Search for files

> **Think of it as:** Searching your entire hard drive for a specific file.

```bash
find / -name "nginx.conf"                   # Find a file named nginx.conf anywhere
find /home -name "*.log"                     # Find all .log files in /home
find /var/log -size +100M                    # Find files larger than 100MB
find / -name "*.tmp" -mtime +7              # Find .tmp files not modified in 7+ days
find /home -type d -name "backup"            # Find only directories named "backup"
find / -user ubuntu                          # Find all files owned by user "ubuntu"
```

---

### `locate` — Find files quickly (uses a database)

> **Think of it as:** Google for your file system — fast but may be slightly outdated.

```bash
sudo updatedb           # Update the file database first
locate nginx.conf       # Instantly find where nginx.conf is
```

---

### `stat` — Show detailed info about a file

> **Think of it as:** Looking at the "Properties" of a file (size, creation date, etc.).

```bash
stat myfile.txt
# Shows: size, permissions, owner, last access time, last modified time
```

---

### `file` — Identify what type a file is

> **Think of it as:** Asking "What kind of document is this?"

```bash
file photo.jpg          # Output: JPEG image data
file script.sh          # Output: Bash script, ASCII text
file mystery            # Tells you what it is even without an extension
```

---

### `tree` — Show folder structure as a tree

> **Think of it as:** A visual map of your folders and files.

```bash
tree                    # Show tree of current directory
tree /var/log           # Show tree of /var/log
tree -L 2              # Show only 2 levels deep
```

---

### `ln` — Create links (shortcuts)

> **Think of it as:** Creating a shortcut on your desktop.

```bash
ln file.txt hardlink.txt            # Hard link — two names for the same data
ln -s /var/log/syslog mylog         # Soft link (symlink) — a shortcut that points to the original
```

**Hard link:** Like having two keys to the same room. Delete one, the room still exists.
**Soft link:** Like a shortcut icon. Delete the original, the shortcut breaks.

---

### `basename` — Get just the filename from a full path

```bash
basename /home/ubuntu/docs/report.pdf
# Output: report.pdf
```

---

### `dirname` — Get just the folder path from a full path

```bash
dirname /home/ubuntu/docs/report.pdf
# Output: /home/ubuntu/docs
```

---

### `realpath` — Show the full absolute path

```bash
realpath myfile.txt
# Output: /home/ubuntu/projects/myfile.txt
```

---

### `readlink` — Show where a symlink points

```bash
readlink /usr/bin/python3
# Output: /usr/bin/python3.10
```

---

## 2 — Permissions Commands

Permissions control WHO can do WHAT with a file. Think of it as a key card system — some people can enter a room, some can only look through the window.

---

### `chmod` — Change file permissions

> **Think of it as:** Changing who has the key to a room.

**Number system (most common):**
```
Owner  Group  Others
 r w x  r w x  r w x
 4 2 1  4 2 1  4 2 1
```

```bash
chmod 755 script.sh     # Owner=all (7), Group=read+execute (5), Others=read+execute (5)
chmod 644 config.txt    # Owner=read+write (6), Group=read (4), Others=read (4)
chmod 700 secret.sh     # Owner=all access, nobody else can touch it
chmod +x script.sh      # Make file executable (quick way)
chmod -w file.txt       # Remove write permission
```

**Common permission combos:**
| Number | Meaning | Use Case |
|--------|---------|----------|
| `755` | Owner: full, Others: read+execute | Scripts, programs |
| `644` | Owner: read+write, Others: read only | Config files, documents |
| `700` | Owner only: full access | Private scripts, SSH keys |
| `600` | Owner only: read+write | SSH private keys, secrets |
| `777` | Everyone: full access | ⚠️ Avoid! Security risk |

---

### `chown` — Change file owner

> **Think of it as:** Transferring ownership of a room to someone else.

```bash
chown ubuntu file.txt               # Change owner to "ubuntu"
chown ubuntu:devops file.txt        # Change owner to "ubuntu" and group to "devops"
chown -R ubuntu:ubuntu /var/www/    # Change owner of folder and ALL contents inside
```

---

### `chgrp` — Change file group

> **Think of it as:** Moving a file to a different department.

```bash
chgrp developers project/           # Change group to "developers"
chgrp -R www-data /var/www/         # Change group of folder and everything inside
```

---

### `umask` — Set default permissions for new files

> **Think of it as:** Setting the default security level for all new rooms built in the building.

```bash
umask                   # Show current umask (e.g., 0022)
umask 027               # New files: owner=full, group=read+execute, others=nothing
```

---

### `getfacl` / `setfacl` — Advanced permissions (ACLs)

> **Think of it as:** Giving a specific person a special key, beyond the normal rules.

```bash
getfacl file.txt                            # View ACL permissions
setfacl -m u:john:rw file.txt              # Give user "john" read+write access
setfacl -m g:developers:rx project/         # Give "developers" group read+execute
setfacl -x u:john file.txt                 # Remove john's special access
```

---

## 3 — Text Processing Commands

These commands help you read, search, filter, and transform text inside files. Think of them as your Swiss Army knife for text.

---

### `cat` — Show entire file contents

> **Think of it as:** Reading a document from start to finish.

```bash
cat file.txt                    # Print all contents of file.txt
cat file1.txt file2.txt         # Print two files one after another
cat > newfile.txt               # Create a file and type content (Ctrl+D to save)
cat >> file.txt                 # Append text to end of a file
```

---

### `less` — View file page by page

> **Think of it as:** Scrolling through a PDF (one page at a time).

```bash
less /var/log/syslog            # Open file — use arrow keys, Page Up/Down, q to quit
```

---

### `head` — Show first few lines

> **Think of it as:** Reading just the beginning of a book.

```bash
head file.txt                   # Show first 10 lines (default)
head -n 5 file.txt              # Show first 5 lines
head -n 20 /var/log/syslog      # Show first 20 lines of syslog
```

---

### `tail` — Show last few lines

> **Think of it as:** Jumping to the end of a book.

```bash
tail file.txt                   # Show last 10 lines
tail -n 20 /var/log/syslog      # Show last 20 lines
tail -f /var/log/syslog         # ⭐ LIVE follow — watch new lines as they appear (great for monitoring!)
```

---

### `grep` — Search for text inside files

> **Think of it as:** Ctrl+F for the terminal. Find specific words in files.

```bash
grep "error" /var/log/syslog            # Find lines containing "error"
grep -i "error" /var/log/syslog         # Case-insensitive search
grep -r "TODO" /home/ubuntu/project/    # Search recursively in all files
grep -n "error" file.txt                # Show line numbers
grep -c "error" file.txt                # Count how many matches
grep -v "debug" file.txt               # Show lines that DON'T contain "debug"
grep -E "error|warning|fail" syslog    # Search for multiple words at once
```

---

### `awk` — Process and extract columns from text

> **Think of it as:** A smart spreadsheet that pulls specific columns from your data.

```bash
awk '{print $1}' file.txt               # Print column 1 of each line
awk '{print $1, $3}' file.txt           # Print columns 1 and 3
awk -F: '{print $1}' /etc/passwd        # Use : as separator, print usernames
awk '$3 > 1000' /etc/passwd             # Print lines where column 3 > 1000
df -h | awk '{print $1, $5}'            # Show disk name and usage percentage
```

---

### `sed` — Find and replace text in files

> **Think of it as:** Find & Replace in Word — but for files in the terminal.

```bash
sed 's/old/new/' file.txt               # Replace first "old" with "new" on each line
sed 's/old/new/g' file.txt              # Replace ALL "old" with "new" (g = global)
sed -i 's/old/new/g' file.txt           # Edit the file directly (in-place)
sed '5d' file.txt                       # Delete line 5
sed -n '10,20p' file.txt               # Print only lines 10 to 20
```

---

### `cut` — Extract specific columns/characters

> **Think of it as:** Cutting a column out of a table.

```bash
cut -d: -f1 /etc/passwd                # Split by : and get field 1 (usernames)
cut -d, -f2,3 data.csv                 # Get columns 2 and 3 from a CSV file
cut -c1-10 file.txt                    # Get first 10 characters of each line
```

---

### `sort` — Sort lines

> **Think of it as:** Arranging items alphabetically or numerically.

```bash
sort file.txt                           # Sort alphabetically
sort -n numbers.txt                     # Sort numerically
sort -r file.txt                        # Sort in reverse order
sort -u file.txt                        # Sort and remove duplicates
sort -t: -k3 -n /etc/passwd            # Sort /etc/passwd by column 3 (UID) numerically
```

---

### `uniq` — Remove duplicate lines (use after sort)

> **Think of it as:** Removing copied entries from a list.

```bash
sort file.txt | uniq                    # Remove duplicates
sort file.txt | uniq -c                 # Count how many times each line appears
sort file.txt | uniq -d                 # Show only duplicated lines
```

---

### `wc` — Count words, lines, characters

> **Think of it as:** Word count — like in Microsoft Word.

```bash
wc file.txt                             # Show lines, words, characters
wc -l file.txt                          # Count only lines
wc -w file.txt                          # Count only words
ls | wc -l                              # Count how many files in a folder
```

---

### `tr` — Translate (replace) characters

> **Think of it as:** A character-level find-and-replace.

```bash
echo "hello" | tr 'a-z' 'A-Z'          # Convert to UPPERCASE → HELLO
echo "hello world" | tr ' ' '_'        # Replace spaces with underscores
echo "aabbcc" | tr -d 'b'              # Delete all 'b' characters → aacc
cat file.txt | tr -s ' '               # Squeeze multiple spaces into one
```

---

### `diff` — Compare two files

> **Think of it as:** Spot-the-difference between two versions of a file.

```bash
diff file1.txt file2.txt                # Show what's different
diff -u file1.txt file2.txt            # Unified format (more readable, like GitHub diffs)
diff -r dir1/ dir2/                    # Compare entire directories
```

---

### `tee` — Write output to screen AND a file at the same time

> **Think of it as:** A T-pipe that splits water into two directions.

```bash
echo "hello" | tee output.txt          # Show "hello" on screen AND save to output.txt
ls -la | tee filelist.txt              # Save directory listing to file AND display it
echo "new line" | tee -a output.txt    # Append to file instead of overwriting
```

---

### `xargs` — Take output from one command and feed it as arguments to another

> **Think of it as:** Passing a list to another command, one by one.

```bash
find /tmp -name "*.log" | xargs rm     # Find all .log files and delete them
cat urls.txt | xargs wget              # Download all URLs listed in a file
echo "file1 file2 file3" | xargs touch # Create all three files
```

---

### `column` — Format output into neat columns

```bash
cat /etc/passwd | column -t -s:        # Display /etc/passwd in clean table format
mount | column -t                      # Display mount info neatly
```

---

### `paste` — Merge lines from multiple files side by side

```bash
paste names.txt ages.txt               # Combine line-by-line: "John    25"
paste -d, names.txt ages.txt          # Use comma as separator: "John,25"
```

---

### `join` — Join two files on a common field (like SQL JOIN)

```bash
join file1.txt file2.txt               # Join on first column (files must be sorted)
```

---

## 4 — Process Management Commands

Processes are programs currently running on your server. Managing them is like managing employees — you can check who's working, pause them, or stop them.

---

### `ps` — Show running processes (snapshot)

> **Think of it as:** Taking a photo of all employees at their desks right now.

```bash
ps                      # Show your own processes
ps aux                  # Show ALL processes from ALL users
ps aux | grep nginx     # Find nginx processes
ps -ef                  # Another format showing parent-child relationships
ps -eo pid,user,%mem,%cpu,cmd --sort=-%mem | head  # Top memory consumers
```

---

### `top` — Live process monitor

> **Think of it as:** A live security camera feed of all work happening on the server.

```bash
top                     # Open live monitor (press q to quit)
# Inside top:
#   M = sort by memory
#   P = sort by CPU
#   k = kill a process
#   q = quit
```

---

### `htop` — Better version of top (colorful, interactive)

```bash
htop                    # Install first: sudo apt install htop (or sudo yum install htop)
```

---

### `kill` — Stop a process by its ID

> **Think of it as:** Telling a specific employee to stop what they're doing.

```bash
kill 1234               # Gently ask process 1234 to stop (SIGTERM)
kill -9 1234            # Force kill process 1234 (SIGKILL — last resort)
kill -HUP 1234          # Restart/reload process (e.g., reload config)
```

---

### `killall` — Stop all processes with a name

```bash
killall nginx           # Stop all nginx processes
killall -9 python3      # Force kill all python3 processes
```

---

### `pgrep` / `pkill` — Find or kill processes by name

```bash
pgrep nginx             # Show PIDs of all nginx processes
pgrep -u ubuntu         # Show all processes owned by user "ubuntu"
pkill nginx             # Kill all nginx processes
```

---

### `nice` / `renice` — Set process priority

> **Think of it as:** Telling an employee "your task is low priority" or "rush this!"

```bash
nice -n 10 ./script.sh          # Start script with lower priority (nice = less urgent)
renice -5 -p 1234               # Change running process 1234 to higher priority
# -20 = highest priority, 19 = lowest priority
```

---

### `nohup` — Keep process running after you log out

> **Think of it as:** "Keep working even after I leave the building."

```bash
nohup ./long-task.sh &          # Run in background and keep running after logout
nohup ./script.sh > output.log 2>&1 &  # Run + save all output to a file
```

---

### `bg` / `fg` / `jobs` — Manage background/foreground jobs

```bash
./script.sh             # Running in foreground (Ctrl+Z to pause)
bg                      # Resume paused job in background
fg                      # Bring background job back to foreground
jobs                    # List all background jobs
```

---

### `systemctl` — Manage system services (start, stop, enable)

> **Think of it as:** The master switch panel for all server services.

```bash
systemctl start nginx           # Start nginx
systemctl stop nginx            # Stop nginx
systemctl restart nginx         # Restart nginx
systemctl status nginx          # Check if nginx is running
systemctl enable nginx          # Auto-start nginx on boot
systemctl disable nginx         # Don't auto-start on boot
systemctl list-units --type=service  # List all services
systemctl is-active nginx       # Quick check: "active" or "inactive"
```

---

### `journalctl` — Read system logs (from systemd)

> **Think of it as:** Reading the diary of the server — everything that happened.

```bash
journalctl                              # Show all logs
journalctl -u nginx                     # Logs for nginx only
journalctl -u nginx --since "1 hour ago"  # Last hour's nginx logs
journalctl -f                           # Follow logs in real-time (like tail -f)
journalctl --disk-usage                 # How much space logs are using
journalctl -p err                       # Show only error-level messages
```

---

## 5 — Disk & Storage Commands

These commands help you check disk space, manage partitions, and understand storage — like checking how full your closets are.

---

### `df` — Show disk space usage

> **Think of it as:** Checking how full each hard drive is.

```bash
df                      # Show all disk usage
df -h                   # Human-readable (GB, MB instead of bytes)
df -h /                 # Check only the root partition
df -h /home             # Check /home partition usage
```

---

### `du` — Show folder/file sizes

> **Think of it as:** "Which folder is eating all my disk space?"

```bash
du -h /var/log                  # Show size of each subfolder in /var/log
du -sh /var/log                 # Show TOTAL size of /var/log
du -sh *                        # Size of each item in current directory
du -h --max-depth=1 /           # Size of top-level folders
du -sh /home/* | sort -rh | head -5  # Top 5 largest user directories
```

---

### `lsblk` — List all block devices (disks/partitions)

> **Think of it as:** Seeing all hard drives and partitions connected to the server.

```bash
lsblk                  # Show all disks and partitions as a tree
lsblk -f               # Also show filesystem type (ext4, xfs, etc.)
```

---

### `mount` / `umount` — Attach or detach a disk

> **Think of it as:** Plugging in or unplugging a USB drive.

```bash
mount /dev/xvdf /mnt/data              # Mount a disk to /mnt/data
umount /mnt/data                        # Unmount it
mount | grep xvdf                       # Check if a disk is mounted
```

---

### `fdisk` — Manage disk partitions

> **Think of it as:** Splitting a hard drive into sections.

```bash
sudo fdisk -l                           # List all disks and partitions
sudo fdisk /dev/xvdf                    # Open partition manager for a disk
```

---

### `mkfs` — Create a filesystem on a disk

> **Think of it as:** Formatting a USB drive before first use.

```bash
sudo mkfs.ext4 /dev/xvdf               # Format as ext4
sudo mkfs.xfs /dev/xvdf                # Format as XFS
```

---

### `blkid` — Show UUID and filesystem type of disks

```bash
sudo blkid                              # Show all disk UUIDs and types
```

---

## 6 — Networking Commands

These commands help you check network connections, download files, test connectivity, and troubleshoot network issues.

---

### `ip` — Show/manage network interfaces and addresses

> **Think of it as:** Checking your server's network card and IP address.

```bash
ip addr                         # Show all IP addresses
ip addr show eth0               # Show IP for specific interface
ip route                        # Show routing table (how traffic flows)
ip link show                    # Show network interfaces status
```

---

### `ss` — Show network connections (replaces netstat)

> **Think of it as:** Checking which doors (ports) are open and who's connected.

```bash
ss -tuln                        # Show all listening ports (TCP + UDP)
ss -tp                          # Show connections with process names
ss -s                           # Summary of all connections
ss -tuln | grep 80              # Check if port 80 is open
```

---

### `netstat` — Older way to show network connections

```bash
netstat -tuln                   # Show listening ports
netstat -an | grep ESTABLISHED  # Show active connections
```

---

### `curl` — Transfer data from/to a URL

> **Think of it as:** A mini web browser in the terminal.

```bash
curl https://example.com                # Get webpage content
curl -I https://example.com             # Show only headers (status code, server info)
curl -o file.zip https://example.com/f  # Download and save as file.zip
curl -X POST -d "name=john" https://api.example.com  # Send POST request
curl -s https://checkip.amazonaws.com   # Check your public IP address
```

---

### `wget` — Download files from the internet

> **Think of it as:** A download manager.

```bash
wget https://example.com/file.zip       # Download a file
wget -O myfile.zip https://example.com/f  # Download and rename
wget -q https://example.com/file.zip    # Quiet mode (no progress bar)
wget -r https://example.com             # Download entire website (recursive)
```

---

### `ping` — Test if a server is reachable

> **Think of it as:** Knocking on a door to see if anyone's home.

```bash
ping google.com                 # Ping Google (Ctrl+C to stop)
ping -c 5 google.com            # Send exactly 5 pings then stop
ping -c 3 10.0.1.5              # Ping a private server
```

---

### `traceroute` — Show the path to a server (every hop)

> **Think of it as:** GPS navigation showing every stop along the route.

```bash
traceroute google.com           # Show all network hops to reach Google
traceroute -n 8.8.8.8           # Show hops using IP addresses only (faster)
```

---

### `nslookup` / `dig` — DNS lookups (translate domain → IP)

> **Think of it as:** Looking up a phone number in the phone book.

```bash
nslookup google.com             # Find IP address of google.com
dig google.com                  # More detailed DNS lookup
dig +short google.com           # Just show the IP address
dig google.com MX               # Find mail servers for a domain
```

---

### `scp` — Securely copy files between servers

> **Think of it as:** Emailing a file to another server (encrypted).

```bash
scp file.txt ubuntu@10.0.1.5:/home/ubuntu/    # Copy file TO remote server
scp ubuntu@10.0.1.5:/tmp/log.txt ./            # Copy file FROM remote server
scp -r myfolder/ ubuntu@10.0.1.5:/backup/      # Copy entire folder
scp -i mykey.pem file.txt ec2-user@1.2.3.4:/   # Copy using SSH key
```

---

### `rsync` — Sync files between locations (smart copy — only copies changes)

> **Think of it as:** A smart backup tool that only copies what changed.

```bash
rsync -avz /source/ /backup/                       # Sync local folders
rsync -avz /local/data/ ubuntu@server:/backup/      # Sync to remote server
rsync -avz --delete /source/ /backup/               # Sync and delete extras in backup
# -a = archive mode (keeps permissions), -v = verbose, -z = compress during transfer
```

---

### `nc` (netcat) — Test network connections

> **Think of it as:** A raw network tool — test if a port is open.

```bash
nc -zv 10.0.1.5 80             # Check if port 80 is open on a server
nc -zv 10.0.1.5 22             # Check if SSH port is open
nc -l 8080                     # Listen on port 8080 (start a simple server)
```

---

### `tcpdump` — Capture network traffic (packet sniffer)

> **Think of it as:** Recording all conversations on the network.

```bash
sudo tcpdump -i eth0                        # Capture all traffic on eth0
sudo tcpdump -i eth0 port 80                # Capture only port 80 traffic
sudo tcpdump -i eth0 -c 50                  # Capture 50 packets then stop
sudo tcpdump -i eth0 -w capture.pcap        # Save capture to file for analysis
```

---

### `nmap` — Scan network for open ports

> **Think of it as:** Checking which doors and windows are open on a building.

```bash
nmap 10.0.1.5                   # Scan common ports on a server
nmap -p 22,80,443 10.0.1.5      # Scan specific ports
nmap -sV 10.0.1.5               # Detect service versions
nmap 10.0.1.0/24                # Scan entire subnet
```

---

## 7 — User Management Commands

These commands help you create, modify, and manage users and groups — like managing employee accounts.

---

### `useradd` — Create a new user

> **Think of it as:** Hiring a new employee and giving them an ID badge.

```bash
sudo useradd john                       # Create user "john"
sudo useradd -m john                    # Create user with a home directory
sudo useradd -m -s /bin/bash john       # Create user with home dir and bash shell
sudo useradd -m -G developers john      # Create user and add to "developers" group
```

---

### `usermod` — Modify a user

> **Think of it as:** Updating an employee's access or department.

```bash
sudo usermod -aG docker john            # Add john to "docker" group (-a = append)
sudo usermod -s /bin/bash john          # Change john's shell to bash
sudo usermod -L john                    # Lock john's account (disable login)
sudo usermod -U john                    # Unlock john's account
```

---

### `userdel` — Delete a user

> **Think of it as:** Removing an employee's access when they leave.

```bash
sudo userdel john                       # Delete user (keep home folder)
sudo userdel -r john                    # Delete user AND their home folder
```

---

### `passwd` — Change a password

```bash
passwd                                  # Change YOUR password
sudo passwd john                        # Change john's password (as admin)
sudo passwd -l john                     # Lock john's password
sudo passwd -e john                     # Force john to change password on next login
```

---

### `groupadd` / `groupdel` — Manage groups

```bash
sudo groupadd developers               # Create a group
sudo groupdel developers               # Delete a group
```

---

### `id` — Show user and group info

```bash
id                      # Show your UID, GID, and groups
id john                 # Show john's info
```

---

### `who` / `w` / `last` — See who's logged in

```bash
who                     # Who is currently logged in
w                       # Who's logged in + what they're doing
last                    # Show login history
last -5                 # Show last 5 logins
whoami                  # Show your current username
```

---

### `su` — Switch user

> **Think of it as:** Temporarily becoming another employee.

```bash
su john                 # Switch to user john (need john's password)
su - john               # Switch to john with john's full environment
su -                    # Switch to root user
```

---

### `sudo` — Run command as admin (superuser)

> **Think of it as:** "I need admin privileges for this one command."

```bash
sudo apt update                         # Run apt update as admin
sudo -i                                 # Open a root shell
sudo -u john whoami                     # Run command as user "john"
```

---

### `visudo` — Safely edit sudo permissions

```bash
sudo visudo                             # Opens /etc/sudoers safely
# Add: john ALL=(ALL) NOPASSWD: ALL    # Give john sudo without password
```

---

## 8 — Package Management Commands

Package managers install, update, and remove software — like an app store for your server.

---

### `apt` — Package manager for Ubuntu/Debian

```bash
sudo apt update                         # Refresh the list of available packages
sudo apt upgrade                        # Upgrade all installed packages
sudo apt install nginx                  # Install nginx
sudo apt remove nginx                   # Remove nginx (keep config)
sudo apt purge nginx                    # Remove nginx AND config files
sudo apt autoremove                     # Remove unused packages
apt search nginx                        # Search for packages
apt list --installed                    # List installed packages
```

---

### `yum` / `dnf` — Package manager for Amazon Linux/CentOS/RHEL

```bash
sudo yum update                         # Update all packages
sudo yum install nginx                  # Install nginx
sudo yum remove nginx                   # Remove nginx
sudo yum list installed                 # List installed packages
sudo yum search nginx                   # Search for packages

# dnf is the newer version (same syntax):
sudo dnf install nginx
```

---

### `rpm` / `dpkg` — Low-level package tools

```bash
rpm -qa                                 # List all installed RPM packages
rpm -qi nginx                           # Show info about nginx package
dpkg -l                                 # List all installed DEB packages
dpkg -i package.deb                     # Install a .deb file manually
```

---

## 9 — Archives & Compression Commands

These commands help you zip and unzip files — like creating a .zip folder on Windows.

---

### `tar` — Create or extract archives

> **Think of it as:** Packing a suitcase (create) or unpacking it (extract).

```bash
# Create archives:
tar -cvf archive.tar folder/           # Create a .tar file (no compression)
tar -czvf archive.tar.gz folder/       # Create .tar.gz (compressed with gzip)
tar -cjvf archive.tar.bz2 folder/      # Create .tar.bz2 (compressed with bzip2)

# Extract archives:
tar -xvf archive.tar                   # Extract .tar
tar -xzvf archive.tar.gz               # Extract .tar.gz
tar -xjvf archive.tar.bz2              # Extract .tar.bz2
tar -xzvf archive.tar.gz -C /target/   # Extract to a specific folder

# Remember: c=create, x=extract, v=verbose, f=file, z=gzip, j=bzip2
```

---

### `gzip` / `gunzip` — Compress/decompress files

```bash
gzip large-file.log                     # Compress → large-file.log.gz (original deleted)
gunzip large-file.log.gz                # Decompress → large-file.log
gzip -k file.log                        # Compress and KEEP original file
```

---

### `zip` / `unzip` — Create/extract .zip files

```bash
zip archive.zip file1.txt file2.txt     # Create a zip with two files
zip -r archive.zip myfolder/            # Zip an entire folder
unzip archive.zip                       # Extract zip file
unzip archive.zip -d /target/           # Extract to specific folder
unzip -l archive.zip                    # List contents without extracting
```

---

### `bzip2` / `xz` — Other compression tools

```bash
bzip2 file.txt                          # Compress with bzip2 (better ratio than gzip)
xz file.txt                             # Compress with xz (best ratio, slowest)
```

---

### `zcat` — Read compressed files without extracting

```bash
zcat file.gz                            # View contents of .gz file
zcat access.log.gz | grep "error"       # Search inside compressed log
```

---

## 10 — System Info Commands

These commands tell you about the server's hardware, performance, and current state.

---

### `uname` — Show system info

```bash
uname -a                # Show everything (OS, kernel, architecture)
uname -r                # Show kernel version
uname -m                # Show architecture (x86_64, arm64, etc.)
```

---

### `hostname` — Show or set the server name

```bash
hostname                # Show current hostname
hostname -I             # Show all IP addresses
sudo hostnamectl set-hostname web-server-01  # Change hostname
```

---

### `uptime` — How long the server has been running

```bash
uptime
# Output: 10:30:00 up 45 days, 3:22, 2 users, load average: 0.15, 0.10, 0.05
# "45 days" = server has been on for 45 days without reboot
# "load average" = how busy the CPU is (lower is better)
```

---

### `free` — Show memory (RAM) usage

```bash
free                    # Show memory in bytes
free -h                 # Show memory in human-readable format (GB/MB)
free -m                 # Show memory in megabytes
```

**How to read it:**
```
              total    used    free    available
Mem:          16Gi     8Gi     2Gi     7Gi
Swap:         4Gi      1Gi     3Gi
```
- **available** is the important number — it's how much RAM you can actually use.

---

### `vmstat` — Virtual memory statistics

```bash
vmstat                  # Snapshot of system performance
vmstat 5                # Update every 5 seconds
vmstat 5 10             # Update every 5 seconds, 10 times
```

---

### `iostat` — Disk I/O statistics

```bash
iostat                  # Basic disk I/O info
iostat -x 5             # Detailed I/O stats every 5 seconds
```

---

### `dmesg` — Kernel messages (hardware events)

> **Think of it as:** Reading the server's startup diary and hardware event log.

```bash
dmesg                           # Show all kernel messages
dmesg | tail -20                # Last 20 kernel messages
dmesg | grep -i error           # Find errors
dmesg | grep -i "usb\|disk"    # Find USB or disk related messages
```

---

### `lscpu` — Show CPU info

```bash
lscpu
# Shows: CPU model, cores, threads, architecture, cache sizes
```

---

### `lsof` — List open files (everything is a file in Linux!)

> **Think of it as:** Checking which files and ports are being used by which processes.

```bash
lsof                            # List ALL open files (lots of output!)
lsof -i :80                     # Which process is using port 80?
lsof -u ubuntu                  # Files opened by user "ubuntu"
lsof /var/log/syslog            # Which process has syslog open?
lsof -i -P -n                  # All network connections
```

---

### `strace` — Trace system calls of a process

> **Think of it as:** Watching every single step a program takes internally (for deep debugging).

```bash
strace ls                       # See every system call "ls" makes
strace -p 1234                  # Attach to running process 1234
strace -e open ls               # Only show "open file" calls
```

---

### `sar` — System activity reporter (historical performance)

```bash
sar -u 5 3                      # CPU usage every 5 seconds, 3 samples
sar -r                          # Memory usage history
sar -d                          # Disk I/O history
sar -n DEV                      # Network usage history
```

---

## 11 — Cron & Scheduling Commands

Cron lets you schedule tasks to run automatically — like setting an alarm clock for the server.

---

### `crontab` — Schedule repeating tasks

> **Think of it as:** Setting a recurring alarm. "Every day at 2 AM, run the backup."

```bash
crontab -e                      # Edit your cron jobs
crontab -l                      # List your cron jobs
crontab -r                      # Remove all your cron jobs
sudo crontab -u john -l         # View john's cron jobs
```

**Cron format:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 7, 0 and 7 = Sunday)
│ │ │ │ │
* * * * * command-to-run
```

**Common examples:**
```bash
# Run backup every day at 2:00 AM
0 2 * * * /home/ubuntu/backup.sh

# Run every 5 minutes
*/5 * * * * /home/ubuntu/check-health.sh

# Run every Monday at 9:00 AM
0 9 * * 1 /home/ubuntu/weekly-report.sh

# Run on the 1st of every month at midnight
0 0 1 * * /home/ubuntu/monthly-cleanup.sh

# Run every day at 6:00 AM and 6:00 PM
0 6,18 * * * /home/ubuntu/sync.sh
```

---

### `at` — Schedule a one-time task

> **Think of it as:** "Do this once at a specific time, then forget about it."

```bash
at 10:00 PM                     # Schedule for 10 PM tonight
at> /home/ubuntu/deploy.sh      # Type the command
at> Ctrl+D                      # Press Ctrl+D to save

at now + 30 minutes             # Run 30 minutes from now
at noon tomorrow                # Run tomorrow at noon
atq                             # List pending jobs
atrm 5                          # Remove job #5
```

---

### `systemd timers` — Modern alternative to cron

```bash
systemctl list-timers                   # List all systemd timers
systemctl status apt-daily.timer        # Check a specific timer
```

---

## 12 — SSH & Security Commands

These commands help you connect to servers securely, manage keys, and protect your server from attacks.

---

### `ssh` — Connect to a remote server securely

> **Think of it as:** Logging into another computer remotely.

```bash
ssh ubuntu@10.0.1.5                     # Connect as "ubuntu" to a server
ssh -i mykey.pem ec2-user@1.2.3.4       # Connect using a private key file
ssh -p 2222 ubuntu@10.0.1.5             # Connect on a different port
ssh -v ubuntu@10.0.1.5                  # Verbose mode (for debugging connection issues)
```

---

### `ssh-keygen` — Create SSH keys

> **Think of it as:** Creating a lock-and-key pair. The private key stays with you, the public key goes on the server.

```bash
ssh-keygen -t rsa -b 4096                    # Create a 4096-bit RSA key pair
ssh-keygen -t ed25519                         # Create a modern Ed25519 key (recommended)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/mykey    # Specify output file name
# Creates: mykey (private — keep secret!) and mykey.pub (public — share freely)
```

---

### `ssh-copy-id` — Copy your public key to a server

> **Think of it as:** Giving the server a copy of your key so it recognizes you.

```bash
ssh-copy-id ubuntu@10.0.1.5            # Copy your public key to the server
ssh-copy-id -i ~/.ssh/mykey.pub ubuntu@10.0.1.5  # Copy a specific key
# After this, you can log in without a password!
```

---

### `iptables` — Firewall rules (low level)

> **Think of it as:** Writing specific security rules for the building entrance.

```bash
sudo iptables -L                                # List all firewall rules
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # Allow incoming port 80 (HTTP)
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # Allow incoming port 443 (HTTPS)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # Allow SSH
sudo iptables -A INPUT -j DROP                        # Block everything else
sudo iptables -D INPUT -p tcp --dport 80 -j ACCEPT   # Remove a rule
sudo iptables-save > /etc/iptables.rules              # Save rules
```

---

### `ufw` — Simplified firewall (Ubuntu)

> **Think of it as:** A simple on/off switch for network access.

```bash
sudo ufw enable                         # Turn on firewall
sudo ufw disable                        # Turn off firewall
sudo ufw status verbose                 # Show current rules
sudo ufw allow 22                       # Allow SSH
sudo ufw allow 80                       # Allow HTTP
sudo ufw allow 443                      # Allow HTTPS
sudo ufw allow from 10.0.1.0/24        # Allow traffic from a subnet
sudo ufw deny 3306                      # Block MySQL port
sudo ufw delete allow 80               # Remove a rule
sudo ufw reset                         # Reset all rules
```

---

### `firewalld` — Firewall manager (CentOS/Amazon Linux)

```bash
sudo systemctl start firewalld
sudo firewall-cmd --state                               # Check if running
sudo firewall-cmd --list-all                             # Show all rules
sudo firewall-cmd --add-service=http --permanent         # Allow HTTP
sudo firewall-cmd --add-service=https --permanent        # Allow HTTPS
sudo firewall-cmd --add-port=8080/tcp --permanent        # Allow custom port
sudo firewall-cmd --reload                               # Apply changes
```

---

### `fail2ban` — Block brute-force attacks automatically

> **Think of it as:** A security guard who bans anyone who keeps trying wrong passwords.

```bash
sudo apt install fail2ban               # Install on Ubuntu
sudo systemctl start fail2ban           # Start the service
sudo systemctl enable fail2ban          # Start on boot

sudo fail2ban-client status             # Check status
sudo fail2ban-client status sshd        # Check SSH jail (banned IPs)
sudo fail2ban-client set sshd unbanip 1.2.3.4  # Unban an IP
```

---

## Quick Reference Cheat Sheet

| Task | Command |
|------|---------|
| Where am I? | `pwd` |
| List files | `ls -la` |
| Go to folder | `cd /path/to/folder` |
| Create file | `touch filename` |
| Create folder | `mkdir foldername` |
| Delete file | `rm filename` |
| Copy file | `cp source dest` |
| Move/rename file | `mv old new` |
| Read file | `cat filename` |
| Search in file | `grep "word" filename` |
| Find a file | `find / -name "filename"` |
| Check disk space | `df -h` |
| Check memory | `free -h` |
| See running processes | `ps aux` |
| Kill a process | `kill PID` |
| Check open ports | `ss -tuln` |
| Download a file | `wget URL` |
| Connect to server | `ssh user@ip` |
| Change permissions | `chmod 755 filename` |
| Change owner | `chown user:group file` |
| Install package (Ubuntu) | `sudo apt install name` |
| Install package (Amazon) | `sudo yum install name` |
| Start a service | `sudo systemctl start name` |
| Check server uptime | `uptime` |
| Schedule a task | `crontab -e` |

---

> **Tip:** The best way to learn these commands is to practice them on a real EC2 instance. Break things, fix them, repeat! 💡
