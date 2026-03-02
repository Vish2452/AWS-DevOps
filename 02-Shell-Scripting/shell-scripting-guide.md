# Shell Scripting — Complete Guide with Examples

> A practical reference covering every Bash scripting concept with real-world examples and clear explanations.

---

## Table of Contents

1. [Getting Started — Your First Script](#1--getting-started--your-first-script)
2. [Variables & Data Types](#2--variables--data-types)
3. [Quoting — Single, Double, and Backticks](#3--quoting--single-double-and-backticks)
4. [Conditionals — if / elif / else / case](#4--conditionals--if--elif--else--case)
5. [Loops — for / while / until](#5--loops--for--while--until)
6. [Functions](#6--functions)
7. [Arrays](#7--arrays)
8. [String Manipulation & Parameter Expansion](#8--string-manipulation--parameter-expansion)
9. [Input — read, Positional Parameters, getopts](#9--input--read-positional-parameters-getopts)
10. [File Descriptors & Redirection](#10--file-descriptors--redirection)
11. [Pipes, Subshells & Process Substitution](#11--pipes-subshells--process-substitution)
12. [Exit Codes & Error Handling](#12--exit-codes--error-handling)
13. [Regex with grep, sed, awk](#13--regex-with-grep-sed-awk)
14. [Here Documents & Here Strings](#14--here-documents--here-strings)
15. [Debugging Techniques](#15--debugging-techniques)
16. [Cron — Scheduling Scripts](#16--cron--scheduling-scripts)
17. [Real-World Script Patterns](#17--real-world-script-patterns)
18. [Best Practices Checklist](#18--best-practices-checklist)

---

## 1 — Getting Started — Your First Script

A shell script is just a text file containing commands that run one after another — like a to-do list the computer follows.

### Creating and Running a Script

```bash
#!/bin/bash
# This line (shebang) tells the system to use Bash to run this file

echo "Hello, DevOps Engineer!"
echo "Today is $(date)"
echo "You are logged in as: $(whoami)"
echo "Your server: $(hostname)"
```

**How to run it:**
```bash
# Step 1: Create the file
nano myscript.sh

# Step 2: Make it executable
chmod +x myscript.sh

# Step 3: Run it
./myscript.sh
```

**Output:**
```
Hello, DevOps Engineer!
Today is Mon Mar 02 10:30:00 UTC 2026
You are logged in as: ubuntu
Your server: web-server-01
```

---

## 2 — Variables & Data Types

Variables store values that your script can use and reuse. Think of them as labeled boxes — you put something in, and later you take it out by name.

### Defining Variables

```bash
#!/bin/bash

# Assigning variables (NO spaces around the = sign!)
NAME="Ubuntu Server"
PORT=8080
IS_PRODUCTION=true
APP_DIR="/var/www/app"

# Using variables (prefix with $)
echo "Server: $NAME"
echo "Running on port: $PORT"
echo "App location: $APP_DIR"
```

**Common mistakes:**
```bash
# WRONG — spaces around = will break it
NAME = "John"        # Error: "NAME: command not found"

# CORRECT
NAME="John"          # Works perfectly
```

### Environment Variables vs Local Variables

```bash
# Local variable — only exists inside THIS script
MY_VAR="hello"

# Environment variable — available to child processes too
export MY_VAR="hello"

# Common built-in environment variables
echo "$HOME"         # Your home directory (/home/ubuntu)
echo "$USER"         # Current user (ubuntu)
echo "$PATH"         # Where the system looks for commands
echo "$PWD"          # Current working directory
echo "$SHELL"        # Your shell (/bin/bash)
echo "$HOSTNAME"     # Server name
echo "$RANDOM"       # Random number (0–32767)
```

### Command Substitution — Store command output in a variable

```bash
# Modern syntax: $(command)
CURRENT_DATE=$(date +%Y-%m-%d)
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
IP_ADDRESS=$(hostname -I | awk '{print $1}')
FILE_COUNT=$(ls /var/log/*.log 2>/dev/null | wc -l)

echo "Date: $CURRENT_DATE"
echo "Disk: $DISK_USAGE used"
echo "IP: $IP_ADDRESS"
echo "Log files: $FILE_COUNT"
```

### Read-Only Variables

```bash
readonly DB_HOST="prod-db.example.com"
DB_HOST="new-value"    # Error! Cannot change a readonly variable
```

---

## 3 — Quoting — Single, Double, and Backticks

Quoting matters — different quotes behave differently.

### Quick Comparison

| Quote | Variables Expand? | Example | Result |
|-------|-------------------|---------|--------|
| `"double"` | Yes | `"Hello $USER"` | `Hello ubuntu` |
| `'single'` | No | `'Hello $USER'` | `Hello $USER` |
| `` `backtick` `` | Command runs | `` `date` `` | `Mon Mar 02 ...` |

### Examples

```bash
NAME="DevOps"

# Double quotes — variables and commands ARE expanded
echo "Welcome, $NAME"                # Welcome, DevOps
echo "Today is $(date +%A)"          # Today is Monday

# Single quotes — everything is treated as plain text
echo 'Welcome, $NAME'                # Welcome, $NAME
echo 'Today is $(date +%A)'          # Today is $(date +%A)

# Backticks — old way to run commands (use $() instead)
echo "Users: `who | wc -l`"          # Users: 3
echo "Users: $(who | wc -l)"         # Users: 3  (preferred modern way)
```

### When to Use Which

```bash
# Use double quotes: when you want variable values
LOG_DIR="/var/log"
echo "Checking logs in $LOG_DIR..."

# Use single quotes: when you want literal text (e.g., regex, awk patterns)
grep -E '^[0-9]+\.[0-9]+' access.log
awk '{print $1}' file.txt

# Use $() for command substitution (avoid backticks in new scripts)
UPTIME=$(uptime -p)
```

---

## 4 — Conditionals — if / elif / else / case

Conditionals let your script make decisions — "if this, do that."

### Basic if Statement

```bash
#!/bin/bash

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$DISK_USAGE" -gt 80 ]; then
    echo "WARNING: Disk usage is at ${DISK_USAGE}%"
elif [ "$DISK_USAGE" -gt 60 ]; then
    echo "NOTICE: Disk usage is at ${DISK_USAGE}%"
else
    echo "OK: Disk usage is at ${DISK_USAGE}%"
fi
```

### Comparison Operators

**For numbers:**
| Operator | Meaning | Example |
|----------|---------|---------|
| `-eq` | Equal to | `[ "$a" -eq 5 ]` |
| `-ne` | Not equal to | `[ "$a" -ne 5 ]` |
| `-gt` | Greater than | `[ "$a" -gt 10 ]` |
| `-lt` | Less than | `[ "$a" -lt 10 ]` |
| `-ge` | Greater or equal | `[ "$a" -ge 10 ]` |
| `-le` | Less or equal | `[ "$a" -le 10 ]` |

**For strings:**
| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal | `[ "$a" = "hello" ]` |
| `!=` | Not equal | `[ "$a" != "hello" ]` |
| `-z` | Is empty | `[ -z "$a" ]` |
| `-n` | Is not empty | `[ -n "$a" ]` |

**For files:**
| Operator | Meaning | Example |
|----------|---------|---------|
| `-f` | Is a regular file | `[ -f "/etc/hosts" ]` |
| `-d` | Is a directory | `[ -d "/var/log" ]` |
| `-e` | Exists (file or dir) | `[ -e "/tmp/lock" ]` |
| `-r` | Is readable | `[ -r "$FILE" ]` |
| `-w` | Is writable | `[ -w "$FILE" ]` |
| `-x` | Is executable | `[ -x "$SCRIPT" ]` |
| `-s` | Is not empty (size > 0) | `[ -s "$LOG" ]` |

### Real Examples

```bash
#!/bin/bash

# Check if a file exists before reading it
CONFIG="/etc/myapp/config.yml"
if [ -f "$CONFIG" ]; then
    echo "Loading config from $CONFIG"
    source "$CONFIG"
else
    echo "ERROR: Config file not found: $CONFIG"
    exit 1
fi

# Check if a service is running
if systemctl is-active --quiet nginx; then
    echo "Nginx is running"
else
    echo "Nginx is NOT running — starting it..."
    sudo systemctl start nginx
fi

# Check if a command exists
if command -v docker &>/dev/null; then
    echo "Docker is installed: $(docker --version)"
else
    echo "Docker is NOT installed"
fi
```

### `[` vs `[[` — What's the Difference?

```bash
# [ is the old, portable way (works in all shells)
if [ "$NAME" = "admin" ]; then echo "Welcome admin"; fi

# [[ is the modern Bash way (more features, safer)
if [[ "$NAME" == "admin" ]]; then echo "Welcome admin"; fi

# [[ supports pattern matching and regex
if [[ "$FILE" == *.log ]]; then echo "It's a log file"; fi
if [[ "$EMAIL" =~ ^[a-zA-Z]+@[a-zA-Z]+\.[a-z]+$ ]]; then echo "Valid email"; fi

# [[ doesn't need to quote variables (safer with empty values)
if [[ -z $MAYBE_EMPTY ]]; then echo "empty"; fi    # Safe
if [ -z $MAYBE_EMPTY ]; then echo "empty"; fi      # Could break if unset
```

### case Statement — Clean Multi-Option Handling

```bash
#!/bin/bash
# Great for menus, argument parsing, and multi-condition logic

ACTION="$1"

case "$ACTION" in
    start)
        echo "Starting the application..."
        systemctl start myapp
        ;;
    stop)
        echo "Stopping the application..."
        systemctl stop myapp
        ;;
    restart)
        echo "Restarting the application..."
        systemctl restart myapp
        ;;
    status)
        systemctl status myapp
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
```

### Real-World Pattern — Environment Detection

```bash
#!/bin/bash

ENVIRONMENT="${1:-dev}"

case "$ENVIRONMENT" in
    dev|development)
        DB_HOST="dev-db.internal"
        DB_PORT=5432
        DEBUG=true
        ;;
    staging|stg)
        DB_HOST="staging-db.internal"
        DB_PORT=5432
        DEBUG=false
        ;;
    prod|production)
        DB_HOST="prod-db.internal"
        DB_PORT=5432
        DEBUG=false
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        echo "Valid options: dev, staging, prod"
        exit 1
        ;;
esac

echo "Deploying to: $ENVIRONMENT"
echo "Database: $DB_HOST:$DB_PORT"
```

---

## 5 — Loops — for / while / until

Loops repeat actions — process every file, check every server, retry until success.

### for Loop

```bash
#!/bin/bash

# Loop through a list
for FRUIT in apple banana cherry; do
    echo "I like $FRUIT"
done

# Loop through files
for FILE in /var/log/*.log; do
    echo "Log file: $FILE ($(du -h "$FILE" | cut -f1))"
done

# Loop through numbers
for i in {1..5}; do
    echo "Iteration $i"
done

# C-style for loop
for ((i=1; i<=10; i++)); do
    echo "Count: $i"
done
```

### Real-World for Loop — Check Multiple Servers

```bash
#!/bin/bash

SERVERS=("web-01" "web-02" "api-01" "db-01")

for SERVER in "${SERVERS[@]}"; do
    if ping -c 1 -W 2 "$SERVER" &>/dev/null; then
        echo "✅ $SERVER — reachable"
    else
        echo "❌ $SERVER — UNREACHABLE"
    fi
done
```

### while Loop

```bash
#!/bin/bash

# Basic counter
COUNT=1
while [ $COUNT -le 5 ]; do
    echo "Count: $COUNT"
    COUNT=$((COUNT + 1))
done

# Read a file line by line
while IFS= read -r LINE; do
    echo "Processing: $LINE"
done < /etc/hosts

# Read a CSV file
while IFS=',' read -r NAME AGE ROLE; do
    echo "$NAME is $AGE years old and works as $ROLE"
done < employees.csv
```

### Real-World while Loop — Wait for a Service to Start

```bash
#!/bin/bash

MAX_RETRIES=30
RETRY=0

echo "Waiting for nginx to start..."
while ! systemctl is-active --quiet nginx; do
    RETRY=$((RETRY + 1))
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "ERROR: Nginx failed to start after $MAX_RETRIES attempts"
        exit 1
    fi
    echo "  Attempt $RETRY/$MAX_RETRIES — waiting..."
    sleep 2
done

echo "Nginx is running!"
```

### until Loop — Opposite of while (runs UNTIL condition is true)

```bash
#!/bin/bash

# Wait until a website responds
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; do
    echo "Waiting for application to be ready..."
    sleep 5
done
echo "Application is ready!"
```

### Loop Control — break and continue

```bash
#!/bin/bash

# Skip certain items with continue
for FILE in /var/log/*; do
    # Skip directories, only process files
    [ -d "$FILE" ] && continue
    echo "File: $FILE"
done

# Stop early with break
for SERVER in web-01 web-02 web-03 db-01; do
    if ! ping -c 1 -W 2 "$SERVER" &>/dev/null; then
        echo "CRITICAL: $SERVER is down. Stopping health check."
        break
    fi
    echo "$SERVER is healthy"
done
```

---

## 6 — Functions

Functions group reusable code — write once, call many times. Like creating your own custom commands.

### Defining and Calling Functions

```bash
#!/bin/bash

# Define a function
greet() {
    echo "Hello, $1! Welcome to $2."
}

# Call it
greet "Alice" "Production Server"
greet "Bob" "Staging Server"
```

**Output:**
```
Hello, Alice! Welcome to Production Server.
Hello, Bob! Welcome to Staging Server.
```

### Functions with Return Values

```bash
#!/bin/bash

# Functions return exit codes (0 = success, non-zero = failure)
is_port_open() {
    local HOST="$1"
    local PORT="$2"
    nc -z -w 2 "$HOST" "$PORT" 2>/dev/null
    return $?    # Returns 0 if open, 1 if closed
}

if is_port_open "localhost" 80; then
    echo "Port 80 is open"
else
    echo "Port 80 is closed"
fi
```

### Functions that Output Values

```bash
#!/bin/bash

# Use echo to "return" a string value
get_disk_usage() {
    local MOUNT_POINT="${1:-/}"
    df -h "$MOUNT_POINT" | awk 'NR==2 {print $5}' | tr -d '%'
}

# Capture the output
USAGE=$(get_disk_usage "/")
echo "Root disk is ${USAGE}% full"

USAGE=$(get_disk_usage "/home")
echo "Home disk is ${USAGE}% full"
```

### Local Variables in Functions

```bash
#!/bin/bash

create_backup() {
    local SOURCE="$1"                # local = only exists inside this function
    local DEST="/tmp/backup_$(date +%Y%m%d)"
    local ARCHIVE_NAME="$(basename "$SOURCE").tar.gz"

    mkdir -p "$DEST"
    tar -czf "$DEST/$ARCHIVE_NAME" "$SOURCE" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "$DEST/$ARCHIVE_NAME"   # Output the path on success
        return 0
    else
        return 1
    fi
}

# Usage
BACKUP_PATH=$(create_backup "/etc/nginx")
if [ $? -eq 0 ]; then
    echo "Backup created: $BACKUP_PATH"
else
    echo "Backup failed!"
fi
```

### Real-World Pattern — Logging Function

```bash
#!/bin/bash
LOG_FILE="/var/log/myapp.log"

log() {
    local LEVEL="$1"
    shift
    local MESSAGE="$*"
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a "$LOG_FILE"
}

log "INFO" "Script started"
log "INFO" "Checking disk space..."

USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USAGE" -gt 80 ]; then
    log "WARN" "Disk usage is high: ${USAGE}%"
else
    log "INFO" "Disk usage is normal: ${USAGE}%"
fi

log "INFO" "Script completed"
```

---

## 7 — Arrays

Arrays store multiple values in a single variable — like a list.

### Indexed Arrays (Numbered Lists)

```bash
#!/bin/bash

# Create an array
SERVERS=("web-01" "web-02" "api-01" "db-01")

# Access elements (0-indexed)
echo "${SERVERS[0]}"        # web-01
echo "${SERVERS[2]}"        # api-01

# All elements
echo "${SERVERS[@]}"        # web-01 web-02 api-01 db-01

# Number of elements
echo "${#SERVERS[@]}"       # 4

# Add an element
SERVERS+=("cache-01")

# Loop through array
for SERVER in "${SERVERS[@]}"; do
    echo "Checking $SERVER..."
done

# Loop with index
for i in "${!SERVERS[@]}"; do
    echo "Server $i: ${SERVERS[$i]}"
done
```

### Associative Arrays (Key-Value Pairs)

```bash
#!/bin/bash
declare -A SERVER_IPS       # Must declare with -A

SERVER_IPS["web-01"]="10.0.1.10"
SERVER_IPS["web-02"]="10.0.1.11"
SERVER_IPS["api-01"]="10.0.2.10"
SERVER_IPS["db-01"]="10.0.3.10"

# Access by key
echo "web-01 IP: ${SERVER_IPS[web-01]}"

# All keys
echo "Servers: ${!SERVER_IPS[@]}"

# All values
echo "IPs: ${SERVER_IPS[@]}"

# Loop through
for SERVER in "${!SERVER_IPS[@]}"; do
    echo "$SERVER → ${SERVER_IPS[$SERVER]}"
done
```

### Real-World Example — Service Health Check

```bash
#!/bin/bash
declare -A SERVICES
SERVICES=(
    ["nginx"]="80"
    ["mysql"]="3306"
    ["redis"]="6379"
    ["app"]="8080"
)

echo "Service Health Check"
echo "===================="

for SERVICE in "${!SERVICES[@]}"; do
    PORT="${SERVICES[$SERVICE]}"
    if ss -tuln | grep -q ":${PORT} "; then
        echo "✅ $SERVICE (port $PORT) — running"
    else
        echo "❌ $SERVICE (port $PORT) — NOT running"
    fi
done
```

---

## 8 — String Manipulation & Parameter Expansion

Bash can slice, dice, replace, and transform strings without external tools.

### String Length

```bash
NAME="DevOps Engineer"
echo "${#NAME}"             # 15
```

### Substring Extraction

```bash
STR="Hello, World!"
echo "${STR:0:5}"           # Hello     (start at 0, take 5 chars)
echo "${STR:7}"             # World!    (from position 7 to end)
echo "${STR: -6}"           # orld!     (last 6 chars — note the space before -)
```

### Search and Replace

```bash
FILE="backup-2026-03-02.tar.gz"

# Replace first match
echo "${FILE/backup/archive}"       # archive-2026-03-02.tar.gz

# Replace all matches
PATH_STR="/home/user/docs/file"
echo "${PATH_STR//\// -> }"         #  -> home -> user -> docs -> file
```

### Remove Patterns

```bash
FILE="report.2026.03.02.tar.gz"

# Remove from the beginning (shortest match)
echo "${FILE#*.}"           # 2026.03.02.tar.gz

# Remove from the beginning (longest match)
echo "${FILE##*.}"          # gz

# Remove from the end (shortest match)
echo "${FILE%.*}"           # report.2026.03.02.tar

# Remove from the end (longest match)
echo "${FILE%%.*}"          # report
```

### Common Patterns

```bash
# Get filename from path
FILEPATH="/var/log/nginx/access.log"
echo "${FILEPATH##*/}"      # access.log

# Get directory from path
echo "${FILEPATH%/*}"       # /var/log/nginx

# Get file extension
echo "${FILEPATH##*.}"      # log

# Remove file extension
echo "${FILEPATH%.*}"       # /var/log/nginx/access

# Change file extension
echo "${FILEPATH%.log}.bak" # /var/log/nginx/access.bak
```

### Default Values

```bash
# Use default if variable is empty or unset
REGION="${AWS_REGION:-us-east-1}"        # Use us-east-1 if AWS_REGION is not set
PORT="${APP_PORT:-8080}"                  # Use 8080 if APP_PORT is not set

# Set variable AND assign default
: "${LOG_DIR:=/var/log/myapp}"           # Sets LOG_DIR if it was empty

# Error if variable is not set
: "${API_KEY:?ERROR: API_KEY must be set}"  # Exits with error if API_KEY is missing
```

### Case Conversion

```bash
NAME="DevOps Engineer"

echo "${NAME,,}"            # devops engineer (all lowercase)
echo "${NAME^^}"            # DEVOPS ENGINEER (all uppercase)
echo "${NAME^}"             # DevOps Engineer (capitalize first letter)
```

---

## 9 — Input — read, Positional Parameters, getopts

### Reading User Input

```bash
#!/bin/bash

# Simple input
read -p "Enter your name: " NAME
echo "Hello, $NAME!"

# Silent input (for passwords)
read -s -p "Enter password: " PASSWORD
echo ""

# Input with timeout
read -t 10 -p "Confirm deployment? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Input with default value
read -p "Enter region [us-east-1]: " REGION
REGION="${REGION:-us-east-1}"
```

### Positional Parameters

When you run `./script.sh hello world 42`:

| Variable | Value | Meaning |
|----------|-------|---------|
| `$0` | `./script.sh` | Script name |
| `$1` | `hello` | First argument |
| `$2` | `world` | Second argument |
| `$3` | `42` | Third argument |
| `$#` | `3` | Number of arguments |
| `$@` | `hello world 42` | All arguments (as separate words) |
| `$*` | `hello world 42` | All arguments (as one string) |
| `$$` | `12345` | Process ID of the script |
| `$?` | `0` | Exit code of last command |

```bash
#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <source_dir> <backup_dir>"
    exit 1
fi

SOURCE="$1"
DESTINATION="$2"
echo "Backing up $SOURCE to $DESTINATION..."
```

### `$@` vs `$*` — The Important Difference

```bash
#!/bin/bash
# If called as: ./script.sh "hello world" "foo bar"

# $@ keeps arguments separate
for arg in "$@"; do
    echo "Arg: $arg"
done
# Output:
# Arg: hello world
# Arg: foo bar

# $* merges everything into one string
for arg in "$*"; do
    echo "Arg: $arg"
done
# Output:
# Arg: hello world foo bar
```

**Rule of thumb:** Always use `"$@"` when passing arguments to other commands.

### getopts — Professional Argument Parsing

```bash
#!/bin/bash
# Usage: ./deploy.sh -e prod -v 2.1.0 -d

ENVIRONMENT="dev"
VERSION="latest"
DRY_RUN=false

usage() {
    echo "Usage: $0 [-e environment] [-v version] [-d dry-run] [-h help]"
    echo "  -e  Environment (dev|staging|prod). Default: dev"
    echo "  -v  Version to deploy. Default: latest"
    echo "  -d  Dry run mode (no actual changes)"
    echo "  -h  Show this help"
    exit 1
}

while getopts "e:v:dh" opt; do
    case $opt in
        e) ENVIRONMENT="$OPTARG" ;;
        v) VERSION="$OPTARG" ;;
        d) DRY_RUN=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

echo "Deploying version $VERSION to $ENVIRONMENT (dry_run=$DRY_RUN)"
```

---

## 10 — File Descriptors & Redirection

Redirection controls where your script's output goes — to the screen, a file, nowhere, or another command.

### The Three Standard Streams

| Stream | Number | Default | Description |
|--------|--------|---------|-------------|
| **stdin** | 0 | Keyboard | Input — data going INTO a command |
| **stdout** | 1 | Screen | Output — normal results |
| **stderr** | 2 | Screen | Errors — error messages |

### Output Redirection

```bash
# Send output to a file (overwrite)
echo "Log entry" > output.log

# Append to a file
echo "Another entry" >> output.log

# Redirect only errors to a file
./script.sh 2> errors.log

# Redirect output AND errors to the same file
./script.sh > all.log 2>&1       # Old way (works everywhere)
./script.sh &> all.log            # Modern way (Bash only)

# Send output to file AND screen simultaneously
./script.sh | tee output.log              # stdout to file + screen
./script.sh 2>&1 | tee output.log         # stdout + stderr to file + screen

# Discard output completely (send to /dev/null — the black hole)
./noisy-script.sh > /dev/null             # Hide output, show errors
./noisy-script.sh 2> /dev/null            # Show output, hide errors
./noisy-script.sh &> /dev/null            # Hide everything
```

### Input Redirection

```bash
# Feed a file as input to a command
sort < unsorted.txt

# Feed a file and save sorted output
sort < unsorted.txt > sorted.txt

# Count lines from a file
wc -l < /var/log/syslog
```

### Practical Examples

```bash
#!/bin/bash
LOG="/var/log/myapp.log"

# Log everything this script does
exec >> "$LOG" 2>&1          # Redirect ALL stdout+stderr to log file

echo "Script started at $(date)"
echo "Running health checks..."

# Only capture errors from a command
ERRORS=$(aws s3 ls 2>&1 >/dev/null)
if [ -n "$ERRORS" ]; then
    echo "AWS Error: $ERRORS"
fi
```

---

## 11 — Pipes, Subshells & Process Substitution

### Pipes — Chain Commands Together

The pipe `|` sends one command's output as input to the next command.

```bash
# Find the top 5 largest log files
du -h /var/log/*.log | sort -rh | head -5

# Count unique IP addresses in a log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Find running nginx processes and count them
ps aux | grep nginx | grep -v grep | wc -l

# Check which process is using the most memory
ps aux --sort=-%mem | head -5

# Find all open ports with their process names
ss -tuln | awk 'NR>1 {print $5}' | sort -u
```

### Subshells — Run Commands in Isolation

```bash
# $() runs a command and captures its output
CURRENT_DATE=$(date +%Y-%m-%d)
NUM_CPUS=$(nproc)

# Subshell with () — changes don't affect parent shell
echo "Current dir: $PWD"
(cd /tmp; echo "Inside subshell: $PWD")
echo "Back to: $PWD"                        # Still in original directory

# Nested command substitution
echo "There are $(find /var/log -name '*.log' -mtime -1 | wc -l) recent log files"
```

### Process Substitution — `<()` and `>()`

Treats command output as a file — useful when a command needs a filename, not piped input.

```bash
# Compare two command outputs like files
diff <(ls dir1/) <(ls dir2/)

# Compare sorted versions of two files
diff <(sort file1.txt) <(sort file2.txt)

# Feed multiple inputs to a command
paste <(cut -d: -f1 /etc/passwd) <(cut -d: -f3 /etc/passwd)

# Write to multiple destinations at once
echo "log entry" | tee >(logger) >> local.log
```

---

## 12 — Exit Codes & Error Handling

Every command returns an exit code: **0 = success**, **non-zero = failure**. This is how scripts know if something worked.

### Checking Exit Codes

```bash
#!/bin/bash

# $? holds the exit code of the last command
ls /tmp
echo "Exit code: $?"          # 0 (success)

ls /nonexistent_folder
echo "Exit code: $?"          # 2 (error — folder doesn't exist)
```

### The Essential Safety Line — `set -euo pipefail`

Put this at the top of EVERY production script:

```bash
#!/bin/bash
set -euo pipefail

# What each flag does:
# -e = Exit immediately if ANY command fails (non-zero exit code)
# -u = Treat unset variables as errors (catches typos like $NAEM instead of $NAME)
# -o pipefail = A pipe fails if ANY command in it fails, not just the last one
```

**Without it:**
```bash
rm -rf /important/data/"$UNSET_VAR"   # If UNSET_VAR is empty, this deletes /important/data/
cp nonexistent.txt /backup/            # Silently fails, script continues
echo "All good!"                        # Prints even though cp failed!
```

**With it:**
```bash
set -euo pipefail
rm -rf /important/data/"$UNSET_VAR"   # ERROR: UNSET_VAR: unbound variable → script stops
```

### Error Handling with `||` and `&&`

```bash
# Run command B only if command A succeeds
mkdir /tmp/mydir && echo "Directory created"

# Run command B only if command A FAILS
mkdir /tmp/mydir || echo "Failed to create directory"

# Common pattern: try or die
cd /app || { echo "ERROR: Cannot cd to /app"; exit 1; }

# Run cleanup on failure
aws s3 cp backup.tar.gz s3://bucket/ || {
    echo "Upload failed, retrying..."
    sleep 5
    aws s3 cp backup.tar.gz s3://bucket/
}
```

### trap — Run Code on Exit or Error

`trap` is like an emergency protocol — "no matter what happens, do this before the script ends."

```bash
#!/bin/bash
set -euo pipefail

TEMP_DIR=$(mktemp -d)

# This runs when the script exits (success or failure)
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# This runs on specific signals
on_error() {
    echo "ERROR on line $1"
    exit 1
}
trap 'on_error $LINENO' ERR

# Now work with temp files safely — they ALWAYS get cleaned up
echo "Working in $TEMP_DIR"
cp important-data.txt "$TEMP_DIR/"
# ... even if the script crashes, cleanup() still runs
```

### Custom Exit Codes

```bash
#!/bin/bash

check_disk() {
    local USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$USAGE" -gt 90 ]; then
        return 2    # Critical
    elif [ "$USAGE" -gt 80 ]; then
        return 1    # Warning
    else
        return 0    # OK
    fi
}

check_disk
case $? in
    0) echo "Disk OK" ;;
    1) echo "Disk WARNING" ;;
    2) echo "Disk CRITICAL" ;;
esac
```

---

## 13 — Regex with grep, sed, awk

Regular expressions (regex) are patterns for matching text — essential for log analysis, data extraction, and text processing.

### grep — Search with Patterns

```bash
#!/bin/bash

# Basic: find lines with "error"
grep "error" /var/log/syslog

# Case-insensitive
grep -i "error" /var/log/syslog

# Extended regex (-E) for more pattern features
grep -E "error|warning|critical" /var/log/syslog

# Show only the matching part
grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' access.log   # Extract IP addresses

# Count matches
grep -c "404" access.log

# Show lines BEFORE and AFTER match (context)
grep -B 3 -A 3 "OutOfMemory" /var/log/syslog    # 3 lines before and after
```

### Common Regex Patterns

| Pattern | Meaning | Example Match |
|---------|---------|---------------|
| `.` | Any single character | `h.t` → hat, hot, hit |
| `*` | Zero or more of previous | `ab*c` → ac, abc, abbc |
| `+` | One or more of previous | `ab+c` → abc, abbc (not ac) |
| `?` | Zero or one of previous | `colou?r` → color, colour |
| `^` | Start of line | `^Error` → lines starting with "Error" |
| `$` | End of line | `\.log$` → lines ending with ".log" |
| `[abc]` | Any character in set | `[aeiou]` → any vowel |
| `[0-9]` | Any digit | `[0-9]+` → one or more digits |
| `[a-zA-Z]` | Any letter | `[a-zA-Z]+` → one or more letters |
| `\b` | Word boundary | `\berror\b` → "error" but not "errors" |
| `{n}` | Exactly n times | `[0-9]{3}` → exactly 3 digits |
| `(a\|b)` | a OR b | `(error\|warn)` → error or warn |

### sed — Stream Editor for Transformations

```bash
#!/bin/bash

# Replace text
sed 's/http/https/g' urls.txt              # Replace http with https
sed -i 's/DEBUG/INFO/g' config.yml         # Edit file in place

# Delete lines
sed '/^#/d' config.yml                     # Remove comment lines
sed '/^$/d' file.txt                       # Remove blank lines

# Insert and append
sed '1i\# This is a header' file.txt      # Insert line at top
sed '$a\# End of file' file.txt           # Append line at bottom

# Extract specific lines
sed -n '10,20p' file.txt                   # Print lines 10-20
sed -n '/START/,/END/p' file.txt           # Print between START and END markers

# Multiple operations
sed -e 's/foo/bar/g' -e '/^$/d' file.txt  # Replace AND remove blank lines
```

### awk — Data Processing Language

```bash
#!/bin/bash

# Print specific columns
awk '{print $1, $3}' access.log            # Print IP and status code

# Filter rows
awk '$9 == 500 {print $0}' access.log     # Only show 500 errors

# Custom field separator
awk -F: '{print $1, $3}' /etc/passwd       # Username and UID

# Calculations
awk '{sum += $5} END {print "Total:", sum}' data.txt    # Sum column 5

# Count occurrences
awk '{count[$9]++} END {for (c in count) print c, count[c]}' access.log

# Format output as a table
df -h | awk 'NR>1 {printf "%-20s %s used\n", $1, $5}'

# Multi-condition processing
awk -F: '
    $3 >= 1000 {
        printf "Regular user: %-15s UID: %s\n", $1, $3
    }
    $3 == 0 {
        printf "ROOT user:    %-15s UID: %s\n", $1, $3
    }
' /etc/passwd
```

### Real-World Example — Log Analysis Pipeline

```bash
#!/bin/bash
# Analyze nginx access log: find top error-producing IPs

echo "Top 10 IPs causing 4xx/5xx errors:"
awk '$9 ~ /^[45]/' /var/log/nginx/access.log | \
    awk '{print $1}' | \
    sort | uniq -c | sort -rn | head -10 | \
    awk '{printf "  %-18s %s errors\n", $2, $1}'
```

---

## 14 — Here Documents & Here Strings

### Here Documents — Multi-Line Input

A here document feeds a block of text to a command — great for config files, emails, and multi-line strings.

```bash
#!/bin/bash

# Create a config file
cat <<EOF > /tmp/nginx.conf
server {
    listen 80;
    server_name example.com;
    root /var/www/html;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}
EOF

# Send a formatted email/notification
cat <<EOF
=================================
  Deployment Report
  Date:    $(date)
  Server:  $(hostname)
  Version: ${APP_VERSION:-unknown}
  Status:  SUCCESS
=================================
EOF

# Use <<'EOF' (quoted) to prevent variable expansion
cat <<'EOF'
This will print literally: $USER $HOME $(date)
Nothing gets expanded inside single-quoted here docs.
EOF
```

### Here Strings — One-Line Input

```bash
# Feed a string directly as stdin
grep "error" <<< "This line has an error in it"

# Useful for processing a variable as input
LINE="John,25,Engineer"
IFS=',' read -r NAME AGE ROLE <<< "$LINE"
echo "$NAME is $AGE and works as $ROLE"

# Count words in a variable
wc -w <<< "Hello World from Bash"       # Output: 4
```

---

## 15 — Debugging Techniques

### Enable Debug Mode

```bash
#!/bin/bash
set -x                  # Print every command before running it

# Or debug just a specific section:
set -x
echo "This section is being debugged"
problematic_function
set +x                  # Turn off debugging
echo "Normal execution resumes"
```

### Debug Output Example

```bash
#!/bin/bash
set -x
NAME="Alice"
echo "Hello, $NAME"
```

**Output with set -x:**
```
+ NAME=Alice
+ echo 'Hello, Alice'
Hello, Alice
```

### Using `trap` for Error Reporting

```bash
#!/bin/bash
set -euo pipefail

trap 'echo "ERROR: Script failed at line $LINENO. Command: $BASH_COMMAND"' ERR

echo "Step 1: OK"
echo "Step 2: OK"
false                    # This fails
echo "Step 3: Never reached"

# Output:
# Step 1: OK
# Step 2: OK
# ERROR: Script failed at line 7. Command: false
```

### ShellCheck — Static Analysis Tool

ShellCheck finds bugs and bad practices in your scripts before you run them.

```bash
# Install
sudo apt install shellcheck         # Ubuntu
sudo yum install ShellCheck         # Amazon Linux

# Run it
shellcheck myscript.sh

# Example warnings it catches:
# SC2034: MY_VAR appears unused
# SC2086: Double quote to prevent word splitting: "$var"
# SC2046: Quote this to prevent word splitting
```

### Debug Logging Pattern

```bash
#!/bin/bash

DEBUG="${DEBUG:-false}"

debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $*" >&2       # Print to stderr so it doesn't interfere with output
    fi
}

debug_log "Starting backup process"
debug_log "Source directory: /var/www/app"

# Run with debugging:  DEBUG=true ./script.sh
# Run without:         ./script.sh
```

---

## 16 — Cron — Scheduling Scripts

### Cron Format Reminder

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 7, 0 and 7 = Sunday)
│ │ │ │ │
* * * * * /path/to/script.sh
```

### Common Cron Schedules

```bash
# Edit cron jobs
crontab -e

# Every 5 minutes
*/5 * * * * /home/ubuntu/health-check.sh >> /var/log/health.log 2>&1

# Every day at 2:00 AM
0 2 * * * /home/ubuntu/backup.sh >> /var/log/backup.log 2>&1

# Every Monday at 9:00 AM
0 9 * * 1 /home/ubuntu/weekly-report.sh

# Every 1st and 15th of the month at midnight
0 0 1,15 * * /home/ubuntu/semi-monthly.sh

# Weekdays at 8 AM and 7 PM (EC2 start/stop)
0 8 * * 1-5 /home/ubuntu/ec2-scheduler.sh start
0 19 * * 1-5 /home/ubuntu/ec2-scheduler.sh stop
```

### Cron Best Practices

```bash
# Always redirect output to a log file
0 2 * * * /home/ubuntu/backup.sh >> /var/log/backup.log 2>&1

# Use full paths (cron has minimal PATH)
0 * * * * /usr/bin/python3 /home/ubuntu/script.py

# Set environment variables at the top of crontab
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
AWS_REGION=us-east-1

0 2 * * * /home/ubuntu/backup.sh
```

---

## 17 — Real-World Script Patterns

### Pattern 1 — Script Template (Use as Starting Point)

```bash
#!/bin/bash
###############################################################################
# Script:      template.sh
# Description: Brief description of what this script does
# Author:      Your Name
# Date:        2026-03-02
# Usage:       ./template.sh [options]
###############################################################################
set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/$(basename "$0" .sh).log"

# --- Functions ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

cleanup() {
    log "Cleaning up..."
    # Remove temporary files here
}
trap cleanup EXIT

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -h  Show help"
    exit 1
}

# --- Parse Arguments ---
while getopts "h" opt; do
    case $opt in
        h) usage ;;
        *) usage ;;
    esac
done

# --- Main ---
log "Script started"

# Your code here

log "Script completed"
```

### Pattern 2 — Lock File (Prevent Multiple Instances)

```bash
#!/bin/bash
set -euo pipefail

LOCK_FILE="/tmp/$(basename "$0").lock"

if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "Script already running (PID: $LOCK_PID). Exiting."
        exit 1
    else
        echo "Stale lock file found. Removing..."
        rm -f "$LOCK_FILE"
    fi
fi

echo $$ > "$LOCK_FILE"          # Write current PID
trap 'rm -f "$LOCK_FILE"' EXIT  # Remove lock on exit

# --- Main logic here ---
echo "Running exclusively..."
sleep 10
```

### Pattern 3 — Retry Logic

```bash
#!/bin/bash
set -euo pipefail

retry() {
    local MAX_ATTEMPTS="$1"
    local DELAY="$2"
    shift 2
    local COMMAND="$@"
    local ATTEMPT=1

    until eval "$COMMAND"; do
        if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
            echo "ERROR: Command failed after $MAX_ATTEMPTS attempts: $COMMAND"
            return 1
        fi
        echo "Attempt $ATTEMPT failed. Retrying in ${DELAY}s..."
        sleep "$DELAY"
        ATTEMPT=$((ATTEMPT + 1))
    done
}

# Usage: retry <max_attempts> <delay_seconds> <command>
retry 5 10 "aws s3 cp backup.tar.gz s3://my-bucket/"
retry 3 5 "curl -sf http://localhost:8080/health"
```

### Pattern 4 — Parallel Execution

```bash
#!/bin/bash
set -euo pipefail

SERVERS=("web-01" "web-02" "web-03" "api-01" "api-02")

deploy_to_server() {
    local SERVER="$1"
    echo "[$SERVER] Deploying..."
    ssh "deploy@$SERVER" "cd /app && git pull && sudo systemctl restart app"
    echo "[$SERVER] Done"
}

# Deploy to all servers in parallel
for SERVER in "${SERVERS[@]}"; do
    deploy_to_server "$SERVER" &
done

# Wait for ALL background jobs to finish
wait
echo "All deployments complete!"
```

---

## 18 — Best Practices Checklist

| Practice | Why It Matters |
|----------|---------------|
| Start with `#!/bin/bash` | Ensures the right shell interpreter is used |
| Add `set -euo pipefail` | Catches errors, unset variables, and pipe failures early |
| Quote all variables `"$VAR"` | Prevents word splitting and globbing bugs |
| Use `local` in functions | Avoids variable name collisions |
| Add a `trap cleanup EXIT` | Ensures temporary files get cleaned up |
| Log with timestamps | Makes troubleshooting easier |
| Use `shellcheck` | Catches common bugs before they run |
| Use meaningful variable names | `BACKUP_DIR` over `BD` — future you will thank you |
| Add comments for complex logic | Explain WHY, not WHAT |
| Use `readonly` for constants | Prevents accidental overwrites |
| Add usage/help functions | Makes scripts self-documenting |
| Test with edge cases | Empty input, missing files, network failures |
| Use lock files for cron scripts | Prevents overlapping executions |
| Redirect cron output to logs | Makes debugging scheduled tasks possible |
| Version control all scripts | Track changes and enable rollbacks |

---

## Quick Reference — One-Liners for Common Tasks

```bash
# Check if root
[ "$(id -u)" -eq 0 ] && echo "Running as root" || echo "Not root"

# Check if a command exists
command -v docker &>/dev/null && echo "Docker installed" || echo "Docker not found"

# Get script's own directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Timestamp for file names
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Generate random string
RANDOM_STR=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)

# Check if variable is a number
[[ "$VAR" =~ ^[0-9]+$ ]] && echo "Is a number" || echo "Not a number"

# Read a config file (key=value format)
source /etc/myapp/config.env

# Get public IP
curl -s https://checkip.amazonaws.com

# Wait for a port to be available
while ! nc -z localhost 8080 2>/dev/null; do sleep 1; done; echo "Port open!"
```

---

> **Practice tip:** The scripts in the [scripts/](scripts/) folder demonstrate these concepts in production-grade implementations. Study them and modify them to fit your own infrastructure.
