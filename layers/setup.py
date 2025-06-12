from setuptools import setup, find_packages

setup(
    name='lambda_layers',
    version='0.1.0',
    package_dir={'': 'layers'},
    packages=find_packages(where='layers'),
    install_requires=[
        'backoff',
        'boto3',
        'requests'
    ],
)
