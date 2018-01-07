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

## Configuration
All configurations are inlined directly in the script.
> It could be possible to improve this by extracting the configuration into an external file. Feel free to file an issue if you're interested.

## Backup
To create a backup, simply run `backup.sh --full` for a full backup, or `backup.sh --incr` for an incremental backup.

When creating a full backup, a new directory is created in the backup root folder. This new directory is named after the current day. It will contain all backups until the next full backup, ie. the initial full backup and all next successive incremental backups. All backups are named after their date of creation, in the format `yyyy-MM-dd`.

## Restore
To restore a backup, simply run `backup.sh --restore <DATE>` where `<DATE>` is the date of the backup to restore in the format `yyyy-MM-dd`. It will then restore the closest available full-backup and all next incremental backups until `<DATE>`.


# Contributions
All contributions are welcome, either as PR or issue.

# Thanks
- [NATHANIEL LANDAU](https://natelandau.com) for his [Boilerplate Shell Script template](https://natelandau.com/boilerplate-shell-script-template).
