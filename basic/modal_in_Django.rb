🔸Modals in Django
  In rails, modal inherits from ApplicationRecord which inherits from ActiveRecord::Base 

  In Django, modal inherits from Django′s base ORM class modals.Modal 
  example: Class User(modals.Modal)

🔸What is models.Model?
  models.Model is Django′s base ORM class.
  It provides all database functionality like table mapping, query methods, saving records, deleting records, migrations integration
  
  Internally it looks roughly like:
    class Model(metaclass=ModelBase):
        ...

  So when you write:
    class Todo(models.Model):

  Python does:
    Create class Todo
    Inherit behavior from models.Model
    Register the model with Django′s ORM


🔸What Happens When Django Loads the Model
    When Django starts, it scans installed apps from INSTALLED_APPS = ["todos"]
    Django loads: todos/models.py

    When Python executes the modal:
      class Todo(models.Model):

    Then Django′s Model metaclass (ModelBase) runs.

    This metaclass i.e (ModelBase) does several things:

       🔹Collect fields
          title = models.CharField(max_length=255)
          completed = models.BooleanField(default=False)

          These become database columns.

          Django stores them internally:
            Todo._meta.fields

       🔹Create table mapping
          Django determines the table name: todos_todo

          Rule: <app_name>_<model_name>

       🔹Attach ORM methods
          Your model now automatically gets methods like:
            Todo.objects.all()
            Todo.objects.create()
            Todo.objects.filter()
            Todo.save()
            Todo.delete()

          Example:
            Todo.objects.create(title="Learn Django")

          Equivalent Rails:
            Todo.create(title: "Learn Django")

🔸What Happens During makemigrations
    Django compares model definitions.

    Your model:
      class Todo(models.Model):
          title = models.CharField(max_length=255)

    Django generates migration:
      class Migration(migrations.Migration):
          operations = [
              migrations.CreateModel(
                  name="Todo",
                  fields=[
                      ("id", models.BigAutoField(primary_key=True)),
                      ("title", models.CharField(max_length=255)),
                  ],
              ),
          ]

    Then migrate creates the SQL table.
    Equivalent Rails flow: Model -> Migration -> DB Table

🔸What Happens When You Query
    Example: Todo.objects.all()

    Execution chain:
      Todo.objects
          ↓
      Manager
          ↓
      QuerySet
          ↓
      SQL generated
          ↓
      Database

    SQL produced:
      SELECT * FROM todos_todo;

    Equivalent Rails: Todo.all

🔸Why Django Uses Metaclasses
    models.Model uses ModelBase metaclass

    This metaclass:
      Reads model fields
      Registers model
      Builds ORM metadata
      Connects migrations
      Generates SQL schema

    This is how Django ORM works without needing separate schema files.

🔸Internal Metadata (_meta)
    Every Django model has metadata. for example Todo._meta

    Example usage:
      Todo._meta.db_table
      Todo._meta.fields
      Todo._meta.get_fields()

    Equivalent concept in Rails:
      ActiveRecord reflection

🔸Full Execution Flow
    When Django starts:
      Django start
          ↓
      Load INSTALLED_APPS
          ↓
      Import models.py
          ↓
      Execute class Todo(models.Model)
          ↓
      ModelBase metaclass runs
          ↓
      Fields registered
          ↓
      ORM mapping created
          ↓
      makemigrations detects model
          ↓
      migrate creates table

🔸What is a Manager?
    In Rails, we use ActiveRecord::Base through ApplicationRecord which providing all querying power directly. 
    In Django, that power is delegated to an object called a Manager.

    A Manager is the interface through which Django database query operations are provided to models. 
    It is the interface between a model and the database query system.
    It provides query operations for a model.
    Every Django model has at least one Manager, and the default one is named objects.

    When you write Todo.objects.all(), objects is the Manager. It acts as the gateway to the database. objects is a Manager instance attached to the model.

    Example:
      class Todo(models.Model):
          title = models.CharField(max_length=255)

      Django automatically adds:
        Todo.objects

      That objects is:
        django.db.models.manager.Manager

      Example usage:
        Todo.objects.all()
        Todo.objects.filter(completed=True)
        Todo.objects.get(id=1)

