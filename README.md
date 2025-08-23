## Spotify API Configuration

The app expects Spotify credentials bundled in `Config/Secrets.plist`.
Provide values for the following keys:

- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_REDIRECT_URI`

This file is included in the app bundle and the credentials are read at runtime using `Bundle.main.object(forInfoDictionaryKey:)`.

Update `Secrets.plist` with your own credentials before building the app.
