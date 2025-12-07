# User Onboarding and Approval Platform - Backend

This directory contains the backend implementation of the User Onboarding and Approval Platform using FastAPI.

## Project Structure

- **app/**: Contains the main application code.
  - **api/**: Contains the API routes and endpoints.
    - **v1/**: Version 1 of the API.
      - **endpoints/**: Contains individual endpoint files for authentication, users, and approvals.
  - **core/**: Contains core configuration and security logic.
  - **models/**: Contains database models.
  - **schemas/**: Contains Pydantic schemas for data validation.
  - **crud/**: Contains CRUD operations for database interactions.
  - **db/**: Contains database setup and session management.
  - **tests/**: Contains unit tests for the application.

- **alembic/**: Contains migration scripts and configuration for database migrations.

- **Dockerfile**: Defines the Docker image for the FastAPI backend.

- **requirements.txt**: Lists the Python dependencies required for the backend.

## Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd user-onboarding-platform/backend
   ```

2. **Create a virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**:
   Copy the `backend.env.example` to `backend.env` and fill in the required values.

5. **Run the application**:
   ```bash
   uvicorn app.main:app --reload
   ```

## Testing

To run the tests, use the following command:
```bash
pytest app/tests
```

## Docker

To build and run the Docker container, use:
```bash
docker-compose up --build
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.