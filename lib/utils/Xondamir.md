# Xondamir Update Summary

------------------------------------------------------------------------

## New Features in Test Provider

### 1. Download Questions and Answers by `test_id`

-   The provider now fetches all questions and answers for a selected
    test.
-   Downloaded data is stored in memory and reused while the app is
    running.
-   Reduces repeated API calls and improves performance.

### 2. Save Downloaded Data During Runtime

-   Once test data is downloaded, it remains available until the program
    exits.
-   This ensures smooth user experience even when navigating between
    screens.

### 3. Send Results and Progress to the Server

-   After a test is completed, results are sent to the server.
-   If a test is unfinished, the provider sends the current progress to
    keep the server state updated.

------------------------------------------------------------------------

## utils folder (Local DB)

### 1. Store Downloaded Tests and Variants

-   Tests and their variants are saved locally in the database.
-   Allows the app to work offline using previously fetched data.

### 2. Store User Answers and Progress

-   Each user answer is saved locally.
-   Test progress (e.g., answered questions, time spent) is stored as
    well.

### 3. Retrieve and Modify Stored Data

-   Utilities allow you to:
    -   Load previously saved test data
    -   Modify stored tests if new data arrives from the server

------------------------------------------------------------------------