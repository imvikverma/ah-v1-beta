"""
Retry decorator for API calls with exponential backoff.
"""

import time
import logging
from functools import wraps
from typing import Callable, TypeVar, Any
from requests.exceptions import RequestException, Timeout, ConnectionError

logger = logging.getLogger("AurumHarmony")

T = TypeVar('T')


def retry_api_call(
    max_retries: int = 3,
    initial_delay: float = 1.0,
    backoff_factor: float = 2.0,
    exceptions: tuple = (RequestException, Timeout, ConnectionError, Exception)
):
    """
    Decorator to retry API calls with exponential backoff.
    
    Args:
        max_retries: Maximum number of retry attempts
        initial_delay: Initial delay in seconds before first retry
        backoff_factor: Multiplier for delay between retries
        exceptions: Tuple of exceptions to catch and retry on
        
    Example:
        @retry_api_call(max_retries=3, initial_delay=1.0)
        def my_api_call():
            ...
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            delay = initial_delay
            last_exception = None
            
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt < max_retries:
                        logger.warning(
                            f"API call failed (attempt {attempt + 1}/{max_retries + 1}): {str(e)}. "
                            f"Retrying in {delay:.2f}s..."
                        )
                        time.sleep(delay)
                        delay *= backoff_factor
                    else:
                        logger.error(
                            f"API call failed after {max_retries + 1} attempts: {str(e)}"
                        )
            
            # If we get here, all retries failed
            raise last_exception
        
        return wrapper
    return decorator
