🔸In Django, tasks are just what we have background jobs in rails.
  The file tasks.py usually contains background jobs (asynchronous tasks).

  In Django projects this is commonly implemented using Celery.

  Project structure:

    users/
      models.py
      selectors.py
      services.py
      views.py
      tasks.py

  Celery auto-discovers tasks from the file tasks.py inside installed apps.
  If you define tasks elsewhere, you must ensure they are imported.

  We generally trigger the task from services.
  Example: 
  #tasks.py
    from celery import shared_task
    from django.core.mail import send_mail

    @shared_task # OR @app.task
    def send_welcome_email(user_email):
        send_mail(
            "Welcome!",
            "Thanks for joining.",
            "noreply@example.com",
            [user_email],
        )


  #services.py
    from .models import User
    from .tasks import send_welcome_email

    def create_user(email):
        user = User.objects.create(email=email)
        send_welcome_email.delay(user.email)  # runs async
        # Or 
        # send_welcome_email.apply_async(args=["user@example.com"])
        return user

  Here, the delay() methods sends the job to the queue.

🔸Background worker systems
  Typical setups in Django ecosystem:
      Celery (most common)
      Redis as queue broker
      Sometimes RabbitMQ    

  Most popular combo in Django:	Celery + Redis


  Mental mapping for a Rails developer
        +-------------------------------------------+
        |   Django	     |    Rails                 |
        |----------------|--------------------------|
        | tasks.py	     |   app/jobs               |
        | Celery task	   |   ActiveJob              |
        | .delay()	     |  perform_later           |
        | Celery worker  |  Sidekiq worker          |
        | Redis (queue)  |  Redis/RabbitMQ (queue)  |
        +-------------------------------------------+

🔸What is @shared_task?
  This is a decorator that comes from Celery.
  It registers the function defined just below it as an asynchronous task (i.e background job) that Celery can execute.
  It makes the function callable via .delay() or .apply_async()
  NOTE: It will register only one function define below it.
        If you have mutiple function, you have to use @shared_task decorator above all function.

🔸What actually processes this task?
  Celery Worker does the processing exactly like sidekiq worker in rails.
  Flow (Django + Celery):
    
    You call:
      send_welcome_email.delay("user@example.com")

    Celery will:
      Serializes the task
      Pushes it to a broker (usually Redis)

    Broker (Redis / RabbitMQ):
      Stores the job in a queue

    Celery Worker (separate process):
      Pulls job from queue
      Executes send_welcome_email

🔸Why use @shared_task instead of @app.task ?
  Celery has two ways to register the function as an asynchronous task:
  1. @app.task
      example:
      
      @app.task
      def task():
        ...

  2. @shared_task (recommended in Django)

  @shared_task is used because:
    Django apps are reusable
    It avoids tight coupling with a specific Celery app instance
    Works automatically across Django projects

NOTE: Just like in rails we run the sidekiq and redis, in Django also we must run the celery and redis in seperate terminal.
  Command to run celery: celery -A project_name worker -l info
  Command to run redis: redis-server

  Django does not include background jobs by default
  You must install and configure Celery separately

🔸What .delay() actually does ?
  When you call: send_welcome_email.delay("user@example.com")

  Celery (Celery) does many things.

  1. Convert function call → message
  2. Serialize to JSON (by default)
      Example:
      {
        "task": "myapp.tasks.send_welcome_email",
        "args": ["user@example.com"],
        "kwargs": {}
      }
  3. Push to broker (Redis/RabbitMQ)

  This is exactly like: In rails, Sidekiq pushing a JSON payload into Redis.
  
  NOTE: 
      While enqueuing a task never pass full model object, instead pass ids or fields.
      Example:
        send_welcome_email.delay(user.email) # Good
        send_welcome_email.delay(user)    # Bad

