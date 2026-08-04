import pytest
import boto3
import psycopg

@pytest.fixture
def db():
    return psycopg.connect("dbname=orders")

def upload(key: str) -> None:
    boto3.client("s3").put_object(Bucket="acme", Key=key)
