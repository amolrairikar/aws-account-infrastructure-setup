from functools import wraps
import logging

import backoff
import botocore
import botocore.exceptions
import requests

logger = logging.getLogger(__name__)

def is_retryable_exception(e: botocore.exceptions.ClientError | requests.exceptions.HTTPError) -> bool:
    """Checks if the returned exception is retryable."""
    if isinstance(e, botocore.exceptions.ClientError):
        return e.response['Error']['Code'] in [
            'InternalServerError'
        ]
    elif isinstance(e, requests.exceptions.HTTPError):
        return e.response.status_code in [
            429, 500, 502, 503, 504
        ]
    return False


def backoff_on_client_error(func):
    """Reusable decorator to retry API calls for server errors."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        instance_or_class = None

        # If the function is a method, extract `self` or `cls`
        if args and hasattr(args[0], func.__name__):
            instance_or_class, *args = args

        @backoff.on_exception(
            backoff.expo,
            (botocore.exceptions.ClientError, requests.exceptions.HTTPError),
            max_tries=3,
            giveup=lambda e: not is_retryable_exception(e),
            on_success=lambda details: logger.info(f"Success after {details['tries']} tries"),
            on_giveup=lambda details: logger.info(f"Giving up after {details['tries']} tries"),
            on_backoff=lambda details: logger.info(f"Backing off after {details['tries']} tries due to {details['exception']}")
        )
        def retryable_call(*args, **kwargs):
            if instance_or_class:
                return func(instance_or_class, *args, **kwargs)  # Call method
            return func(*args, **kwargs)  # Call standalone function

        return retryable_call(*args, **kwargs)

    return wrapper