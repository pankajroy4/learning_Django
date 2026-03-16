🔸Rails vs Django - Architecture Mapping
  --------------------------------------

  +-------------------------------------------------------------------------------------------+
  |          Rails              |         Django           |        Explanation               |
  |-----------------------------+--------------------------+----------------------------------|
  | routes.rb                   | urls.py                  | URL routing                      |
  | Controller                  | View                     | Django calls controllers "views" |
  | Model (ActiveRecord)        | Model (ORM)              | Similar concept                  |
  | Migration                   | Migration                | Very similar                     |
  | Service Objects             | Services / utils modules | Not built-in but common pattern  |
  | Concerns                    | Mixins                   | Python classes                   |
  | Background Jobs             | Celery / RQ / Django-Q   | Async jobs                       |
  | Devise                      | Django Auth              | Built-in auth system             |
  | ActiveStorage / CarrierWave | Django Storage           | File uploads                     |
  | Rails Console               | Django Shell             | CLI                              |
  +-----------------------------+--------------------------+----------------------------------+

🔸Django Project Structure
  ------------------------

    myproject/
    │   
    ├── venv/
    ├── manage.py
    ├── requirements.txt
    │
    ├── config/
    │   ├── settings.py
    │   ├── urls.py
    │   ├── asgi.py
    │   └── wsgi.py
    │
    ├── users/
    │   ├── __init__.py
    │   ├── admin.py
    │   ├── apps.py   -> it is equivalent to config/application.rb or config/initializers/ in rails
    │   ├── models.py
    │   ├── views.py
    │   ├── migrations/
    │   ├── urls.py
    │   ├── signals.py
    │   ├── serializers.py
    │   ├── services/
    │   │   └── create_users.py
    │   ├── templates/
    │   │   └── users/
    │   │        ├── show.html
    │   │        └── index.html
    │   └── tests.py
    │ 
    ├── payments/
    │   ├── __init__.py
    │   ├── admin.py
    │   ├── apps.py
    │   ├── models.py
    │   ├── views.py
    │   ├── migrations/
    │   ├── urls.py
    │   ├── signals.py
    │   ├── services/
    │   │   └── create_payment.py
    │   │── templates/
    │   │   └── payments/
    │   │        ├── show.html
    │   │        └── index.html
    │   └── tests.py

    Django uses two levels of routing to keep large applications modular.
    In Django, “apps” are modular components inside a project that encapsulate a specific domain or feature. Think of them as self-contained feature modules with their own models, views, routes, templates, and tests.
    An app = one domain / feature module.
    Each app contains everything related to that feature.
    So apps separate business domains.
    Apps are reusable - One big design goal of Django apps: Apps can be reused across projects. You can install a app from one project to another project. Like installing a gem.

    Apps are registered in settings.
    Every Django project has: settings.py
      INSTALLED_APPS = [
          "users",
          "orders",
          "payments",
      ]
    This tells Django which apps exist.
    90% of Django backend jobs use DRF instead of classic Django views( i.e controllers).

🔸Django is Batteries Included 
  ----------------------------

    +------------------------+
    | Feature     | Django   |
    |-------------+----------|
    | Auth        | built-in | -> Django Auth / JWT
    | Admin Panel | built-in |
    | ORM         | built-in |
    | Forms       | built-in |
    | Migrations  | built-in |
    | Permissions | built-in | -> Permissions / DRF permissions
    +------------------------+

   ➤The admin panel is extremely powerful.

🔸Learning Curve
   🔹Django Core:
      ➤Django project structure
      ➤Models
      ➤Migrations
      ➤Views
      ➤URL routing
      ➤Django ORM

   🔹Production Django:
      ➤Django REST Framework
      ➤Authentication
      ➤Permissions
      ➤Pagination
      ➤Filtering

   🔹Architecture:
      ➤Service layer
      ➤Celery jobs
      ➤Caching (Redis)
      ➤Signals
      ➤Middleware

   🔹Scaling:
      ➤Gunicorn
      ➤Nginx
      ➤Docker
      ➤Async Django

🔸Template syntax

    +-----------------------------------------------------------------------+
    |   Feature    |       Rails ERB             |    Django Template       |
    |--------------+-----------------------------+--------------------------|
    | variable     | <%= user.name %>`           |  {{ user.name }}`        |
    | if condition | <% if user.admin? %>`       |  {% if user.is_admin %}` |
    | loop         | <% users.each do \|u\| %>`  |  {% for u in users %}`   |
    | end loop     | <% end %>`                  |  {% endfor %}`           |
    +-----------------------------------------------------------------------+

    Example:
      {% for user in users %}
        <p>{{ user.name }}</p>
      {% endfor %}

🔸Layout system (like Rails layout)
   ➤In rails, we have layouts/application.html.erb and we use yield.

   ➤Django uses template inheritance.
      Base template: templates/base.html
          <html>
            <body>
            {% block content %}
            {% endblock %}
            </body>
          </html>
      
      Child template: users/show.html
          {% extends "base.html" %}
          {% block content %}
          <h1>{{ user.name }}</h1>
          {% endblock %}

        This is similar to Rails yield

  Many Django developers do not use templates anymore.
  Instead they build APIs: Django REST Framework(DRF) + React frontend

  Django also has powerful built-in template tools
    Examples:
      template filters
      template tags
      static files
      csrf protection
      form rendering

    Example filter:
      {{ user.name|upper }}


🔸One more powerful feature: URL namespacing
    Example:
      path("users/", include(("users.urls", "users"), namespace="users"))
    
    Then you can reverse URLs:
    reverse("users:user_detail")

    Similar to:
      users_path
      user_path(id)
    in Rails.


╰➤
➤
🔹
→