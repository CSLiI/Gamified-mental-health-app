# Gunicorn configuration for Render deployment
# This file is automatically detected by Gunicorn

import multiprocessing

# Worker settings
workers = 1  # Keep single worker for Render free tier
worker_class = "uvicorn.workers.UvicornWorker"

# Timeout settings (critical for cold DB connections)
timeout = 120          # Increased from default 30s to handle slow Supabase connections
graceful_timeout = 60  # Time to finish requests during graceful shutdown

# Connection settings
keepalive = 5          # Seconds to wait for requests on Keep-Alive connection

# Binding
bind = "0.0.0.0:10000"

# Logging
accesslog = "-"        # Log to stdout
errorlog = "-"         # Log to stdout
loglevel = "info"

# Preload app for faster worker spawns (be careful with this in dev)
preload_app = False    # Set to True if you want to load app before forking workers
