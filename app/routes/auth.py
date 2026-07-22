from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import verify_password, get_password_hash, create_access_token, get_current_user
from app.middleware.rate_limit import limiter, get_rate_limit

router = APIRouter(prefix="/auth", tags=["auth"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, user: UserAccount = Depends(get_current_user)):
    if user:
        return RedirectResponse(url="/", status_code=303)
    return templates.TemplateResponse("auth/login.html", {"request": request, "error": None})


@router.post("/login")
@limiter.limit(get_rate_limit("auth"))
async def login(request: Request, username: str = Form(...), password: str = Form(...), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(UserAccount).where(UserAccount.username == username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(password, user.password_hash):
        return templates.TemplateResponse("auth/login.html", {"request": request, "error": "Неверное имя пользователя или пароль"})

    token = create_access_token(data={"sub": user.username, "is_admin": user.is_admin})
    response = RedirectResponse(url="/", status_code=303)
    response.set_cookie("access_token", token, httponly=True, max_age=86400)
    return response


@router.get("/register", response_class=HTMLResponse)
async def register_page(request: Request, user: UserAccount = Depends(get_current_user)):
    if user:
        return RedirectResponse(url="/", status_code=303)
    return templates.TemplateResponse("auth/register.html", {"request": request, "error": None})


@router.post("/register")
@limiter.limit(get_rate_limit("auth"))
async def register(request: Request, username: str = Form(...), email: str = Form(...), password: str = Form(...), db: AsyncSession = Depends(get_db)):
    # Password validation
    if len(password) < 8:
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Пароль должен содержать минимум 8 символов"})
    if not any(c.isupper() for c in password):
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Пароль должен содержать хотя бы одну заглавную букву"})
    if not any(c.islower() for c in password):
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Пароль должен содержать хотя бы одну строчную букву"})
    if not any(c.isdigit() for c in password):
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Пароль должен содержать хотя бы одну цифру"})
    
    # Username validation
    if len(username) < 3:
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Имя пользователя должно содержать минимум 3 символа"})
    
    existing = await db.execute(select(UserAccount).where(UserAccount.username == username))
    if existing.scalar_one_or_none():
        return templates.TemplateResponse("auth/register.html", {"request": request, "error": "Пользователь уже существует"})

    user = UserAccount(
        username=username,
        email=email,
        password_hash=get_password_hash(password),
        display_name=username,
        is_admin=False
    )
    db.add(user)
    await db.flush()

    token = create_access_token(data={"sub": user.username, "is_admin": user.is_admin})
    response = RedirectResponse(url="/", status_code=303)
    response.set_cookie("access_token", token, httponly=True, max_age=86400)
    return response


@router.get("/logout")
async def logout():
    response = RedirectResponse(url="/auth/login", status_code=303)
    response.delete_cookie("access_token")
    return response
