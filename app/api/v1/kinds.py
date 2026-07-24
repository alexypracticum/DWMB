"""
API v1 Kinds endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.services.kind_service import KindService

router = APIRouter()


class CreateKindRequest(BaseModel):
    """Запрос на создание типа сущности."""
    kind_code: str
    description: Optional[str] = None
    is_abstract: bool = False
    sort_order: int = 0
    parent_kind_code: Optional[str] = None
    label_ru: Optional[str] = None
    label_en: Optional[str] = None


class KindResponse(BaseModel):
    """Модель типа сущности."""
    kind_id: str
    kind_code: str
    description: Optional[str]
    is_abstract: bool
    sort_order: int
    label: str


@router.get("/", response_model=List[KindResponse], summary="Типы сущностей", tags=["kinds"])
async def list_kinds(
    include_abstract: bool = Query(False, description="Включить абстрактные типы"),
    lang: str = Query("ru", description="Язык меток"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Получить список всех типов сущностей (film, book, song, person и т.д.)."""
    kinds = await KindService.list_kinds(db, include_abstract=include_abstract, lang=lang)
    
    return [
        KindResponse(
            kind_id=str(k["kind"].kind_id),
            kind_code=k["kind"].kind_code,
            description=k["kind"].description,
            is_abstract=k["kind"].is_abstract,
            sort_order=k["kind"].sort_order,
            label=k["label"],
        )
        for k in kinds
    ]


@router.get("/{kind_id}", response_model=KindResponse, summary="Получить тип", tags=["kinds"])
async def get_kind(
    kind_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Получить один тип сущности по UUID."""
    result = await KindService.get_kind(db, UUID(kind_id))
    if not result:
        raise HTTPException(status_code=404, detail="Kind not found")
    
    return KindResponse(
        kind_id=str(result["kind"].kind_id),
        kind_code=result["kind"].kind_code,
        description=result["kind"].description,
        is_abstract=result["kind"].is_abstract,
        sort_order=result["kind"].sort_order,
        label=result["label"],
    )


@router.post("/", response_model=KindResponse, status_code=201, summary="Создать тип", tags=["kinds"])
async def create_kind(
    request: CreateKindRequest,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Создать новый тип сущности с мультиязычными метками."""
    try:
        result = await KindService.create_kind(
            db,
            kind_code=request.kind_code,
            description=request.description,
            is_abstract=request.is_abstract,
            sort_order=request.sort_order,
            parent_kind_code=request.parent_kind_code,
            label_ru=request.label_ru,
            label_en=request.label_en,
        )
        
        return KindResponse(
            kind_id=str(result["kind"].kind_id),
            kind_code=result["kind"].kind_code,
            description=result["kind"].description,
            is_abstract=result["kind"].is_abstract,
            sort_order=result["kind"].sort_order,
            label=request.label_ru or request.kind_code,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{kind_id}", summary="Удалить тип", tags=["kinds"])
async def delete_kind(
    kind_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Удалить тип сущности (если нет сущностей этого типа)."""
    try:
        result = await KindService.delete_kind(db, UUID(kind_id))
        if not result:
            raise HTTPException(status_code=404, detail="Kind not found")
        return {"success": True, "message": "Kind deleted"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
