# Otter Drift Documentation

Welcome to the Otter Drift documentation. This directory contains comprehensive documentation for developers, contributors, and users.

## Documentation Structure

### API Documentation

Generate API documentation using dartdoc:

```bash
dart doc
```

The generated documentation will be available in `docs/api/`.

### Guides

- **[Deployment Guide](deployment.md)** - Step-by-step instructions for deploying to Google Play Store and configuring advertisements

### Code Documentation

All code is documented using dartdoc comments. Key areas:

- **Game Engine** (`lib/game/`) - Core game logic and components
- **Services** (`lib/services/`) - Business logic, API integration, and ad management
- **UI Components** (`lib/screens/`, `lib/widgets/`) - User interface screens and widgets
- **Models** (`lib/models/`) - Data models and structures

## Generating Documentation

### Prerequisites

- Dart SDK installed
- Flutter SDK installed (for Flutter-specific documentation)

### Generate API Docs

```bash
# Generate documentation
dart doc

# Documentation will be generated in docs/api/
```

### View Documentation

Open `docs/api/index.html` in your web browser to view the generated documentation.

## Documentation Standards

This project follows Dart documentation best practices:

- All public APIs are documented with dartdoc comments
- Examples are provided for complex APIs
- See also references link related documentation
- Code examples are tested and working

## Contributing to Documentation

When adding new features:

1. Add dartdoc comments to all public APIs
2. Include usage examples for complex functionality
3. Update relevant guides if needed
4. Regenerate documentation: `dart doc`

## Additional Resources

- [Dart Documentation Guide](https://dart.dev/guides/language/documentation)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Project README](../README.md)



