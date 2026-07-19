"""
Storage service for MinIO S3 integration.
Handles file uploads, downloads, and management.
"""
import hashlib
from typing import Optional, BinaryIO
from uuid import UUID

import boto3
from botocore.exceptions import ClientError
from fastapi import UploadFile

from app.config import get_settings


class StorageService:
    """MinIO S3 storage service."""

    def __init__(self):
        settings = get_settings()
        self.s3_client = boto3.client(
            "s3",
            endpoint_url=f"http://{settings.MINIO_ENDPOINT}",
            aws_access_key_id=settings.MINIO_ACCESS_KEY,
            aws_secret_access_key=settings.MINIO_SECRET_KEY,
            region_name="us-east-1",
        )
        self.public_endpoint = settings.MINIO_PUBLIC_ENDPOINT
        self.bucket = settings.MINIO_BUCKET
        self._ensure_bucket()

    def _ensure_bucket(self) -> None:
        """Create bucket if it doesn't exist."""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket)
        except ClientError:
            self.s3_client.create_bucket(Bucket=self.bucket)

    def generate_key(self, entity_id: UUID, filename: str) -> str:
        """Generate S3 key from entity ID and filename."""
        safe_name = filename.replace(" ", "_").replace("/", "_")
        return f"entities/{entity_id}/{safe_name}"

    async def upload_file(
        self,
        file: UploadFile,
        entity_id: UUID,
        content_type: str = "application/octet-stream",
    ) -> dict:
        """
        Upload file to MinIO.
        Returns dict with key, hash, size.
        """
        key = self.generate_key(entity_id, file.filename)

        # Read file content for hash calculation
        content = await file.read()
        file_hash = hashlib.sha256(content).hexdigest()

        # Upload
        self.s3_client.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=content,
            ContentType=content_type,
        )

        return {
            "key": key,
            "hash": file_hash,
            "size": len(content),
            "original_name": file.filename,
        }

    def get_presigned_url(self, key: str, expires: int = 3600) -> str:
        """Generate pre-signed URL for download (uses browser-reachable endpoint)."""
        settings = get_settings()
        url = self.s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": key},
            ExpiresIn=expires,
        )
        # Replace Docker-internal endpoint with public endpoint for browser access
        url = url.replace(f"http://{settings.MINIO_ENDPOINT}", f"http://{self.public_endpoint}")
        return url

    def get_file(self, key: str) -> Optional[bytes]:
        """Download file content."""
        try:
            response = self.s3_client.get_object(Bucket=self.bucket, Key=key)
            return response["Body"].read()
        except ClientError:
            return None

    def delete_file(self, key: str) -> bool:
        """Delete file from storage."""
        try:
            self.s3_client.delete_object(Bucket=self.bucket, Key=key)
            return True
        except ClientError:
            return False

    def list_files(self, prefix: str = "") -> list[dict]:
        """List files with optional prefix."""
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket, Prefix=prefix
            )
            files = []
            for obj in response.get("Contents", []):
                files.append(
                    {
                        "key": obj["Key"],
                        "size": obj["Size"],
                        "last_modified": obj["LastModified"],
                    }
                )
            return files
        except ClientError:
            return []


storage_service = StorageService()
