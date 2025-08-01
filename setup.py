"""Setup script for Agent-NN."""
from setuptools import setup, find_packages

setup(
    name="agentnn",
    version="1.0.0-beta",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "click>=8.0.0",
        "rich>=10.0.0",
        "requests>=2.25.0",
        "psutil>=5.8.0",
        "numpy>=1.19.0",
        "pandas>=1.2.0",
        "torch>=1.9.0",
        "langchain>=0.1.0",
        "langchain_openai>=0.0.1",
        "langchain_community>=0.0.1"
    ],
    entry_points={
        "console_scripts": [
            "agentnn=sdk.cli.main:app",
        ],
    },
    author="OpenHands",
    author_email="openhands@all-hands.dev",
    description="Command line interface for Agent-NN",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/openhands/smolit-llm-nn",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    python_requires=">=3.8",
)
