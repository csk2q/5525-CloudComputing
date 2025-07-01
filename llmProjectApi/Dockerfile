FROM python:3.12-alpine

WORKDIR /code

# Install dependiies for llama-cpp-python
# RUN apt update && apt install -y \
RUN apk update && apk add --no-cache g++ git


COPY ./app/requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./app/ /code/app/

WORKDIR /code/app
CMD ["fastapi", "run", "main.py", "--port", "80"]

EXPOSE 80