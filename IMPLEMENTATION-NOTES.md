@Marco please move these into `docs/further-background/wrapping-derived-types.md` (and do any other clean up and formatting fixes you'd like)

## What is the goal?

The goal is to be able to run MAGICC, a model written in Fortran, from Python.
This means we need to be able to instantiate MAGICC's inputs in memory in Python,
pass them to Fortran to solve the model and get them back as results in Python.

Our data is not easily represented as primitive types (floats, ints, strings, arrays)
because we want to have more robust data handling, e.g. attaching units to arrays.
As a result, we need to pass objects to Fortran and return Fortran derived types to Python.
It turns out that wrapping derived types is tricky.
Notably, [f2py](https://numpy.org/doc/stable/f2py/)
does not provide direct support for it.
As a result, we need to come up with our own solution.

## Our solution

Our solution is based on a key simplifying assumption.
Once we have passed data across the Python-Fortran interface,
there is no way to modify it again from the other side of the interface.
In other words, our wrappers are not views,
instead they are independent instantiations of the same (or as similar as possible) data models.

For example, if I have an object in Python
and I pass this to a wrapped Fortran function which alters some attribute of this object,
that modification will only happen on the Fortran side,
the original Python object will remain unchanged
(as a note, to see the result, we must return a new Python object from the Fortran wrapper).

This assumption makes ownership and memory management clear.
We do not need to keep instances around as views
and worry about consistency across the Python-Fortran interface.
Instead, we simply pass data back and forth,
and the normal rules of data consistency within each programming language apply.

To actually pass derived types back and forth across the Python-Fortran interface,
we introduce a 'manager' module for all derived types.

The manager module has two key components:

1. an allocatable array of instances of the derived type it manages,
   call this `instance_array`.
   The array of instances are instances which the manager owns.
   In practice, they are essentially temporary variables.
1. an allocatable array of logical (boolean) values,
   call this `available_array`.
   The convention is that, if `available_array(i)`, where `i` is an integer,
   is `.true.` then the instance at `instance_array(i)` is available for the manager to use,
   otherwise the manager assumes that the instance is already being used for some purpose
   and therefore cannot be used for whatever operation is currently being performed.

This setup allows us to effectively pass derived types back and forth between Python and Fortran.

Whenever we need to return a derived type to Python, we:

[TODO think about retrieving multiple derived types at once]

1. get the derived type from whatever Fortran function or subroutine created it,
   call this `derived_type_original`
1. find an index, `idx`, in `available_array` such that `available_array(idx)` is `.true.`
1. set `instance_array(idx)` equal to `derived_type_original`
1. we return `idx` to Python
    - `idx` is an integer, so we can return this easily to Python using `f2py`
1. we then create a Python object with an API that mirrors `derived_type_original`
   using the class method `from_instance_index`.
   This class method is [TODO or will be] auto-generated via `pyfgen`
   and handles retrieval of all the attribute values of `derived_type_original`
   from Fortran and sets them on the Python object that is being instantiated
    - we can do this as, if you dig down deep enough, all attributes eventually
      become primitive types which can be passed back and forth using `f2py`,
      it can just be that multiple levels of recursion are needed
      if you have derived types that themselves have derived type attributes
1. we then call the manager [TODO I think this will end up being wrapper, we can tighten the language later]
   module's `finalise_instance_index` function to free the (temporary) instance
   that was used by the manager
    - this instance is no longer needed because all the data has been transferred to Python
1. we end up with a Python instance that has the result
   and no extra/leftover memory footprint in Fortran
   (and leave Fortran to decide whether to clean up `derived_type_original` or not)

Whenever we need to pass a derived type to Fortran, we:

[TODO think about passing multiple derived types at once]

1. call the manager [TODO I think this will end up being wrapper, we can tighten the language later]
   module's `get_free_instance_index` function to get an available index to use for the passing
1. call the manager [TODO I think this will end up being wrapper, we can tighten the language later]
   module's `build_instance` function with the index we just received
   plus all of the Python object's attribute values
    - on the Fortran side, there is now an instantiated derived type, ready for use
1. call the wrapped Fortran function of interest,
   except we pass the instance index instead of the derived type
1. on the Fortran side, retrieve the instantiated index from the manager module
   and use this to call the Fortran function/subroutine of interest
1. return the result from Fortran back to Python
1. call the manager [TODO I think this will end up being wrapper, we can tighten the language later]
   module's `finalise_instance_index` function to free the (temporary) instance
   that was used to pass the instance in the first place
    - this instance is no longer needed because all the data has been transferred and used by Fortran
1. we end up with the result of the Fortran callable back in Python
   and no extra/leftover memory footprint in Fortran from the instance created by the manager module

## Further background

We initially started this project and took quite a different route.
The reason was that we were actually solving a different problem.
What we were trying to do was to provide views into underlying Fortran instances.
For example, we wanted to enable the following:

```python
>>> from some_fortran_wrapper import SomeWrappedFortranDerivedType


>>> inst = SomeWrappedFortranDerivedType(value1=2, value2="hi")
>>> inst2 = inst
>>> inst.value1 = 5
>>> # Updating the view via `inst` also affects `inst2`
>>> inst2.value1
5
```

Supporting views like this introduces a whole bunch of headaches,
mainly due to consistency and memory management.

A first headache is consistency.
Consider the following, which is a common gotcha with numpy

```python
>>> import numpy as np
>>>
>>> a = np.array([1.2, 2.2, 2.5])
>>> b = a
>>> a[2] = 0.0
>>> # b has been updated too - many users don't expect this
>>> b
array([1.2, 2.2, 0. ])
```

The second is memory management.
For example, in the example above, if I delete variable `a`,
what should variable `b` become?

With numpy, it turns out that the answer is that `b` is unaffected

```python
>>> del a
>>> a
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name 'a' is not defined
>>> b
array([1.2, 2.2, 0. ])
```

However, we would argue that this is not the only possibility.
It could also be that `b` should become undefined,
as the underlying array it views has been deleted.
Doing it like this must also be very complicated for numpy,
as they need to keep track of how many references
there are to the array underlying the Python variables
to know whether to actually free the memory or not.

We don't want to solve these headaches,
which is why our solution does not support views,
instead only supporting the passing of data across the Python-Fortran interface
(which ensures that ownership is clear at all times
and normal Python rules apply in Python
(which doesn't mean there aren't gotchas, just that we won't introduce any new gotchas)).

## Other solutions we rejected

### Provide views rather than passing data

Note: this section was never properly finished.
Once we started trying to write it,
we realised how hard it would be to avoid weird edge cases
so we stopped and changed to [our current solution][Our solution]
(@Marco please check that this internal cross-reference works
once the docs are built).

To pass derived types back and forth across the Python-Fortran interface,
we introduce a 'manager' module for all derived types.
This manager module is responsible for managing derived type instances
that are passed across the Python-Fortran interface
and is needed because we can't pass them directly using f2py.

The manager module has two key components:

1. an allocatable array of instances of the derived type it manages
1. an allocatable array of logical (boolean) values

The array of instances are instances which the manager owns.
It holds onto these: can instantiate them, can make them have the same values
as results from Fortran functions etc.
(I think we need to decide whether this is an array of instances
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
