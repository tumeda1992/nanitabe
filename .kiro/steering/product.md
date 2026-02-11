# Product Overview

**Nanitabe** is a meal planning and dish management application built as a full-stack web application with mobile support.

## Core Features
- **Dish Management**: Create, edit, and organize dishes with evaluations and tags
- **Meal Planning**: Plan meals using registered dishes
- **Calendar Integration**: View meals in calendar format (monthly/weekly views)
- **User Authentication**: JWT-based authentication with Devise
- **Source Tracking**: Track dish sources and relationships

## Application Architecture
The application follows Domain-Driven Design (DDD) principles with a layered architecture:
- **Presentation Layer**: GraphQL API and React frontend
- **Use Case Layer**: Application services (Commands for mutations, Queries for reads)
- **Domain Layer**: Business logic and domain models
- **Infrastructure Layer**: Database and external API connections

## Target Users
Users who want to organize their meal planning, track dishes they've tried, and maintain a personal recipe/dish database with evaluations and sources.