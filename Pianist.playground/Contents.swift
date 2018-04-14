//: Welcome to Pianist.playground! Play around with this interactive piano and see what you can come up with. Need some inspiration? Open up the songs menu on the right and select from any of the included songs to play!

//: Entry by Kyle Johnson for WWDC 2018.

import UIKit
import PlaygroundSupport

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // primary views
    var piano: Piano! // container for all keys
    var keys = [Key]()  // 24 total (10 black, 14 white)
    var notesView: NotesView! // container for all rising notes
    
    // secondary views
    var header: Header! // "Entry by Kyle Johnson"
    var titleText: Title! // "Pianist.playground"
    var menu: Menu! // contains songs list
    
    // who doesn't love pastel?
    let colors = [ #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), #colorLiteral(red: 0.5568627715, green: 0.5, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1), #colorLiteral(red: 0.8156862745, green: 0.7853227123, blue: 0.6800557263, alpha: 1) ]
    
    // song related
    var songs = [String]()
    var sortedKeys = [Key]()
    var songList: UITableView!
    var selectedRow: IndexPath?
    var selectedSong: String?
    var currentSong: Song?
    
    // directions
    var welcome: UIImageView!
    var arrow: UIImageView!

    override func loadView() {
        let view = UIView()

        piano = Piano()
        view.addSubview(piano)
        
        // 10 black keys
        for i in 0..<10 {
            let key = BlackKey(index: i)
            piano.addSubview(key)
            keys.append(key)
        }
        
        // 14 white keys
        for i in 0..<14 {
            let key = WhiteKey(index: i)
            piano.addSubview(key)
            keys.append(key)
        }
        
        notesView = NotesView()
        header = Header()
        titleText = Title()
        menu = Menu()
        
        view.addSubview(notesView)
        view.addSubview(header)
        view.addSubview(titleText)
        view.addSubview(menu)
        
        // store keys by id for O(1) access
        sortedKeys = keys.sorted(by: { $0.id < $1.id })

        self.view = view
        
        // auto-populate songs and setup images
        populateSongs()
        setupImages()
    }
    
    func populateSongs() {
        let songURLs = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Songs")!
        for url in songURLs {
            let full = url.lastPathComponent
            // trim off extension
            let lastIndex = full.index(full.endIndex, offsetBy: -4)
            let song = String(full[..<lastIndex])
            songs.append(song)
            songs.sort()
        }
    }
    
    func setupImages() {
        arrow = UIImageView(image: UIImage(named: "Images/arrow"))
        arrow.frame = CGRect(x: 250, y: 50, width: 120, height: 120)
        view.addSubview(arrow)
        
        welcome = UIImageView(image: UIImage(named: "Images/welcome"))
        welcome.frame = CGRect(x: 104, y: 335, width: 160, height: 60)
        view.addSubview(welcome)
        
        UIView.animate(withDuration: 1.5, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.welcome.transform = CGAffineTransform(translationX: 0, y: 10)
        }, completion: nil)
    }
    
    func hideWelcomeImage() {
        UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
            self.welcome.alpha = 0
        }, completion: { _ in
            self.welcome.removeFromSuperview()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            // check for key touches
            let touchPt = touch.location(in: piano)
            for key in keys {
                if key.frame.contains(touchPt) {
                    key.activateKey()
                    break
                }
            }
            
            // opening and closing songs menu
            let menuPt = touch.location(in: menu)
            if menu.chevron.frame.contains(menuPt) {
                if menu.isShowing {
                    menu.retract()
                } else {
                    menu.reveal()
                }
            } else {
                // also retract if clicking outside menu bounds
                if menu.isShowing && menu.content.frame.contains(menuPt) == false {
                    menu.retract()
                }
            }
            
            // choosing a song to play
            let contentPt = touch.location(in: menu.content)
            if menu.playSong.frame.contains(contentPt) {
                if selectedRow == nil {
                    menu.playSong.backgroundColor = UIColor.lightGray
                } else {
                    let color = selectedRow!.row % 7
                    menu.playSong.backgroundColor = colors[color]

                    if currentSong == nil || currentSong?.isPlaying == false {
                        if menu.setupSong() {
                            // retract menu if song is successfully loaded
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                                self.menu.retract()
                            })
                        }
                    }
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchPt = touch.location(in: piano)
            var activeKey: Key? = nil
            
            // check for movements through keys
            for key in keys {
                if key.frame.contains(touchPt) {
                    key.activateKey()
                    activeKey = key
                    break
                }
            }
            for key in keys {
                if key.isActive && activeKey != key {
                    key.deactivateKey()
                    break
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchPt = touch.location(in: piano)
            
            // check for key releases
            for key in keys {
                if key.frame.contains(touchPt) {
                    key.deactivateKey()
                    break
                }
            }
            
            // songs menu touch events
            let menuPt = touch.location(in: menu)
            if currentSong == nil || currentSong!.isPlaying || menu.playSong.frame.contains(menuPt) == false {
                menu.playSong.backgroundColor = UIColor.white
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow,
            indexPathForSelectedRow == indexPath {
            tableView.deselectRow(at: indexPath, animated: false)
            selectedRow = nil
            selectedSong = nil
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath
        selectedSong = songs[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = vc.songList.dequeueReusableCell(withIdentifier: "Song", for: indexPath)
        cell.textLabel?.text = songs[indexPath.row]
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        cell.textLabel?.numberOfLines = 0
        
        let color = indexPath.row % 7
        cell.backgroundColor = colors[color]
        cell.textLabel?.highlightedTextColor = colors[color]
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black
        cell.selectedBackgroundView = selectedView
        
        return cell
    }
}

/// Container for all piano keys.
class Piano: UIView {
    init() {
        let f = CGRect(x: 0, y: 400, width: 368, height: 100)
        super.init(frame: f)
        
        self.layer.backgroundColor = UIColor.black.cgColor
        self.layer.zPosition = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Basic key superclass. White and black keys inherit from here.
class Key: UIView {
    
    var id: Int
    var color: Int
    var isBlack: Bool
    var isActive: Bool
    
    let colorsW = [ #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), #colorLiteral(red: 0.5568627715, green: 0.5, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1), #colorLiteral(red: 0.8156862745, green: 0.7853227123, blue: 0.6800557263, alpha: 1) ]
    let colorsB = [ #colorLiteral(red: 0.2002224392, green: 0.3964301215, blue: 0.4489746094, alpha: 1), #colorLiteral(red: 0.2336968316, green: 0.2266438802, blue: 0.4402126736, alpha: 1), #colorLiteral(red: 0.4311794705, green: 0.1903211806, blue: 0.2878960503, alpha: 1), #colorLiteral(red: 0.4797092014, green: 0.3942599826, blue: 0.2457953559, alpha: 1), #colorLiteral(red: 0.3425835503, green: 0.408203125, blue: 0.2745225694, alpha: 1) ]
    
    init(frame: CGRect, _ id: Int, _ color: Int, _ isBlack: Bool) {
        self.id = id
        self.color = color
        self.isBlack = isBlack
        self.isActive = false
        
        super.init(frame: frame)
    }
    
    func activateKey() {
        guard self.isActive == false else { return }
        
        self.backgroundColor = isBlack ? colorsB[color] : colorsW[color]
        self.isActive = true
        
        // play sound for key (sound files are fixed length for performance sake)
        let soundPath = Bundle.main.path(forResource: "key\(self.id)", ofType: "wav", inDirectory: "Sounds")!
        let soundURL = URL(fileURLWithPath: soundPath)
        Sound.play(url: soundURL)
        
        // spawn note at key position
        let note = Note(key: self)
        vc.notesView.addSubview(note)
        
        // hide welcome image after first key is activated
        if vc.welcome.superview != nil && vc.welcome.alpha == 1 {
            vc.hideWelcomeImage()
        }
    }
    
    func deactivateKey() {
        guard self.isActive else { return }
        
        self.backgroundColor = isBlack ? UIColor.black : UIColor.white
        self.isActive = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The black keys (10 total).
class BlackKey: Key {
    
    var indices = [2, 4, 6, 9, 11, 14, 16, 18, 21, 23]
    var offsets = [0, 1, 2, 4, 5, 7, 8, 9, 11, 12]
    
    init(index: Int) {
        let id = indices[index]
        let color = index % 5
        
        let f = CGRect(x: 19 + (offsets[index] * 26), y: 4, width: 18, height: 55)
        super.init(frame: f, id, color, true)
        
        self.layer.backgroundColor = UIColor.black.cgColor
        self.layer.zPosition = 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The white keys (14 total).
class WhiteKey: Key {
    
    var indices = [1, 3, 5, 7, 8, 10, 12, 13, 15, 17, 19, 20, 22, 24]
    
    init(index: Int) {
        let id = indices[index]
        let color = index % 7
        
        let f = CGRect(x: 4 + (index * 26), y: 4, width: 22, height: 92)
        super.init(frame: f, id, color, false)
        
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.zPosition = 3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Container for all note views.
class NotesView: UIView {
    init() {
        let f = CGRect(x: 0, y: 0, width: 368, height: 400)
        super.init(frame: f)

        // for fade away effect
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 50, width: 368, height: 350)
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0, 0.5]
        self.layer.mask = gradient
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Notes that rise from the piano keys when pressed.
class Note: UIView {
    
    var key: Key
    
    init(key: Key) {
        self.key = key
        
        let f = CGRect(x: key.frame.origin.x, y: key.frame.origin.y + 398, width: key.frame.width, height: 20)
        super.init(frame: f)

        self.backgroundColor = key.backgroundColor
        
        // prevent blending of overlapping notes with divider
        let divider = UIView()
        divider.frame = CGRect(x: 0, y: -2, width: self.frame.width, height: 2)
        divider.backgroundColor = UIColor.black
        self.addSubview(divider)

        // animate note upwards
        UIView.animate(withDuration: 10, delay: 0, options: .curveLinear, animations: {
            self.frame.origin.y -= 500
        }, completion: { _ in
            UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        })
        
        // increase note length as key is held
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.185) {
            self.increaseNoteLength()
        }
    }
    
    func increaseNoteLength() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.185) {
            if self.key.isActive {
                var f = self.frame
                f.size.height += 10
                self.frame = f
                self.increaseNoteLength()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Song object created from chosen file.
class Song {
    
    var notes: [String]
    var index = 0
    var isPlaying = false
    
    init(song: String) {
        let trimmedSong = song.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = trimmedSong.components(separatedBy: .newlines)
    }
    
    func play() {
        
        // set true at beginning of song
        if self.isPlaying == false {
            self.isPlaying = true
        }
        
        /*  loop through all notes in selected song file
            - id = the key to play (1-24), 0 = rest
            - length = how long the note should be held (1 = quarter note, 4 = whole note, fractions allowed)
        */
        if index < notes.count {
            let tokens = notes[index].components(separatedBy: ":")
            let id = Int(tokens[0])!
            let length = Double(tokens[1])!
            index += 1
            
            if id == 0 {
                // rest
                DispatchQueue.main.asyncAfter(deadline: .now() + length * 0.4) {
                    self.play()
                }
            } else {
                vc.sortedKeys[id-1].activateKey()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + (length - 1) * 0.4) {
                    vc.sortedKeys[id-1].deactivateKey()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // play the next key
                        self.play()
                    }
                }
            }
        } else {
            // set false at end of song
            self.isPlaying = false
            vc.currentSong = nil
        }
    }
    
    // displays song title before playing
    func showTitle() {
        let songTitle = UILabel()
        songTitle.frame = CGRect(x: 40, y: 215, width: 288, height: 150)
        songTitle.font = UIFont.systemFont(ofSize: 40, weight: .light)
        songTitle.text = "\"\(vc.selectedSong!)\""
        songTitle.textColor = UIColor.white
        songTitle.numberOfLines = 0
        songTitle.textAlignment = .center
        vc.view.addSubview(songTitle)
        songTitle.alpha = 0
        
        // fade in and slide up title, then fade out
        UIView.animate(withDuration: 2, animations: {
            songTitle.alpha = 1
            songTitle.frame.origin.y -= 50
        }, completion: { _ in
            UIView.animate(withDuration: 1, delay: 1.5, options: [], animations: {
                songTitle.alpha = 0
                songTitle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }, completion: { _ in
                songTitle.removeFromSuperview()
            })
        })
    }
}

/// The white credits bar at the top of the playground view.
class Header: UIView {

    init() {
        let f = CGRect(x: 0, y: 0, width: 368, height: 25)
        super.init(frame: f)
        
        self.backgroundColor = UIColor.white
        
        let credits = UILabel(frame: CGRect(x: 0, y: -1, width: 362, height: 25))
        credits.text = "Entry by Kyle Johnson"
        credits.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.light)
        credits.textAlignment = .right
        self.addSubview(credits)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The "Pianist.playground" text in the top left corner.
class Title: UIView {
    
    init() {
        let f = CGRect(x: 14, y: 35, width: 120, height: 65)
        super.init(frame: f)

        let title = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        
        // NSMutableAttributedString used to color each individual character
        let pianistText = "Pianist"
        var mutableText = NSMutableAttributedString()
        mutableText = NSMutableAttributedString(string: pianistText, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.light)])
        
        // match each character to a different color
        for i in 0..<vc.colors.count {
            mutableText.addAttribute(NSAttributedStringKey.foregroundColor, value: vc.colors[i], range: NSRange(location: i, length: 1))
        }
        
        title.attributedText = mutableText
        self.addSubview(title)
        
        // larger dot for aesthetics
        let dot = UIView(frame: CGRect(x: 0, y: 54, width: 3, height: 3))
        dot.backgroundColor = UIColor.white
        dot.layer.cornerRadius = 1.5
        self.addSubview(dot)
        
        let playgroundText = UILabel(frame: CGRect(x: 5, y: 38, width: 120, height: 25))
        playgroundText.text = "playground"
        playgroundText.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.light)
        playgroundText.textColor = UIColor.white
        self.addSubview(playgroundText)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The side menu containing preset songs to play from.
class Menu: UIView {

    var chevron: UIView
    var content: UIView
    var playSong: UIView
    
    // true if menu is revealed
    var isShowing = false

    init() {
        chevron = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        chevron.backgroundColor = UIColor.darkGray
        chevron.layer.cornerRadius = 5
        
        let icon = UILabel(frame: CGRect(x: 4, y: 0, width: 30, height: 60))
        icon.text = "♩" // +1 for unicode!
        icon.textColor = UIColor.white
        chevron.addSubview(icon)
        
        content = UIView(frame: CGRect(x: 24, y: 0, width: 150, height: 238))
        content.backgroundColor = UIColor.gray
        
        playSong = UIView(frame: CGRect(x: 25, y: 202, width: 80, height: 25))
        playSong.backgroundColor = UIColor.white
        playSong.layer.cornerRadius = 10
        content.addSubview(playSong)
        
        let playText = UILabel()
        playText.frame = CGRect(x: 0, y: 0, width: 80, height: 25)
        playText.text = "Play Song"
        playText.font = UIFont.boldSystemFont(ofSize: 12)
        playText.textAlignment = .center
        playSong.addSubview(playText)
        
        let f = CGRect(x: 344, y: 37, width: 522, height: 238)
        super.init(frame: f)
        
        self.addSubview(chevron)
        self.addSubview(content)
        
        let visualizeText = UILabel(frame: CGRect(x: 12, y: 6, width: 110, height: 40))
        visualizeText.text = "Select a song to visualize!"
        visualizeText.font = UIFont.boldSystemFont(ofSize: 14)
        visualizeText.numberOfLines = 0
        visualizeText.textColor = UIColor.white
        content.addSubview(visualizeText)
        
        // table view holding available songs to play from
        vc.songList = UITableView(frame: CGRect(x: 10, y: 52, width: 110, height: 140))
        vc.songList.delegate = vc
        vc.songList.dataSource = vc
        vc.songList.register(UITableViewCell.self, forCellReuseIdentifier: "Song")
        vc.songList.separatorStyle = .none
        content.addSubview(vc.songList)
        
        self.layer.zPosition = 1
    }

    func reveal() {
        self.isShowing = true
        
        // hide welcome image if not already hidden
        if vc.welcome.superview != nil && vc.welcome.alpha == 1 {
            vc.hideWelcomeImage()
        }
        
        // this spring effect is so cool...
        UIView.animate(withDuration: 1, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 8, options: .curveEaseInOut, animations: {
             self.frame.origin.x -= 130
        }, completion: { _ in
            if vc.arrow.superview != nil {
                vc.arrow.removeFromSuperview()
            }
        })
    }

    func retract() {
        self.isShowing = false
        
        // I LOVE IT SO MUCH
        UIView.animate(withDuration: 1, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 8, options: .curveEaseInOut, animations: {
            self.frame.origin.x += 130
        }, completion: { _ in
            self.deselectSong()
        })
    }
    
    func deselectSong() {
        if let selectedRow = vc.selectedRow {
            vc.songList.deselectRow(at: selectedRow, animated: false)
            vc.selectedRow = nil
            self.playSong.backgroundColor = UIColor.white
        }
    }
    
    func setupSong() -> Bool {
        if let songFile = Bundle.main.path(forResource: vc.selectedSong, ofType: "txt", inDirectory: "Songs") {
            do {
                // only play if no other song is playing
                guard vc.currentSong == nil else { return false }
                
                let contents = try String(contentsOfFile: songFile)
                let song = Song(song: contents)
                vc.currentSong = song
                
                // display name of song before starting
                song.showTitle()
                
                // start the song after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    song.play()
                }
                return true
                
            } catch {
                print("Error loading contents of song.")
                return false
            }
        } else {
            print("Specified song could not be found.")
            return false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Present the view controller in the Live View window
let vc = ViewController()
vc.preferredContentSize = CGSize(width: 368, height: 500)
PlaygroundPage.current.liveView = vc

// My goal was to keep this under 700 lines.
// Just made it. ✅
