"""Settings used exclusively by the automated Django test suite."""

from .settings import *  # noqa: F403


# Tests must not require database-administration privileges from the runtime
# PostgreSQL role. SQLite provides an isolated disposable database while the
# application itself continues to use PostgreSQL through core.settings.
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]

EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
