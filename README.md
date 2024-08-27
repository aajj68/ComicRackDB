
# ComicRack Docker Database

A Docker container for ComicRack database.

IMPORTANT: This Docker container was created and tested on Windows 11. Minor adjustments will likely be needed to run it on other platforms, especially regarding file and directory paths.

## Features

- MariaDB for ComicRack database
- phpMyAdmin to access the database
- Automatic backup (daily, weekly, and monthly)
- Warnings by email if something goes wrong
- Warnings by Telegram if email warnings fail

## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

- `COMICRACK_CONTAINER`
- `COMICRACK_USER`
- `COMICRACK_USER_PASSWORD`
- `COMICRACK_ROOT_PASSWORD`
- `MYSQL_DATABASE`
- `APPDATA`
- `BACKUP`
- `SSMTP_MAILHUB`
- `SSMTP_AUTHUSER`
- `SSMTP_AUTHPASS`
- `SSMTP_REWRITEDOMAIN`
- `SSMTP_HOSTMAME`
- `SSMTP_TO`
- `TELEGRAM_API_KEY`
- `TELEGRAM_CHAT_ID`

See more in app/var.env.examples

## Email
To configure email sending, if you are using Gmail, you will need to set up an app password in the administrative area of your [Google account](https://myaccount.google.com/) otherwise, you won't be able to send emails.
```
SSMTP_AUTHUSER=<username>@gmail.com
SSMTP_AUTHPASS=password
SSMTP_TO=any-email-you-want@domain.com
```

## Telegram

Create a bot in telegram, get TELEGRAM_API_KEY and TELEGRAM_CHAT_ID and test sending a message:
- Create a bot [https://core.telegram.org/bots]
- To get chat_id [`https://api.telegram.org/bot<token>/getMe`]
- To send a message [`https://api.telegram.org/bot<token>/sendmessage?chat_id=<chat_id>&text=<message>`]

## Project Tree
```
ComicRackDB
├─ app
│  ├─ comicrack.sh
│  ├─ crontab-cron
│  ├─ docker-entrypoint.sh
│  ├─ send_email.sh
│  ├─ ssmtp.conf
│  ├─ start_containers.bat
│  ├─ telegram.sh
│  ├─ var.env
│  └─ var.env.example
├─ data
├─ log
├─ docker-compose.yml
├─ LICENSE
├─ README.md
├─ run.bat
└─ run.sh

```

## ComicRack.ini
Modify the file C:\Program Files (x86)\ComicRack\ComicRack.ini with the database connection parameters:

```
DataSource = mysql:Server=localhost;Uid=COMICRACK_USER;Pwd=COMICRACK_PASSWORD;Database=MYSQL_DATABASE
````
Note that you should substitute with the same values declared in the var.env file. If the Docker container is running on another machine on your internal network, you should change the "localhost" parameter to this IP. For example: "192.168.0.10". Verify that port 3306 is allowed through your firewall.

## Backup database
Log files are stored in /log and mapped to the host. In case of errors, the system will attempt to send an email alerting of the backup failure. If the email notification fails, it will then try to notify via Telegram. Therefore, please verify that everything is configured correctly to ensure your database is backed up.

In addition to daily, weekly, and monthly backups, the folders are also shared via Microsoft OneDrive.

var.env
```
APPDATA=C:\Users\<username>\appdata\Roaming\cYo\ComicRack
BACKUP=C:\Users\<username>\OneDrive\Documents\ComicRack
```
docker-compose.yml
```
    volumes:
      - .\data\mariadb:/var/lib/mysql
      - .\app:/app
      - "${BACKUP}:/windows/backup"
      - "${APPDATA}:/windows/appdata"
      - .\log:/var/log/
```
Note that APPDATA refers to the local settings and plugins of ComicRack, while BACKUP refers to the folder within OneDrive. Of course, you could point it to another service, like Dropbox.

## contab.cron
In the file app/crontab.cron are the scheduled backup tasks. You can modify this file according to your preferences. To disable the monthly backup, for example, just comment out the line:
```
0 12 * * *  /bin/bash /app/comicrack.sh -c day 2>&1 | tee /var/log/comicrack.log
0 13 * * 0  /bin/bash /app/comicrack.sh -c week 2>&1 | tee /var/log/comicrack.log
# 0 14 1 * *  /bin/bash /app/comicrack.sh -c month 2>&1 | tee /var/log/comicrack.log
```
### Rebuild and restar docker container.
To do this, simply run the command:
```
C:\Users\<username>\projects\Docker\ComicRackDB>run.bat
```

## Authors

- [@aajj68](https://github.com/aajj68)