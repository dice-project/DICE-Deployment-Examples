import sys
import time
import pika
from cassandra.cluster import Cluster

connection = pika.BlockingConnection(pika.ConnectionParameters(sys.argv[1]))
channel = connection.channel()
channel.queue_declare(queue="hello")

cluster = Cluster([sys.argv[2]])
session = cluster.connect()
session.execute(
    """
    create keyspace if not exists demo with
    replication = {'class': 'SimpleStrategy', 'replication_factor': 1}
    """
)
session.set_keyspace("demo")
session.execute(
    """
    create table if not exists randoms
    (received timestamp primary key, content text)
    """
)


def callback(ch, method, properties, body):
    session.execute("insert into randoms (received, content) values (%s, %s)",
                    (int(time.time() * 1000), body))


channel.basic_consume(callback, queue="hello", no_ack=True)
channel.start_consuming()
