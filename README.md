# RandomQueue

A queue adopting as dequeue policy a random approach: that is when dequeueing an element, it will randomly pick one from its stored elements.

`RandomQueue` is also an ordered, random-access collection, it basically presents the same interface and behavior of an array (including value semantics), but with the advantage of an amortized O(1) complexity for operations on the first position of its storage, rather than O(*n*) as arrays do.
A `RandomQueue` is a random queue, thus it'll dequeue elements in random order. 
To implement the random dequeue policy, everytime a dequeue operation is performed on a `RandomQueue` instance, its first element will be first swapped with another one stored at a different position. 

