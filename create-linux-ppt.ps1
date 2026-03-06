# Create Linux Fundamentals PowerPoint Presentation
# Uses COM automation - requires PowerPoint installed

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$savePath = Join-Path $PSScriptRoot "Linux-Fundamentals.pptx"

# Launch PowerPoint
$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = 1

$presentation = $ppt.Presentations.Add()

# Widescreen 16:9
$presentation.PageSetup.SlideWidth = 960
$presentation.PageSetup.SlideHeight = 540

# Colors
function C($r,$g,$b) { [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb($r,$g,$b)) }
$W = C 255 255 255;  $BK = C 30 30 30;  $DBG = C 20 24 36
$BL = C 0 120 215;   $OR = C 255 152 0;  $GR = C 76 175 80
$RD = C 244 67 54;   $YL = C 255 235 59; $LBG = C 240 244 248
$AC = C 63 81 181;   $TL = C 0 150 136;  $PU = C 156 39 176
$GB = C 40 55 80;    $DB = C 40 50 70

function TB($sl,$l,$t,$w,$h,$txt,$sz,$clr,$b=0,$a=1,$fn="Segoe UI") {
    $sh = $sl.Shapes.AddTextbox(1,$l,$t,$w,$h)
    $sh.TextFrame.WordWrap = -1; $sh.TextFrame.AutoSize = 0
    $r = $sh.TextFrame.TextRange
    $r.Text = $txt; $r.Font.Size = $sz; $r.Font.Color.RGB = $clr
    $r.Font.Bold = $b; $r.Font.Name = $fn; $r.ParagraphFormat.Alignment = $a
}

function BG($sl,$clr) {
    $sl.FollowMasterBackground = 0
    $sl.Background.Fill.Solid()
    $sl.Background.Fill.ForeColor.RGB = $clr
}

function RR($sl,$l,$t,$w,$h,$fc,$txt,$sz,$tc,$b=0) {
    $sh = $sl.Shapes.AddShape(5,$l,$t,$w,$h)
    $sh.Fill.Solid(); $sh.Fill.ForeColor.RGB = $fc
    $sh.Line.Visible = 0; $sh.Shadow.Visible = 0
    if ($txt) {
        $sh.TextFrame.WordWrap = -1
        $sh.TextFrame.TextRange.Text = $txt
        $sh.TextFrame.TextRange.Font.Size = $sz
        $sh.TextFrame.TextRange.Font.Color.RGB = $tc
        $sh.TextFrame.TextRange.Font.Bold = $b
        $sh.TextFrame.TextRange.Font.Name = "Segoe UI"
        $sh.TextFrame.TextRange.ParagraphFormat.Alignment = 2
        $sh.TextFrame.MarginLeft = 10; $sh.TextFrame.MarginRight = 10
        $sh.TextFrame.MarginTop = 8;  $sh.TextFrame.MarginBottom = 8
    }
}

function LN($sl,$l,$t,$w,$h,$clr) {
    $sh = $sl.Shapes.AddShape(1,$l,$t,$w,$h)
    $sh.Fill.Solid(); $sh.Fill.ForeColor.RGB = $clr; $sh.Line.Visible = 0
}

function Add-Footer($sl,$isDark=$true) {
    # Professional footer: bottom-right corner on every slide
    $ftColor = if ($isDark) { C 90 100 120 } else { C 140 150 165 }
    $sh = $sl.Shapes.AddTextbox(1, 580, 515, 370, 20)
    $sh.TextFrame.WordWrap = -1; $sh.TextFrame.AutoSize = 0
    $r = $sh.TextFrame.TextRange
    $r.Text = [char]0x00A9 + " All Rights Reserved by Elite DevOpsPro"
    $r.Font.Size = 9; $r.Font.Color.RGB = $ftColor
    $r.Font.Bold = 0; $r.Font.Name = "Segoe UI"
    $r.Font.Italic = -1
    $r.ParagraphFormat.Alignment = 3  # right-align
}

