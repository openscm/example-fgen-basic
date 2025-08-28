@Marco please move these into `docs/further-background/wrapping-derived-types.md` (and do any other clean up and formatting fixes you'd like)

Wrapping derived types is tricky.
Notably, [f2py](@Marco please add link) does not provide direct support for it.
As a result, we need to come up with our own solution.

## Our solution

To pass derived types back and forth across the Python-Fortran interface,
we introduce a 'manager' module for all derived types.
This manager module is responsible for managing derived type instances
that are passed across the Python-Fortran interface
and is needed because we can't pass them directly using f2py.

The manager module has two key components:

1. an allocatable array of instances of the derived type it manages
   (@Marco note that this isn't how it is implemented now,
   but this is how we will end up implementing it)
1. an allocatable array of logical (boolean) values

The array of instances are instances which the manager owns.
It holds onto these: can instantiate them, can make them have the same values
as results from Fortran functions etc.
(@Marco I think we need to decide whether this is an array of instances
or an array of pointers to instances (although I don't think that's a thing https://fortran-lang.discourse.group/t/arrays-of-pointers/4851/6,
so doing something like this might require yet another layer of abstraction).
Array of instances means we have to do quite some data copying
and be careful about changes made on the Fortran side propagating to the Python side,
I think (although we have to test as I don't know enough about whether Fortran is pass by reference or pass by value by default),
array of pointers would mean change propagation should be more automatic.
We're going to have to define our requirements and tests quite carefully then see what works and what doesn't.
I think this is also why I introduced the 'no setters' views,
as some changes just can't be propagated back to Fortran in a 'permanent' way.
We should probably read this and do some thinking: https://stackoverflow.com/questions/4730065/why-does-a-fortran-pointer-require-a-target).

Whenever we need to return a derived type to Python,
we follow a recipe like the below:

1. we firstly ask the manager to give us an index (i.e. an integer) such that `logical_array(index)` is `.false.`.
   The convention is that `logical_array(index)` is `.false.` means that `instance_array(index)` is available for use.
1. We set `logical_array(index)` equal to `.true.`, making clear that we are now using `instance_array(index)`
1. We set the value of `instance_array(index)` to match the the derived type that we want to return
1. We return the index value (i.e. an integer) to Python
1. The Python side just holds onto this integer
1. When we want to get attributes (i.e. values) of the derived type,
   we pass the index value (i.e. an integer) of interest from Python back to Fortran
1. The manager gets the derived type at `instance_array(index)` and then can return the atribute of interest back to Python
1. When we want to set attributes (i.e. values) of the derived type,
   we pass the index value (i.e. an integer) of interest and the value to set from Python back to Fortran
1. The manager gets the derived type at `instance_array(index)` and then sets the desired atribute of interest on the Fortran side
1. When we finalise an instance from Python,
   we pass the index value (i.e. an integer) of interest from Python back to Fortran
   and then call any finalisation routines on `instance_array(index)` on the Fortran side,
   while also setting `logical_array(index)` back to `.false.`, marking `instance_array(index)`
   as being available for use for another purpose

Doing it this means that ownership is easier to manage.
Let's assume we have two Python instances backed by the same Fortran instance,
call them `PythonObjA` and `PythonObjB`.
If we finalise the Fortran instance via `PythonObjA`, then `logical_array(index)` will now be marked as `.false.`.
Then, if we try and use this instance via `PythonObjB`,
we will see that `logical_array(index)` is `.false.`,
hence we know that the object has been finalised already hence the view that `PythonObjB` has is no longer valid.
(I can see an edge case where, we finalise via `PythonObjA`,
then initialise a new object that gets the (now free) instance index
used by `PythonObjB`, so when we look again via `PythonObjB`,
we see the new object, which could be very confusing.
We should a) test this to see if we can re-create such an edge case
then b) consider a fix (maybe we need an extra array which counts how many times
this index has been initialised and finalised so we can tell if we're still
looking at the same initialisation or a new one that has happened since we last looked).)

This solution allows us to a) only pass integers across the Python-Fortran interface
(so we can use f2py) and b) keep track of ownership.
The tradeoff is that we use more memory (because we have arrays of instances and logicals),
are slightly slower (as we have extra layers of lookup to do)
and have slow reallocation calls sometimes (when we need to increase the number of available instances dynamically).
There is no perfect solution, and we think this way strikes the right balance of
'just works' for most users while also offering access to fine-grained memory control for 'power users'.

## Other solutions we rejected

### Pass pointers back and forth

Example repository: https://github.com/Nicholaswogan/f2py-with-derived-types

Another option is to pass pointers to objects back and forth.
We tried this initially.
Where this falls over is in ownership.
Basically, the situation that doesn't work is this.

From Python, I create an object which is backed by a Fortran derived type.
Call this `PythonObjA`.
From Python, I create another object which is backed by the same Fortran derived type instance i.e. I get a pointer to the same Fortran derived type instance.
Call this `PythonObjB`.
If I now finalise `PythonObjA` from Python, this causes the following to happen.
The pointer that was used by `PythonObjA` is now pointing to `null`.
This is fine.
However, the pointer that is being used by `PythonObjB` is now in an undefined state
(see e.g. community.intel.com/t5/Intel-Fortran-Compiler/DEALLOCATING-DATA-TYPE-POINTERS/m-p/982338#M100027
or https://www.ibm.com/docs/en/xl-fortran-aix/16.1.0?topic=attributes-deallocate).
As a result, whenever I try to do anything with `PythonObjB`,
the result cannot be predicted and there is no way to check
(see e.g. https://stackoverflow.com/questions/72140217/can-you-test-for-nullpointers-in-fortran),
either from Python or Fortran, what the state of the pointer used by `PythonObjB` is
(it is undefined).

This unresolvable problem is why we don't use the purely pointer-based solution
and instead go for a slightly more involved solution with a much clearer ownership model/logic.
We could do something like add a reference counter or some other solution to make this work.
This feels very complicated though.
General advice also seems to be to avoid pointers where possible
(community.intel.com/t5/Intel-Fortran-Compiler/how-to-test-if-pointer-array-is-allocated/m-p/1138643#M136486),
prefering allocatable instead, which has also helped shape our current solution.
