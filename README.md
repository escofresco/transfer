## Spotify API Configuration

A template file is provided at `amtransfer/Config/Secrets.example.plist`.
Copy it to `amtransfer/Config/Secrets.plist` and update the placeholders
with your own Spotify credentials. The app expects this `Secrets.plist`
to be bundled in the app at build time. Provide values for the following keys:

- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_REDIRECT_URI`

This file is included in the app bundle and the credentials are read at runtime using `Bundle.main.object(forInfoDictionaryKey:)`.
