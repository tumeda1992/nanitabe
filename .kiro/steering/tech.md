# Technology Stack

## Backend (Ruby on Rails)
- **Framework**: Rails 7.1 with Ruby 3.2.2
- **Database**: SQLite3 (development/test), MySQL2 (production)
- **API**: GraphQL with graphql-ruby gem
- **Authentication**: Devise + JWT tokens via graphql_devise
- **Testing**: RSpec with FactoryBot
- **Code Quality**: RuboCop with custom rules

## Frontend (Next.js)
- **Framework**: Next.js 16 with React 19
- **Language**: TypeScript 5.6
- **GraphQL Client**: Apollo Client 3.13
- **Styling**: SASS with Bootstrap 5.2
- **Forms**: React Hook Form with Zod validation
- **Testing**: Jest with Testing Library
- **Code Generation**: GraphQL Code Generator

## Mobile (React Native)
- **Framework**: React Native 0.77
- **Language**: TypeScript 5.0
- **WebView**: react-native-webview for hybrid approach

## Infrastructure
- **Containerization**: Docker with docker-compose
- **Cloud**: AWS (Lambda, S3, CloudFront, API Gateway)
- **Infrastructure as Code**: Terraform

## Common Development Commands

### Backend (Rails)
```bash
# Start development server
docker compose up -d

# Run tests (MUST be in container)
docker compose exec backend bundle exec rspec

# Database operations
docker compose exec backend rails db:create db:migrate
docker compose exec backend rails db:test:prepare

# Console access
docker compose exec backend rails console

# Install dependencies
docker compose exec backend bundle install
```

### Frontend (Next.js)
```bash
# Start development server
docker compose up -d frontend

# Run tests
docker compose exec frontend yarn test

# Generate GraphQL types
docker compose exec frontend yarn codegen

# Linting
docker compose exec frontend yarn lint

# Build for production
docker compose exec frontend yarn build
```

### Mobile (React Native)
```bash
# Install dependencies
npm install

# Start Metro bundler
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android

# Run tests
npm test
```

## Build & Deployment
- **Development**: Docker Compose with hot reload
- **Production**: AWS Lambda (frontend), containerized backend
- **CI/CD**: GitHub Actions with Terraform deployment