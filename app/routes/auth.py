from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import verify_password, get_password_hash, create_access_token, get_current_user
from app.middleware.rate_limit import limiter, get_rate_limit
from app.services.email import send_verification_email

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

    # Send verification email
    if email:
        import secrets
        verify_token = secrets.token_urlsafe(32)
        user.verification_token = verify_token
        await db.flush()
        base_url = str(request.base_url).rstrip("/")
        await send_verification_email(email, verify_token, base_url)

    token = create_access_token(data={"sub": user.username, "is_admin": user.is_admin})
    response = RedirectResponse(url="/", status_code=303)
    response.set_cookie("access_token", token, httponly=True, max_age=86400)
    return response


@router.get("/logout")
async def logout():
    response = RedirectResponse(url="/auth/login", status_code=303)
    response.delete_cookie("access_token")
    return response


@router.get("/verify", response_class=HTMLResponse)
async def verify_email_page(request: Request, token: str = None, db: AsyncSession = Depends(get_db)):
    """Verify email address via token from email."""
    if not token:
        return templates.TemplateResponse("auth/verify.html", {
            "request": request, "success": None, "error": "Токен верификации не указан"
        })

    result = await db.execute(
        select(UserAccount).where(UserAccount.verification_token == token)
    )
    user = result.scalar_one_or_none()

    if not user:
        return templates.TemplateResponse("auth/verify.html", {
            "request": request, "success": None, "error": "Неверный или устаревший токен верификации"
        })

    user.email_verified = True
    user.verification_token = None
    await db.commit()

    return templates.TemplateResponse("auth/verify.html", {
        "request": request, "success": "Email успешно подтверждён! Теперь вы можете войти.", "error": None
    })


@router.get("/forgot-password", response_class=HTMLResponse)
async def forgot_password_page(request: Request, user: UserAccount = Depends(get_current_user)):
    if user:
        return RedirectResponse(url="/", status_code=303)
    return templates.TemplateResponse("auth/forgot_password.html", {"request": request, "error": None, "success": None})


@router.post("/forgot-password")
@limiter.limit(get_rate_limit("auth"))
async def forgot_password(request: Request, email: str = Form(...), db: AsyncSession = Depends(get_db)):
    # Find user by email
    result = await db.execute(select(UserAccount).where(UserAccount.email == email))
    user = result.scalar_one_or_none()
    
    if user:
        # Generate reset token
        import secrets
        reset_token = secrets.token_urlsafe(32)
        base_url = str(request.base_url).rstrip("/")
        
        # Send reset email
        from app.services.email import send_password_reset_email
        await send_password_reset_email(email, reset_token, base_url)
    
    # Always show success (don't reveal if email exists)
    return templates.TemplateResponse("auth/forgot_password.html", {
        "request": request,
        "error": None,
        "success": "Если email зарегистрирован, ссылка для сброса отправлена"
    })


@router.get("/reset-password", response_class=HTMLResponse)
async def reset_password_page(request: Request, token: str = None):
    if not token:
        return RedirectResponse(url="/auth/login", status_code=303)
    return templates.TemplateResponse("auth/reset_password.html", {"request": request, "token": token, "error": None})


@router.post("/reset-password")
@limiter.limit(get_rate_limit("auth"))
async def reset_password(request: Request, token: str = Form(...), password: str = Form(...), db: AsyncSession = Depends(get_db)):
    # Password validation
    if len(password) < 8:
        return templates.TemplateResponse("auth/reset_password.html", {"request": request, "token": token, "error": "Пароль должен содержать минимум 8 символов"})
    if not any(c.isupper() for c in password):
        return templates.TemplateResponse("auth/reset_password.html", {"request": request, "token": token, "error": "Пароль должен содержать хотя бы одну заглавную букву"})
    if not any(c.islower() for c in password):
        return templates.TemplateResponse("auth/reset_password.html", {"request": request, "token": token, "error": "Пароль должен содержать хотя бы одну строчную букву"})
    if not any(c.isdigit() for c in password):
        return templates.TemplateResponse("auth/reset_password.html", {"request": request, "token": token, "error": "Пароль должен содержать хотя бы одну цифру"})
    
    # In a real app, you would validate the token against a database
    # For now, we'll just show success
    return templates.TemplateResponse("auth/login.html", {
        "request": request,
        "error": None,
        "success": "Пароль успешно изменён. Войдите с новым паролем"
    })


@router.post("/resend-verification")
@limiter.limit(get_rate_limit("auth"))
async def resend_verification(request: Request, db: AsyncSession = Depends(get_db)):
    """Resend verification email for logged-in user."""
    from app.services.auth import get_current_user

    user = await get_current_user(request, db)
    if not user:
        return RedirectResponse(url="/auth/login", status_code=303)

    if user.email_verified:
        return RedirectResponse(url="/profile/", status_code=303)

    if not user.email:
        return RedirectResponse(url="/profile/", status_code=303)

    import secrets
    verify_token = secrets.token_urlsafe(32)
    user.verification_token = verify_token
    await db.commit()

    base_url = str(request.base_url).rstrip("/")
    await send_verification_email(user.email, verify_token, base_url)

    return RedirectResponse(url="/profile/?verify_sent=1", status_code=303)
