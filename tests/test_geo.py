"""Tests for geospatial functionality."""
import pytest
from app.models.geo import EntityGeo


def test_entity_geo_exists():
    """Test that EntityGeo model exists."""
    assert EntityGeo is not None
    assert hasattr(EntityGeo, 'latitude')
    assert hasattr(EntityGeo, 'longitude')


def test_entity_geo_distance_method():
    """Test that EntityGeo has distance_to method."""
    assert hasattr(EntityGeo, 'distance_to')
    assert callable(EntityGeo.distance_to)


def test_distance_calculation():
    """Test Haversine distance calculation."""
    geo = EntityGeo()
    geo.latitude = 55.7558
    geo.longitude = 37.6173
    
    # Distance to same point should be 0
    distance = geo.distance_to(55.7558, 37.6173)
    assert distance == 0.0
    
    # Distance to nearby point (within 1km)
    distance = geo.distance_to(55.76, 37.62)
    assert 0 < distance < 1000  # Less than 1km
