import UIKit
import SnapKit

struct ServerResponse: Codable {
    let count: Int
    let name: String
    let country: [Country]
}

struct Country: Codable {
    let countryID: String
    let probability: Double
    
    enum CodingKeys: String, CodingKey {
        case countryID = "country_id"
        case probability
    }
    
    var flag: String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryID.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
}

class ViewController: UIViewController {
    let tableView = UITableView()
    var responseData: ServerResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureTableView()
        configureNavigationBar()
    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configureNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(buttonTapped))
        navigationItem.rightBarButtonItem = addButton
        navigationItem.title = "Узнать национальность"
    }
    
    @objc func buttonTapped() {
        let alertController = UIAlertController(title: "Узнать национальность", message: "Введите ваше имя", preferredStyle: .alert)
        alertController.addTextField()
        
        let addAction = UIAlertAction(title: "Узнать", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first else { return }
            let name = textField.text ?? ""
            
            if let url = URL(string: "https://api.nationalize.io/?name=\(name)") {
                let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        print("Error: \(error)")
                        return
                    }
                    
                    if let data = data {
                        let decoder = JSONDecoder()
                        if let decodedData = try? decoder.decode(ServerResponse.self, from: data) {
                            DispatchQueue.main.async {
                                self?.responseData = decodedData
                                self?.tableView.reloadData()
                            }
                        }
                    }
                }
                
                task.resume()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responseData?.country.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let country = responseData?.country[indexPath.row]
        
        cell.textLabel?.text = "\(country?.flag ?? "") Страна: \(country?.countryID ?? ""), Вероятность: \(country?.probability ?? 0.0)"
        
        return cell
    }
}
