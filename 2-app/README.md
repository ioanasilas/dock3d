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

We include a Python image that is lighter and choose the working directory inside the container. Then we first copy just the requirements and install them. This is better than installing everything at once since `Docker` has layers and this will be cached so it can be reused if we do not change the dependencies but we change the application for example.

Then we add the app itself and expose port 8080 and give the default command to run when we start a container from the `Docker` image. There we need to specify we accept connections from all sources and not just from inside the container, we use the flag and the IP with port for that.

When I built the image, it worked. But when I tried to run it, I encountered an error:
```bash
alina@hoststuff:~/Documents/Internship-Resources-2025/2-app$ docker build -t test:latest .                                                                                        
[+] Building 1.2s (10/10) FINISHED                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile                                                                                                                          0.0s
 => => transferring dockerfile: 381B                                                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/python:3.9-alpine                                                                                                          1.0s
 => [internal] load .dockerignore                                                                                                                                             0.0s
 => => transferring context: 2B                                                                                                                                               0.0s
 => [1/5] FROM docker.io/library/python:3.9-alpine@sha256:e345f1410de8c8c40a0afac784deabce796a52f26965c41290a710d4fb47fabe                                                    0.0s
 => [internal] load build context                                                                                                                                             0.0s
 => => transferring context: 101B                                                                                                                                             0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                 0.0s
 => CACHED [3/5] COPY src/requirements.txt ./                                                                                                                                 0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                                                                          0.0s
 => CACHED [5/5] COPY src /app                                                                                                                                                0.0s
 => exporting to image                                                                                                                                                        0.0s
 => => exporting layers                                                                                                                                                       0.0s
 => => writing image sha256:cfde1c7554fc0398486db78c8de55111f042eee0b048db07902f240926151a04                                                                                  0.0s
 => => naming to docker.io/library/test:latest                                                                                                                                0.0s
malina@hoststuff:~/Documents/Internship-Resources-2025/2-app$ docker run test:latest 
[2025-03-21 15:56:01 +0000] [1] [INFO] Starting gunicorn 20.1.0
[2025-03-21 15:56:01 +0000] [1] [INFO] Listening at: http://0.0.0.0:8080 (1)
[2025-03-21 15:56:01 +0000] [1] [INFO] Using worker: sync
[2025-03-21 15:56:01 +0000] [7] [INFO] Booting worker with pid: 7
[2025-03-21 15:56:01 +0000] [7] [ERROR] Exception in worker process
Traceback (most recent call last):
  File "/usr/local/lib/python3.9/site-packages/gunicorn/arbiter.py", line 589, in spawn_worker
    worker.init_process()
  File "/usr/local/lib/python3.9/site-packages/gunicorn/workers/base.py", line 134, in init_process
    self.load_wsgi()
  File "/usr/local/lib/python3.9/site-packages/gunicorn/workers/base.py", line 146, in load_wsgi
    self.wsgi = self.app.wsgi()
  File "/usr/local/lib/python3.9/site-packages/gunicorn/app/base.py", line 67, in wsgi
    self.callable = self.load()
  File "/usr/local/lib/python3.9/site-packages/gunicorn/app/wsgiapp.py", line 58, in load
    return self.load_wsgiapp()
  File "/usr/local/lib/python3.9/site-packages/gunicorn/app/wsgiapp.py", line 48, in load_wsgiapp
    return util.import_app(self.app_uri)
  File "/usr/local/lib/python3.9/site-packages/gunicorn/util.py", line 359, in import_app
    mod = importlib.import_module(module)
  File "/usr/local/lib/python3.9/importlib/__init__.py", line 127, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
  File "<frozen importlib._bootstrap>", line 1030, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1007, in _find_and_load
  File "<frozen importlib._bootstrap>", line 986, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 680, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 850, in exec_module
  File "<frozen importlib._bootstrap>", line 228, in _call_with_frames_removed
  File "/app/calculator.py", line 1, in <module>
    from flask import Flask, request, jsonify, render_template_string
ModuleNotFoundError: No module named 'flask'
[2025-03-21 15:56:01 +0000] [7] [INFO] Worker exiting (pid: 7)
[2025-03-21 15:56:01 +0000] [1] [INFO] Shutting down: Master
[2025-03-21 15:56:01 +0000] [1] [INFO] Reason: Worker failed to boot.
```

