//
//  ViewController.swift
//  LeakPlayer
//
//  Created by John Kim on 11/20/23.
//

import UIKit
import UniformTypeIdentifiers



class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    // MARK: - Properties
    @IBOutlet var table: UITableView!
    var songs = [Song]()
    var filteredSongs = [Song]()
    let searchController = UISearchController(searchResultsController:  nil)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure
        table.delegate  = self
        table.dataSource = self
        loadSongs()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
                table.addGestureRecognizer(longPressGesture)
        
        // Configure Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Songs"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importAudioFile))
        
        
    }
    
    // MARK: - Data Handling
    func loadSongs() {
        // Load songs from UserDefaults or initialize default songs
        if let savedSongsData = UserDefaults.standard.object(forKey: "savedSongs") as? Data,
           let savedSongs = try? JSONDecoder().decode([Song].self, from: savedSongsData) {
            songs = savedSongs
        } else {
            // Load default songs if no saved data is available
            configureSongs()
        }
    }
    
    func saveSongs() {
        // save songs to UserDefaults
        if let encodedSongs = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(encodedSongs, forKey: "savedSongs")
        }
    }
    
    func configureSongs() {
        // initialize default song list
        songs.append(Song(name: "Believe Me",
                          albumName: "Leaked Uzi 2019",
                          artistName: "Lil Uzi Vert",
                          imageName: "cover1",
                          trackName: "song1"))
        songs.append(Song(name: "FAYC",
                          albumName: "Leaked Uzi 2019",
                          artistName: "Lil Uzi Vert",
                          imageName: "cover2",
                          trackName: "song2"))
        songs.append(Song(name: "Thought Back",
                          albumName: "Leaked Uzi 2019",
                          artistName: "Lil Uzi Vert",
                          imageName: "cover3",
                          trackName: "song3"))
        songs.append(Song(name: "Watch This",
                          albumName: "Leaked Uzi 2019",
                          artistName: "Lil Uzi Vert",
                          imageName: "cover4",
                          trackName: "song4"))
    }
    
    
    // MARK: - UI Interactions
    @objc func importAudioFile() {
        // Handle audio file import
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Set to true if you want to allow multiple file selections
        present(documentPicker, animated: true)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        // handle long press on table view cell
        if gesture.state == .began {
            let point = gesture.location(in: table)
            if let indexPath = table.indexPathForRow(at: point) {
                presentEditSongAlert(for: indexPath)
            }
        }
    }

    func presentEditSongAlert(for indexPath: IndexPath) {
        // present alert to edit song details
        let song = songs[indexPath.row]
        let alertController = UIAlertController(title: "Edit Song", message: "Update song details", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.text = song.name
        }
        alertController.addTextField { textField in
            textField.text = song.albumName
        }
        alertController.addTextField { textField in
            textField.text = song.artistName
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self, let newName = alertController.textFields?[0].text,
                  let newAlbum = alertController.textFields?[1].text,
                  let newArtist = alertController.textFields?[2].text else { return }

            // Update the song information
            self.songs[indexPath.row].name = newName
            self.songs[indexPath.row].albumName = newAlbum
            self.songs[indexPath.row].artistName = newArtist
            self.table.reloadRows(at: [indexPath], with: .automatic)
            saveSongs()
        }

        alertController.addAction(saveAction)
        present(alertController, animated: true)
    }
    
    func presentSongDetailsInput(fileURL: URL) {
        // present alert to input new song details
        let alertController = UIAlertController(title: "New Song", message: "Enter song details", preferredStyle: .alert)

        // Add text fields for song name, album name, and artist name
        alertController.addTextField { textField in
            textField.placeholder = "Song Name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Album Name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Artist Name"
        }

        // Add an action to handle the user input
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let songName = alertController.textFields?[0].text ?? "Unknown Song"
            let albumName = alertController.textFields?[1].text ?? "Unknown Album"
            let artistName = alertController.textFields?[2].text ?? "Unknown Artist"

            // Create the new song object
            let newSong = Song(name: songName, albumName: albumName, artistName: artistName, imageName: "defaultCover", trackName: fileURL.lastPathComponent)
            self.songs.append(newSong)
            self.table.reloadData()
            saveSongs()
        }

        alertController.addAction(addAction)
        present(alertController, animated: true)
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        // update search results based on search bar input
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredSongs = songs.filter { song in
                return song.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            filteredSongs = songs
        }
        table.reloadData()
    }

    // MARK: - UITableView DatasSource and Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows in the table
        return searchController.isActive ? filteredSongs.count : songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // configure and return a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = searchController.isActive ? filteredSongs[indexPath.row] : songs[indexPath.row]
        // configure
        
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.albumName
        cell.accessoryType = . disclosureIndicator
        cell.imageView?.image = UIImage(named: song.imageName)
        cell.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Helvetica", size: 17)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // set row height
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // handle selection of a table row
        tableView.deselectRow(at: indexPath, animated: true)
        
        // present the player
        let position = indexPath.row
        let selectedSongs = searchController.isActive ? filteredSongs : songs
        
        guard let vc = storyboard?.instantiateViewController(identifier: "player") as? PlayerViewController else {
            return
        }
        
        vc.songs = selectedSongs // Use the selectedSongs variable here
        vc.position = position
        
        present(vc, animated: true)
    }

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Determine which song to delete
            let songToDelete = searchController.isActive ? filteredSongs[indexPath.row] : songs[indexPath.row]

            // Delete the audio file from the document directory
            let fileManager = FileManager.default
            if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent(songToDelete.trackName)
                if fileManager.fileExists(atPath: fileURL.path) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("File deleted successfully.")
                    } catch {
                        print("Error deleting file: \(error)")
                    }
                }
            }

            // Remove the song from the data source
            if searchController.isActive {
                if let index = songs.firstIndex(where: { $0.name == songToDelete.name }) {
                    songs.remove(at: index)
                }
                filteredSongs.remove(at: indexPath.row)
            } else {
                songs.remove(at: indexPath.row)
            }

            // Update the table view
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveSongs()
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Handle the selection of a document
        guard let url = urls.first else { return }

        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

        // Check if file exists, if not, copy it
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: url, to: destinationURL)
                // Proceed to create a new Song object
                presentSongDetailsInput(fileURL: destinationURL)
            } catch {
                print("Error copying file: \(error)")
            }
        } else {
            print("File already exists at destination URL")
            // Handle the scenario where the file already exists
        }
    }
}

// MARK: - Song Structure
struct Song: Codable {
    var name: String
    var albumName: String
    var artistName: String
    var imageName: String
    var trackName: String
}