# ==== SLIDE 1: TITLE ====
Write-Host "Creating slide 1 - Title..."
$s = $presentation.Slides.Add(1, 12); BG $s $DBG
LN $s 0 0 960 6 $BL
TB $s 60 30 840 40 "Elite DevOpsPro" 28 $OR 1 2
LN $s 350 72 260 2 $OR
RR $s 390 100 180 60 $BL "LINUX" 24 $W 1
TB $s 60 185 840 80 "Linux Fundamentals" 44 $W 1 2
TB $s 60 275 840 50 "Master Linux Administration for DevOps and Cloud" 22 $OR 0 2
TB $s 60 340 840 40 "From Zero to Production-Ready Server" 18 (C 150 160 180) 0 2
RR $s 200 420 560 40 $DB "Netflix | Google | Amazon | Facebook - All run on Linux" 12 (C 180 190 200) 0
Add-Footer $s $true


# ==== SLIDE 2: WHY LINUX ====
Write-Host "Creating slide 2 - Why Linux..."
$s = $presentation.Slides.Add(2, 12); BG $s $LBG
TB $s 40 20 880 50 "Why Linux for DevOps?" 36 $BK 1 1
LN $s 40 70 200 4 $BL

$items = @(
    ,@("96% of servers", "run Linux worldwide", $BL)
    ,@("Open Source", "Free, customizable, community-driven", $GR)
    ,@("Cloud Native", "AWS, Azure, GCP default to Linux", $OR)
    ,@("Automation", "Shell scripting powers CI/CD pipelines", $PU)
)
$y = 100
foreach ($r in $items) {
    RR $s 60 $y 400 80 $r[2] $r[0] 20 $W 1
    TB $s 480 ($y+10) 450 60 $r[1] 16 $BK 0 1
    $y += 95
}
Add-Footer $s $false


# ==== SLIDE 3: ARCHITECTURE ====
Write-Host "Creating slide 3 - Architecture..."
$s = $presentation.Slides.Add(3, 12); BG $s $DBG
TB $s 40 15 880 45 "Linux Architecture - The Building Analogy" 32 $W 1 1
LN $s 40 58 300 3 $OR

$items = @(
    ,@("Foundation = KERNEL", "The invisible core. Nothing works without it.", $BL)
    ,@("Reception = SHELL", "You talk to the shell to get things done.", $GR)
    ,@("Rooms = FILE SYSTEM", "/home=offices /etc=admin /var/log=cameras /tmp=meeting room", $OR)
    ,@("Key Cards = PERMISSIONS", "Owner(rwx) Group(r-x) Others(---)", $RD)
    ,@("Employees = PROCESSES", "Each running program is an employee doing a task.", $PU)
    ,@("Guard = FIREWALL", "Controls who enters (inbound) and leaves (outbound).", $TL)
)
$y = 75
foreach ($item in $items) {
    RR $s 50 $y 260 58 $item[2] $item[0] 13 $W 1
    TB $s 325 ($y+5) 610 50 $item[1] 12 (C 200 210 220) 0 1
    $y += 65
}
Add-Footer $s $true


# ==== SLIDE 4: BOOT PROCESS ====
Write-Host "Creating slide 4 - Boot Process..."
$s = $presentation.Slides.Add(4, 12); BG $s $LBG
TB $s 40 20 880 50 "Linux Boot Process" 36 $BK 1 1
LN $s 40 68 200 4 $BL

$steps = @(
    ,@("1. BIOS/UEFI", "Hardware check, finds boot device", $BL)
    ,@("2. GRUB", "Bootloader - picks which kernel to load", $GR)
    ,@("3. Kernel", "Loads into memory, initializes drivers", $OR)
    ,@("4. systemd", "First process - starts all services", $RD)
    ,@("5. Login", "System ready! SSH or console login", $PU)
)
$x = 30
foreach ($step in $steps) {
    RR $s $x 110 170 100 $step[2] $step[0] 14 $W 1
    TB $s $x 220 170 60 $step[1] 11 $BK 0 2
    if ($x -lt 780) { TB $s ($x+175) 135 20 40 ">" 24 $BK 1 2 }
    $x += 190
}

