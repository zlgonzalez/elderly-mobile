# Quickstart: Connecting Google Pixel to MacBook Microservices over Wi-Fi

**Feature**: `004-configurable-api-url`

## 1. Start the Microservices Stack on Your MacBook

In `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices`:

```bash
docker compose up -d
```

Verify the gateway is listening on port `8080`:

```bash
curl http://localhost:8080/api/v1/auth/demo-accounts
```

## 2. Find Your MacBook's Local Wi-Fi IP Address

Run the following command on your MacBook:

```bash
ipconfig getifaddr en0
```

Example output: `192.168.1.50`

## 3. Configure the Mobile App on Your Google Pixel Phone

1. Ensure your Google Pixel phone is connected to the **same Wi-Fi network** as your MacBook.
2. Launch the **Kubo North** mobile app on your phone.
3. Tap the **Settings** (gear) button in the top-right corner of the Welcome / Demo Profile screen (or in the main portal header if already signed in).
4. In the **Server Connection Settings** modal sheet:
   - Enter either your MacBook's IP address (`192.168.1.50`) or the full URL (`http://192.168.1.50:8080/api/v1`).
   - Tap **Test Connection** to verify the phone can reach your MacBook over Wi-Fi (it will normalize the URL to `http://192.168.1.50:8080/api/v1` and verify server response).
   - Tap **Save & Apply**.
5. The modal closes, all microservices immediately route to `http://192.168.1.50:8080/api/v1`, and the setting persists across app restarts.
6. To revert at any time, open **Settings** and tap **Reset to Default**.

## 4. Running Tests

From `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile`:

```bash
flutter test
```
