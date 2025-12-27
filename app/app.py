# Import necessary modules from Flask
from flask import Flask, jsonify, request, render_template
import json
import os

# Initialize the Flask application
app = Flask(__name__, template_folder='templates') # Specify the templates folder location

# Configuration for the JSON "database" and the Secret Token
POSTS_FILE = 'posts.json'
# Get the secret token from the Kubernetes environment variable
SECRET_TOKEN = os.environ.get('FEED_SECRET_TOKEN', 'default-secure-token') 

# --- Helper Functions for JSON DB ---

def load_posts():
    """Reads and loads all posts from the JSON file."""
    # Check if the file exists before reading
    if not os.path.exists(POSTS_FILE):
        return []
    try:
        with open(POSTS_FILE, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        # Handle case where file is empty or invalid JSON
        return []

def save_posts(posts):
    """Writes the current list of posts back to the JSON file."""
    with open(POSTS_FILE, 'w') as f:
        json.dump(posts, f, indent=4)

# --- HTML Template Routes ---

@app.route('/')
def home():
    """Serves the public index.html page (Post display)."""
    # The frontend will call /api/posts via JavaScript
    return render_template('index.html')

@app.route('/feed')
def feed_page():
    """Serves the restricted feed.html page (Post creation form)."""
    return render_template('feed.html')

# --- API Endpoints ---

# Endpoint for public posts (GET /api/posts)
@app.route('/api/posts', methods=['GET'])
def get_posts():
    """Returns all public posts in JSON format."""
    posts = load_posts()
    # The JSON structure ensures easy consumption by the frontend JS
    return jsonify(posts)

# Endpoint for posting new content (POST /api/feed) - Restricted
@app.route('/api/feed', methods=['POST'])
def add_post():
    """Adds a new post, requiring authentication via the Authorization header."""
    
    # 1. Authentication check against the Kubernetes Secret token
    auth_header = request.headers.get('Authorization')
    expected_header = f'Bearer {SECRET_TOKEN}'
    
    if not auth_header or auth_header != expected_header:
        # 401 Unauthorized response if token is missing or invalid
        return jsonify({"error": "Access denied. Invalid token."}), 401
    
    # 2. Data validation and post addition
    try:
        data = request.get_json()
    except Exception:
        return jsonify({"error": "Invalid JSON payload."}), 400

    image_url = data.get('image_url')
    description = data.get('description')
    title = data.get('title', 'Untitled Post') # Optional title field

    if not image_url or not description:
        return jsonify({"error": "Fields 'image_url' and 'description' are mandatory."}), 400

    posts = load_posts()
    # Determine the next ID for the new post
    new_id = (posts[-1]['id'] + 1) if posts else 1
    
    new_post = {
        "id": new_id,
        "title": title,
        "image_url": image_url, 
        "description": description
    }

    posts.append(new_post)
    save_posts(posts)

    # 201 Created response
    return jsonify({"message": "Post added successfully!", "post": new_post}), 201

if __name__ == '__main__':
    # Run the application, host 0.0.0.0 is necessary for Docker/Kubernetes exposure
    app.run(host='0.0.0.0', port=5000)