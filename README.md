# map_shopper

A Location-aware Shopping List App with Shop Recommendation Notifications

## Getting Started

- Windows User
    1. Install [Flutter](https://docs.flutter.dev/get-started/install/windows) 2.2.3.
    2. [Set up Android Studio](https://docs.flutter.dev/get-started/editor).
        - If Flutter cannot find installed Android Studio, you can run the command.
          ```
          flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
          ```
    4. Copy `assets/config.json`.
    5. Add `MAPS_API_KEY= <key>` to `android/local.properties`.
    6. Run the Flutter Project in Android Studio with additional running args:
       ```
       # Android
       --no-sound-null-safety
       # web
       --no-sound-null-safety --web-renderer html
       ```
- How to deploy
    1. Install the Firebase CLI.
    2. Set up a project directory using `firebase init`. (See details
       in [Johannes's video](https://www.youtube.com/watch?v=xJo7Mqse960).)
    3. Build the Flutter web app.
       ```
       flutter build web --web-renderer html --release --no-sound-null-safety
       ```
    4. Deploy the web app.
       ```
       firebase deploy --only hosting
       ```