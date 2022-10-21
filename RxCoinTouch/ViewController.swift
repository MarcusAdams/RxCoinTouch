//
//  ViewController.swift
//  RxCoinTouch
//
//  Created by marcus.adams on Oct-19-2022.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation

let imageSize = 95
let minY = 50
let paddingY = 10
let secondsToTap = 3
let coinCount = 2
let addCoinEvery = 100

var audio: AVAudioPlayer?

class ViewController: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var startGameButton: UIButton!

    let score = BehaviorRelay(value: 0)
    let game = BehaviorRelay(value: false)
    let gameEndedTrigger = PublishRelay<Int>()
    let disposeBag = DisposeBag()
    var timerDisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        prepareDing()

        gameOverLabel.isHidden = true

        // Bind the score to the score label
        score
            .map({value -> String in
            return String(value)
        })
            .bind(to: scoreLabel.rx.text)
            .disposed(by: disposeBag)

        // Bind visibilty of Start Game button to game Boolean
        game
            .bind(to: startGameButton.rx.isHidden)
            .disposed(by: disposeBag)

        // Bind visibility of Game Over label to game Boolean
        game
            .skip(until: startGameButton.rx.tap)
            .bind(to: gameOverLabel.rx.isHidden)
            .disposed(by: disposeBag)

        // Start game
        game
            .filter({value in
                value
            })
            .subscribe(onNext: {game in
                self.score.accept(0)
                self.clearCoins()
                for _ in 1...coinCount {
                    self.spawnCoin()
                }
        })
            .disposed(by: disposeBag)

        // End game
        game
            .filter({value in
                !value
            })
            .subscribe(onNext: {game in
                self.gameEndedTrigger.accept(1)
                self.timerDisposeBag = DisposeBag()
        })
            .disposed(by: disposeBag)

        // Start game button tap
        startGameButton.rx.tap
            .bind(onNext: {
                self.game.accept(true)
            })
            .disposed(by: disposeBag)

        score
            .subscribe(onNext: {score in
                if score > 0 && score % addCoinEvery == 0 {
                    self.spawnCoin()
                }
            })
            .disposed(by: disposeBag)

    }

    func clearCoins() {
        for view in self.view.subviews {
            if let view = view as? UIButton, view.backgroundImage(for: .normal) != nil {
                view.removeFromSuperview()
            }
        }
    }

    func spawnCoin() {
        // Random location
        let maxX = Int(self.view.bounds.width) - imageSize
        let maxY = Int(self.view.bounds.height) - imageSize - paddingY
        let x = Int.random(in: 0...maxX)
        let y = Int.random(in: minY...maxY)

        // Create coin button
        let coin = UIButton(frame: CGRect(x: x, y: y, width: imageSize, height: imageSize))
        coin.setBackgroundImage(UIImage(named: "penny"), for: .normal)
        self.view.insertSubview(coin, at: 0)

        let counter = UILabel(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        counter.textColor = .white
        counter.font = counter.font.withSize(60)
        counter.textAlignment = .center
        counter.text = "3"
        coin.addSubview(counter)

        // Coin tap
        coin.rx.tap
            .take(1)
            .take(until: gameEndedTrigger)
            .subscribe(onNext: {
                playDing()
                coin.removeFromSuperview()
                self.score.accept(self.score.value + 1)
                self.spawnCoin()
            }, onDisposed: {
                print("Coin disposed")
            })
            .disposed(by: disposeBag)

        // Coin timer
        Observable<Int>
            .just(1)
            .delay(.seconds(secondsToTap), scheduler: MainScheduler.instance)
            .take(until: coin.rx.tap)
            //.take(until: gameEndedTrigger) // Causes re-entry
            .subscribe(onNext: {value in
                if self.game.value {
                    counter.text = "0"
                    self.game.accept(false)
                }
            }, onDisposed: {
                print("Timer disposed")
            })
            .disposed(by: timerDisposeBag)

        // Coin counter
        Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(until: coin.rx.tap)
            .take(until: gameEndedTrigger)
            .subscribe(onNext: {timePassed in
                counter.text = String(2 - timePassed)
            })
            .disposed(by: disposeBag)
    }
}

func playDing() {
    audio?.currentTime = 0
    audio?.play()
}

func prepareDing() {
    guard let url = Bundle.main.url(forResource: "ding0", withExtension: "mp3") else { return }
    audio = try? AVAudioPlayer.init(contentsOf: url)
}

