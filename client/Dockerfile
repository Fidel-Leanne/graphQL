# Use the Ballerina runtime as the base image

FROM ballerina/ballerina

# Create a directory for your Ballerina client

WORKDIR /usr/src/app

# Copy your Ballerina client source code into the container

COPY /client /usr/src/app

# Set the entry point to run the Ballerina client

CMD ballerina run -e client/src/client.bal
