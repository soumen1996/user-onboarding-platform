# Infrastructure Setup for User Onboarding and Approval Platform

This directory contains the necessary files and configurations for setting up the infrastructure of the User Onboarding and Approval Platform using Docker and Docker Compose.

## Directory Structure

- **docker-compose.yml**: This file defines the services required for the application, including the backend, frontend, and database services. It specifies how these services interact with each other.

- **backend.env.example**: This file provides an example of the environment variables needed for the backend service. It should be copied to `.env` and filled with the appropriate values for local development.

- **frontend.env.example**: This file provides an example of the environment variables needed for the frontend service. Similar to the backend, it should be copied to `.env` and filled with the appropriate values.

- **.env.example**: This file serves as a template for the main environment variables used across the application. It should be copied to `.env` and customized as needed.

- **sql/init.sql**: This file contains SQL scripts for initializing the database schema and seeding initial data. It is executed when the database service starts.

## Getting Started

1. **Clone the Repository**: Start by cloning the repository to your local machine.

2. **Set Up Environment Variables**: Copy the example environment variable files to `.env` and fill in the required values.

   ```bash
   cp backend.env.example backend.env
   cp frontend.env.example frontend.env
   cp .env.example .env
   ```

3. **Build and Run the Services**: Use Docker Compose to build and run the services.

   ```bash
   docker-compose up --build
   ```

4. **Access the Application**: Once the services are running, you can access the frontend and backend through the specified ports in the `docker-compose.yml` file.

## Notes

- Ensure that Docker and Docker Compose are installed on your machine before proceeding with the setup.
- For production deployment, consider additional security measures and optimizations.

This README provides a high-level overview of the infrastructure setup. For more detailed information about the backend and frontend, please refer to their respective README files in the `backend` and `frontend` directories.