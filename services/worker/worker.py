import os
import time
import json
import redis
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

redis_host = os.getenv("REDIS_HOST", "localhost")
redis_port = int(os.getenv("REDIS_PORT", "6379"))
redis_queue_name = os.getenv("REDIS_QUEUE_NAME", "yasn_ticket_jobs")

poll_interval_seconds = int(os.getenv("POLL_INTERVAL_SECONDS", "1"))

redis_client = redis.Redis(host=redis_host, port=redis_port, db=0)


def process_ticket_created(job):
    ticket_id = job.get("ticket_id")
    created_by = job.get("created_by")
    logging.info("Processing ticket_created for ticket %s by %s", ticket_id, created_by)
    # Here you could send email, Slack, or further enrich the ticket


def process_ticket_updated(job):
    ticket_id = job.get("ticket_id")
    status = job.get("status")
    logging.info("Processing ticket_updated for ticket %s new status %s", ticket_id, status)
    # Here you could push audit events into OpenSearch or another sink


def process_job(job_json: str):
    try:
        job = json.loads(job_json)
    except json.JSONDecodeError:
        logging.error("Failed to decode job JSON, %s", job_json)
        return

    job_type = job.get("type")
    if job_type == "ticket_created":
        process_ticket_created(job)
    elif job_type == "ticket_updated":
        process_ticket_updated(job)
    else:
        logging.warning("Unknown job type, %s", job_type)


def main():
    logging.info("Worker started, listening on Redis queue %s", redis_queue_name)
    while True:
        _, job_bytes = redis_client.brpop(redis_queue_name)
        job_json = job_bytes.decode("utf-8")
        logging.info("Received job, %s", job_json)
        process_job(job_json)
        time.sleep(poll_interval_seconds)


if __name__ == "__main__":
    main()