TB $s 40 310 880 30 "Runlevels vs systemd Targets" 20 $BK 1 1
RR $s 60 350 840 45 $DBG "0=poweroff | 1=rescue | 3=multi-user | 5=graphical | 6=reboot" 14 $W 0
Add-Footer $s $false


# ==== SLIDE 5: FILE SYSTEM HIERARCHY ====
Write-Host "Creating slide 5 - File System..."
$s = $presentation.Slides.Add(5, 12); BG $s $DBG
TB $s 40 15 880 45 "File System Hierarchy (FHS)" 32 $W 1 1

$dirs = @(
    ,@("/", "Root of everything", $RD)
    ,@("/home", "User home directories (personal offices)", $BL)
    ,@("/etc", "Configuration files (admin office)", $GR)
    ,@("/var/log", "System logs (security cameras)", $OR)
    ,@("/tmp", "Temporary files (cleaned on reboot)", $PU)
    ,@("/opt", "Optional/third-party software", $TL)
    ,@("/bin /sbin", "Essential commands and system binaries", $BL)
    ,@("/usr", "User programs and libraries", $GR)
    ,@("/dev", "Device files (hardware access)", $OR)
    ,@("/proc", "Virtual filesystem - process info", $RD)
)
$col = 0; $row = 0; $yS = 70
foreach ($d in $dirs) {
    $xx = 30 + ($col * 480)
    $yy = $yS + ($row * 75)
    RR $s $xx $yy 120 55 $d[2] $d[0] 14 $W 1
    TB $s ($xx+130) ($yy+8) 320 45 $d[1] 13 (C 200 210 220) 0 1
    $col++; if ($col -ge 2) { $col = 0; $row++ }
}
Add-Footer $s $true


# ==== SLIDE 6: FILE AND DIRECTORY COMMANDS ====
Write-Host "Creating slide 6 - File Commands..."
$s = $presentation.Slides.Add(6, 12); BG $s $LBG
TB $s 40 15 880 45 "Essential Commands: File and Directory" 32 $BK 1 1
LN $s 40 58 250 4 $BL

$cmds = @(
    ,@("ls -la", "List all files with details (including hidden)")
    ,@("cd /path", "Change directory - move into a folder")
    ,@("pwd", "Print working directory - where am I?")
    ,@("cp -r src/ dest/", "Copy files/folders recursively")
    ,@("mv old new", "Move or rename files")
    ,@("rm -rf folder/", "Delete folder permanently (careful!)")
    ,@("mkdir -p a/b/c", "Create nested directories")
    ,@("find / -name *.log", "Search entire system for .log files")
    ,@("touch file.txt", "Create empty file or update timestamp")
    ,@("ln -s target link", "Create symbolic (soft) link")
)
$y = 72
foreach ($c in $cmds) {
    RR $s 40 $y 220 34 $DBG $c[0] 12 $GR 1
    TB $s 275 ($y+2) 660 30 $c[1] 13 $BK 0 1
    $y += 40
}
Add-Footer $s $false


# ==== SLIDE 7: PERMISSIONS ====
Write-Host "Creating slide 7 - Permissions..."
$s = $presentation.Slides.Add(7, 12); BG $s $DBG
TB $s 40 15 880 45 "Permissions - The Key Card System" 32 $W 1 1
TB $s 50 70 860 35 "Every file has: Owner (u) | Group (g) | Others (o)" 18 $OR 1 2

$perms = @(
    ,@("r (read) = 4", "View file contents / list directory", $GR)
    ,@("w (write) = 2", "Edit file / add-remove in directory", $BL)
    ,@("x (execute) = 1", "Run as program / enter directory", $OR)
)
$y = 120
foreach ($p in $perms) {
    RR $s 60 $y 250 45 $p[2] $p[0] 16 $W 1
    TB $s 330 ($y+5) 600 35 $p[1] 14 (C 200 210 220) 0 1
    $y += 55
}

