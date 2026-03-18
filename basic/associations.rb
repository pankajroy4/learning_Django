In Django, the ORM is simply known as the Django ORM.
Django ORM, associations are expressed through model fields rather than separate macros like Rails.
Conceptually they map very closely to Rails associations.

🔸ForeignKey
    This is exactly like belongs_to in rails.
    It is used for foreign key 

    Rails Example:
      class Post < ApplicationRecord
        belongs_to :user
      end

      posts table contains user_id

    Django Example:
      class Post(models.Model):
          user = models.ForeignKey("User", on_delete=models.CASCADE)
          # here django will define a foreign key field 'user_id'

      ForeignKey represents many-to-one
      on_delete defines behavior when parent is deleted.

      Common options for on_delete:
        models.CASCADE
        models.SET_NULL
        models.PROTECT
        models.SET_DEFAULT
        models.DO_NOTHING

      Example:
        class Post(models.Model):
          user = models.ForeignKey(
              "User",
              on_delete=models.CASCADE,
              related_name="posts"
          )

        Usage example:
          post.user
          user.posts.all()

🔸has many relation in Django
    Rails Example:
      class User < ApplicationRecord
        has_many :posts
      end

    Django does not require you to define this explicitly.
    If the Post model has a ForeignKey, Django automatically creates the reverse relation.

    Django Example:
      class Post(models.Model):
          user = models.ForeignKey(User, on_delete=models.CASCADE) # user_id

      Now automatically you get:
        user.post_set.all()

      But we usually rename it with related_name.

        class Post(models.Model):
          user = models.ForeignKey(User,
                  on_delete=models.CASCADE,
                  related_name="posts")

      Now you can do:
        user.posts.all()

      NOTE: If you do not define related_name then you have to use modal_name_set which is automatically added by Django.

🔸OneToOneField
    This is exactly like has_one in rails.

    Rails Example:
      class User < ApplicationRecord
        has_one :profile
      end

      class Profile < ApplicationRecord
        belongs_to :user
      end

    Django Example:
      class Profile(models.Model):
        user = models.OneToOneField(
            User,
            on_delete=models.CASCADE,
            related_name="profile"
        )

    Usage example:
      user.profile
      profile.user

🔸ManyToManyField(through=)
    This is exactly like has_many :through in rails.

    Rails example:
      class User < ApplicationRecord
        has_many :memberships
        has_many :groups, through: :memberships
      end

      class Group < ApplicationRecord
        has_many :memberships
      end

      class Membership < ApplicationRecord
        belongs_to :user
        belongs_to :group
      end

    Django Example:
      class User(models.Model):
        name = models.CharField(max_length=100)
        groups = models.ManyToManyField(Group, through="Membership") # This line tells Django that: “Don’t create an automatic join table. Use membership instead.” So Django internally connects: User <-- membership --> Group
        #Here, groups is a manager for a collection of Group objects. It is not a column.

      class Group(models.Model):
        name = models.CharField(max_length=100)

      class Membership(models.Model):
        user = models.ForeignKey(User, on_delete=models.CASCADE)    # user_id
        group = models.ForeignKey(Group, on_delete=models.CASCADE)  # group_id
        role = models.CharField(max_length=50)                      # role

      Usage example:
        user.groups.all()
        # Generated Sql:
          SELECT group.*
          FROM group
          JOIN membership ON group.id = membership.group_id
          WHERE membership.user_id = 101;

🔸ManyToManyField
    This is exactly like has_and_belongs_to_many in rails.
    
    Rails Example:
      class Student
        has_and_belongs_to_many :courses
      end

      class Course
        has_and_belongs_to_many :students
      end

    Django Example:
      class Course(models.Model):
        title = models.CharField(max_length=200)

      class Student(models.Model):
        name = models.CharField(max_length=200)
        courses = models.ManyToManyField(Course)

    Django automatically creates join table.

    Usage Example:
      student.courses.add(course)
      student.courses.all()

🔸Rails to Django Associations Mapping
    +-------------------------------------------------------+
    |         Rails           |           Django            |
    |-------------------------+-----------------------------|
    | belongs_to              | ForeignKey                  |
    | has_many                | ForeignKey reverse relation |
    | has_one                 | OneToOneField               |
    | has_many :through       | ManyToManyField(through=)   |
    | has_and_belongs_to_many | ManyToManyField             |
    +-------------------------------------------------------+

🔸Rails usages association macros but,
🔸Django usages relationship fields, Meaning relationships are defined directly in the model fields.

=======================================================================================================

