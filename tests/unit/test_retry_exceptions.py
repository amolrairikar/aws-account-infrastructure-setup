"""Module for testing retry_exceptions.py"""
import unittest
from unittest.mock import patch, MagicMock

import requests
import botocore

from layers.retry_api_exceptions.retry_api_exceptions import is_retryable_exception, backoff_on_client_error

class TestIsRetryableException(unittest.TestCase):
    """Class for testing is_retryable_exception method."""

    def test_retryable_aws_error(self):
        """Test a retryable botocore ClientError with InternalServerError."""
        error_response = {'Error': {'Code': 'InternalServerError'}}
        client_error = botocore.exceptions.ClientError(error_response, 'OperationName')
        self.assertTrue(is_retryable_exception(e=client_error))


    def test_non_retryable_aws_error(self):
        """Test a non-retryable botocore ClientError with a different error code."""
        error_response = {'Error': {'Code': 'AccessDenied'}}
        client_error = botocore.exceptions.ClientError(error_response, 'OperationName')
        self.assertFalse(is_retryable_exception(e=client_error))


    def test_retryable_http_error(self):
        """Test a retryable requests HTTPError with status code 429."""
        response_mock = MagicMock()
        response_mock.status_code = 429
        http_error = requests.exceptions.HTTPError(response=response_mock)
        self.assertTrue(is_retryable_exception(e=http_error))


    def test_non_retryable_http_error(self):
        """Test a non-retryable requests HTTPError with status code 429."""
        response_mock = MagicMock()
        response_mock.status_code = 404
        http_error = requests.exceptions.HTTPError(response=response_mock)
        self.assertFalse(is_retryable_exception(e=http_error))


    def test_non_retryable_other_exception(self):
        """Test an exception that is neither ClientError nor HTTPError."""
        other_exception = ValueError('Some other exception')
        self.assertFalse(is_retryable_exception(e=other_exception))


class TestBackoffOnClientError(unittest.TestCase):
    """Class for testing backoff_on_client_error decorator."""

    def create_mock_client_error(self, code='InternalServerError', message='InternalServerError'):
        """Helper function to create a mock botocore.exceptions.ClientError."""
        error_response = {'Error': {'Code': code, 'Message': message}}
        operation_name = 'TestOperation'
        return botocore.exceptions.ClientError(error_response, operation_name)

    def create_mock_http_error(self, status_code=429, reason='Too Many Requests'):
        """Helper function to create a mock requests.exceptions.HTTPError."""
        mock_response = MagicMock()
        mock_response.status_code = status_code
        mock_response.reason = reason
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(
            f'{status_code} {reason}', response=mock_response
        )
        return requests.exceptions.HTTPError(f'{status_code} {reason}', response=mock_response)


    def test_success_on_first_try(self):
        """Test case where the decorated function succeeds immediately."""
        mock_func = MagicMock(return_value='Success')

        @backoff_on_client_error
        def api_call():
            return mock_func()

        result = api_call()
        self.assertEqual(result, 'Success')
        mock_func.assert_called_once()

    def test_retries_and_succeeds_client_error(self):
        """Test case where the decorated function fails with ClientError initially
            and then succeeds on a retry."""
        call_count = 0
        def side_effect_func():
            nonlocal call_count
            call_count += 1
            if call_count <= 1:
                raise self.create_mock_client_error(code='InternalServerError', message='InternalServerError')
            return 'Success on retry'

        mock_func = MagicMock(side_effect=side_effect_func)

        @backoff_on_client_error
        def api_call():
            return mock_func()

        result = api_call()
        self.assertEqual(result, 'Success on retry')
        self.assertEqual(mock_func.call_count, 2)

    def test_retries_and_succeeds_http_error(self):
        """Test case where the decorated function fails with HTTPError initially
            and then succeeds on a retry."""
        call_count = 0
        def side_effect_func():
            nonlocal call_count
            call_count += 1
            if call_count <= 2:
                raise self.create_mock_http_error(status_code=503, reason="Service Unavailable")
            return 'Success on second retry'

        mock_func = MagicMock(side_effect=side_effect_func)

        @backoff_on_client_error
        def api_call():
            return mock_func()

        result = api_call()
        self.assertEqual(result, 'Success on second retry')
        self.assertEqual(mock_func.call_count, 3)


    def test_retries_and_gives_up_client_error(self):
        """Test case where the decorated function fails with ClientError
            for all retries and eventually gives up."""
        mock_func = MagicMock(side_effect=self.create_mock_client_error(code='InternalServerError', message='InternalServerError'))

        @backoff_on_client_error
        def api_call():
            return mock_func()

        with self.assertRaises(botocore.exceptions.ClientError):
            api_call()

        self.assertEqual(mock_func.call_count, 3)


    def test_retries_and_gives_up_http_error(self):
        """Test case where the decorated function fails with HTTPError
            for all retries and eventually gives up."""
        mock_func = MagicMock(side_effect=self.create_mock_http_error(status_code=504, reason='Gateway Timeout'))

        @backoff_on_client_error
        def api_call():
            return mock_func()

        with self.assertRaises(requests.exceptions.HTTPError):
            api_call()

        self.assertEqual(mock_func.call_count, 3)


    def test_non_retryable_exception_gives_up_immediately(self):
        """Test case where a non-retryable ClientError (e.g., AccessDenied)
            is raised and the decorator gives up immediately."""

        mock_func = MagicMock(side_effect=self.create_mock_client_error(code='AccessDenied', message='Forbidden'))

        @backoff_on_client_error
        def api_call():
            return mock_func()

        with self.assertRaises(botocore.exceptions.ClientError) as client_error:
            api_call()

        self.assertEqual(client_error.exception.response.get('Error', {}).get('Code'), 'AccessDenied')
        self.assertEqual(mock_func.call_count, 1)

    def test_instance_method_is_called_with_self(self):
        """Ensure the decorator works when applied to an instance method."""

        class Dummy:
            def __init__(self):
                self.called = False
                self.value = None

            @backoff_on_client_error
            def do_work(self, x):
                self.called = True
                self.value = x
                return x * 2

        d = Dummy()
        result = d.do_work(5)
        self.assertTrue(d.called)
        self.assertEqual(d.value, 5)
        self.assertEqual(result, 10)

    def test_class_method_is_called_with_cls(self):
        """Ensure the decorator works when applied to a class method."""

        class Dummy:
            called = False
            value = None

            @classmethod
            @backoff_on_client_error
            def do_work(cls, x):
                cls.called = True
                cls.value = x
                return x * 3

        result = Dummy.do_work(7)
        self.assertTrue(Dummy.called)
        self.assertEqual(Dummy.value, 7)
        self.assertEqual(result, 21)

    def test_decorator_on_standalone_function(self):
        """Ensure the decorator works when applied to a standalone method."""
        call_args = {}

        @backoff_on_client_error
        def add(a, b):
            call_args['a'] = a
            call_args['b'] = b
            return a + b

        result = add(3, 4)
        self.assertEqual(result, 7)
        self.assertEqual(call_args['a'], 3)
        self.assertEqual(call_args['b'], 4)