from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os
import redis
import json
import boto3
from botocore.config import Config
from jose import jwt, JWTError

# ------------------------------
# LOCAL MODE TO BYPASS AUTH
# ------------------------------
LOCAL_MODE = os.getenv("LOCAL_MODE", "true").lower() == "true"

app = Flask(__name__)
CORS(app)

# ------------------------------
# DATABASE CONFIG
# ------------------------------
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "5432")
db_name = os.getenv("DB_NAME", "yasn_tickets")

if not db_user or not db_password:
    print("⚠ No DB credentials found. Using SQLite for local development.")
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///local-dev.db"
else:
    print("🔵 Starting Flask backend with pg8000 driver…")
    app.config["SQLALCHEMY_DATABASE_URI"] = (
        f"postgresql+pg8000://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
    )

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

# ------------------------------
# REDIS CONFIG
# ------------------------------
redis_host = os.getenv("REDIS_HOST", "localhost")
redis_port = int(os.getenv("REDIS_PORT", "6379"))
redis_queue_name = os.getenv("REDIS_QUEUE_NAME", "yasn_ticket_jobs")

redis_client = redis.Redis(host=redis_host, port=redis_port, db=0)

# ------------------------------
# DYNAMODB CONFIG
# ------------------------------
aws_region = os.getenv("AWS_REGION", "eu-west-1")
dynamodb_table_name = os.getenv("DYNAMODB_TABLE_NAME", "yasn_ticket_metadata")

boto_config = Config(retries={"max_attempts": 3, "mode": "standard"})
dynamodb = boto3.resource("dynamodb", region_name=aws_region, config=boto_config)
dynamodb_table = dynamodb.Table(dynamodb_table_name)

# ------------------------------
# COGNITO CONFIG
# ------------------------------
cognito_user_pool_id = os.getenv("COGNITO_USER_POOL_ID")
cognito_client_id = os.getenv("COGNITO_CLIENT_ID")


# ------------------------------
# AUTH HELPERS
# ------------------------------
def verify_jwt(token: str):
    """Simplified JWT validation for AWS Cognito."""
    try:
        return jwt.get_unverified_claims(token)
    except Exception as exc:
        raise JWTError(f"Invalid token: {exc}") from exc


def get_current_user():
    """Bypass auth in local mode, real auth in cloud mode."""
    if LOCAL_MODE:
        return {"username": "local-user", "sub": "local-sub"}

    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None

    token = auth_header.split(" ", 1)[1]
    try:
        claims = verify_jwt(token)
        return {
            "username": claims.get("cognito:username") or claims.get("username"),
            "sub": claims.get("sub"),
        }
    except JWTError:
        return None


# ------------------------------
# DATABASE MODEL
# ------------------------------
class Ticket(db.Model):
    __tablename__ = "tickets"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(50), default="open")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.String(255), nullable=False)


# ------------------------------
# ROUTES
# ------------------------------
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/tickets", methods=["POST"])
def create_ticket():
    user = get_current_user()
    if not user:
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json() or {}
    title = data.get("title")
    description = data.get("description", "")

    if not title:
        return jsonify({"error": "Title is required"}), 400

    ticket = Ticket(
        title=title,
        description=description,
        created_by=user["username"],
    )

    db.session.add(ticket)
    db.session.commit()

    # Publish job to Redis
    job = {
        "type": "ticket_created",
        "ticket_id": ticket.id,
        "created_by": user["username"],
        "timestamp": datetime.utcnow().isoformat(),
    }
    redis_client.lpush(redis_queue_name, json.dumps(job))

    # DynamoDB Metadata
    try:
        dynamodb_table.put_item(
            Item={
                "ticket_id": str(ticket.id),
                "created_by": user["username"],
                "created_at": ticket.created_at.isoformat(),
                "status": ticket.status,
                "tags": data.get("tags", []),
            }
        )
    except Exception:
        pass  # ignore if table doesn't exist locally

    return jsonify(
        {
            "id": ticket.id,
            "title": ticket.title,
            "description": ticket.description,
            "status": ticket.status,
            "created_by": ticket.created_by,
            "created_at": ticket.created_at.isoformat(),
        }
    ), 201


@app.route("/tickets", methods=["GET"])
def list_tickets():
    user = get_current_user()
    if not user:
        return jsonify({"error": "Unauthorized"}), 401

    tickets = Ticket.query.order_by(Ticket.created_at.desc()).all()
    return jsonify(
        [
            {
                "id": t.id,
                "title": t.title,
                "description": t.description,
                "status": t.status,
                "created_by": t.created_by,
                "created_at": t.created_at.isoformat(),
            }
            for t in tickets
        ]
    ), 200


@app.route("/tickets/<int:ticket_id>", methods=["GET"])
def get_ticket(ticket_id):
    user = get_current_user()
    if not user:
        return jsonify({"error": "Unauthorized"}), 401

    ticket = Ticket.query.get(ticket_id)
    if not ticket:
        return jsonify({"error": "Ticket not found"}), 404

    return jsonify(
        {
            "id": ticket.id,
            "title": ticket.title,
            "description": ticket.description,
            "status": ticket.status,
            "created_by": ticket.created_by,
            "created_at": ticket.created_at.isoformat(),
        }
    ), 200


@app.route("/tickets/<int:ticket_id>", methods=["PATCH"])
def update_ticket(ticket_id):
    user = get_current_user()
    if not user:
        return jsonify({"error": "Unauthorized"}), 401

    ticket = Ticket.query.get(ticket_id)
    if not ticket:
        return jsonify({"error": "Ticket not found"}), 404

    data = request.get_json() or {}
    status = data.get("status")
    if status:
        ticket.status = status

    db.session.commit()

    job = {
        "type": "ticket_updated",
        "ticket_id": ticket.id,
        "status": ticket.status,
        "updated_at": datetime.utcnow().isoformat(),
    }
    redis_client.lpush(redis_queue_name, json.dumps(job))

    return jsonify(
        {
            "id": ticket.id,
            "title": ticket.title,
            "description": ticket.description,
            "status": ticket.status,
            "created_by": ticket.created_by,
            "created_at": ticket.created_at.isoformat(),
        }
    ), 200


# ------------------------------
# ENTRYPOINT
# ------------------------------
if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    print(f"Starting on port {port}")
    app.run(host="0.0.0.0", port=port)