We could see that we were missing `Flask`, which is true, since it was not mentioned in the dependencies. I look up the most recent version of Flask, `3.1.0`. I add it, build again and:
```bash
malina@hoststuff:~/Documents/Internship-Resources-2025/2-app$ docker build -t test:latest .
[+] Building 4.1s (8/9)                                                                                                                                             docker:default
 => [internal] load build definition from Dockerfile                                                                                                                          0.0s
 => => transferring dockerfile: 381B                                                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/python:3.9-alpine                                                                                                          0.5s
 => [internal] load .dockerignore                                                                                                                                             0.0s
 => => transferring context: 2B                                                                                                                                               0.0s
 => [internal] load build context                                                                                                                                             0.0s
 => => transferring context: 156B                                                                                                                                             0.0s
 => [1/5] FROM docker.io/library/python:3.9-alpine@sha256:e345f1410de8c8c40a0afac784deabce796a52f26965c41290a710d4fb47fabe                                                    0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                 0.0s
 => [3/5] COPY src/requirements.txt ./                                                                                                                                        0.1s
 => ERROR [4/5] RUN pip install -r requirements.txt                                                                                                                           3.4s
------                                                                                                                                                                             
 > [4/5] RUN pip install -r requirements.txt:                                                                                                                                      
2.312 Collecting gunicorn==20.1.0                                                                                                                                                  
2.451   Downloading gunicorn-20.1.0-py3-none-any.whl (79 kB)                                                                                                                       
2.514      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 79.5/79.5 kB 1.2 MB/s eta 0:00:00                                                                                              
2.583 Collecting Werkzeug==2.0.3                                                                                                                                                   
2.608   Downloading Werkzeug-2.0.3-py3-none-any.whl (289 kB)
2.655      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 289.2/289.2 kB 6.1 MB/s eta 0:00:00
2.705 Collecting Flask==3.1.0
2.728   Downloading flask-3.1.0-py3-none-any.whl (102 kB)
2.746      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 103.0/103.0 kB 5.8 MB/s eta 0:00:00
2.751 Requirement already satisfied: setuptools>=3.0 in /usr/local/lib/python3.9/site-packages (from gunicorn==20.1.0->-r requirements.txt (line 1)) (58.1.0)
2.798 Collecting blinker>=1.9
2.821   Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
2.876 Collecting click>=8.1.3
2.899   Downloading click-8.1.8-py3-none-any.whl (98 kB)
2.916      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 98.2/98.2 kB 6.1 MB/s eta 0:00:00
3.010 Collecting importlib-metadata>=3.6
3.033   Downloading importlib_metadata-8.6.1-py3-none-any.whl (26 kB)
3.046 INFO: pip is looking at multiple versions of werkzeug to determine which version is compatible with other requirements. This could take a while.
3.046 INFO: pip is looking at multiple versions of <Python from Requires-Python> to determine which version is compatible with other requirements. This could take a while.
3.047 INFO: pip is looking at multiple versions of gunicorn to determine which version is compatible with other requirements. This could take a while.
3.047 ERROR: Cannot install -r requirements.txt (line 3) and Werkzeug==2.0.3 because these package versions have conflicting dependencies.
3.047 
3.047 The conflict is caused by:
3.047     The user requested Werkzeug==2.0.3
3.047     flask 3.1.0 depends on Werkzeug>=3.1
3.047 
3.047 To fix this you could try to:
3.047 1. loosen the range of package versions you've specified
3.047 2. remove package versions to allow pip attempt to solve the dependency conflict
3.047 
3.048 ERROR: ResolutionImpossible: for help visit https://pip.pypa.io/en/latest/topics/dependency-resolution/#dealing-with-dependency-conflicts
3.232 
3.232 [notice] A new release of pip is available: 23.0.1 -> 25.0.1
3.232 [notice] To update, run: pip install --upgrade pip
------
Dockerfile:9
--------------------
   7 |     COPY src/requirements.txt ./
   8 |     
   9 | >>> RUN pip install -r requirements.txt
  10 |     
  11 |     COPY src /app
--------------------
ERROR: failed to solve: process "/bin/sh -c pip install -r requirements.txt" did not complete successfully: exit code: 1
```

We can see that we get a build error this time, telling us that the `Flask` version is not compatible with the `Werkzeug` one. So I change the `requirements.txt`    file to look like this:

```txt
gunicorn==20.1.0
Werkzeug==3.1
Flask==3.1.0
```

Now we build again and run and this time we get no errors:

```bash
malina@hoststuff:~/Documents/Internship-Resources-2025/2-app$ docker build -t test:latest .
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
malina@hoststuff:~/Documents/Internship-Resources-2025/2-app$ docker run test:latest 
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
```bash
malina@hoststuff:~/Documents/Internship-Resources-2025/2-app/src$ curl http://localhost:8080

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

To have the app catch the container's stop signal and do a clean shutdown, I added this signal handler in the application code:

```python
def handle_shutdown(signal, frame):
    print("Gracefully shutting down")
    sys.exit(0)

# Docker would send SIGTERM signal
signal.signal(signal.SIGTERM, handle_shutdown)
```

So that when `Docker` stops, we handle it ourselves instead of having `Gunicorn` handle it.

Regarding the environmental variables, we should not hardcode them in the `Dockerfile` or application code. We can use this command to pass them:
```bash
docker run -p 8080:8080 --env  SECRET=some-secret test:latest
```

In the application code, we can then get the variable doing this:
```python
import os

SECRET_KEY = os.getenv("SECRET_KEY")
```
Then we rename the image and after logging in, we push it to `Dockerhub`:
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

Then the workflow run was failing since I was not using an access token, so I generated one and updated the corresponding secret and then it worked.