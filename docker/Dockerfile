FROM python:3.10-slim-buster

WORKDIR /usr/local/bin

# Install required Python packages
RUN python3 -m pip install -U openpyxl pandas

# Copy the Python script into the container
COPY get_score.py .

# Ensure the script has the correct shebang and is executable
RUN chmod +x get_score.py

