from django.test import TestCase
from django.urls import reverse


class DashboardViewTests(TestCase):

    def test_dashboard_renders_successfully(self):
        response = self.client.get(reverse("dashboard"))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "HITL")