TB $s 50 300 880 30 "Common Permission Examples" 18 $YL 1 1
$exs = @(
    ,@("chmod 755 file", "Owner: rwx, Group: r-x, Others: r-x")
    ,@("chmod 644 file", "Owner: rw-, Group: r--, Others: r--")
    ,@("chown user:group file", "Change who owns the file")
    ,@("umask 022", "Default permissions for new files")
)
$y = 338
foreach ($e in $exs) {
    RR $s 50 $y 230 32 $AC $e[0] 12 $W 1
    TB $s 295 ($y+2) 640 28 $e[1] 12 (C 200 210 220) 0 1
    $y += 38
}
Add-Footer $s $true


# ==== SLIDE 8: TEXT PROCESSING ====
Write-Host "Creating slide 8 - Text Processing..."
$s = $presentation.Slides.Add(8, 12); BG $s $LBG
TB $s 40 15 880 45 "Text Processing Commands" 32 $BK 1 1
LN $s 40 58 250 4 $GR

$cmds = @(
    ,@("cat file.txt", "Display entire file contents")
    ,@("less file.txt", "View file page by page (scrollable)")
    ,@("head -20 file", "Show first 20 lines")
    ,@("tail -f /var/log/syslog", "Follow log in real-time (live updates!)")
    ,@("grep error log.txt", "Search for text pattern in file")
    ,@("grep -r TODO /src/", "Search recursively in all files")
    ,@("awk print column", "Extract specific columns from file")
    ,@("sed s/old/new/g file", "Find and replace text")
    ,@("sort | uniq -c", "Sort and count unique lines")
    ,@("wc -l file.txt", "Count number of lines in file")
)
$y = 72
foreach ($c in $cmds) {
    RR $s 40 $y 260 34 $DBG $c[0] 12 $GR 1
    TB $s 315 ($y+2) 620 30 $c[1] 13 $BK 0 1
    $y += 40
}
Add-Footer $s $false


# ==== SLIDE 9: PROCESS MANAGEMENT ====
Write-Host "Creating slide 9 - Process Management..."
$s = $presentation.Slides.Add(9, 12); BG $s $DBG
TB $s 40 15 880 45 "Process Management" 32 $W 1 1

$cmds = @(
    ,@("ps aux", "List ALL running processes with details")
    ,@("top / htop", "Real-time process monitor (Task Manager)")
    ,@("kill PID", "Stop a process gracefully")
    ,@("kill -9 PID", "Force kill a stuck process")
    ,@("systemctl start nginx", "Start a service")
    ,@("systemctl enable nginx", "Auto-start service on boot")
    ,@("systemctl status nginx", "Check if service is running")
    ,@("journalctl -u nginx", "View service logs")
    ,@("nohup cmd", "Run command that survives logout")
    ,@("bg / fg / jobs", "Manage background/foreground jobs")
)
$y = 70
foreach ($c in $cmds) {
    RR $s 40 $y 270 34 $GB $c[0] 12 $GR 1
    TB $s 325 ($y+2) 610 30 $c[1] 13 (C 200 210 220) 0 1
    $y += 40
}
Add-Footer $s $true


# ==== SLIDE 10: NETWORKING ====
Write-Host "Creating slide 10 - Networking..."
$s = $presentation.Slides.Add(10, 12); BG $s $LBG
TB $s 40 15 880 45 "Networking Commands" 32 $BK 1 1
LN $s 40 58 200 4 $TL

