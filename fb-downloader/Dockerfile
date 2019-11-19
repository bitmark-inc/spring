FROM ubuntu:18.04

# Install Node.js
RUN apt-get update
RUN apt-get install --yes curl
RUN curl --silent --location https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install --yes nodejs
RUN apt-get install --yes build-essential
RUN apt-get install --yes default-jre
RUN apt-get install --yes chromium-browser

# Bundle app source
# Trouble with COPY http://stackoverflow.com/a/30405787/2926832
COPY . /src

# Install app dependencies
RUN cd /src; npm install
RUN mkdir /data

ENV CHROME_PATH=/usr/bin/chromium-browser
ENV DATA_DIR=/data

# Binds to port 8080
EXPOSE  8080

WORKDIR /src
ENTRYPOINT [ "node", "server.js" ]