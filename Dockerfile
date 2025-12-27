# Use a slimmed-down Python 3.12 image based on Alpine Linux.
FROM python:3.12-alpine

# Set the working directory inside the container
WORKDIR /usr/src/app

# 1. Install build dependencies: 
#    'build-base' (includes gcc and other compilation tools) is required 
#    by pip to compile necessary Python packages (like MarkupSafe, which Flask uses).
#    These tools will be removed in a later step to keep the final image small.
RUN apk add --no-cache build-base

# 2. Copy the requirements file and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Remove build dependencies:
RUN apk del build-base \
    && rm -rf /root/.cache/pip

# 4. Copy the application code:
#    This includes app.py, posts.json, and the templates/ folder.
COPY app/ .

# 5. Expose the port the Flask app runs on
EXPOSE 5000

# 6. Command to run the application when the container starts
CMD ["python", "app.py"]