🔸Retries in celery
  In rails when using sidekiq we just do retry: 5 to retry a failed job.
  
  In Django (Celery), we do something like this:
  Example:
    
    from celery import shared_task

    @shared_task(bind=True, max_retries=5)
    def send_welcome_email(self, user_email):
        try:
            ...
        except Exception as exc:
            raise self.retry(exc=exc, countdown=60)

    
  Key concepts:
   🔹bind=True → gives access to self (task instance)
   🔹self.retry() → re-enqueue task
   🔹countdown=60 → retry after 60 sec

🔸Queues in celery
  In rails or in sidekiq we can select queue as:
    queue_as :default
    queue_as :mailers

  In celery , we do something like this. We pass the queue name to @shared_task decorator.
  Example:

    @shared_task(queue="mailers")
    def send_welcome_email(user_email):
      ...

  NOTE: We can run the Celery worker for a specific queue also.
        Command: celery -A project_name worker -Q mailers -l info

🔸Scheduling a task or Cron jobs
  In rails we use gem like sidekiq-cron or whenever gem to schedule background jobs or to run corn jobs.

  In Celery, We use Celery Beat to schedule a task or to run Corn jobs.
  Celery Beat is equivalent to Sidekiq Cron gem.

  Example: Using Celery beat.
      # Inside setting.py, we define scheduling:

        CELERY_BEAT_SCHEDULE = {
          "send-daily-email": {
              "task": "myapp.tasks.send_welcome_email",
              "schedule": 86400.0,  # every 24 hours
              "args": ("user@example.com",)
          },
        }

      # Or using cron style:
      from celery.schedules import crontab
      "schedule": crontab(hour=9, minute=0)

🔸NOTE: Best practice is to keep tasks thin. Put business logic inside service object and import it.
      Example:
        # tasks.py
        @shared_task
        def send_welcome_email(user_id):
            from .services import send_email_logic
            send_email_logic(user_id)

        # services.py
        def send_email_logic(user_id):
            ...


🔸What is ETA and countdown ?
  ETA stands for “Earliest Time of Arrival”
  In Celery, it means: “Do NOT execute this job before this specific time”
  It is used when we need exact time scheduling.

  Example 1:

    from datetime import datetime, timedelta
    send_welcome_email.apply_async(
        args=["user@example.com"],
        eta=datetime.utcnow() + timedelta(minutes=10)
    )

    It means: “Run this task at EXACTLY 10 minutes from now”.
    Rails equivalent: MyJob.set(wait_until: 10.minutes.from_now).perform_later(user.email)

  Example 2:
    
    from datetime import datetime
    send_welcome_email.apply_async(
        args=["user@example.com"],
        eta=datetime(2026, 3, 25, 10, 30, 0)  # YYYY, MM, DD, HH, MM, SS
    )
    
    This means: Run on March 25, 2026 at 10:30:00
    Rails equivalent: MyJob.set(wait_until: Time.new(2026, 3, 25, 10, 30)).perform_later(user.email)

    NOTE: VERY IMPORTANT (Timezone gotcha):
        datetime(2026, 3, 25, 10, 30) => This is a naive datetime (no timezone)
        Celery + Django may misinterpret it.

        It is always better to use timezone-aware datetime.
        
        Example 1:
          from django.utils import timezone
          eta_time = timezone.make_aware(
              datetime(2026, 3, 25, 10, 30)
          )

          send_welcome_email.apply_async(
              args=["user@example.com"],
              eta=eta_time
          )

        Example 2:(Even better):
          from django.utils import timezone
          eta_time = timezone.datetime(2026, 3, 25, 10, 30)

          send_welcome_email.apply_async(
              args=["user@example.com"],
              eta=eta_time
          )

        Example 3: Based on user timezone (real-world case)
          import pytz
          from datetime import datetime
          ist = pytz.timezone("Asia/Kolkata")
          eta = ist.localize(datetime(2026, 3, 25, 10, 30))

          send_welcome_email.apply_async(
              args=["user@example.com"],
              eta=eta
          )

          Rails equivalent: MyJob.set(wait_until: Time.zone.parse("2026-03-25 10:30")).perform_later

  🔹Countdown:
    It is relative delay (from now). It is Easy and most commonly used.
    Example:
      send_welcome_email.apply_async(args=["user@example.com"], countdown=30)

      It means: Run this task 30 seconds from now”

      Rails equivalent: MyJob.set(wait: 30.seconds).perform_later(user.email)
      In rails:
        wait_until: absolute time (you decide the exact timestamp)
        wait: relative delay (Rails calculates based on enqueue time)

  🔹Note:
    Celery workers will not execute task before ETA but,
    Execution is not guaranteed to be exactly at that time (depends on worker load). Same as Sidekiq scheduling.

    Task is stored in broker (Redis)
    Worker checks ETA
    It wil not execute before that time
    But execution might be slightly delayed if worker is busy


