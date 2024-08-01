FROM python:3.10-slim-buster

WORKDIR /usr/local/bin

RUN python3 -m pip install -U openpyxl pandas 

COPY get_score.py .

RUN chmod +x get_score.py

