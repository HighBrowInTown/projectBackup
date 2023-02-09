Backup your project to GitHub as you save your file.

projectBackups script uses inotifywait to check changes made to the file executes the git backups.
Running as a systemd service which start the project directory monitoring for any file changes.