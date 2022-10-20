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

var audio: AVAudioPlayer?

class ViewController: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var startGameButton: UIButton!

    let score = BehaviorRelay(value: 0)
    let game = BehaviorRelay(value: false)
    let gameEndedTrigger = PublishRelay<Int>()
    let disposeBag = DisposeBag()

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
                self.spawnCoin()
                self.spawnCoin()
        })
            .disposed(by: disposeBag)

        // End game
        game
            .filter({value in
                !value
            })
            .subscribe(onNext: {game in
                self.gameEndedTrigger.accept(1)
        })
            .disposed(by: disposeBag)

        // Start game button tap
        startGameButton.rx.tap
            .bind(onNext: {
                self.game.accept(true)
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

        // Coin tap
        coin.rx.tap
            .take(1)
            .take(until: gameEndedTrigger)
            .withLatestFrom(self.game)
            .subscribe(onNext: {value in
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
            .take(until: gameEndedTrigger)
            .delay(.seconds(secondsToTap), scheduler: MainScheduler.instance)
            .take(until: coin.rx.tap)
            .subscribe(onNext: {value in
                self.game.accept(false)
            }, onDisposed: {
                print("Timer disposed")
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

