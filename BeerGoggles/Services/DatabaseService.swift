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

  static let shared = DatabaseService()

  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "BeerGoggles")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

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

  func save(beers: [BeerJson], image: UUID) -> Promise<Void, Error> {
    let promiseSource = PromiseSource<Void, Error>()

    persistentContainer.performBackgroundTask { ctx in
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
        model.label = beer.label
        model.rating_score = beer.rating_score ?? 0
        return model
      }

      let match = SessionModel(context: ctx)
      match.beers = Set(beerModels) as NSSet
      match.captureDate = Date()
      match.imageGuid = image

      do {
        try ctx.save()
      } catch {
        return promiseSource.reject(error)
      }

      promiseSource.resolve(())
    }

    return promiseSource.promise
  }

  func add(beers: [BeerJson], id: UUID) -> Promise<Void, Error> {
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
          model.label = beer.label
          model.rating_score = beer.rating_score ?? 0
          return model
        }

        let request: NSFetchRequest<SessionModel> = SessionModel.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(SessionModel.imageGuid), id.uuidString)

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