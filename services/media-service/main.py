"""
Media Microservice for DWMB.
Handles file storage and management via MinIO.
"""
import os
import logging
from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional, List
import boto3
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DWMB Media Service", version="1.0.0")

# MinIO configuration
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "minio:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "dwmb_minio")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "dwmb_minio_secret")
MINIO_BUCKET = os.getenv("MINIO_BUCKET", "dwmb-media")


def get_s3_client():
    """Get MinIO S3 client."""
    return boto3.client(
        "s3",
        endpoint_url=f"http://{MINIO_ENDPOINT}",
        aws_access_key_id=MINIO_ACCESS_KEY,
        aws_secret_access_key=MINIO_SECRET_KEY,
        region_name="us-east-1",
    )


class UploadResponse(BaseModel):
    key: str
    url: str
    size: int


class FileInfo(BaseModel):
    key: str
    size: int
    last_modified: Optional[str]
    content_type: Optional[str]


@app.get("/health")
async def health():
    return {"status": "ok", "service": "media-service"}


@app.post("/upload", response_model=UploadResponse)
async def upload_file(file: UploadFile = File(...), prefix: str = "uploads"):
    """Upload a file to MinIO."""
    try:
        s3 = get_s3_client()
        
        # Generate unique key
        import hashlib
        import time
        file_content = await file.read()
        file_hash = hashlib.md5(file_content).hexdigest()[:8]
        ext = file.filename.split(".")[-1] if "." in file.filename else ""
        key = f"{prefix}/{file_hash}_{int(time.time())}.{ext}"
        
        # Ensure bucket exists
        try:
            s3.head_bucket(Bucket=MINIO_BUCKET)
        except ClientError:
            s3.create_bucket(Bucket=MINIO_BUCKET)
        
        # Upload file
        s3.put_object(
            Bucket=MINIO_BUCKET,
            Key=key,
            Body=file_content,
            ContentType=file.content_type or "application/octet-stream"
        )
        
        url = f"http://{MINIO_ENDPOINT}/{MINIO_BUCKET}/{key}"
        
        return UploadResponse(
            key=key,
            url=url,
            size=len(file_content)
        )
    except Exception as e:
        logger.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/files/{key:path}")
async def get_file(key: str):
    """Get file info from MinIO."""
    try:
        s3 = get_s3_client()
        
        response = s3.head_object(Bucket=MINIO_BUCKET, Key=key)
        
        return FileInfo(
            key=key,
            size=response.get("ContentLength", 0),
            last_modified=str(response.get("LastModified", "")),
            content_type=response.get("ContentType", "")
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "404":
            raise HTTPException(status_code=404, detail="File not found")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/files/{key:path}")
async def delete_file(key: str):
    """Delete file from MinIO."""
    try:
        s3 = get_s3_client()
        s3.delete_object(Bucket=MINIO_BUCKET, Key=key)
        return {"success": True}
    except Exception as e:
        logger.error(f"Delete error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/files")
async def list_files(prefix: str = "", limit: int = 100):
    """List files in MinIO."""
    try:
        s3 = get_s3_client()
        
        response = s3.list_objects_v2(
            Bucket=MINIO_BUCKET,
            Prefix=prefix,
            MaxKeys=limit
        )
        
        files = []
        for obj in response.get("Contents", []):
            files.append({
                "key": obj["Key"],
                "size": obj["Size"],
                "last_modified": str(obj["LastModified"])
            })
        
        return {"files": files, "count": len(files)}
    except Exception as e:
        logger.error(f"List error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
