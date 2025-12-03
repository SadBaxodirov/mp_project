# Sayidabdullaxon – Flutter Project Structure Documentation

## core/api

### **api_client**
- Provides reusable `GET`, `POST`, `PUT`, and `DELETE` methods.
- Automatically attaches authentication headers (JWT access token).
- Simplifies API calls for other developers.

### **api_constants**
- Stores backend base URLs and endpoints.
- Works similarly to an environment configuration file (`.env`).

### **Feature-specific APIs**
- Contains API handlers for:
  - `test`
  - `question`
  - `option`
  - `user`
- Each uses `api_client` internally.
- Example: `getTests()`, `getUser()`, `getQuestions(testId)`.

### **token_storage**
- Wrapper around Flutter Secure Storage.
- Stores and retrieves JWT access & refresh tokens.

---

## core/models

### **Model Definitions**
- All data models used across the app.
- Each model includes:
  - `fromJson` — converts backend JSON response into Dart objects.
  - `toJson` — converts Dart objects back to JSON for API requests.

### **Current Models**
- `User`
- `Test`
- `Question`
- `QuestionOption`
- `UserTest`

These models reflect backend structure and ensure type safety and strong integration between Flutter and the Django REST API.

---

## Summary
This architecture ensures:
- Secure token handling  
- Reusable, maintainable API logic  
- Strong data modeling aligned with backend

