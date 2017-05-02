# iOS-FileManager-Swift
Learning Swift by writing Utils 😃

Currently has three types handled: JSON, Generic (Data) and Texts.

## Usage

``` swift
//Saving Resource
FileManagerWrapper.save(generic: dataToSave, inCache: true, withName: "GenericFileName", canOverride: true)

//Accessing Resource
FileManagerWrapper.loadGeneric(from: "GenericFileName", fromCache: true) { (dataFromFile:Data?) in
            guard let unwrappedDataFromFile = dataFromFile else {return}
            ...
        }

//Removing Resource
FileManagerWrapper.removeResource(name: "GenericFileName", from: .FMDirectoryLevelCache, of: .FMContentTypeGeneric)
```
TODO:- 🚧 Document and Clean Code 🚧
