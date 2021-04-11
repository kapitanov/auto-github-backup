#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import threading
import time
import requests
import boto3
import glob
from requests.auth import HTTPBasicAuth
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


class ProgressPercentage(object):

    def __init__(self, filename):
        self._filename = filename
        self._size = float(os.path.getsize(filename))
        self._seen_so_far = 0
        self._lock = threading.Lock()

    def __call__(self, bytes_amount):
        with self._lock:
            self._seen_so_far += bytes_amount
            percentage = (self._seen_so_far / self._size) * 100
            sys.stderr.write('\rUploading %s / %s  (%.2f%%)' %
                             (self._seen_so_far, self._size, percentage))
            sys.stderr.flush()


S3_URL = env_var('S3_URL', required=False)
S3_BUCKET = env_var('S3_BUCKET', '')
S3_ACCESS_KEY = env_var('S3_ACCESS_KEY')
S3_SECRET_KEY = env_var('S3_SECRET_KEY')
S3_PREFIX = env_var('S3_PREFIX', default='', required=False)
BACKUP_FILE_PATH = sys.argv[1]

s3client = boto3.client('s3', endpoint_url=S3_URL,
                        aws_access_key_id=S3_ACCESS_KEY, aws_secret_access_key=S3_SECRET_KEY)
tail = os.path.split(BACKUP_FILE_PATH)[1]
key = S3_PREFIX + tail

if S3_URL != None:
    sys.stderr.write('Uploading \"%s\" to %s/%s/%s\n' %
                     (BACKUP_FILE_PATH, S3_URL, S3_BUCKET, key))
else:
    sys.stderr.write('Uploading \"%s\" to s3://%s/%s\n' %
                     (BACKUP_FILE_PATH, S3_BUCKET, key))
sys.stderr.flush()

s3client.upload_file(Filename=BACKUP_FILE_PATH, Bucket=S3_BUCKET,
                                Key=key, Callback=ProgressPercentage(BACKUP_FILE_PATH))
sys.stderr.write('\nCompleted\n')
sys.stderr.flush()
