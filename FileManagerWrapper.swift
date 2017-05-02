//
//  FileManagerWrapper.swift
//  MIT License
//
//  Copyright (c) 2017 Tushar Mohan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

typealias DictionaryLoadClosure = (Dictionary<String,Any>?) -> ()
typealias GenericLoadClosure    = (Data?) -> ()
typealias TextLoadClosure       = (String?) -> ()

enum FMDirectoryLevel:Comparable {
    case FMDirectoryLevelCache, FMDirectoryLevelDocuments
    
    static public func ==(x: FMDirectoryLevel, y: FMDirectoryLevel) -> Bool {
        return x.hashValue == y.hashValue
    }
    
    static public func <(x: FMDirectoryLevel, y: FMDirectoryLevel) -> Bool {
        return x.hashValue < y.hashValue
    }
}

enum FMContentType {
    case FMContentTypeDictionary, FMContentTypeGeneric, FMContentTypeText, FMContentTypeImage
    
    func getDirectoryRoot() -> String {
        let directoryRoot: String
        
        switch self {
        case .FMContentTypeDictionary:
            directoryRoot = "Dictionary"
        case .FMContentTypeGeneric:
            directoryRoot = "Generics"
        case .FMContentTypeText:
            directoryRoot = "Texts"
        case .FMContentTypeImage:
            directoryRoot = "Images"
        }
        
        return directoryRoot
    }
    
}

fileprivate extension String {
    
    func deleteLastPathComponent() -> String {
        return (URL(string:self)?.deletingLastPathComponent().path)!
    }
    
    mutating func deletePathExtension() -> String {
        return (URL(string:self)?.deletingPathExtension().path)!
    }
    
}

class FileManagerWrapper {
    class func save(dictionary:Dictionary<String,Any>, inCache:Bool, withName fileName:String, canOverride:Bool) {
        let directoryLevel: FMDirectoryLevel = inCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        let dictData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        guard let path = FileManagerWrapper.createFilePath(fileName: fileName, directoryLevel: directoryLevel, type: .FMContentTypeDictionary) else {return}
        
