Initializing a Django project
-----------------------------

1. Create Project Folder
    mkdir django_todo_app
    cd django_todo_app

2. Create Virtual Environment 
    Run Command: python3 -m venv venv

    In Python projects we isolate dependencies.
    Equivalent to Bundler and Gemfile of rails but environment based.

    In Rails, each project can have its own gem versions because of Gemfile, Gemfile.lock and bundle install.

    Python does not have this isolation by default.
    If you run:
      pip install django
    It installs globally on your machine.
    That creates problems.

    So Python created Virtual Environments. Virtual Environment isolates dependencies per project.
    Virtual Environment = Project-specific dependencies installation
  
      +-----------------------------------------+
      | Rails World       | Python World        |
      |-------------------|---------------------|
      | Gemfile           | requirements.txt    |
      | bundle install    | pip install         |
      | Bundler isolation | Virtual Environment |
      | bundle exec rails | activated venv      |
      +-----------------------------------------+

  🔸What the command "python3 -m venv venv" Actually Does?
    This creates a folder:
      project/
        venv/
            bin/
            lib/
            include/
            pyvenv.cfg

    Inside this folder Python creates:
      its own python executable
      its own pip
      its own packages

    So dependencies install inside this folder, not globally.
    The command "python3 -m venv venv" looks confusing because the word venv appears twice, but they mean two different things.

    ➤First venv → Python module name

      The command:
        python3 -m venv

      Here:
          -m means run a Python module as a script
          venv is the standard Python module used to create virtual environments
      So this part means: “Run the built-in Python module called venv.

      Exampels:
        python3 -m http.server
        python3 -m pip install django
        python3 -m venv myenv

    ➤Second venv → Folder name
      The last argument is simply the directory name where the virtual environment will be created.

      python3 -m venv venv
      It means:
        Use the venv module to create a virtual environment inside a folder called venv.
        After running, it will create:
          project/
            venv/
                bin/
                lib/
                pyvenv.cfg
              
      You can name it anything,for example: python3 -m venv myenv

3. Activate virtual Environment:
    Run Command: source venv/bin/activate

    This tells your shell: "Use Python from the venv folder, not the system Python."
    Your prompt changes to something like: (venv) laptop11@laptop11:~/todo_app$
    
    Now when you run: pip install django
    it installs inside "venv/lib/python3.x/site-packages/" instead of system Python.

    So, Real Dev Workflow
      Every time you open the project:
        cd todo_app
        source venv/bin/activate

      Now your environment is isolated.

4. Install dependencies like Django
    Run command: pip install django

    You can check the Django version: django-admin --version

5. Save dependencies
    Run the command:
      pip freeze > requirements.txt

    This generates something like below inside requirements.txt:
      Django==5.0.2
      psycopg2==2.9.9
      celery==5.3.6

    Then another developer just runs:
      pip install -r requirements.txt
    Equivalent to bundle install in rails

