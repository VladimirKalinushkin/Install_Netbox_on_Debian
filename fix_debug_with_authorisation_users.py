
from users.models import User, UserConfig
for user in User.objects.all():
    try:
        # Try to access config
        _ = user.config
        print(f"✓ User '{user.username}' has valid config")
    except UserConfig.DoesNotExist:
        # Create a new config if it does not exist
        UserConfig.objects.create(user=user)
        print(f"✗ User '{user.username}' was missing config. Created a new one.")
