//
//  ViewController.swift
//  RxCoinTouch
//
//  Created by marcus.adams on Oct-19-2022.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import AVFoundation

let imageSize = 60
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
    let disposeBag = DisposeBag()
    var timerDisposeBag = DisposeBag()
    var coinDisposeBag = DisposeBag()

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
                self.timerDisposeBag = DisposeBag()
                self.coinDisposeBag = DisposeBag()
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
        let maxX = Int(self.view.bounds.width) - imageSize
        let maxY = Int(self.view.bounds.height) - imageSize - paddingY
        let x = Int.random(in: 0...maxX)
        let y = Int.random(in: minY...maxY)
        let coin = UIButton(frame: CGRect(x: x, y: y, width: imageSize, height: imageSize))
        coin.setBackgroundImage(UIImage(named: "penny"), for: .normal)
        self.view.insertSubview(coin, at: 0)
        coin.rx.tap
            .take(1)
            .withLatestFrom(self.game)
            .subscribe(onNext: {value in
                if value {
                    playDing()
                    coin.removeFromSuperview()
                    self.score.accept(self.score.value + 1)
                    self.spawnCoin()
                }
            })
            .disposed(by: self.disposeBag)

        Observable<Int>
            .just(1)
            .delay(.seconds(secondsToTap), scheduler: MainScheduler.instance)
            .take(until: coin.rx.tap)
            .subscribe(onNext: {value in
                self.game.accept(false)
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

