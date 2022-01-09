import os
import signal
import socket

from flask import Flask
from buzz import generator

app = Flask(__name__)

signal.signal(signal.SIGINT, lambda s, f: os._exit(0))


@app.route("/")
def generate_buzz():
    page = '<html><body><h1>'
    page += f'{generator.generate_buzz()} <br> This is done on {socket.gethostname()}'
    page += '</h1></body></html>'
    return page


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
