from setuptools import setup, find_packages

setup(
    name='lambda_utils',
    version='0.1.0',
    packages=find_packages(),
    install_requires=[
        'backoff',
        'boto3',
        'requests'
    ],
)