        let fileExistsAlready = (FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeDictionary) != nil)
        
        
        if FileManagerWrapper.canWriteToDisk(overrideAllowed: canOverride, fileExists: fileExistsAlready) {
            _ = FileManagerWrapper.saveFile(fileData: dictData, to: path)
        }
        
    }
    
    class func save(generic:Data, inCache:Bool, withName fileName:String, canOverride:Bool) {
        let directoryLevel: FMDirectoryLevel = inCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        guard let path = FileManagerWrapper.createFilePath(fileName: fileName, directoryLevel: directoryLevel, type: .FMContentTypeGeneric) else {return}
        
        let fileExistsAlready = (FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeGeneric) != nil)
        
        if FileManagerWrapper.canWriteToDisk(overrideAllowed: canOverride, fileExists: fileExistsAlready) {
            _ = FileManagerWrapper.saveFile(fileData: generic, to: path)
        }
        
    }
    
    class func save(text:String, inCache:Bool, withName fileName:String, canOverride:Bool) {
        let directoryLevel: FMDirectoryLevel = inCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        let textData = NSKeyedArchiver.archivedData(withRootObject: text)
        guard let path = FileManagerWrapper.createFilePath(fileName: fileName, directoryLevel: directoryLevel, type: .FMContentTypeText) else {return}
        
        let fileExistsAlready = (FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeText) != nil)
        
        if FileManagerWrapper.canWriteToDisk(overrideAllowed: canOverride, fileExists: fileExistsAlready) {
            _ = FileManagerWrapper.saveFile(fileData: textData, to: path)
        }
        
        
    }
    
    // MARK: - Reading From Disk
    
    class func loadDictionary(from fileName:String, fromCache isFromCache:Bool, onCompletion:DictionaryLoadClosure) {
        let directoryLevel: FMDirectoryLevel = isFromCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        
        guard let retreivedFileName = FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeDictionary) else {onCompletion(nil); return}
        
        let requiredDictionary: [String: Any]? = (NSKeyedUnarchiver.unarchiveObject(with: try! Data(contentsOf: URL(fileURLWithPath: retreivedFileName))) as? [String: Any])
        
        onCompletion(requiredDictionary!)
    }
    
    class func loadGeneric(from fileName:String, fromCache isFromCache:Bool, onCompletion:GenericLoadClosure) {
        let directoryLevel: FMDirectoryLevel = isFromCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        
        guard let retreivedFileName = FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeGeneric) else {onCompletion(nil); return}
        
        let requiredData = try? Data(contentsOf: URL(fileURLWithPath: retreivedFileName))
        
        onCompletion(requiredData!)
    }
    
    class func loadText(from fileName:String, fromCache isFromCache:Bool, onCompletion:TextLoadClosure) {
        let directoryLevel: FMDirectoryLevel = isFromCache ? .FMDirectoryLevelCache : .FMDirectoryLevelDocuments
        
        guard let retreivedFileName = FileManagerWrapper.fetchPathOf(fileName, from: directoryLevel, ofType: .FMContentTypeText) else {onCompletion(nil); return}
        
        let requiredText: String? = (NSKeyedUnarchiver.unarchiveObject(with: try! Data(contentsOf: URL(fileURLWithPath: retreivedFileName))) as? String)
        
        onCompletion(requiredText!)
    }
    
    // MARK: - Removing From Disk
    
    class func removeAllItems(from directory:FMDirectoryLevel) {
        let defaultFileManager = FileManager.default
        
        guard let filePath = FileManagerWrapper.getDirectoryFor(directory) else {return}
        
        try? defaultFileManager.removeItem(atPath: filePath)
        
    }
    
    class func removeResource(name: String, from level:FMDirectoryLevel, of type:FMContentType) {
        guard let filePath = FileManagerWrapper.fetchPathOf(name, from: level, ofType: type) else {return}
        try? FileManager.default.removeItem(atPath: filePath)
    }
    
    // MARK: - Utilities
    
    class func  fetchPathOf(_ fileName: String, from dir:FMDirectoryLevel, ofType type:FMContentType) ->String? {
        guard let filePath = FileManagerWrapper.createFilePath(fileName: fileName, directoryLevel: dir, type: type) else{return nil}
        
        let defaulFileManager = FileManager.default
        let isFileExisting = defaulFileManager.fileExists(atPath: filePath)
        let path: String?;
        
        if isFileExisting {
            path = filePath
        }
        else {
            path = nil
        }
        
        return path
    }
    
    // MARK: - Private Helpers
    
    class private func createFilePath(fileName:String, directoryLevel:FMDirectoryLevel, type:FMContentType) -> String? {
        let moddedFileName = fileName.replacingOccurrences(of: "/", with: "")
        
        guard let filePath =  FileManagerWrapper.getDirectoryFor(directoryLevel) else {return nil}
        
        let subDirectory = filePath.appending("/\(type.getDirectoryRoot())")
        
        return subDirectory.appending("/\(moddedFileName)")
    }
    
    class private func getDirectoryFor(_ level:FMDirectoryLevel) -> String? {
        guard let dirLevel = FileManagerWrapper.storageDirectoryWith(subPath: "Data",level: level) else {return nil}
        return dirLevel
    }
    
    class private func storageDirectoryWith(subPath:String, level:FMDirectoryLevel) -> String? {
        let pathsArray:[String];
        
        switch level {
        case .FMDirectoryLevelCache:
            pathsArray = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        case .FMDirectoryLevelDocuments:
            pathsArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            
        }
        
        guard pathsArray.count > 0 else {return nil}
        
        var directoryPath = pathsArray[0]
        directoryPath = directoryPath.appending("/\(subPath)")
        
        return directoryPath
    }
    
    class private func canWriteToDisk(overrideAllowed:Bool, fileExists:Bool) -> Bool {
        let writeLogicTuple = (overrideAllowed,fileExists)
        let canWriteToDisk: Bool
        
        switch writeLogicTuple {
        case (false,true):
            canWriteToDisk = false
        case (_,_):
            canWriteToDisk = true
        }
        
        return canWriteToDisk
    }
    
    // MARK: - Actual Writing to Disk
    
    class private func saveFile(fileData:Data, to path:String) -> Bool {
        let defaultFileManager = FileManager.default
        let dirPath = path.deleteLastPathComponent()
        if !defaultFileManager.fileExists(atPath: dirPath) {
            try? defaultFileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        do{
            try fileData.write(to:URL(fileURLWithPath:path),options:.atomic)
        }
        catch {
            Logger.error(error)
            return false
        }
        
        return true
    }
    
}
