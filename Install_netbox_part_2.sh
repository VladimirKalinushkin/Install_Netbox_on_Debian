#!/bin/bash

    # Python libraries install

    apt update

    apt install -y python3 python3-pip python3-venv python3-dev \
    build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev \
    libssl-dev zlib1g-dev -y

    python3 --version
    
