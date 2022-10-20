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

class ViewController: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var startGameButton: UIButton!

    let score = BehaviorRelay(value: 0)
    let game = BehaviorRelay(value: false)
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

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

        // Start game
        game
            .filter({value in
                value
            })
            .subscribe(onNext: {game in
                self.score.accept(0)
                self.spawnCoin()
        })
            .disposed(by: disposeBag)

    }

    func spawnCoin() {
        let coin = UIButton(frame: CGRect(x: 150, y: 50, width: 60, height: 60))
        coin.setBackgroundImage(UIImage(named: "penny"), for: .normal)
        self.view.insertSubview(coin, at: 0)
        coin.rx.tap
            .debug()
            .withLatestFrom(self.game)
            .subscribe(onNext: {value in
                if value {
                    coin.removeFromSuperview()
                    self.score.accept(self.score.value + 1)
                    self.spawnCoin()
                }
            })
            .disposed(by: self.disposeBag)

        Observable<Int>
            .interval(.seconds(3), scheduler: MainScheduler.instance)
            .subscribe(onNext: {timePassed in
                
            })

    }

    @IBAction func buttonPress(_ sender: Any) {
        game.accept(true)
    }

}

