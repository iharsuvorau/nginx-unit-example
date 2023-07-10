# Nginx Unit sample multi-language deployment of Go and Python applications using the same web app server

This repository demonstrates how to set up Nginx Unit to start and manage Go and Python applications.

## Getting Started

Run it with the following command:

```bash
docker build -t nginx-unit-example .
docker compose up
```

Then, you can access both apps either directly at `:8080` and `:9090`, or through the Nginx Unit proxy at `:9999`. The Go app is available at `http://localhost:9999/go` and the Python app at `http://localhost:9999/python`.

## Nginx Unit Configuration

This configuration starts both applications and proxies requests to them based on the port and URI:

```json
{
    "listeners": {
        "*:9000": {
            "pass": "applications/go"
        },
        "*:8000": {
            "pass": "applications/python"
        },
        "*:8080": {
            "pass": "routes"
        }
    },
    "routes": [
        {
            "match": {
                "uri": [
                    "/go"
                ]
            },
            "action": {
                "pass": "applications/go"
            }
        },
        {
            "match": {
                "uri": [
                    "/python*"
                ]
            },
            "action": {
                "pass": "applications/python"
            }
        }
    ],
    "applications": {
        "go": {
            "type": "external",
            "working_directory": "/apps/go-app",
            "executable": "/apps/go-app/go-app"
        },
        "python": {
            "type": "python",
            "working_directory": "/apps/python-app/",
            "path": "/apps/python-app/",
            "home": ".venv/",
            "module": "starlette_demo.main",
            "callable": "app",
            "protocol": "asgi"
        }
    }
}
```

## Dockerfile

The Dockerfile is based on the official Nginx Unit minimal image and installs the necessary language-specific modules. It then installs the Python environment and app dependencies, and builds the Go app.

```dockerfile
FROM unit:1.30.0-minimal AS unit
# We take a minimal Unit image and install language-specific modules.

# First, we install the required tooling and add Unit's repo.
RUN apt update && apt install -y curl apt-transport-https gnupg2 lsb-release  \
    &&  curl -o /usr/share/keyrings/nginx-keyring.gpg                         \
    https://unit.nginx.org/keys/nginx-keyring.gpg                      \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg]            \
    https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit"    \
    > /etc/apt/sources.list.d/unit.list

# Next, we install the necessary language module packages and perform cleanup.
RUN apt update && apt install -y                                              \
    unit-python3.9 unit-go \
    && apt remove -y apt-transport-https gnupg2 lsb-release              \
    && apt autoremove --purge -y                                              \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list

# Then, we install the Python environment and app dependencies.
RUN apt-get update && apt-get install -y python3-pip python3-dev
COPY python-app /apps/python-app
RUN pip3 install poetry
RUN cd /apps/python-app && poetry install

# Then, we install the Go app dependencies and build the app.
COPY go-app /apps/go-app
WORKDIR /apps/go-app
RUN go get unit.nginx.org/go
RUN go build -o /apps/go-app/go-app

# Copying initial Unit configuration.
RUN chown -R unit:unit /apps
COPY unit.config.json /docker-entrypoint.d/config.json

```