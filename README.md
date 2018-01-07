# bash-system-backup
BASH script to automate system backup

> **DISCLAIMER**
> This is an *EXPERMIENTAL* script for system backup. Use at your own risk.

# Usage
The same script is used for backup and restore.

```sh
Usage:
 * backup:  backup --full
            backup --incr
 * restore: backup --restore [DATE]
           
Options:
      --full        Create a new full backup
      --incr        Create a new incremental backup
      --restore     Restore a backup. Specify date as only parameter or defaults to latest
      --reset       Reset all backup files (DEV/DEBUG only)
  -h, --help        Display this help and exit
      --version     Output version information and exit
```

# Contributions
All contributions are welcome, either as PR or issue.

# Thanks
- [NATHANIEL LANDAU](https://natelandau.com) for his [Boilerplate Shell Script template](https://natelandau.com/boilerplate-shell-script-template).
