"""
Routes module for the AeraSync API.
This package contains all API route definitions.
"""

from .health import router as health_router
from .aerator import router as aerator_router
from .root import router as root_router
from fastapi import APIRouter

router = APIRouter()

router.include_router(health_router)
router.include_router(aerator_router)
router.include_router(root_router)