$cmds = @(
    ,@("ip addr show", "Show IP addresses of all interfaces")
    ,@("ss -tulnp", "Show listening ports and processes")
    ,@("curl http://example.com", "Make HTTP request (test APIs)")
    ,@("wget URL", "Download a file from the internet")
    ,@("ping host", "Check if a server is reachable")
    ,@("traceroute host", "Show network path to destination")
    ,@("dig domain.com", "DNS lookup - resolve domain to IP")
    ,@("scp file user@host:/path", "Copy file to remote server securely")
    ,@("rsync -avz src/ dest/", "Sync files efficiently (only changes)")
    ,@("tcpdump -i eth0", "Capture network packets (debugging)")
)
$y = 72
foreach ($c in $cmds) {
    RR $s 40 $y 280 34 $DBG $c[0] 12 $GR 1
    TB $s 335 ($y+2) 600 30 $c[1] 13 $BK 0 1
    $y += 40
}
Add-Footer $s $false


# ==== SLIDE 11: USER MANAGEMENT ====
Write-Host "Creating slide 11 - User Management..."
$s = $presentation.Slides.Add(11, 12); BG $s $DBG
TB $s 40 15 880 45 "User and Group Management" 32 $W 1 1

$cmds = @(
    ,@("useradd -m john", "Create user with home directory")
    ,@("passwd john", "Set or change password")
    ,@("usermod -aG sudo john", "Add user to sudo group")
    ,@("userdel -r john", "Delete user and home directory")
    ,@("groupadd devops", "Create a new group")
    ,@("id john", "Show user UID, GID, and groups")
    ,@("who / w", "See who is currently logged in")
    ,@("sudo command", "Run command as root (superuser)")
    ,@("visudo", "Safely edit sudoers file")
    ,@("/etc/passwd /etc/shadow", "User info vs encrypted passwords")
)
$y = 70
foreach ($c in $cmds) {
    RR $s 40 $y 290 34 $GB $c[0] 12 $GR 1
    TB $s 345 ($y+2) 590 30 $c[1] 13 (C 200 210 220) 0 1
    $y += 40
}
Add-Footer $s $true


# ==== SLIDE 12: DISK AND STORAGE ====
Write-Host "Creating slide 12 - Disk and Storage..."
$s = $presentation.Slides.Add(12, 12); BG $s $LBG
TB $s 40 15 880 45 "Disk and Storage Commands" 32 $BK 1 1
LN $s 40 58 200 4 $OR

$cmds = @(
    ,@("df -h", "Show disk space usage (human-readable)")
    ,@("du -sh /var/log", "Show size of a specific directory")
    ,@("lsblk", "List all block devices and partitions")
    ,@("mount /dev/sdb1 /mnt", "Mount a disk to a directory")
    ,@("fdisk /dev/sdb", "Partition a disk interactively")
    ,@("mkfs.ext4 /dev/sdb1", "Format partition with ext4")
    ,@("blkid", "Show UUID and filesystem type")
    ,@("/etc/fstab", "Config file for auto-mounting on boot")
)
$y = 72
foreach ($c in $cmds) {
    RR $s 40 $y 270 34 $DBG $c[0] 12 $GR 1
    TB $s 325 ($y+2) 610 30 $c[1] 13 $BK 0 1
    $y += 40
}
Add-Footer $s $false


# ==== SLIDE 13: SSH AND SECURITY ====
Write-Host "Creating slide 13 - SSH and Security..."
$s = $presentation.Slides.Add(13, 12); BG $s $DBG
TB $s 40 15 880 45 "SSH and Security" 32 $W 1 1
TB $s 50 65 880 30 "SSH Key-Based Authentication Flow:" 18 $OR 1 1

$steps = @("Generate Key Pair","Copy Public Key","Connect via SSH","Server Verifies")
$descs = @("ssh-keygen -t rsa","ssh-copy-id user@host","ssh user@host","Matches keys = Access!")
$cols = @($BL, $GR, $OR, $TL)
$x = 30
for ($i = 0; $i -lt 4; $i++) {
    RR $s $x 100 210 45 $cols[$i] $steps[$i] 13 $W 1
    TB $s $x 150 210 25 $descs[$i] 11 (C 180 190 200) 0 2
    $x += 235
}

