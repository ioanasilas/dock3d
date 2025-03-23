# 2-Docker

## Creating Dockerfile, building, running
I chose to containerize the `Python` app. I created this file:

```Dockerfile
FROM python:3.9-alpine

WORKDIR /app

COPY src/requirements.txt ./

RUN pip install -r requirements.txt

COPY src /app

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "calculator:app"]
```

I included a Python image that is lighter and chose the working directory inside the container. Then we first copy just the requirements and install them. This is better than installing everything at once since `Docker` has layers and this will be cached so it can be reused if we do not change the dependencies but we change the application for example.

Then I added the app itself and expose port 8080 and give the default command to run when we start a container from the `Docker` image. There we need to specify we accept connections from all sources and not just from inside the container, I use the flag and the IP with port for that.

When I built the image, it worked. But when I tried to run it, I encountered an error:
```bash
docker build -t
  File "/app/calculator.py", line 1, in <module>
    from flask import Flask, request, jsonify, render_template_string
ModuleNotFoundError: No module named 'flask'
[2025-03-21 15:56:01 +0000] [7] [INFO] Worker exiting (pid: 7)
[2025-03-21 15:56:01 +0000] [1] [INFO] Shutting down: Master
[2025-03-21 15:56:01 +0000] [1] [INFO] Reason: Worker failed to boot.
```

We could see that we were missing `Flask`, which is true, since it was not mentioned in the dependencies. I looked up the most recent version of Flask, `3.1.0`. I add it, build again and:
```bash
docker build -t test:latest .
3.047 ERROR: Cannot install -r requirements.txt (line 3) and Werkzeug==2.0.3 because these package versions have conflicting dependencies.
3.047 
3.047 The conflict is caused by:
3.047     The user requested Werkzeug==2.0.3
3.047     flask 3.1.0 depends on Werkzeug>=3.1
```

We can see that we get a build error this time, telling us that the `Flask` version is not compatible with the `Werkzeug` one. So I change the `requirements.txt`    file to look like this:

```txt
gunicorn==20.1.0
Werkzeug==3.1
Flask==3.1.0
```

Now we build again and run and this time we get no errors:

```bash
docker build -t test:latest .
[+] Building 6.8s (10/10) FINISHED                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile                                                                                                                          0.0s
 => => transferring dockerfile: 381B                                                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/python:3.9-alpine                                                                                                          0.7s
 => [internal] load .dockerignore                                                                                                                                             0.0s
 => => transferring context: 2B                                                                                                                                               0.0s
 => [internal] load build context                                                                                                                                             0.0s
 => => transferring context: 154B                                                                                                                                             0.0s
 => [1/5] FROM docker.io/library/python:3.9-alpine@sha256:e345f1410de8c8c40a0afac784deabce796a52f26965c41290a710d4fb47fabe                                                    0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                 0.0s
 => [3/5] COPY src/requirements.txt ./                                                                                                                                        0.1s
 => [4/5] RUN pip install -r requirements.txt                                                                                                                                 4.8s
 => [5/5] COPY src /app                                                                                                                                                       0.1s 
 => exporting to image                                                                                                                                                        1.0s 
 => => exporting layers                                                                                                                                                       0.9s 
 => => writing image sha256:653d5c2e2d58b05d328b4b4868912c4fdc4cbd31ac01af68e4c208b2b9d76818                                                                                  0.0s 
 => => naming to docker.io/library/test:latest                                                                                                                                0.0s 
docker run test:latest 
[2025-03-21 15:59:41 +0000] [1] [INFO] Starting gunicorn 20.1.0
[2025-03-21 15:59:41 +0000] [1] [INFO] Listening at: http://0.0.0.0:8080 (1)
[2025-03-21 15:59:41 +0000] [1] [INFO] Using worker: sync
[2025-03-21 15:59:41 +0000] [7] [INFO] Booting worker with pid: 7
[2025-03-21 16:05:48 +0000] [1] [INFO] Handling signal: winch
```