6. Create Django Project
    Run the command: django-admin startproject config .
    Note: The dot i.e (.) means create project in current directory.

    It will create:
      MyProject/
        manage.py
        config/
            __init__.py
            settings.py
            urls.py
            asgi.py
            wsgi.py

    This command is equivalent to "rails new my_app"

      +----------------------------------------------------------------------+
      |     File      |                 Purpose                              |
      |---------------|------------------------------------------------------|
      | settings.py   | Project configuration (database, apps, middleware)   |
      | urls.py       | Global URL routing                                   |
      | asgi.py       | ASGI entry point (async servers like Daphne/Uvicorn) |
      | wsgi.py       | WSGI entry point (Gunicorn, uWSGI)                   |
      +----------------------------------------------------------------------+

    🔸What is django-admin ?
      django-admin is a CLI utility provided by Django.
      It contains commands for: creating projects, running migrations, starting apps, running the server, creating superusers etc

      Example commands: 
        django-admin startproject
        django-admin startapp
        django-admin check
        django-admin shell

    🔸What is startproject?
      startproject is a subcommand that creates the basic Django project structure.
      Equivalent Rails concept "rails new"
      It generates: configuration files, project settings and entry points

    🔸What is config ?
      This is simply the Django project name. Django will create a Python package with this name that holds the project′s configuration.

      If we do not use dot i.e (.), then it will create a extra folder called config
      So, when we run: django-admin startproject config

          MyProject/  
            config/        -> just a directory created by Django, if we use dot, then this extra folder will not be created.
              manage.py
              config/      -> python package containing settings
                  __init__.py
                  settings.py
                  urls.py
                  asgi.py
                  wsgi.py

    🔸What is manage.py ?
      manage.py is a project-specific command runner.
      You use it to run Django commands inside the context of your project.

      Example:
        python manage.py runserver
        python manage.py migrate
        python manage.py createsuperuser
        python manage.py startapp users
        Rails Equivalent

      Think of manage.py like: bin/rails
        Example Rails commands:
          bin/rails server
          bin/rails db:migrate
          bin/rails console
          bin/rails generate model

        Equivalent Django commands:
          python manage.py runserver
          python manage.py migrate
          python manage.py shell
          python manage.py startapp

    🔸Why not use django-admin for everything?
      You can run many commands with django-admin.
      Example: django-admin migrate

      But it does not know which project settings to use.

      manage.py automatically loads "config/settings.py"
      So it knows:
        database
        installed apps
        middleware
        environment config

    🔸What python manage.py runserver does?
      Command: python manage.py runserver
      
      This command will:
        loads Django settings
        loads installed apps
        connects to database
        starts a development web server

      Django startup sequence roughly:
        1.Load settings.py
        2.Read INSTALLED_APPS
        3.Import each app′s AppConfig  (UsersConfig/PaymentsConfig etc)
        4.Initialize the apps
        5.Load models
        6.Start server

      Default server:
        http://127.0.0.1:8000

      This is Rails equivalent to: rails server

7. Django vs Rails Command Mapping

    +---------------------------------------------------+
    |        Rails         |          Django            |
    |----------------------|----------------------------|
    | rails new            | django-admin startproject  |
    | rails server         | python manage.py runserver |
    | rails db:migrate     | python manage.py migrate   |
    | rails console        | python manage.py shell     |
    | rails generate model | python manage.py startapp  |
    | bin/rails            | manage.py                  |
    +---------------------------------------------------+

8. Note
    Always use:
        python -m pip install
    instead of
        pip install

    This becomes important when working with multiple Python versions, similar to rbenv/rvm issues in Ruby.

9. Create App
   Example Command: python manage.py startapp users
   This will creates a modular component inside the project.
   This will generates structure like:
      users/
        __init__.py
        admin.py
        apps.py  -> it is equivalent to config/application.rb or config/initializers/ in rails
        models.py
        tests.py
        urls.py
        views.py
        migrations/

  Note: 
    users/apps.py -> This file exists to define AppConfig, which Django uses to configure and initialize the app during project startup. Sample code inside users/apps.py:
      class UsersConfig(AppConfig):
        name = "users"

        def ready(self):
            import users.signals

    Practical Use Cases for apps.py
      1. Register signals (Signals are just like modal callbacks in rails - before_create/after_save etc).
         You often load signals in apps.py

            class UsersConfig(AppConfig):
              name = "users"

              def ready(self):
                  import users.signals

         This ensures signals are loaded when Django starts.

      2. Custom startup logic - You can run the Custom code when the app initializes.
            def ready(self):
              print("Users app initialized")

      3. App metadata - You can customize app name
            class UsersConfig(AppConfig):
              name = "users"
              verbose_name = "User Management"

          Used in Django Admin UI.

10. Activate App
    Creating an app is not enough. You must register it in config/settings.py
    Example:  
        INSTALLED_APPS = [
            "django.contrib.admin",
            "django.contrib.auth",
            "users",  -> Django automatically detects the AppConfig in apps.py
        ]
    
    Now Django loads that app.