🔸Difference between delay() and apply_async() methods used to enqueuing tasks
  
  delay() is just simple version.
  example: send_welcome_email.delay("user@example.com")
  This is just a shortcut for: send_welcome_email.apply_async(args=["user@example.com"])

  So, delay is just like we use perform_later in rails.
  Rails equivalent: MyJob.perform_later(user.email)

  apply_async() is more powerful version.
  Example:
      send_welcome_email.apply_async(
        args=["user@example.com"],
        countdown=30,
        queue="mailers",
        retry=True
      )

    It gives you full control.
    Rails equivalent: MyJob.set(wait: 30.seconds, queue: :mailers).perform_later(user.email)

  
  Use .delay() when:
    You just want to enqueue a job
    No scheduling
    No custom queue
    No advanced options

    It will cover your 80% of cases.

  Use .apply_async() when:
    You need delay (countdown)
    You need exact time (eta)
    You want specific queue
    You want retries / routing / priority


🔸What is priority?
  Priority means which job runs first inside the same queue.
  Example:
    send_welcome_email.apply_async(
        args=["user@example.com"],
        priority=9
    )
    
    Higher number = higher priority (depends on broker config)
    Worker picks higher priority jobs first

  Note:
    Priority works best with RabbitMQ
    Redis support is limited / simulated using queues.

  Rails equivalent
    Sidekiq does NOT support priority inside a queue directly.
    Instead, you simulate it with multiple queues:

    :queues:
      - critical
      - default
      - low
    
    Worker checks queues in order → same effect as priority.

  Best Practice:
    Prefer routing (queues) over priority.
    Because queues are:
      More predictable
      Easier to scale

  Production-style setup
    Instead of doing this:
      priority=10
  
    Do this:
      @shared_task(queue="critical")
      def urgent_task():
          ...

    You can run celery worker like this:
        celery -A project worker -Q critical --concurrency=4 
        This means: this worker can process 4 tasks at the same time (in parallel)

        celery -A project worker -Q default --concurrency=2

  NOTE:
      Routing means: queue selection
      Priority means: ordering inside queue → optional
      Real-world scaling: multiple queues + dedicated workers for each queue.

🔸Concurrency
  In Rails, Sidekiq:
    :concurrency: 5

  It means 5 jobs processed in parallel by one Sidekiq process using multiple threads.

  In Celery:
    celery -A project_name worker -Q critical --concurrency=4 

    Worker starts a pool.
    Pool can be:
      processes (default)
      threads
      event loop (advanced)

    With --concurrency=4:
      4 processes (default)
      Each picks a task from queue

    Example:
      Queue has 10 jobs: Job1, Job2, Job3, Job4, Job5...
      So, With: --concurrency=4

      Execution:
        Time 0:
          Worker handles → Job1, Job2, Job3, Job4

        Time 1:
          Next → Job5, Job6, Job7, Job8

  NOTE:
    Sidekiq uses threads, Celery (default) uses processes
    So:
      Sidekiq concurrency = threads
      Celery concurrency = processes (by default)

  NOTE:
    More concurrency ≠ always better
    Depends on job type:
        CPU-bound tasks (heavy computation)
          Example:
            image processing
            data crunching

          So, Use lower concurrency

        I/O-bound tasks (most common)
          Example:
            sending emails
            API calls
            DB queries
        So, Use higher concurrency


