import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreCRUDViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

   @IBOutlet weak var tableView: UITableView!
   var shows: [Show] = []

   override func viewDidLoad() {
       super.viewDidLoad()

       fetchShowsFromFirestore()
   }

   func fetchShowsFromFirestore() {
       let db = Firestore.firestore()
       db.collection("shows").getDocuments { (snapshot, error) in
           if let error = error {
               print("Error fetching documents: \(error)")
               return
           }

           var fetchedShows: [Show] = []

           for document in snapshot!.documents {
               let data = document.data()

               do {
                   var show = try Firestore.Decoder().decode(Show.self, from: data)
                   show.documentID = document.documentID // Set the documentID

                   fetchedShows.append(show)
               } catch {
                   print("Error decoding show data: \(error)")
               }
           }

           DispatchQueue.main.async {
               self.shows = fetchedShows
               self.tableView.reloadData()
           }
       }
   }

   // MARK: - UITableViewDataSource

   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return shows.count
   }

   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: "ShowCell", for: indexPath) as! ShowTableViewCell

       let show = shows[indexPath.row]

       cell.titleLabel?.text = show.title
       cell.genresLabel?.text = show.genres
       // cell.originalReleaseLabel?.text = show.originalRelease

       // Load and display the show image
       if let imageURL = URL(string: show.imageURL) {
           URLSession.shared.dataTask(with: imageURL) { data, response, error in
               if let data = data {
                   DispatchQueue.main.async {
                       cell.showImageView.image = UIImage(data: data)
                   }
               }
           }.resume()
       }

       return cell
   }

   // MARK: - Actions

   @IBAction func addButtonPressed(_ sender: UIButton) {
       performSegue(withIdentifier: "AddEditSegue", sender: nil)
   }

   // MARK: - Navigation

   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if segue.identifier == "AddEditSegue" {
           if let addEditVC = segue.destination as? AddEditShowViewController {
               addEditVC.showViewController = self
               if let indexPath = sender as? IndexPath {
                   let show = shows[indexPath.row]
                   addEditVC.show = show
               } else {
                   addEditVC.show = nil
               }

               addEditVC.showUpdateCallback = { [weak self] in
                   self?.fetchShowsFromFirestore()
               }
           }
       }
   }

   // MARK: - Helper Methods

   func showDeleteConfirmationAlert(for show: Show, completion: @escaping (Bool) -> Void) {
       let alert = UIAlertController(title: "Delete Show", message: "Are you sure you want to delete this show?", preferredStyle: .alert)

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
           completion(false)
       })

       alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
           completion(true)
       })

       present(alert, animated: true, completion: nil)
   }

   func deleteShow(at indexPath: IndexPath) {
       let show = shows[indexPath.row]

       guard let documentID = show.documentID else {
           print("Invalid document ID")
           return
       }

       let db = Firestore.firestore()
       db.collection("shows").document(documentID).delete { [weak self] error in
           if let error = error {
               print("Error deleting document: \(error)")
           } else {
               DispatchQueue.main.async {
                   print("Show deleted successfully.")
                   self?.shows.remove(at: indexPath.row)
                   self?.tableView.deleteRows(at: [indexPath], with: .fade)
               }
           }
       }
   }
}
