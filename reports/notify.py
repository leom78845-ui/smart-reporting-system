# reports/notify.py

def send_push_notification(token, title, body):
    """
    Simulates sending a push notification to a single device.
    Firebase is removed in favor of purely offline/local SQLite system.
    """
    if not token:
        return False

    print(f"\n[NOTIFICATION LOG] Token: {token} | Title: {title} | Body: {body}\n")
    return True

