# Use the Ballerina runtime as the base image
FROM ballerina/ballerina

# Create a directory for your Ballerina service
WORKDIR /usr/src/app

# Copy your Ballerina service source code into the container
COPY /server /usr/src/app

# Expose the Ballerina service's port
EXPOSE 8080

# Set the entry point to run the Ballerina service
CMD bal run -e /server /usr/src/app/service.bal