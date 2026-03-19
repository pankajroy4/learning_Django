🔸In Django, Management Commands are just like Rake Tasks in rails.

    +---------------------------------------------------+
    |    Rails	          |     Django                  |
    |---------------------------------------------------|
    |  rake task	        |  management command         |
    |  lib/tasks/*.rake	  |  management/commands/*.py   |
    |  rake db:migrate	  |  python manage.py migrate   |
    +---------------------------------------------------+

🔸Rails uses Rake, while Django uses management commands through manage.py

  Example:Rails Rake task
    #lib/tasks/users.rake
    namespace :users do
      desc "Deactivate inactive users"
      task deactivate: :environment do
        User.where("last_login < ?", 1.year.ago).update_all(active: false)
      end
    end

    Running rake task:
      rake users:deactivate

  Django management command
    Directory structure:
      users/
        management/
          commands/
            deactivate_users.py

    #deactivate_users.py
    from django.core.management.base import BaseCommand
    from users.models import User
    from datetime import timedelta
    from django.utils import timezone

    class Command(BaseCommand):
      help = "Deactivate inactive users"

      def handle(self, *args, **kwargs):
        cutoff = timezone.now() - timedelta(days=365)
        User.objects.filter(last_login__lt=cutoff).update(active=False)
        self.stdout.write(self.style.SUCCESS("Users deactivated"))

    Running management command:
      python manage.py deactivate_users

  Management commands are used in cases like:
    data migrations
    cron jobs
    importing CSV
    cleaning database
    sending bulk emails
    running scripts

  Django auto-discovers commands from installed apps.

======================================================================================================
                            Arguments & Options in Management Commands
======================================================================================================

🔸Rails Rake Taks with arguments
  Example 1: Passing Arguments to rake tasks
    task :notify, [:email, :message] => :environment do |t, args|
      email   = args[:email]
      message = args[:message]

      puts "Sending '#{message}' to #{email}"
    end

    Run the task:
      rake my_tasks:notify[user@example.com,Hello]
    To specify the environment, we can do like this:
      RAILS_ENV=production rake my_tasks:notify[user@example.com,Hello]

    NOTE: 
      Arguments are positional, not keyword-based.
      If you skip one, it becomes nil.
      No spaces allowed unless quoted (depends on shell).

  Example 2: Setting default for arguments in rails take task
    task :notify, [:email, :message] => :environment do |t, args|
      args.with_defaults(message: "Default message")

      puts "Sending '#{args[:message]}' to #{args[:email]}"
    end

  Example 3: Using ENV variables to pass arguments (very common in production)
    task :send_email => :environment do
      email = ENV['EMAIL']
      puts "Sending email to #{email}"
    end

    Run the taks:
      EMAIL=user@example.com rake my_tasks:send_email
      #Or
      rake my_tasks:send_email EMAIL=user@example.com

    NOTE:
    This way is often preferred because:
      Works better with shells (no escaping issues)
      Easier for scripts and CI/CD


🔸Django management commands with arguments
  Example 1: Passing Arguments to management command
    # myapp/management/commands/send_email.py

    from django.core.management.base import BaseCommand
    class Command(BaseCommand):
      help = "Send an email"

      def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='User email')
      
      def handle(self, *args, **options):
        email = options['email']
        print(f"Sending email to {email}")

    Run the management command:
        python manage.py send_email user@example.com
    To specify the environment, we can do like this:
      python manage.py send_email user@example.com --settings=project.settings.production

  Example 2: Passing multiple Arguments to management command
    # myapp/management/commands/send_email.py

    from django.core.management.base import BaseCommand
    class Command(BaseCommand):
      help = "Send an email"

      def add_arguments(self, parser):
        parser.add_argument('email', type=str)
        parser.add_argument('message', type=str)
            
      def handle(self, *args, **options):
        email = options['email']
        print(f"Sending email to {email}")

    Run the management command:
      python manage.py send_email user@example.com "Hello there"

  Example 3: Optional (named) arguments
    # myapp/management/commands/send_email.py

    from django.core.management.base import BaseCommand
    class Command(BaseCommand):
      help = "Send an email"

      def add_arguments(self, parser):
        parser.add_argument('--email', type=str, required=True)
        parser.add_argument('--message', type=str, default="Default message")
            
      def handle(self, *args, **options):
        email = options['email']
        print(f"Sending email to {email}")

    Run the management command:
      python manage.py send_email --email=user@example.com --message="Hi"

  Example 4: Flags (booleans)
    # myapp/management/commands/send_email.py

    from django.core.management.base import BaseCommand
    class Command(BaseCommand):
      help = "Send an email"

      def add_arguments(self, parser):
        parser.add_argument('--dry-run', action='store_true')
            
      def handle(self, *args, **options):
        if options['dry_run']:
          print("Dry run mode")

    Run the management command:
      python manage.py send_email --dry-run
      # Or  
      python manage.py send_email

🔸What are *args and **options?        
    def add_arguments(self, parser):
      parser.add_argument('--dry-run', action='store_true')
          
    def handle(self, *args, **options):
      if options['dry_run']:
        print("Dry run mode")

   🔹Here the argument **options is a dictionary of all arguments parsed by add_arguments()
    It contains both:
      positional arguments
      named (--flag) arguments

    When you run:
      python manage.py send_email user@example.com --dry-run

    Then we got option as this:
      options = {
        'email': 'user@example.com',
        'dry_run': True
      }

   🔹Here the argument *args is a tuple of extra positional arguments not defined in add_arguments()
     In most Django commands → it is empty and unused.
     So, typically: 
        args = ()

🔸Why does Django include *args at all?
  It is mostly for:
    backward compatibility
    flexibility (older or dynamic commands)
    But in modern Django, You almost never use *args

    So, If we want then we can also write like this:
      def handle(self, **options):
    But Django’s base class expects *args, so best practice is to keep both.


🔸Exception in management command
  Example:
    from django.core.management.base import BaseCommand, CommandError

    class Command(BaseCommand):
      def handle(self, *args, **options):
        try:
          # your logic
          raise ValueError("Oops")
      
        except Exception as e:    # Here you catch the exception or errors.
          # log/debug if needed
            raise CommandError(f"Failed: {str(e)}")  # Here you raised a clean CLI error.