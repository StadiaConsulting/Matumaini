#!/bin/bash

# Make sure this variable is in sync with variables.tf
BaseS3Bucket=kch-matumaini

echo "Removing all files in S3 bucket $BaseS3Bucket"
aws s3 rm s3://$BaseS3Bucket --recursive