TB $s 50 195 880 30 "SSH Hardening Best Practices:" 18 $YL 1 1
$tips = @(
    "Disable root login: PermitRootLogin no",
    "Disable password auth: PasswordAuthentication no",
    "Change default port: Port 2222 (not 22)",
    "Use fail2ban to block brute-force attacks",
    "Allow specific users: AllowUsers deploy admin"
)
$y = 230
foreach ($t in $tips) {
    RR $s 60 $y 840 30 $GB $t 13 (C 200 210 220) 0
    $y += 36
}

TB $s 50 420 880 30 "Firewall:" 16 $RD 1 1
RR $s 60 452 400 30 $GB "ufw allow 443 | ufw deny 22 | ufw enable" 12 $GR 0
Add-Footer $s $true


# ==== SLIDE 14: PACKAGES AND CRON ====
Write-Host "Creating slide 14 - Packages and Cron..."
$s = $presentation.Slides.Add(14, 12); BG $s $LBG
TB $s 40 15 880 45 "Package Management and Cron Jobs" 32 $BK 1 1

TB $s 40 70 400 25 "Package Managers:" 18 $BK 1 1
$pkgs = @(
    ,@("apt update; apt install nginx", "Debian/Ubuntu")
    ,@("yum install httpd", "CentOS/RHEL/Amazon Linux")
    ,@("dnf install nginx", "Fedora / newer RHEL")
    ,@("rpm -ivh package.rpm", "Install from .rpm file")
)
$y = 100
foreach ($p in $pkgs) {
    RR $s 40 $y 350 30 $DBG $p[0] 11 $GR 1
    TB $s 400 ($y+2) 200 26 $p[1] 12 $BK 0 1
    $y += 36
}

TB $s 40 265 400 25 "Cron - Schedule Tasks:" 18 $BK 1 1
TB $s 40 295 880 30 "Format: MIN HOUR DAY MONTH WEEKDAY COMMAND" 14 $BL 1 1

$crons = @(
    ,@("0 2 * * * /backup.sh", "Run backup every day at 2 AM")
    ,@("*/5 * * * * /check.sh", "Run every 5 minutes")
    ,@("0 0 * * 0 /cleanup.sh", "Every Sunday at midnight")
    ,@("crontab -e", "Edit your cron jobs")
    ,@("crontab -l", "List your cron jobs")
)
$y = 330
foreach ($c in $crons) {
    RR $s 40 $y 300 30 $DBG $c[0] 11 $GR 1
    TB $s 355 ($y+2) 580 26 $c[1] 12 $BK 0 1
    $y += 36
}
Add-Footer $s $false


# ==== SLIDE 15: PROJECT ====
Write-Host "Creating slide 15 - Project..."
$s = $presentation.Slides.Add(15, 12); BG $s $DBG
TB $s 40 15 880 45 "Project: EC2 Server Hardening" 32 $W 1 1
TB $s 40 58 880 25 "Build a production-ready, hardened server from scratch" 16 $OR 0 1

$proj = @(
    ,@("1. SSH Hardened", "Key-only auth, custom port, fail2ban", $BL)
    ,@("2. Log Rotation", "Automated with logrotate + cron", $GR)
    ,@("3. Disk Monitoring", "Alerts via cron + SNS when disk > 80%", $OR)
    ,@("4. Firewall Rules", "iptables / firewalld - only needed ports", $RD)
    ,@("5. Nginx Secured", "Installed, configured, SSL-ready", $PU)
    ,@("6. Automation Scripts", "Repeatable setup - infrastructure as code", $TL)
)
$y = 95
foreach ($p in $proj) {
    RR $s 50 $y 240 50 $p[2] $p[0] 14 $W 1
    TB $s 305 ($y+8) 640 40 $p[1] 13 (C 200 210 220) 0 1
    $y += 58
}

RR $s 50 450 860 35 $DB "Deliverable: Hardened server + automation scripts + security audit checklist" 12 $YL 0
Add-Footer $s $true


