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
