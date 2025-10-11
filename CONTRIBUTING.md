# Contributing to AI Student Assistant 🎓

First off, thank you for considering contributing to AI Student Assistant! It's people like you that make this project such a great learning tool for students worldwide.

## 🚀 Quick Links

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## 📋 Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 🎯 How Can You Contribute?

### 🐛 **Report Bugs**
- Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Check if the bug has already been reported
- Include detailed steps to reproduce

### ✨ **Suggest Features**
- Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Explain the feature and its benefits for students
- Include mockups or examples if possible

### 💻 **Code Contributions**
- Fix bugs or implement new features
- Improve documentation
- Add tests for better coverage
- Optimize performance

### 📚 **Documentation**
- Improve existing documentation
- Add examples and tutorials
- Translate documentation
- Fix typos and formatting

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.24+
- Firebase CLI
- Git
- VS Code or Android Studio (recommended)

### 1. Fork & Clone
```bash
# Fork the repository on GitHub first, then:
git clone https://github.com/YOUR-USERNAME/ai-student-assistant.git
cd ai-student-assistant
```

### 2. Environment Setup
```bash
# Install dependencies
flutter pub get

# Copy environment template
cp .env.template .env

# Add your OpenRouter API keys to .env
# Get free keys from https://openrouter.ai/
```

### 3. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Set up local project (follow prompts)
flutterfire configure
```

### 4. Run the App
```bash
# Web
flutter run -d chrome

# Android (with device/emulator connected)
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

### 5. Run Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 🔄 Pull Request Process

### 1. Create a Branch
```bash
# Create a feature branch from main
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b bugfix/issue-description
```

### 2. Make Your Changes
- Write clean, readable code
- Follow our [style guidelines](#style-guidelines)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes
```bash
# Run tests
flutter test

# Test on different platforms
flutter run -d chrome
flutter run -d android

# Check for analysis issues
flutter analyze
```

### 4. Commit Your Changes
```bash
# Use conventional commit messages
git commit -m "feat: add flashcard difficulty levels"
git commit -m "fix: resolve chat message overflow issue"
git commit -m "docs: update API setup instructions"
```

### 5. Push and Create PR
```bash
git push origin feature/your-feature-name
```
- Go to GitHub and create a Pull Request
- Use our [PR template](.github/pull_request_template.md)
- Link any related issues

### 6. Code Review Process
- Maintainers will review your PR
- Address feedback and make requested changes
- Once approved, your PR will be merged

## 📝 Style Guidelines

### Dart Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Run `flutter analyze` to check for issues

### Commit Messages
We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

feat: add new feature
fix: bug fix
docs: documentation changes
style: formatting, no code change
refactor: code refactoring
test: adding tests
chore: maintenance tasks
```

### Documentation
- Use clear, concise language
- Include code examples where helpful
- Update README.md for new features
- Comment complex code sections

## 🏗️ Project Structure

```
ai_student_assistant/
├── lib/
│   ├── src/
│   │   ├── models/          # Data models
│   │   ├── providers/       # Riverpod providers
│   │   ├── screens/         # UI screens
│   │   ├── services/        # Business logic
│   │   └── widgets/         # Reusable widgets
│   └── main.dart           # App entry point
├── test/                   # Test files
├── assets/                 # Images, fonts, etc.
├── docs/                   # Documentation
└── .github/               # GitHub templates
```

## 🧪 Testing Guidelines

### Types of Tests
1. **Unit Tests**: Test individual functions/classes
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test complete user flows

### Writing Tests
```dart
// Example unit test
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_student_assistant/src/models/flashcard.dart';

void main() {
  group('Flashcard Model', () {
    test('should create flashcard with valid data', () {
      // Arrange
      const question = 'What is Flutter?';
      const answer = 'A UI toolkit by Google';
      
      // Act
      final flashcard = Flashcard(
        question: question,
        answer: answer,
      );
      
      // Assert
      expect(flashcard.question, equals(question));
      expect(flashcard.answer, equals(answer));
    });
  });
}
```

## 🏷️ Issue Labels

We use these labels to organize issues:

- `bug` - Something isn't working
- `enhancement` - New feature or improvement
- `documentation` - Documentation changes
- `good first issue` - Great for newcomers
- `help wanted` - Extra attention needed
- `priority: high` - Important issues
- `priority: low` - Nice to have
- `status: in progress` - Currently being worked on

## 💡 Feature Request Guidelines

When suggesting new features:

1. **Check existing issues** first
2. **Describe the problem** you're trying to solve
3. **Explain your proposed solution**
4. **Consider alternatives** and trade-offs
5. **Think about implementation** complexity

## 🐛 Bug Report Guidelines

When reporting bugs:

1. **Use descriptive title**
2. **Provide steps to reproduce**
3. **Include expected vs actual behavior**
4. **Add screenshots/videos** if helpful
5. **Specify platform/version** details
6. **Include relevant logs** or error messages

## 🎯 Areas We Need Help

- 🧪 **Test Coverage**: More unit and widget tests
- 🌍 **Internationalization**: Multi-language support
- 📱 **Platform Features**: iOS/Android specific implementations
- 🎨 **UI/UX**: Design improvements and accessibility
- 📚 **Documentation**: Tutorials and guides
- 🔍 **Code Review**: Help review pull requests

## ❓ Questions?

- 💬 **GitHub Discussions**: For general questions
- 🐛 **GitHub Issues**: For bug reports and feature requests
- 📧 **Email**: For security concerns or private matters

## 🎉 Recognition

Contributors are recognized in:
- GitHub contributors list
- Release notes for significant contributions
- Special mentions for first-time contributors

Thank you for making AI Student Assistant better for students everywhere! 🎓✨