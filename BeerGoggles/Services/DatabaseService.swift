//
//  DatabaseService.swift
//  BeerGoggles
//
//  Created by Tomas Harkema on 04-11-17.
//  Copyright © 2017 Tomas Harkema. All rights reserved.
//

import Foundation
import CoreData
import Promissum

class DatabaseService {

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "BeerGoggles")
    container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
      if let error = error {
        if let url = storeDescription.url {
          try? FileManager.default.removeItem(at: url)
          container.loadPersistentStores(completionHandler: { _,_ in })
        } else {
          fatalError("Derp \(error)")
        }
      }
    })
    
    return container
  }()

  init() {
    try? migratePhotos()
  }
  
  func migrate(storeDescription: NSPersistentStoreDescription, error: CocoaError) {
    print(storeDescription)
    
    do {
      
      try migratePhotos()
      
      if let url = storeDescription.url {
        try FileManager.default.removeItem(at: url)
      }
      
    } catch {
      fatalError("Error: \(error)")
    }
  }
  
  private func migratePhotos() throws {
    let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let files = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
    
    print(files)
    print(files)
    
    try files.forEach {
      let data = try Data(contentsOf: $0)
      try intitialOnMain(identifier: SessionIdentifier(), imageData: data)
      try FileManager.default.removeItem(at: $0)
    }
    try persistentContainer.viewContext.save()
  }
  
  func sessions() -> Promise<[Session], Error> {
    let promiseSource = PromiseSource<[Session], Error>()

    persistentContainer.performBackgroundTask { ctx in
      let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
      request.sortDescriptors = [NSSortDescriptor(key: #keyPath(SessionModel.captureDate), ascending: false)]
      do {
        promiseSource.resolve(try ctx.fetch(request).flatMap {
          Session(model: $0)
        })
      } catch {
        return promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }
  
  private func initialBlocking(on ctx: NSManagedObjectContext, identifier: SessionIdentifier, imageData: Data?) throws -> SessionModel {
    let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
    request.predicate = NSPredicate(format: "%K == %@", #keyPath(SessionModel.identifier), identifier.rawValue.uuidString)
    
    let match = (try ctx.fetch(request).first) ?? SessionModel(context: ctx)
    match.beers = NSSet()
    match.captureDate = Date()
    match.identifier = identifier.rawValue.uuidString
    match.possibles = []
    match.done = false
    if let data = imageData {
      match.image = data
    }
    
    try ctx.save()
    return match
  }
  
  func intitialOnMain(identifier: SessionIdentifier, imageData: Data? = nil) throws -> SessionModel {
    return try initialBlocking(on: persistentContainer.viewContext, identifier: identifier, imageData: imageData)
  }
  
  func initial(identifier: SessionIdentifier, imageData: Data?) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()
    
    persistentContainer.performBackgroundTask { ctx in
      do {
        _ = try self.initialBlocking(on: ctx, identifier: identifier, imageData: imageData)
        return promiseSource.resolve(())
      } catch {
        return promiseSource.reject(error)
      }
    }
    
    return promiseSource.promise
  }
  
  func save(beers: [BeerJson], identifier: SessionIdentifier, imageData: Data? = nil) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()

    persistentContainer.performBackgroundTask { ctx in
      do {
        let beerModels = beers.map { (beer: BeerJson) -> BeerModel in
          let model = BeerModel(context: ctx)
          model.id = Int64(beer.id)
          model.bid = beer.bid.map { Int64($0) } ?? -1
          model.name = beer.name
          model.brewery = beer.brewery
          model.full_name = beer.full_name
          model.abv = beer.abv
          model.ibu = Int64(beer.ibu)
          model.style = beer.style
          model.beerDescription = beer.description
          model.label = beer.label.absoluteString
          model.rating_score = beer.rating_score ?? 0
          return model
        }
        
        let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(SessionModel.identifier), identifier.rawValue.uuidString)
        
        let match = (try ctx.fetch(request).first) ?? SessionModel(context: ctx)
        match.beers = Set(beerModels) as NSSet
        match.captureDate = Date()
        match.identifier = identifier.rawValue.uuidString
        match.possibles = []
        match.done = true
        if let data = imageData {
          match.image = data
        } else if match.image == nil && imageData == nil {
          assertionFailure("ImageData should be set by now...")
        }
      
        try ctx.save()
        promiseSource.resolve(())
      } catch {
        return promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

  func add(possibles: [String], identifier: SessionIdentifier) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()
    
    persistentContainer.performBackgroundTask { ctx in
      do {
        let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(SessionModel.identifier), identifier.rawValue.uuidString)
        
        if let result = try ctx.fetch(request).first {
          result.possibles = possibles as NSArray
        }
        
        try ctx.save()
        return promiseSource.resolve(())
      } catch {
        return promiseSource.reject(error)
      }
    }
    return promiseSource.promise
  }
  
  func add(beers: [BeerJson], identifier: SessionIdentifier) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()

    persistentContainer.performBackgroundTask { ctx in
      do {

        let beerModels = try beers.map { (beer: BeerJson) -> BeerModel in

          let fetch: NSFetchRequest<BeerModel> = BeerModel.fetchRequest()
          fetch.predicate = NSPredicate(format: "%K == %i", #keyPath(BeerModel.bid), beer.bid ?? -1)
          let oldBeer = try ctx.fetch(fetch).first

          let model = oldBeer ?? BeerModel(context: ctx)
          model.id = Int64(beer.id)
          model.bid = beer.bid.map { Int64($0) } ?? -1
          model.name = beer.name
          model.brewery = beer.brewery
          model.full_name = beer.full_name
          model.abv = beer.abv
          model.ibu = Int64(beer.ibu)
          model.style = beer.style
          model.beerDescription = beer.description
          model.label = beer.label.absoluteString
          model.rating_score = beer.rating_score ?? 0
          return model
        }

        let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(SessionModel.identifier), identifier.rawValue.uuidString)

        if let result = try ctx.fetch(request).first {
          result.addToBeers(Set(beerModels) as NSSet)
        }
        try ctx.save()
        return promiseSource.resolve(())
      } catch {
        return promiseSource.reject(error)
      }
    }

    return promiseSource.promise
  }

}
