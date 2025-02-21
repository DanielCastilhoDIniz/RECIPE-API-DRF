"""
Tests for models.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model


class ModelTests(TestCase):
    """Test models."""

    def test_create_user_with_email_successful(self):
        """Test creating a user with an email is successful."""
        email = 'test@example.com'
        password = 'testpass123'
        user = get_user_model().objects.create_user(
            email=email,
            password=password,
        )
        self.assertEqual(user.email, email, f"Email {email} não foi salvo corretamente.")
        self.assertTrue(user.check_password(password),
                        "A senha não foi verificada corretamente.")

    def test_new_user_email_normalized(self):
        """Test email is normalized for new users."""
        sample_emails = [
            ['test01@EXAMPLE.com', 'test01@example.com'],
            ['Test02@Example.com', 'test02@example.com'],
            ['TEST03@EXAMPLE.COM', 'test03@example.com'],
            ['Test04@Example.COM', 'test04@example.com'],
            ['TEST05@eXaMpLe.CoM', 'test05@example.com'],
            ['TeSt06@ExAmPlE.cOm', 'test06@example.com'],
            ['test07@EXAMPLE.COM', 'test07@example.com'],
            ['TeSt08@example.COM', 'test08@example.com'],
        ]
        for email, excepted in sample_emails:
            # Creates a user using the unnormalized email
            user = get_user_model().objects.create_user(email, 'sample123')
            # Checks if the user's email was correctly normalized
            self.assertEqual(user.email, excepted)

    def test_new_user_without_email_raises_error(self):
        """Test that creating a user without an email raises a ValueError."""
        with self.assertRaises(ValueError):
            get_user_model().objects.create_user('', 'test123')

    def test_create_superuser(self):
        """Test creating a superuser"""
        user = get_user_model().objects.create_superuser(
            'test@example.com',
            'test123',
        )

        self.assertTrue(user.is_superuser)
        self.assertTrue(user.is_staff)
