from fastapi import FastAPI
from .api.routers import users, auth, public, user, admin

def create_app() -> FastAPI:
    app = FastAPI(title="Onboarding API")

    @app.get("/health", tags=["health"])
    async def health():
        return {"status": "ok"}

    # include routers under /api/v1
    app.include_router(users.router, prefix="/api/v1", tags=["users"])
    app.include_router(auth.router, prefix="/api/v1", tags=["auth"])
    app.include_router(public.router, prefix="/api/v1", tags=["public"])
    app.include_router(user.router, prefix="/api/v1", tags=["user"])
    app.include_router(admin.router, prefix="/api/v1", tags=["admin"])
    return app

app = create_app()
