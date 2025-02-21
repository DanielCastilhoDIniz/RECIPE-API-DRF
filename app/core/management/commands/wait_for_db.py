"""
Django command to wait for the database to be available
"""
import time

from psycopg2 import OperationalError as Psycopg2OpError

from django.db.utils import OperationalError
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    """ Django command to wait for the database. """
    def handle(self, *args, **options):
        self.stdout.write(' ⏳ ⏳ Waiting for database...')
        max_retries = 30
        retries = 0
        db_up = False
        while db_up is False and retries < max_retries:
            try:
                self.check(databases=['default'])
                db_up = True
            except (Psycopg2OpError, OperationalError):
                self.stdout.write('🟡 Database unavailable, waiting 1 second...')
                time.sleep(1)
                retries += 1
        if retries == max_retries:
            self.stdout.write(self.style.ERROR('❌ Database unavailable after 30 seconds. Exiting...'))
            sys.exit(1)
        self.stdout.write(self.style.SUCCESS('✅ Database available! ✅ Postgres Database Started Successfully'))