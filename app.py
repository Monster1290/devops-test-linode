import os
import signal
import socket
import sys
import threading

from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics
from buzz import generator

app = Flask(__name__)
metrics = PrometheusMetrics(app)

signal.signal(signal.SIGINT, lambda s, f: os._exit(0))


@app.route("/")
def generate_buzz():
    page = '<html><body><h1>'
    page += f'{generator.generate_buzz()} <br> This is done on {socket.gethostname()}'
    page += '</h1></body></html>'
    return page


if __name__ == "__main__":
    if '--build' in sys.argv:
        threading.Timer(5, sys.exit)

    app.run(host='0.0.0.0', port=8080)
