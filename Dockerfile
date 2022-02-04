# syntax=docker/dockerfile:1

FROM --platform=linux/amd64 python:3.10.1-alpine
RUN apk add --update python py-pip
COPY requirements.txt /src/requirements.txt
RUN pip install -r /src/requirements.txt
COPY app.py /src
COPY buzz /src/buzz
CMD python /src/app.py