FROM python:3.9-alpine

WORKDIR /app

# we utilize Docker layering by first copying the requirements
# and installing them
COPY src/requirements.txt ./

RUN pip install -r requirements.txt

COPY src /app

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "calculator:app"]
