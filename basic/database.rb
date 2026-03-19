

In Django, the equivalent of Rails’ ActiveRecord::Base.transaction is:

from django.db import transaction
✅ Basic equivalent
Rails
ActiveRecord::Base.transaction do
  user.save!
  profile.save!
end

Django
from django.db import transaction

with transaction.atomic():
    user.save()
    profile.save()
🔹 How it works

transaction.atomic() creates a database transaction block

If any exception occurs, everything is rolled back

If everything succeeds, it commits automatically

🔥 Important difference
Rails
save!   # raises exception
save    # returns false (no exception)

Django
save()  # DOES NOT raise exception normally

👉 So in Django:
You must raise exceptions manually if you want rollback
Or rely on database errors (e.g., constraint violations)

✅ Example with validation

from django.db import transaction
from django.core.exceptions import ValidationError

with transaction.atomic():
    user.save()

    if not user.email:
        raise ValidationError("Email required")  # triggers rollback

✅ Nested transactions (like Rails)
with transaction.atomic():
    user.save()

    with transaction.atomic():
        profile.save()

Django uses savepoints internally (similar to Rails)

✅ Manual rollback (rare case)
from django.db import transaction

with transaction.atomic():
    user.save()
    transaction.set_rollback(True)

🧠 Mental mapping
| Rails                            | Django                     |
| -------------------------------- | -------------------------- |
| `ActiveRecord::Base.transaction` | `transaction.atomic()`     |
| `raise`                          | `raise`                    |
| `save!` (raises)                 | manually raise or DB error |
| nested transactions              | nested `atomic()`          |


⚠️ Common gotcha

This will NOT rollback:

with transaction.atomic():
    user.save()
    return  # no exception → commits!

Only exceptions trigger rollback.

✅ Best practice
with transaction.atomic():
    # do all DB operations
    # raise exceptions on failure

If you want, I can show how Django transactions behave with Celery/background jobs or how to mimic Rails after_commit callbacks.
==========================
what is @transaction.atomic

In Django, @transaction.atomic is a decorator version of transaction.atomic()—it lets you wrap an entire function or method in a database transaction, instead of using a with block.

🔹 Basic Usage
from django.db import transaction

@transaction.atomic
def create_user_and_profile(user_data, profile_data):
    user = User.objects.create(**user_data)
    profile = Profile.objects.create(user=user, **profile_data)
    # if any exception occurs here, both user and profile are rolled back

Equivalent to:

def create_user_and_profile(user_data, profile_data):
    with transaction.atomic():
        user = User.objects.create(**user_data)
        profile = Profile.objects.create(user=user, **profile_data)

🔹 How it works

Django starts a database transaction at the start of the function.

If the function raises an exception, Django rolls back all changes.

If it completes successfully, Django commits the transaction.

🔹 When to use

Wrapping entire view functions or service methods in a transaction.

Cleaner than with transaction.atomic() if your logic is fully contained in one function.

Example:

@transaction.atomic
def process_order(order_id):
    order = Order.objects.select_for_update().get(id=order_id)
    order.status = 'processed'
    order.save()
    
    Payment.objects.create(order=order, amount=order.total)

If any step fails, nothing is committed.

🔹 Nested atomic() blocks
@transaction.atomic
def outer():
    ...
    inner()  # can also be atomic

Django uses savepoints for nested atomic blocks, similar to Rails nested transaction do.

🔹 Quick Rails analogy
| Rails                                       | Django                           |
| ------------------------------------------- | -------------------------------- |
| `ActiveRecord::Base.transaction do ... end` | `with transaction.atomic(): ...` |
| wrap **method with transaction**            | `@transaction.atomic`            |


In short:

with transaction.atomic() → block-level transaction
@transaction.atomic → function-level transaction



If you want, I can also explain the difference between atomic and commit_on_success from older Django versions, which often confuses people coming from Rails.