🔸String reference In Django:
    In Django, Most projects keep all models in one models.py per app, so imports are rarely needed.
    Example structure:
      accounts/
        models.py
      groups/
        models.py

    But, when we need to create associations between the modal across the app, then you have to import the modal.
    For example:
        from django.db import models
        from users.models import User   => Importing User model from users/models.py

        class Group(models.Model):
          name = models.CharField(max_length=100)

        class Membership(models.Model):
          user = models.ForeignKey(User, related_name = "memberships", on_delete=models.CASCADE)
          group = models.ForeignKey(Group, on_delete=models.CASCADE)
          role = models.CharField(max_length=50)
            
    In such case, we can use "String Reference" to avoid importing models and circular import error.
    We can simply do:
      user = models.ForeignKey("accounts.User", on_delete=models.CASCADE)
      group = models.ForeignKey("groups.Group", on_delete=models.CASCADE)

    Notice the string reference:
      "accounts.User" or "groups.Group"
    Using strings allows Django to resolve the model later (avoids circular dependency problems).
    So, In Django production projects (multiple apps) you will often import models, but Django also provides string references ("app.Model") specifically to avoid circular imports.

🔸production tip
    Django′s AUTH_USER_MODEL often replaces User.

    Example:
      from django.conf import settings
      user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    This is the recommended way.

🔸In most Django apps there is one models.py file per app, like this:
      blog/
        models.py
        views.py
        admin.py
    This is the standard Django convention.

    But, Large apps sometimes have 20 to 50 models, and one models.py becomes messy. In this case, split models into models/ folder. 
    So, Instead of a single file, you create a models package.
    
    Example:
      blog/
        models/
          __init__.py
          post.py
          comment.py
          category.py
    
    1: models/post.py

        from django.db import models
        from .category import Category

        class Post(models.Model):
          title = models.CharField(max_length=200)
          category = models.ForeignKey(Category, on_delete=models.CASCADE)

    2: models/category.py

        from django.db import models

        class Category(models.Model):
          name = models.CharField(max_length=100)

    3: models/__init__.py
        You must expose models so Django can discover them:

          from .post import Post
          from .comment import Comment
          from .category import Category

    NOTE: 
      Even if models are split, Django still sees them as app_name.ModelName
      Example:
        blog.Post
        blog.Comment

      Django does not care about the internal file structure.

🔸What models/__init__.py does ?
    In Python, __init__.py turns a folder into a package. __init__.py acts like an export file.

    So when you do:
      blog/
        models/
          __init__.py
          post.py
          comment.py

    Then python treats models folder as a module package.
    This allows imports like:
      from blog.models import Post

    instead of:
      from blog.models.post import Post
    
    External code only interacts with blog.models , not the internal files.

    Django expects models to be accessible from app_name.models
    When you split models into multiple files, Django still loads blog.models
    So models/__init__.py re-exports the models.

    Without this file, you would need:  
      from blog.models.post import Post
    which breaks Django conventions in places like:
      admin, migrations, signals, imports across apps


 🔹Pro Django tip:
    Large projects sometimes also use __all__ in __init__.py:

      from .post import Post
      from .comment import Comment
      __all__ = ["Post", "Comment"]

    This explicitly defines the public models API.

=================================================================================================
🔸What are selectors in Django?
    In Django architecture, selectors are functions (or modules) responsible only for reading/querying data from the database. They are not part of Django itself—it is an organizational pattern used in large Django projects.
    So, A selector is a function (or class or modules) responsible for retrieving data from the database.

    Comparing to Ruby on Rails, selectors are somewhat similar to query objects / scopes / read-only service objects that encapsulate database queries. For examples: app/operation, app/services 

    In Django, The idea is:
      Selectors → read data
      Services → write/change data

  Project Structure example:
    orders/
      models.py
      selectors.py    # read queries
      services.py     # business logic + writes
      views.py        # controllers
      tasks.py        # background jobs - async

  Example:
    #orders/selectors.py
      from .models import Order
      def get_active_orders():
        return Order.objects.filter(status="active").select_related("user")

    # views.py (i.e controllers)
      from .selectors import get_active_orders
      def active_orders(request):
        orders = get_active_orders()
        return render(request, "orders.html", {"orders": orders})

    This gives us Benefits like centralized Query logic, Reusable, Easier to test.
    Selectors Are Especially Useful in case of Django REST Framework APIs, Large projects, Complex queries, Performance optimizations (select_related, prefetch_related)

    Rule of selectors:
      Selectors should:
        Read/query data
        Contain ORM logic
        Return QuerySets or objects

  Example:
    # users/selectors.py
    from django.contrib.auth import get_user_model

    User = get_user_model()

    def get_active_users():
      return User.objects.filter(is_active=True)

    def get_user_with_groups(user_id):
      return (
        User.objects
        .select_related("profile")
        .prefetch_related("groups")
        .get(id=user_id)
      )