🔸Difference between process vs thread pool in Celery (important vs Sidekiq)
  This is a very important concept—especially coming from Sidekiq, because Sidekiq = threads, while Celery defaults to processes.

    +-------------------------------------------------------------------------------------------+
    |                   | Celery (default) |          Sidekiq                                   |
    |-------------------|------------------|----------------------------------------------------|
    | Concurrency model | Processes        | Threads.                                           |
    | Memory            | High             | Low                                                |
    | CPU usage         | True parallelism | Limited by GIL (Ruby has no GIL issue like Python) |
    | Isolation         | Strong           | Weak                                               |
    | Speed (I/O)       | Good             | Excellent                                          |
    +-------------------------------------------------------------------------------------------+
==============================================
1. Process Pool (Celery default)
celery -A project worker --concurrency=4

👉 This creates 4 separate OS processes

🧠 What that means

Each worker process:

Has its own memory

Has its own Python interpreter

Runs independently

👉 Think:

Worker:
  Process 1 → Task A
  Process 2 → Task B
  Process 3 → Task C
  Process 4 → Task D
✅ Pros
1. True parallelism (BIG)

Uses multiple CPU cores

No GIL limitation

2. Isolation

One crash ≠ kill others

Safer for buggy code

3. Good for CPU-heavy jobs

image processing

data computation

❌ Cons
1. High memory usage

Each process ≈ full Python app loaded

2. Slower startup
🧵 2. Thread Pool (Celery alternative)
celery -A project worker --pool=threads --concurrency=10

👉 One process, multiple threads

🧠 What that means
Worker:
  Process 1:
    Thread 1 → Task A
    Thread 2 → Task B
    Thread 3 → Task C
✅ Pros
1. Low memory

Shared memory space

2. Great for I/O tasks

API calls

emails

DB queries

3. Faster context switching
❌ Cons (VERY important)
1. Python GIL 😬

👉 Only ONE thread executes Python code at a time

So:

CPU-bound tasks → no real parallelism

🧠 Sidekiq comparison

In Ruby on Rails + Sidekiq:

Uses threads

Ruby does NOT have the same GIL limitation (MRI has GVL but behaves differently with I/O)

👉 That’s why Sidekiq works great with high concurrency like:

:concurrency: 25
🔥 Key insight (VERY important)

👉 Celery chose processes by default because:

Python’s GIL makes threads bad for CPU work

⚖️ When to use what?
✅ Use process pool (default)

Best for:

CPU-heavy jobs

general safe default

most production setups

celery -A project worker --concurrency=4
✅ Use thread pool

Best for:

API calls

sending emails

external services

celery -A project worker --pool=threads --concurrency=20
🧠 Real-world pattern

Smart teams split workloads:

# CPU-heavy queue
celery -A project worker -Q heavy --concurrency=2

# I/O-heavy queue
celery -A project worker -Q io --pool=threads --concurrency=20
⚠️ Gotcha (Rails dev trap)

If you try:

--pool=threads --concurrency=20

for CPU-heavy work:

👉 It will NOT scale like Sidekiq
👉 It will be slower due to GIL

💡 Final intuition

Process pool → “multiple machines in one server”

Thread pool → “multiple workers sharing same brain”

🧠 One-line takeaway

Sidekiq = threads everywhere
Celery = processes by default, threads only for I/O

If you want next, I can show:

how to pick the right pool + concurrency based on your server (CPU cores, RAM)

or real production configs (this is where most teams mess up)