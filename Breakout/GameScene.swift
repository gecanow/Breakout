//
//  GameScene.swift
//  Breakout
//
//  Created by Necanow on 7/11/18.
//  Copyright © 2018 EcaKnowGames. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var ball = SKShapeNode()
    var paddle = SKSpriteNode()
    var bricks = [SKSpriteNode]()
    var loseZone = SKSpriteNode()
    
    let defaults = UserDefaults.standard
    var scores = [0,0]
    
    override func didMove(to view: SKView) {
        createBackground()
        makeLoseZone()
        start()
        
        physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        if let savedData = defaults.object(forKey: "scoreArr") as? Data {
            if let decoded = try? JSONDecoder().decode([Int].self, from: savedData) {
                scores = decoded
            }
        }
    }
    
    func start() {
        for y in stride(from: frame.maxY - 30, to: frame.maxY - 150, by: -30) {
            for x in stride(from: -frame.maxX + 30, to: frame.width - 30, by: 70) {
                makeBrick(xCord: Int(x), yCord: Int(y))
            }
        }
        makePaddle()
        makeBall()
        ball.physicsBody?.isDynamic = true
        
        ball.physicsBody?.applyImpulse(CGVector(dx: 3, dy: 5))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            paddle.position.x = location.x
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            paddle.position.x = location.x
        }
    }
    
    func createBackground() {
        let stars = SKTexture(imageNamed: "galaxy")
        for i in 0...1 {
            let starsBackground = SKSpriteNode(texture: stars)
            starsBackground.zPosition = -1
            starsBackground.position = CGPoint(x: 0, y: starsBackground.size.height * CGFloat(i))
            addChild(starsBackground)
            let moveDown = SKAction.moveBy(x: 0, y: -starsBackground.size.height, duration: 20)
            let moveReset = SKAction.moveBy(x: 0, y: starsBackground.size.height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            starsBackground.run(moveForever)
        }
    }
    
    func makeBall() {
        ball = SKShapeNode(circleOfRadius: 10)
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        ball.strokeColor = UIColor.black
        ball.fillColor = UIColor.blue
        ball.name = "ball"
        
        // physics shape matches ball image
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        // ignores all forces and impulses
        ball.physicsBody?.isDynamic = false
        // use precise collision detection
        ball.physicsBody?.usesPreciseCollisionDetection = true
        // no loss of energy from friction
        ball.physicsBody?.friction = 0
        // gravity is not a factor
        ball.physicsBody?.affectedByGravity = false
        // bounces fully off of other objects
        ball.physicsBody?.restitution = 1
        // does not slow down over time
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.contactTestBitMask = (ball.physicsBody?.collisionBitMask)!
        
        addChild(ball) // add ball object to the view
    }
    
    func makePaddle() {
        paddle = SKSpriteNode(color: UIColor.white, size: CGSize(width: frame.width/4, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + 125)
        paddle.name = "paddle"
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        addChild(paddle)
    }

    func makeBrick(xCord: Int, yCord: Int) {
        let brick = SKSpriteNode(color: UIColor.red, size: CGSize(width: 50, height: 20))
        brick.position = CGPoint(x: xCord, y: yCord)
        brick.name = "brick"
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.isDynamic = false
        bricks.append(brick)
        addChild(brick)
    }
    
    func makeLoseZone() {
        loseZone = SKSpriteNode(color: UIColor.black, size: CGSize(width: frame.width, height: 50))
        loseZone.position = CGPoint(x: frame.midX, y: frame.minY + 25)
        loseZone.name = "loseZone"
        loseZone.physicsBody = SKPhysicsBody(rectangleOf: loseZone.size)
        loseZone.physicsBody?.isDynamic = false
        addChild(loseZone)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var maybeBrick : SKSpriteNode?
        if contact.bodyA.node?.name == "brick" {
            maybeBrick = contact.bodyA.node as? SKSpriteNode
        } else if contact.bodyB.node?.name == "brick" {
            maybeBrick = contact.bodyB.node as? SKSpriteNode
        } else {}
        
        if maybeBrick != nil {
            if maybeBrick?.color == .red {
                maybeBrick?.color = .orange
            } else if maybeBrick?.color == .orange {
                maybeBrick?.color = .yellow
            } else if maybeBrick?.color == .yellow {
                maybeBrick?.color = .white
            } else {
                bricks.remove(at: bricks.index(of: maybeBrick!)!)
                maybeBrick?.removeFromParent()
                
                if bricks.isEmpty {
                    endGame(scoreIndex: 0, message: "You Win!")
                }
            }
        }
        if contact.bodyA.node?.name == "loseZone" ||
            contact.bodyB.node?.name == "loseZone" {
            endGame(scoreIndex: 1, message: "You Lose.")
        }
    }
    
    func endGame(scoreIndex: Int, message: String) {
        ball.removeFromParent()
        paddle.removeFromParent()
        displayEndingMessage(message)
        scores[scoreIndex] += 1
        saveData()
    }
    
    func displayEndingMessage(_ str: String) {
        let alert = UIAlertController(title: str, message: "", preferredStyle: .alert)
        
        let restart = UIAlertAction(title: "Play Again", style: .default) { (void) in
            self.start()
        }
        alert.addAction(restart)
        
        let quit = UIAlertAction(title: "Quit", style: .cancel) { (void) in
            exit(0)
        }
        alert.addAction(quit)
        
        self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(scores) {
            defaults.set(encoded, forKey: "scoreArr")
        }
    }
}
