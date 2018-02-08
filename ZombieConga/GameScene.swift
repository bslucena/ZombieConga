//
//  GameScene.swift
//  ZombieConga
//
//  Created by Bernardo Sarto de Lucena on 1/25/18.
//  Copyright © 2018 Bernardo Sarto de Lucena. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: Proprties
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        
        // You create an array that will store all of the textures to run in the animation.
        var textures: [SKTexture] = []
        
        // The animation frames are named zombie1.png, zombie2.png, zombie3.png and zombie4.png. This makes it easy to fashion a loop that creates a string for each image name and then makes a texture object from each name using the SKTexture(imageNamed:) initializer. The first for loop adds frames 1 to 4, which is most of the “forward walk”.
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        // This adds frames 3 and 2 to the list — remember, the textures array is 0-based. In total, the textures array now contains the frames in this or
        textures.append(textures[2])
        textures.append(textures[1])
        // Once you have the array of textures, running the animation is easy — you simply create and run an action with animate(with:timePerFrame:).
        zombieAnimation = SKAction.animate(with: textures,
                                           timePerFrame: 0.1)
        
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "background1")
        //z position is the order in which the nodes are drawn
        background.zPosition = -1
        addChild(background)
        
        //let mySize = background.size
        //print("Size: \(mySize)")
        //background.zRotation = CGFloat.pi/8
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        
        zombie.position = CGPoint(x: 400, y: 400)
        //zombie.setScale(2)
        addChild(zombie)
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        
        // spawn enemies
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run {
            [weak self] in
                self?.spawnEnemy()
            }, SKAction.wait(forDuration: 2.0)])))
        
        // spawn cats
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCat()
                },
                               SKAction.wait(forDuration: 1.0)])))
        
        debugDrawPlayableArea()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0 }
        lastUpdateTime = currentTime
        
        //print("\(dt*1000) milliseconds since last update")
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
                zombie.position = lastTouchLocation
                velocity = CGPoint.zero
                stopZombieAnimation()
            } else {
                move(sprite: zombie, velocity: velocity)
                rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            }
        }
        
        boundsCheckZombie()
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckZombie() {
        
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        let actionMove =
            SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
   
    // starts the zombie animation.
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(
                SKAction.repeatForever(zombieAnimation),
                withKey: "animation")
        }
        
    }
    
    // tops the zombie animation by removing the action with the key “animation”.
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    func spawnCat() {
        // You create a cat at a random spot inside the playable rectangle. You set the cat’s scale to 0, which makes the cat effectively invisible
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        // You create an action to scale the cat up to normal size by calling scale(to:duration:). This action isn’t reversible, so you also create a similar action to scale the cat back down to 0. In sequence, the cat appears, waits for a bit, disappears and is then removed from the parent.
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        let wait = SKAction.wait(forDuration: 10.0)
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, wait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
}
