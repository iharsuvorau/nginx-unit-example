from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.routing import Route


async def home(request: Request) -> JSONResponse:
    return JSONResponse({"hello": "world"})


async def about(request: Request) -> JSONResponse:
    return JSONResponse({"about": "this is a demo app"})


app = Starlette(
    debug=True, routes=[Route("/python", home), Route("/python/about", about)]
)
