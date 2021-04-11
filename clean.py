#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import boto3
from datetime import datetime, timedelta, timezone


def env_var(key, default=None, required=True):
    value = os.environ.get(key)
    if value == None:
        if required == True:
            sys.stderr.write(
                'ERROR! Environment variable %s is not set\n' % (key))
            sys.stderr.flush()
            sys.exit(1)
        else:
            return default
    else:
        return value


S3_URL = env_var('S3_URL', required=False)
S3_BUCKET = env_var('S3_BUCKET', '')
S3_ACCESS_KEY = env_var('S3_ACCESS_KEY')
S3_SECRET_KEY = env_var('S3_SECRET_KEY')
S3_FILE_MASK = sys.argv[1]
BACKUP_KEEP_DAYS = int(env_var('BACKUP_KEEP_DAYS', default=30, required=False))


s3client = boto3.client('s3', endpoint_url=S3_URL,
                        aws_access_key_id=S3_ACCESS_KEY, aws_secret_access_key=S3_SECRET_KEY)
today = datetime.now(tz=timezone.utc)
threshold = timedelta(days=BACKUP_KEEP_DAYS)
start_date = today - threshold
sys.stderr.write(
    'Dropping old backups from cloud (matching mask \"%s\" and older than %s)\n' % (S3_FILE_MASK, start_date))
sys.stderr.flush()

objects = s3client.list_objects(
    Bucket=S3_BUCKET, Prefix=S3_FILE_MASK, Delimiter='/')['Contents']
keys_to_drop = []
for obj in objects:
    if obj['LastModified'] < start_date:
        sys.stderr.write('Marking \"%s\" for removal\n' % obj['Key'])
        sys.stderr.flush()
        s3client.delete_object(Bucket=S3_BUCKET, Key=obj['Key'])
    else:
        sys.stderr.write('Won\'t remove \"%s\"\n' % obj['Key'])
        sys.stderr.flush()

if keys_to_drop.count > 0:
    if keys_to_drop.count < objects.count:
        for key in keys_to_drop:
            sys.stderr.write('Removing \"%s\"\n' % key)
            sys.stderr.flush()
            s3client.delete_object(Bucket=S3_BUCKET, Key=key)
    else:
        sys.stderr.write('Won\'t remove any backups since all backups were marked for removal\n')
        sys.stderr.flush()

sys.stderr.write('Completed\n')
sys.stderr.flush()
