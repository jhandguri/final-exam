import UIKit
import Firebase

class AddEditShowViewController: UIViewController {

   // UI References
   @IBOutlet weak var AddEditTitleLabel: UILabel!
   @IBOutlet weak var UpdateButton: UIButton!

   // Show Fields
   @IBOutlet weak var imageView: UIImageView!
   @IBOutlet weak var titleLabel: UITextField!
   @IBOutlet weak var genresLabel: UITextField!
   @IBOutlet weak var creatorsLabel: UITextField!
   @IBOutlet weak var composersLabel: UITextField!
   @IBOutlet weak var descriptionTextView: UITextView!
   @IBOutlet weak var castLabel: UITextField!
   @IBOutlet weak var languageLabel: UITextField!
   @IBOutlet weak var networkLabel: UITextField!
   @IBOutlet weak var seasonsLabel: UITextField!
   @IBOutlet weak var episodesLabel: UITextField!
   @IBOutlet weak var originalReleaseLabel: UITextField!
   @IBOutlet weak var imageURLLabel: UITextField!

   var show: Show?
   var showViewController: FirestoreCRUDViewController?
   var showUpdateCallback: (() -> Void)?

   override func viewDidLoad() {
       super.viewDidLoad()

       if let show = show {
           // Editing existing show
           titleLabel.text = show.title
           genresLabel.text = show.genres
           creatorsLabel.text = show.creators
           composersLabel.text = show.composers
           descriptionTextView.text = show.description
           castLabel.text = show.cast
           languageLabel.text = show.language
           networkLabel.text = show.network
           seasonsLabel.text = show.seasons
           episodesLabel.text = show.episodes
           originalReleaseLabel.text = show.originalRelease
           imageURLLabel.text = show.imageURL

           AddEditTitleLabel.text = "Edit Show"
           UpdateButton.setTitle("Update", for: .normal)

           if let imageURL = URL(string: show.imageURL) {
               URLSession.shared.dataTask(with: imageURL) { data, response, error in
                   if let data = data {
                       DispatchQueue.main.async {
                           self.imageView.image = UIImage(data: data)
                       }
                   }
               }.resume()
           }
       } else {
           AddEditTitleLabel.text = "Add Show"
           UpdateButton.setTitle("Add", for: .normal)
       }
   }

   @IBAction func cancelButtonPressed(_ sender: UIButton) {
       dismiss(animated: true, completion: nil)
   }

   @IBAction func updateButtonPressed(_ sender: UIButton) {
       guard
           let title = titleLabel.text,
           let genres = genresLabel.text,
           let creators = creatorsLabel.text,
           let composers = composersLabel.text,
           let description = descriptionTextView.text,
           let cast = castLabel.text,
           let language = languageLabel.text,
           let network = networkLabel.text,
           let seasons = seasonsLabel.text,
           let episodes = episodesLabel.text,
           let originalRelease = originalReleaseLabel.text,
           let imageURL = imageURLLabel.text else {
           print("Invalid data")
           return
       }

       let showData = Show(
           title: title,
           genres: genres,
           creators: creators,
           composers: composers,
           description: description,
           cast: cast,
           language: language,
           network: network,
           seasons: seasons,
           episodes: episodes,
           imageURL: imageURL,
           originalRelease: originalRelease
           //imageURL: imageURL
       )

       let db = Firestore.firestore()

       if let show = show {
           // Update existing show
           guard let documentID = show.documentID else {
               print("Document ID not available.")
               return
           }

           let showRef = db.collection("shows").document(documentID)
           showRef.updateData([
               "title": showData.title,
               "genres": showData.genres,
               "creators": showData.creators,
               "composers": showData.composers,
               "description": showData.description,
               "cast": showData.cast,
               "language": showData.language,
               "network": showData.network,
               "seasons": showData.seasons,
               "episodes": showData.episodes,
               "originalRelease": showData.originalRelease,
               "imageURL": showData.imageURL
           ]) { [weak self] error in
               if let error = error {
                   print("Error updating show: \(error)")
               } else {
                   print("Show updated successfully.")
                   self?.dismiss(animated: true) {
                       self?.showUpdateCallback?()
                   }
               }
           }
       } else {
           // Add new show
           db.collection("shows").addDocument(data: [
               "title": showData.title,
               "genres": showData.genres,
               "creators": showData.creators,
               "composers": showData.composers,
               "description": showData.description,
               "cast": showData.cast,
               "language": showData.language,
               "network": showData.network,
               "seasons": showData.seasons,
               "episodes": showData.episodes,
               "originalRelease": showData.originalRelease,
               "imageURL": showData.imageURL
           ]) { [weak self] error in
               if let error = error {
                   print("Error adding show: \(error)")
               } else {
                   print("Show added successfully.")
                   self?.dismiss(animated: true) {
                       self?.showUpdateCallback?()
                   }
               }
           }
       }
   }
}
