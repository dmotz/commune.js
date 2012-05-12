# Commune.js
## Web workers lose their chains

### Intro
Commune.js makes it easy to run computationally heavy functions in a separate thread and retrieve the results asynchronously. By delegating these functions to a separate thread, you can avoid slowing down the main thread that affects the UI.

Using straightforward syntax, you can add web worker support to your app's functions without the need to create separate files (as web workers typically require) and without the need to change the syntax of your functions. Best of all, everything will work identically on browsers that do not support web workers.


### Usage
Here's an example where the first argument is the function to thread, the second argument is an array of arguments to pass to it, and the third is a callback to handle the result once it comes through:

```javascript
var heavyFunction = function(a, b, c){
    var num = 0;
    //do some work 100 million times
    for(var i = 0; i < 1e8; i++){
        a++;
        b++;
        c++;
    }
    //return arguments modified
    return [a, b, c];
}

commune(heavyFunction, [1, 2, 3], function(result){
    console.log(result); // [100000001, 100000002, 100000003]
});

//go ahead and continue with more work in the main thread without being held up:
console.log('I will appear before the above does.');

setTimeout(function(){
    console.log('I probably will too, depending on how fast your CPU is.');
}, 500);

```

In a browser that supports worker threads, the above will output:

```
I will appear before the above does.
I probably will too, depending on how fast your CPU is.
[100000001, 100000002, 100000003]
```

In a browser without web worker support, everything still works, just in a different order:

```
[100000001, 100000002, 100000003]
I will appear before the above does.
I probably will too, depending on how fast your CPU is.
```


### How It Works
When you pass a new function to Commune.js, it creates a modified version of the function using web worker syntax. Commune.js memoizes the result so additional calls using the same function don't have to be rewritten.

Just write your functions as you normally would using return statements.


### Caveats
Since web workers operate in a different context, you can't reference any variables outside of the function's scope (including the DOM) and you can't use references to `this` since it will refer to the worker itself. For functions you want to use Commune.js with, use a functional style where they return a modified version of their input.

Also, since this is an abstraction designed for ease-of-use and transparency, it does not work exactly as web workers do -- namely you can't have multiple return events from a single worker.

Commune.js is an early stage experiment so contributions and ideas are very welcome.