Issue faced: when I tried to `curl` the app, I got this:
```bash
curl http://localhost:8080
curl: (7) Failed to connect to localhost port 8080 after 0 ms: Could not connect to server
```

Then realized that `localhost` on my machine does not refer to `localhost` inside the container itself and we need port mapping for this, so if we run again:

```
docker run -p 8080:8080 test:latest
```

and we curl, we get:
```html
curl http://localhost:8080

<!DOCTYPE html>
<html>
<head>
    <title>Calculator API</title>
    <style>
        body { font-family: Arial; max-width: 800px; margin: 0 auto; padding: 20px; }
        .result { margin: 20px 0; padding: 10px; background: #f0f0f0; }
        button { padding: 5px 10px; }
        input { margin: 5px; padding: 5px; }
    </style>
</head>
<body>
    <h1>Calculator API</h1>
    <div>
        <h3>Add or Multiply Numbers</h3>
        <input type="text" id="numbers" placeholder="Enter numbers (comma-separated)">
        <select id="operation">
            <option value="add">Add</option>
            <option value="multiply">Multiply</option>
        </select>
        <button onclick="calculate()">Calculate</button>
    </div>
    <div class="result" id="result"></div>

    <script>
        async function calculate() {
            const numbers = document.getElementById('numbers').value.split(',').map(Number);
            const operation = document.getElementById('operation').value;
            
            const response = await fetch('/calculate', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({operation, numbers})
            });
            
            const data = await response.json();
            document.getElementById('result').innerText = 
                data.result !== undefined ? `Result: ${data.result}` : `Error: ${data.error}`;
        }
    </script>
</body>
</html>
```

And we can access it from our browser through `http://localhost:8080/`.

## Docker stop signal + env variables

### Stop signal
To have the app catch the container's stop signal and do a clean shutdown, I added this signal handler in the application code:

```python
def handle_shutdown(signal, frame):
    print("Gracefully shutting down")
    sys.exit(0)

# Docker would send SIGTERM signal
signal.signal(signal.SIGTERM, handle_shutdown)
```

So that when `Docker` stops, we handle it ourselves instead of having `Gunicorn` handle it.

If we run and then from another terminal we do
```bash
docker stop <container-name>
```

We can see that now our function handles the `SIGTERM`:

```bash
malina@hoststuff:~/tremend-task$ docker run -p 8080:8080 --env SECRET=some-secret test:latest
...
Gracefully shutting down
[2025-03-22 13:13:22 +0000] [1] [INFO] Shutting down: Master
```

### Env variables
Regarding the environmental variables, we should not hardcode them in the `Dockerfile` or application code. We can use this command to pass them:
```bash
docker run -p 8080:8080 --env  SECRET=some-secret test:latest
```

In the application code, we can then get the variable doing this:
```python
import os

SECRET = os.getenv("SECRET")
```
Then we rename the image and after logging in, we push it to `Dockerhub`:=
```bash
docker push zwx13/calculator-app:final
```

## Automation

For the automation part, I went to the `GitHub` repo > Actions > Docker Image, then modified the default file provided to this:

```yaml
name: Docker Image CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:

  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4
    - name: Build the Docker image
      run: docker build . -t zwx13/calculator-app:${{ github.sha }}
    - name: Log in to Docker Hub
      run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
    - name: Push image
      run: docker push zwx13/calculator-app:${{ github.sha }}
```

Then did Settings > Secrets and variables > Actions > New repository secret and added the 2 secrets.

Then, encountered an error:
```bash
Run docker build . -t zwx13/calculator-app:188f1890bd1f7773df2d13d3a42f2d5338a5153e
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 2B done
#1 DONE 0.0s
ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
Error: Process completed with exit code 1.
```

Since the Dockerfile is not in `root`, but in a subfolder, so I modified this part:
```yaml
run: docker build 2-app -f 2-app/Dockerfile -t zwx13/calculator-app:${{ github.sha }}
```

Then the workflow run was failing since I was not using an access token, so I generated one and updated the corresponding secret (DOCKER_PASSWORD) and then logging in worked and so did the whole workflow.
