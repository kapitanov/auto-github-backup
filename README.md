# auto-github-backup

[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/kapitanov/auto-github-backup?style=flat-square)](https://hub.docker.com/r/kapitanov/auto-github-backup/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/kapitanov/auto-github-backup?style=flat-square)](https://hub.docker.com/r/kapitanov/auto-github-backup)
![GitHub](https://img.shields.io/github/license/kapitanov/auto-github-backup?style=flat-square)

This container makes a backup daily of your GitHub repositories, uploads them to S3 object storage and keeps up to defined number of backups.

Under the hood it uses:

* [python-github-backup](https://github.com/josegonzalez/python-github-backup) to take backups
* [AWS SDK for Python](https://github.com/boto/boto3/) to upload and manage backup files

## Install and run

1. Generate [GitHub access token](https://github.com/settings/tokens)
2. Clone this repo to `/opt/github-backup` (or any other suitable location):

   ```shell
   git clone https://github.com/kapitanov/auto-github-backup.git /opt/github-backup
   ```

3. Build docker image:

   ```shell
   cd /opt/github-backup
   docker-compose build
   ```

4. Create `.env` file containing env variables (see table below).
5. Start docker container:

   ```shell
   docker-compose up -d
   ```

   Backups will be taken on daily basis and uploaded (in `.tar.gz` format) to S3 object storage.
   All backups older than `$BACKUP_KEEP_DAYS` will be deleted from S3.

## Configuration

This container is configured via environment variables:

| Variable              | Is required | Default value | Description                                 |
| --------------------- | ----------- | ------------- | ------------------------------------------- |
| `GITHUB_USER`         | Yes         |               | Comma-separated list of GitHub user names   |
| `GITHUB_ACCESS_TOKEN` | Yes         |               | GitHub access token                         |
| `S3_ACCESS_KEY`       | Yes         |               | Access key for S3                           |
| `S3_SECRET_KEY`       | Yes         |               | Secret key for S3                           |
| `S3_BUCKET`           | Yes         |               | S3 bucket name                              |
| `S3_URL`              | No          |               | S3 service URL (not needed for AWS S3)      |
| `S3_PREFIX`           | No          |               | S3 filename prefix (e.g. `backups/github/`) |
| `BACKUP_KEEP_DAYS`    | No          | `30`          | Max age of backups (in days)                |

### Example .env file for AWS S3

```env
GITHUB_USER=github-user-1,github-user-2,github-user-3
GITHUB_ACCESS_TOKEN=my-github-access-token
S3_BUCKET=my-github-backups
S3_ACCESS_KEY=my-s3-access-key
S3_SECRET_KEY=my-s3-secret-key
```

### Example .env file for custom S3-compatible service

```env
GITHUB_USER=github-user-1,github-user-2,github-user-3
GITHUB_ACCESS_TOKEN=my-github-access-token
S3_URL=https://custom-s3-service.com/
S3_BUCKET=my-github-backups
S3_ACCESS_KEY=my-s3-access-key
S3_SECRET_KEY=my-s3-secret-key
```
