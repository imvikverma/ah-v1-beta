"""
Input validation utilities for API endpoints.
"""

from typing import Any, Dict, List, Optional
from flask import request, jsonify


def validate_json_required() -> Optional[Dict[str, Any]]:
    """
    Validate that request has JSON body.
    Returns the JSON data if valid, None otherwise.
    """
    if not request.is_json:
        return None
    return request.json


def validate_required_fields(data: Dict[str, Any], required_fields: List[str]) -> Optional[str]:
    """
    Validate that all required fields are present in data.
    
    Args:
        data: Dictionary to validate
        required_fields: List of required field names
        
    Returns:
        Error message if validation fails, None otherwise
    """
    missing = [field for field in required_fields if field not in data or data[field] is None]
    if missing:
        return f"Missing required fields: {', '.join(missing)}"
    return None


def validate_field_types(data: Dict[str, Any], field_types: Dict[str, type]) -> Optional[str]:
    """
    Validate that fields have correct types.
    
    Args:
        data: Dictionary to validate
        field_types: Dict mapping field names to expected types
        
    Returns:
        Error message if validation fails, None otherwise
    """
    errors = []
    for field, expected_type in field_types.items():
        if field in data:
            if not isinstance(data[field], expected_type):
                errors.append(
                    f"Field '{field}' must be of type {expected_type.__name__}, "
                    f"got {type(data[field]).__name__}"
                )
    
    if errors:
        return "; ".join(errors)
    return None


def validate_numeric_range(
    data: Dict[str, Any],
    field: str,
    min_val: Optional[float] = None,
    max_val: Optional[float] = None
) -> Optional[str]:
    """
    Validate that a numeric field is within a range.
    
    Args:
        data: Dictionary containing the field
        field: Field name to validate
        min_val: Minimum allowed value (inclusive)
        max_val: Maximum allowed value (inclusive)
        
    Returns:
        Error message if validation fails, None otherwise
    """
    if field not in data:
        return None  # Let required field validation handle missing fields
    
    try:
        value = float(data[field])
        if min_val is not None and value < min_val:
            return f"Field '{field}' must be >= {min_val}"
        if max_val is not None and value > max_val:
            return f"Field '{field}' must be <= {max_val}"
    except (ValueError, TypeError):
        return f"Field '{field}' must be numeric"
    
    return None