# ==== SLIDE 16: INTERVIEW QUESTIONS ====
Write-Host "Creating slide 16 - Interview Questions..."
$s = $presentation.Slides.Add(16, 12); BG $s $LBG
TB $s 40 15 880 45 "Top Linux Interview Questions" 32 $BK 1 1
LN $s 40 58 250 4 $RD

$qs = @(
    "1. Explain the Linux boot process (BIOS > GRUB > Kernel > systemd)",
    "2. Hard link vs Soft link - what is the difference?",
    "3. chmod 755 vs chmod 644 - when to use each?",
    "4. How to find files >100MB modified in last 7 days?",
    "5. Explain iptables chains: INPUT, OUTPUT, FORWARD",
    "6. How does SSH key-based authentication work?",
    "7. What is the sticky bit and when to use it?",
    "8. How to troubleshoot a service that will not start?",
    "9. Difference between /etc/passwd and /etc/shadow?",
    "10. ps aux vs top - when to use which?"
)
$y = 72
foreach ($q in $qs) {
    RR $s 40 $y 880 34 (C 50 60 80) $q 13 $W 0
    $y += 39
}
Add-Footer $s $false


# ==== SLIDE 17: CHEAT SHEET ====
Write-Host "Creating slide 17 - Cheat Sheet..."
$s = $presentation.Slides.Add(17, 12); BG $s $DBG
TB $s 40 10 880 40 "Linux Quick Reference Cheat Sheet" 28 $W 1 2

$cats = @(
    ,@("Files", "ls  cd  cp  mv  rm  mkdir  find  touch  ln", $BL)
    ,@("Permissions", "chmod  chown  chgrp  umask  getfacl  setfacl", $GR)
    ,@("Text", "cat  grep  awk  sed  head  tail  sort  uniq  wc", $OR)
    ,@("Process", "ps  top  kill  systemctl  journalctl  nohup  bg  fg", $RD)
    ,@("Network", "ip  ss  curl  wget  ping  dig  scp  rsync  tcpdump", $TL)
    ,@("Users", "useradd  usermod  userdel  passwd  groupadd  sudo", $PU)
    ,@("Disk", "df  du  mount  lsblk  fdisk  mkfs  blkid", $BL)
    ,@("Packages", "apt  yum  dnf  rpm  dpkg  snap  pip", $GR)
    ,@("SSH", "ssh  ssh-keygen  ssh-copy-id  scp  ufw  iptables", $OR)
    ,@("System", "uname  hostname  uptime  free  vmstat  dmesg  lscpu", $RD)
)
$y = 55
foreach ($cat in $cats) {
    RR $s 30 $y 120 36 $cat[2] $cat[0] 13 $W 1
    TB $s 160 ($y+3) 790 30 $cat[1] 12 (C 200 210 220) 0 1 "Consolas"
    $y += 42
}
Add-Footer $s $true


# ==== SLIDE 18: THANK YOU ====
Write-Host "Creating slide 18 - Thank You..."
$s = $presentation.Slides.Add(18, 12); BG $s $DBG
LN $s 0 0 960 6 $BL
RR $s 320 100 320 60 $BL "LINUX FUNDAMENTALS" 20 $W 1
TB $s 60 200 840 60 "You Are Now Ready!" 44 $W 1 2
TB $s 60 280 840 40 "Practice these commands daily on an EC2 instance" 20 $OR 0 2
TB $s 60 340 840 35 "Next Module: Shell Scripting" 18 (C 150 160 180) 0 2
RR $s 200 420 560 40 $DB "Keep Learning | Keep Building | Keep Growing" 14 (C 180 190 200) 0
Add-Footer $s $true

# ==== SAVE ====
Write-Host ""
Write-Host "Saving presentation..."
$presentation.SaveAs($savePath)
Write-Host "====================================="
Write-Host "PPT CREATED SUCCESSFULLY!"
Write-Host "Location: $savePath"
Write-Host "Total Slides: 18"
Write-Host "====================================="
