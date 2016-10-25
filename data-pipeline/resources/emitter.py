import sys
import time
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(sys.argv[1]))
channel = connection.channel()
channel.queue_declare(queue="hello")

while True:
    channel.basic_publish(exchange="", routing_key="hello", body="Hello")
    time.sleep(10)