🔸What Manager Actually Does?
    Manager creates QuerySets.
    Example:
      Todo.objects.all()
    Internally:
      Manager.all()
          ↓
      returns QuerySet

    Simplified version of Django code:
      class Manager:
          def all(self):
              return QuerySet(model=Todo)

    So Manager is basically a factory for QuerySets.

🔸What is a QuerySet?
    A QuerySet represents a lazy database query.
    Example:
      todos = Todo.objects.filter(completed=True)

      At this point, No SQL executed yet.
      QuerySet only stores query instructions.

    Example internal representation:

      QuerySet
        model = Todo
        filters = completed=True
        order_by = None

    SQL runs only when you evaluate it.

🔸QuerySet is Lazy
    Example:
      todos = Todo.objects.filter(completed=True)
      No query executed.

      Query executes only when we evaluate it, for example:
        list(todos)
        todos[0]
        print(todos)
        for todo in todos:

🔸QuerySet is Chainable
    Example:
      Todo.objects.filter(user=1).order_by("-created_at")

      Each step returns a new QuerySet.
      Internally:
        QuerySet1 = filter(user=1)
        QuerySet2 = QuerySet1.order_by("-created_at")
      
      This builds SQL step-by-step.

      Final SQL:
        SELECT * FROM todos_todo
        WHERE user_id = 1
        ORDER BY created_at DESC;

      Rails equivalent:
        Todo.where(user_id: 1).order(created_at: :desc)

🔸QuerySet vs Model Instance
    QuerySet return collection of records.
      Example:
        Todo.objects.filter(completed=True)
      
      This will returns:
        <QuerySet [Todo, Todo, Todo]>

    Model Instance returns Single record.
      Example:
        Todo.objects.get(id=1)

      This will returns:
        <Todo object>

🔸Custom Manager
    Managers allow custom query APIs.
  
    Example:
      class TodoManager(models.Manager):
          def completed(self):
              return self.filter(completed=True)

      We have to attach it with modal class:
        class Todo(models.Model):
            title = models.CharField(max_length=255)
            completed = models.BooleanField(default=False)
            objects = TodoManager()

      Then we can use it like:
        Todo.objects.completed()

    Rails equivalent:
      scope :completed, -> { where(completed: true) }

🔸Custom QuerySet (Advanced)
    QuerySet is considered as better pattern because it allows chainable custom queries.
    Example:
      class TodoQuerySet(models.QuerySet):
          def completed(self):
              return self.filter(completed=True)

      We have to attach it to modal class
        class Todo(models.Model):
            objects = TodoQuerySet.as_manager()
      
      Then we can use it like:
        Todo.objects.completed()

🔸QuerySet Cloning
    Every QuerySet operation returns a new immutable QuerySet.

    Example:
      qs1 = Todo.objects.all()
      qs2 = qs1.filter(completed=True)

    Now:
      qs1 → SELECT * FROM todos
      qs2 → SELECT * FROM todos WHERE completed=True

    This avoids modifying existing queries.
    Rails ActiveRecord does the same.

🔸QuerySet Internals
    Internally Django stores queries in "django.db.models.sql.Query"
    QuerySet structure roughly:
      QuerySet
        model
        query
        connection

    The query object stores:
      filters
      joins
      order
      limits
      annotations

    SQL is generated later.

    Full Execution Flow
    Example:
      Todo.objects.filter(completed=True).order_by("-created_at")
    Flow:
        Todo.objects → Manager → filter() → QuerySet created → order_by() → new QuerySet → iteration → SQL generated → database query

🔸Why Django Has Manager
    Managers allow multiple query entry points.
    Example:
      class Todo(models.Model):
        objects = models.Manager()
        completed = CompletedManager()

      We can use it like:
        Todo.objects.all()
        Todo.completed.all()

      This is not possible with only QuerySets.

🔸N+1 Query problems:
    In Rails we use include or preload to solve N+1 query problem.
    Similarily, In Django we use:
      select_related
      prefetch_related

    to avoid N+1 query.

