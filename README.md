# Bluffalo
Bluffalo allows you to do real mocking and stubbing in Swift.

## What does it do?
It generates a subclass of whatever class you want with some extra methods and properties that allow you to stub values and see what was called.

## Limitations
- Because this relies on subclassing, this will not work for stubs.
- Properties cannot be stubbed yet.

# Usage

## Generating a fake

```
bluffalo -file path/to/Cat.swift -outputFile path/to/FakeCat.swift -module containingModule
```

You should add the outputted file to your project. The command used to create the fake will be added as a comment to the top of the file. This will make it easier to regenerate your class if you change it.

## Using a fake
Lets say we have the following class
```
class Cat {
  func numberOfLives() -> Int {
    return 9
  }

  func meow(numberOfTimes: Int) {
    while i < numberOfTimes {
      print("Meow")
    }
  }
}
```


### Stubbing Values
```
let fakeCat = FakeCat()
print( fakeCat.numberOfLives() ) // prints 9
fakeCat.stub(.numberOfLives()).andReturn(4)
print( fakeCat.numberOfLives() ) // prints 4
```

### Mocking
```
let fakeCat = FakeCat()
let numberOfLives = fakeCat.numberOfLives()
fakeCat.meow(numberOfTimes: 5)

print( fakeCat.didCall(method: .numberOfLives()) ) // prints true
print( fakeCat.matchingMethods(.numberOfLives()) ) // prints 1

// Arguments matter
print( fakeCat.didCall(method: .meow(numberOfTimes: 5)) ) // prints true
print( fakeCat.didCall(method: .meow(numberOfTimes: 4)) ) // prints false
```
