![Bluffalo: Real Mocking In Swift](https://raw.githubusercontent.com/PeqNP/bluffalo/master/assets/bluffalo-with-text.png)

Bluffalo allows you to do real mocking and stubbing in Swift.

## What does it do?

It generates a fake subclass, from a Swift class or protocol, and allows you to stub and inspect which methods were called on the fake.

## Limitations

- Because this relies on subclassing, this will not work for stubs.
- Properties cannot be stubbed yet.

# Usage

## Generating a fake

```
bluffalo -f path/to/Cat.swift -o path/to/FakeCat.swift -m MyContainingModule
```

## Using a fake

Let's say we have the following class:

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
