"""
Admin notification service for birthdays and anniversaries.
Provides monthly reminders to admins about upcoming birthdays and anniversaries.
"""

from datetime import datetime, date
from typing import List, Dict, Any
from sqlalchemy import extract
from aurum_harmony.database.db import db
from aurum_harmony.database.models import User


def get_upcoming_birthdays_and_anniversaries(month: int = None, year: int = None) -> Dict[str, List[Dict[str, Any]]]:
    """
    Get all users with birthdays and anniversaries in the specified month.
    
    Args:
        month: Month number (1-12). If None, uses current month.
        year: Year number. If None, uses current year.
    
    Returns:
        Dictionary with 'birthdays' and 'anniversaries' lists, each containing user info.
    """
    if month is None:
        month = datetime.now().month
    if year is None:
        year = datetime.now().year
    
    # Get users with birthdays this month
    birthdays = User.query.filter(
        User.date_of_birth.isnot(None),
        extract('month', User.date_of_birth) == month,
        User.is_active == True
    ).all()
    
    # Get users with anniversaries this month
    anniversaries = User.query.filter(
        User.anniversary.isnot(None),
        extract('month', User.anniversary) == month,
        User.is_active == True
    ).all()
    
    # Format birthday data
    birthday_list = []
    for user in birthdays:
        birthday_list.append({
            'user_id': user.id,
            'user_code': user.user_code,
            'email': user.email,
            'name': user.email.split('@')[0],  # Use email prefix as name placeholder
            'date_of_birth': user.date_of_birth.isoformat() if user.date_of_birth else None,
            'birthday_day': user.date_of_birth.day if user.date_of_birth else None,
            'fee_waiver_eligible': True,  # Policy: birthday = full fee waiver
        })
    
    # Format anniversary data
    anniversary_list = []
    for user in anniversaries:
        anniversary_list.append({
            'user_id': user.id,
            'user_code': user.user_code,
            'email': user.email,
            'name': user.email.split('@')[0],  # Use email prefix as name placeholder
            'anniversary': user.anniversary.isoformat() if user.anniversary else None,
            'anniversary_day': user.anniversary.day if user.anniversary else None,
            'fee_discount_eligible': True,  # Policy: anniversary = fee discount (amount TBD)
        })
    
    return {
        'month': month,
        'year': year,
        'birthdays': birthday_list,
        'anniversaries': anniversary_list,
        'total_birthdays': len(birthday_list),
        'total_anniversaries': len(anniversary_list),
    }


def get_birthday_anniversary_summary() -> Dict[str, Any]:
    """
    Get a summary of all upcoming birthdays and anniversaries for the current month.
    This is the main function to call for monthly admin notifications.
    """
    now = datetime.now()
    return get_upcoming_birthdays_and_anniversaries(month=now.month, year=now.year)

