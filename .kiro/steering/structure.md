# Project Structure

## Repository Organization
This is a monorepo containing multiple applications:

```
nanitabe/
├── backend/          # Rails API server
├── frontend/         # Next.js web application  
├── native/           # React Native mobile app
├── infrastructure/   # Terraform configurations
└── docker-compose.yml
```

## Backend Structure (Rails + DDD)
```
backend/
├── app/
│   ├── controllers/           # Presentation layer (GraphQL)
│   ├── graphql/              # GraphQL schema, types, mutations, queries
│   │   ├── mutations/        # GraphQL mutations (Commands)
│   │   ├── queries/          # GraphQL queries (Queries)
│   │   └── types/            # GraphQL type definitions
│   ├── domain/               # Domain-driven design layers
│   │   ├── application/      # Use case layer
│   │   │   ├── command/      # Commands (write operations)
│   │   │   └── finder/       # Queries (read operations)
│   │   └── business/         # Domain layer (business logic)
│   └── models/               # ActiveRecord models (Infrastructure)
├── spec/                     # RSpec tests
├── docs/ai_guideline/        # Development standards
└── temp_prompts/             # AI prompt templates
```

## Frontend Structure (Next.js)
```
frontend/
├── src/
│   ├── app/                  # Next.js App Router pages
│   │   ├── dishes/           # Dish management pages
│   │   ├── calender/         # Calendar views
│   │   ├── login/            # Authentication pages
│   │   └── meal/             # Meal planning pages
│   ├── components/           # Reusable React components
│   │   ├── auth/             # Authentication components
│   │   ├── dish/             # Dish-related components
│   │   ├── meal/             # Meal-related components
│   │   ├── calender/         # Calendar components
│   │   └── common/           # Shared UI components
│   ├── features/             # Feature-specific logic
│   │   ├── auth/             # Authentication logic
│   │   ├── dish/             # Dish management logic
│   │   └── meal/             # Meal planning logic
│   └── lib/                  # Utilities and configurations
│       └── graphql/          # GraphQL client setup
├── spec/                     # Jest tests
└── docs/ai_guideline/        # Development standards
```

## Key Architectural Patterns

### Backend (DDD Layers)
- **Controllers/GraphQL**: Entry points, input validation
- **Application Layer**: Use cases (Commands/Queries), orchestration
- **Domain Layer**: Business logic, domain models
- **Models (ActiveRecord)**: Data persistence, acts as repository

### Frontend (Feature-Based)
- **Pages (app/)**: Route-based components using App Router
- **Components**: Reusable UI components organized by domain
- **Features**: Business logic, API calls, custom hooks
- **Lib**: Shared utilities, GraphQL client configuration

### File Naming Conventions
- **Backend**: snake_case for Ruby files
- **Frontend**: camelCase for directories, PascalCase for React components
- **Tests**: `*_spec.rb` (RSpec), `*.spec.tsx` (Jest)

### Import/Export Patterns
- **Frontend**: Barrel exports from feature directories
- **GraphQL**: Generated types in `src/lib/graphql/generated/`
- **Styling**: SCSS modules with Bootstrap integration

## Configuration Files
- **Backend**: `Gemfile`, `.rubocop.yml`, database configs
- **Frontend**: `package.json`, `next.config.js`, `codegen.yml`
- **Docker**: `docker-compose.yml`, individual Dockerfiles
- **Infrastructure**: Terraform modules in `terraform/`