🔸Custom QuerySets are better than Custom Manager because QuerySets keep queries chainable and composable.
  Understanding the Core Difference
  1:Custom Manager
    Manager methods return QuerySets, but they live outside the QuerySet chain.

    Example:
      class TodoManager(models.Manager):
        def completed(self):
            return self.filter(completed=True)

      Attach it to the modal:
        class Todo(models.Model):
          title = models.CharField(max_length=255)
          completed = models.BooleanField(default=False)

          objects = TodoManager()

      Use it like:
        Todo.objects.completed()  => Works fine

        Todo.objects.filter(user=1).completed()  => This will fail
        This will fail Because:
          filter() returns QuerySet
          completed() exists only on Manager
        So the method disappears.

  2:Custom QuerySet:
      class TodoQuerySet(models.QuerySet):
        def completed(self):
          return self.filter(completed=True)

      Attach it to the modal:
        class Todo(models.Model):
          title = models.CharField(max_length=255)
          completed = models.BooleanField(default=False)

          objects = TodoQuerySet.as_manager()

      Use it like:
        Todo.objects.completed()   => Works fine
        Todo.objects.filter(user=1).completed()   => This will also works fine

        Here, Both works because
          filter() returns QuerySet
          completed() exists on QuerySet

🔸Django Official Recommendation
    Django documentation recommends:
      Put query logic in QuerySets, not Managers.

    Managers should mostly:
      expose QuerySets
      provide entry points

🔸Clean Production Pattern for Manager and QuerySet:
    class TodoQuerySet(models.QuerySet):
      def completed(self):
          return self.filter(completed=True)

      def pending(self):
          return self.filter(completed=False)

    class TodoManager(models.Manager):
      def get_queryset(self):
          return TodoQuerySet(self.model, using=self._db)

      def completed(self):
          return self.get_queryset().completed()

    class Todo(models.Model):
      title = models.CharField(max_length=255)
      completed = models.BooleanField(default=False)

      objects = TodoManager()

🔸When to Use Manager Instead
    Managers are useful for:

      1.Multiple query entry points
          Example:
            Todo.objects
            Todo.active_objects
            Todo.deleted_objects

          Used in soft delete systems.
          Example:
            Todo.objects.all()
            Todo.deleted.all()
            
      2.Changing default queryset
          Example:
            class ActiveManager(models.Manager):
                def get_queryset(self):
                    return super().get_queryset().filter(deleted=False)

🔸What is get_queryset()
    get_queryset() is a Manager method that defines the base QuerySet used for all queries.

    Django internally calls this whenever you do:
      Todo.objects.all()
      Todo.objects.filter(...)
      Todo.objects.get(...)

    So the flow is:
      Todo.objects →  Manager → get_queryset() → QuerySet created → filter(), order_by(), etc

    🔹Default Django Implementation
        Inside Django, the default Manager looks roughly like this:
          class Manager:
            def get_queryset(self):
              return QuerySet(self.model, using=self._db)

        So when you write:
          Todo.objects.all()
        Internally Django does:
          Manager.get_queryset() → QuerySet(Todo)

    🔹Why Override get_queryset()
        We override it when we want the manager to return a custom QuerySet instead of Django’s default.

        Example:
          class TodoQuerySet(models.QuerySet):
            def completed(self):
              return self.filter(completed=True)

          Then the manager must return that QuerySet.

          class TodoManager(models.Manager):
            def get_queryset(self):
              return TodoQuerySet(self.model, using=self._db)

          Now every query starts with:
            TodoQuerySet
          instead of:
            QuerySet

    🔹Why self.model Is Passed in TodoQuerySet(self.model, using=self._db)
        QuerySet needs to know which model it is querying.
        Example:
          TodoQuerySet(self.model)

        It means: This QuerySet works with the Todo model.
        Internally Django uses it to generate SQL:
          SELECT * FROM todos_todo

        So self.model provides:
          Todo model metadata
          table name
          fields
          relationships

    🔹Why using=self._db is Passed in TodoQuerySet(self.model, using=self._db)
        Django supports multiple databases.
        Example configuration:
          DATABASES = {
              "default": {...},
              "replica": {...}
          }

        A manager may be attached to a specific DB.
        Example:
          Todo.objects.using("replica")

        Internally Django stores the DB name in self._db
        So this:
          TodoQuerySet(self.model, using=self._db)
        ensures the QuerySet uses the same database connection as the manager.
        Without this, the QuerySet might ignore DB routing.

    🔹Cleaner Alternative (Modern Django)
        Django provides a shortcut:
          objects = TodoQuerySet.as_manager()
        This automatically generates the manager.

        So you do not need get_queryset()

        Example:
          class Todo(models.Model):
            title = models.CharField(max_length=255)
            completed = models.BooleanField(default=False)

            objects = TodoQuerySet.as_manager()