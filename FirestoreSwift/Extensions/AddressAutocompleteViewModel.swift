//
//  AddressAutocompleteViewModel.swift
//  FirestoreSwift
//
//  Created by Kamran Alison on 9/10/24.
//

import SwiftUI
import MapKit

class AddressAutocompleteViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var queryFragment: String = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching: Bool = false
    
    private var completer: MKLocalSearchCompleter
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        self.completer.resultTypes = .address
        super.init()
        self.completer.delegate = self
    }
    
    func updateSearchResults(for query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        completer.queryFragment = query
        isSearching = true
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        isSearching = !completer.results.isEmpty
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error in address autocomplete: \(error.localizedDescription)")
        searchResults = []
        isSearching = false
    }
    
    func selectCompletion(_ completion: MKLocalSearchCompletion, completionHandler: @escaping (MKPlacemark?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let error = error {
                print("Error in search: \(error.localizedDescription)")
                completionHandler(nil)
                return
            }
            guard let placemark = response?.mapItems.first?.placemark else {
                completionHandler(nil)
                return
            }
            // After selection, clear search results and stop searching
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
            completionHandler(placemark)
        }
    }
}
