//
//  GameScene.swift
//  HelloGit
//
//  Castlevania-style side-scrolling game with turtle enemies
//

import SpriteKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let hero:       UInt32 = 0b1        // 1
    static let ground:     UInt32 = 0b10       // 2
    static let enemy:      UInt32 = 0b100      // 4
    static let projectile: UInt32 = 0b1000     // 8
    static let platform:   UInt32 = 0b10000    // 16
}

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Nodes
    private var hero: SKNode!
    private var worldNode: SKNode!
    private var cameraNode: SKCameraNode!
    private var hudNode: SKNode!

    // MARK: - Background layers for parallax
    private var bgLayer1: SKNode! // far mountains
    private var bgLayer2: SKNode! // near hills
    private var bgLayer3: SKNode! // ground decorations

    // MARK: - Game State
    private var isOnGround = true
    private var isGameOver = false
    private var score = 0
    private var lives = 3
    private var isAttacking = false
    private var heroFacingRight = true
    private var lastUpdateTime: TimeInterval = 0
    private var scrollSpeed: CGFloat = 120.0
    private var heroSpeed: CGFloat = 200.0
    private var jumpImpulse: CGFloat = 480.0
    private var isMovingLeft = false
    private var isMovingRight = false

    // MARK: - HUD Labels
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!

    // MARK: - Level Generation
    private var lastGroundX: CGFloat = 0
    private var lastEnemySpawnX: CGFloat = 0
    private var groundSegmentWidth: CGFloat = 200
    private var groundHeight: CGFloat = 60
    private var totalWorldWidth: CGFloat = 0

    // MARK: - Whip Attack
    private var whipNode: SKNode?

    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: -18)
        physicsWorld.contactDelegate = self

        setupWorldNode()
        setupParallaxBackground()
        setupGround()
        setupHero()
        setupCamera()
        setupHUD()
        setupControls()
        spawnInitialEnemies()

        // Atmospheric moon
        let moon = SKShapeNode(circleOfRadius: 30)
        moon.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.7, alpha: 0.8)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: size.width * 0.8, y: size.height * 0.85)
        moon.zPosition = -90
        addChild(moon)
    }

    private func setupWorldNode() {
        worldNode = SKNode()
        worldNode.name = "world"
        addChild(worldNode)
    }

    // MARK: - Parallax Background
    private func setupParallaxBackground() {
        bgLayer1 = SKNode()
        bgLayer1.zPosition = -80
        addChild(bgLayer1)

        bgLayer2 = SKNode()
        bgLayer2.zPosition = -60
        addChild(bgLayer2)

        // Far mountains (dark purple silhouettes)
        for i in 0..<20 {
            let mountain = createMountain(
                width: CGFloat.random(in: 200...400),
                height: CGFloat.random(in: 100...200),
                color: SKColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 1.0)
            )
            mountain.position = CGPoint(
                x: CGFloat(i) * 300 - 200,
                y: groundHeight - 10
            )
            bgLayer1.addChild(mountain)
        }

        // Near hills (darker silhouettes)
        for i in 0..<30 {
            let hill = createMountain(
                width: CGFloat.random(in: 100...200),
                height: CGFloat.random(in: 50...120),
                color: SKColor(red: 0.1, green: 0.03, blue: 0.18, alpha: 1.0)
            )
            hill.position = CGPoint(
                x: CGFloat(i) * 180 - 100,
                y: groundHeight - 5
            )
            bgLayer2.addChild(hill)
        }

        // Scattered stars
        for _ in 0..<60 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.3...1.0))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.4...size.height)
            )
            star.zPosition = -95
            addChild(star)

            // Twinkle animation
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 1...3)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 1...3))
            ])
            star.run(SKAction.repeatForever(fade))
        }
    }

    private func createMountain(width: CGFloat, height: CGFloat, color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width / 2, y: 0))
        path.addLine(to: CGPoint(x: -width * 0.2, y: height * 0.7))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.6))
        path.addLine(to: CGPoint(x: width / 2, y: 0))
        path.closeSubpath()

        let mountain = SKShapeNode(path: path)
        mountain.fillColor = color
        mountain.strokeColor = .clear
        return mountain
    }

    // MARK: - Ground
    private func setupGround() {
        let totalSegments = 40
        for i in 0..<totalSegments {
            let segment = createGroundSegment(at: CGFloat(i) * groundSegmentWidth)
            worldNode.addChild(segment)

            // Add some decorative elements on ground
            if Int.random(in: 0...3) == 0 {
                let gravestone = createGravestone()
                gravestone.position = CGPoint(
                    x: CGFloat(i) * groundSegmentWidth + CGFloat.random(in: 20...180),
                    y: groundHeight + 12
                )
                worldNode.addChild(gravestone)
            }

            // Occasional torches on posts
            if Int.random(in: 0...5) == 0 {
                let torch = createTorch()
                torch.position = CGPoint(
                    x: CGFloat(i) * groundSegmentWidth + CGFloat.random(in: 40...160),
                    y: groundHeight + 40
                )
                worldNode.addChild(torch)
            }
        }
        totalWorldWidth = CGFloat(totalSegments) * groundSegmentWidth
        lastGroundX = totalWorldWidth
    }

    private func createGroundSegment(at xPos: CGFloat) -> SKNode {
        let segment = SKNode()

        // Main ground block
        let ground = SKSpriteNode(color: SKColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1.0), size: CGSize(width: groundSegmentWidth, height: groundHeight))
        ground.position = CGPoint(x: xPos + groundSegmentWidth / 2, y: groundHeight / 2)

        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        ground.physicsBody?.friction = 0.8
        segment.addChild(ground)

        // Ground surface detail - stone brick pattern
        let surfaceLine = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.22, blue: 0.15, alpha: 1.0),
            size: CGSize(width: groundSegmentWidth, height: 4)
        )
        surfaceLine.position = CGPoint(x: xPos + groundSegmentWidth / 2, y: groundHeight)
        surfaceLine.zPosition = 1
        segment.addChild(surfaceLine)

        // Brick lines on ground
        for row in 0..<3 {
            let lineY = CGFloat(row) * 20 + 10
            let brickLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: xPos, y: lineY))
            path.addLine(to: CGPoint(x: xPos + groundSegmentWidth, y: lineY))
            brickLine.path = path
            brickLine.strokeColor = SKColor(red: 0.2, green: 0.12, blue: 0.08, alpha: 0.6)
            brickLine.lineWidth = 1
            segment.addChild(brickLine)
        }

        return segment
    }

    private func createGravestone() -> SKNode {
        let stone = SKNode()

        let body = SKShapeNode(rectOf: CGSize(width: 14, height: 20), cornerRadius: 3)
        body.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.42, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.32, alpha: 1.0)
        body.lineWidth = 1
        stone.addChild(body)

        // Cross on gravestone
        let crossV = SKSpriteNode(color: SKColor(red: 0.5, green: 0.5, blue: 0.52, alpha: 1.0), size: CGSize(width: 2, height: 8))
        crossV.position = CGPoint(x: 0, y: 3)
        stone.addChild(crossV)

        let crossH = SKSpriteNode(color: SKColor(red: 0.5, green: 0.5, blue: 0.52, alpha: 1.0), size: CGSize(width: 6, height: 2))
        crossH.position = CGPoint(x: 0, y: 5)
        stone.addChild(crossH)

        stone.zPosition = 2
        return stone
    }

    private func createTorch() -> SKNode {
        let torch = SKNode()

        // Post
        let post = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 1.0),
            size: CGSize(width: 4, height: 40)
        )
        torch.addChild(post)

        // Flame
        let flame = SKShapeNode(ellipseOf: CGSize(width: 8, height: 12))
        flame.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.9)
        flame.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.7)
        flame.position = CGPoint(x: 0, y: 24)
        flame.glowWidth = 3
        torch.addChild(flame)

        // Flame animation
        let flicker = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 0.8, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        flame.run(SKAction.repeatForever(flicker))

        // Light glow
        let glow = SKShapeNode(circleOfRadius: 30)
        glow.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.08)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 24)
        torch.addChild(glow)

        torch.zPosition = 3
        return torch
    }

    // MARK: - Hero (Castlevania-style Vampire Hunter)
    private func setupHero() {
        hero = SKNode()
        hero.name = "hero"
        hero.position = CGPoint(x: 150, y: groundHeight + 40)
        hero.zPosition = 10

        // Body (dark armor)
        let body = SKShapeNode(rectOf: CGSize(width: 18, height: 28), cornerRadius: 2)
        body.fillColor = SKColor(red: 0.15, green: 0.1, blue: 0.3, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.5, alpha: 1.0)
        body.lineWidth = 1
        body.name = "heroBody"
        hero.addChild(body)

        // Chest armor plate
        let chestPlate = SKShapeNode(rectOf: CGSize(width: 14, height: 12), cornerRadius: 1)
        chestPlate.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.4, alpha: 1.0)
        chestPlate.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.6, alpha: 0.8)
        chestPlate.lineWidth = 1
        chestPlate.position = CGPoint(x: 0, y: 2)
        hero.addChild(chestPlate)

        // Head
        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor = SKColor(red: 0.9, green: 0.75, blue: 0.6, alpha: 1.0)
        head.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.4, alpha: 1.0)
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 22)
        hero.addChild(head)

        // Hair (flowing, brown - classic Belmont style)
        let hairPath = CGMutablePath()
        hairPath.move(to: CGPoint(x: -8, y: 22))
        hairPath.addCurve(to: CGPoint(x: -12, y: 10),
                          control1: CGPoint(x: -12, y: 28),
                          control2: CGPoint(x: -14, y: 16))
        hairPath.addLine(to: CGPoint(x: -6, y: 18))
        hairPath.addCurve(to: CGPoint(x: -10, y: 6),
                          control1: CGPoint(x: -10, y: 14),
                          control2: CGPoint(x: -12, y: 10))
        hairPath.addLine(to: CGPoint(x: -4, y: 16))

        let hair = SKShapeNode(path: hairPath)
        hair.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        hair.strokeColor = SKColor(red: 0.3, green: 0.18, blue: 0.05, alpha: 1.0)
        hair.lineWidth = 1
        hero.addChild(hair)

        // Eyes
        let leftEye = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -3, y: 23)
        hero.addChild(leftEye)

        let leftPupil = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
        leftPupil.fillColor = SKColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: -2, y: 23)
        hero.addChild(leftPupil)

        let rightEye = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 3, y: 23)
        hero.addChild(rightEye)

        let rightPupil = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
        rightPupil.fillColor = SKColor(red: 0.2, green: 0.1, blue: 0.0, alpha: 1.0)
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 4, y: 23)
        hero.addChild(rightPupil)

        // Cape (red, classic Belmont look)
        let capePath = CGMutablePath()
        capePath.move(to: CGPoint(x: -6, y: 14))
        capePath.addLine(to: CGPoint(x: -14, y: -14))
        capePath.addQuadCurve(to: CGPoint(x: -4, y: -16), control: CGPoint(x: -10, y: -18))
        capePath.addLine(to: CGPoint(x: -2, y: -4))
        capePath.closeSubpath()

        let cape = SKShapeNode(path: capePath)
        cape.fillColor = SKColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1.0)
        cape.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.8)
        cape.lineWidth = 1
        cape.name = "cape"
        cape.zPosition = -1
        hero.addChild(cape)

        // Boots
        let leftBoot = SKShapeNode(rectOf: CGSize(width: 8, height: 6), cornerRadius: 1)
        leftBoot.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        leftBoot.strokeColor = .clear
        leftBoot.position = CGPoint(x: -5, y: -17)
        hero.addChild(leftBoot)

        let rightBoot = SKShapeNode(rectOf: CGSize(width: 8, height: 6), cornerRadius: 1)
        rightBoot.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.05, alpha: 1.0)
        rightBoot.strokeColor = .clear
        rightBoot.position = CGPoint(x: 5, y: -17)
        hero.addChild(rightBoot)

        // Whip (coiled at side when not attacking)
        let whipCoil = SKShapeNode(circleOfRadius: 4)
        whipCoil.fillColor = SKColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)
        whipCoil.strokeColor = SKColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 0.8)
        whipCoil.position = CGPoint(x: 10, y: 0)
        whipCoil.name = "whipCoil"
        hero.addChild(whipCoil)

        // Belt with cross buckle
        let belt = SKSpriteNode(
            color: SKColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0),
            size: CGSize(width: 20, height: 3)
        )
        belt.position = CGPoint(x: 0, y: -6)
        hero.addChild(belt)

        let buckle = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
        buckle.fillColor = SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0)
        buckle.strokeColor = .clear
        buckle.position = CGPoint(x: 0, y: -6)
        hero.addChild(buckle)

        // Physics body
        hero.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 40), center: CGPoint(x: 0, y: 0))
        hero.physicsBody?.categoryBitMask = PhysicsCategory.hero
        hero.physicsBody?.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.enemy | PhysicsCategory.platform
        hero.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform
        hero.physicsBody?.allowsRotation = false
        hero.physicsBody?.friction = 0.2
        hero.physicsBody?.restitution = 0.0
        hero.physicsBody?.mass = 0.5

        worldNode.addChild(hero)
    }

    // MARK: - Camera
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }

    // MARK: - HUD
    private func setupHUD() {
        hudNode = SKNode()
        hudNode.zPosition = 100
        cameraNode.addChild(hudNode)

        // Score
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 35)
        scoreLabel.text = "SCORE: 0"
        hudNode.addChild(scoreLabel)

        // Lives
        livesLabel = SKLabelNode(fontNamed: "Courier-Bold")
        livesLabel.fontSize = 18
        livesLabel.fontColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: size.width / 2 - 20, y: size.height / 2 - 35)
        livesLabel.text = "LIVES: 3"
        hudNode.addChild(livesLabel)

        // Title
        let titleLabel = SKLabelNode(fontNamed: "Courier-Bold")
        titleLabel.fontSize = 14
        titleLabel.fontColor = SKColor(red: 0.6, green: 0.5, blue: 0.8, alpha: 0.7)
        titleLabel.position = CGPoint(x: 0, y: size.height / 2 - 35)
        titleLabel.text = "CASTLE HUNTER"
        hudNode.addChild(titleLabel)
    }

    // MARK: - Controls
    private func setupControls() {
        // Left button
        let leftBtn = createButton(name: "leftBtn", symbol: "<", position: CGPoint(x: -size.width / 2 + 55, y: -size.height / 2 + 50))
        hudNode.addChild(leftBtn)

        // Right button
        let rightBtn = createButton(name: "rightBtn", symbol: ">", position: CGPoint(x: -size.width / 2 + 120, y: -size.height / 2 + 50))
        hudNode.addChild(rightBtn)

        // Jump button
        let jumpBtn = createButton(name: "jumpBtn", symbol: "JUMP", position: CGPoint(x: size.width / 2 - 130, y: -size.height / 2 + 50))
        jumpBtn.children.first?.run(SKAction.scale(to: 1.1, duration: 0))
        hudNode.addChild(jumpBtn)

        // Attack / Whip button
        let attackBtn = createButton(name: "attackBtn", symbol: "WHIP", position: CGPoint(x: size.width / 2 - 55, y: -size.height / 2 + 50))
        hudNode.addChild(attackBtn)
    }

    private func createButton(name: String, symbol: String, position: CGPoint) -> SKNode {
        let btn = SKNode()
        btn.name = name
        btn.position = position
        btn.zPosition = 110

        let bg = SKShapeNode(circleOfRadius: 30)
        bg.fillColor = SKColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 0.7)
        bg.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.7, alpha: 0.8)
        bg.lineWidth = 2
        bg.name = name
        btn.addChild(bg)

        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.fontSize = symbol.count > 1 ? 12 : 20
        label.fontColor = SKColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.text = symbol
        label.name = name
        btn.addChild(label)

        return btn
    }

    // MARK: - Turtle Enemies
    private func spawnInitialEnemies() {
        let spawnPositions: [CGFloat] = [500, 900, 1300, 1800, 2200, 2800, 3300, 3900, 4500, 5100,
                                          5600, 6100, 6700, 7200, 7800]
        for xPos in spawnPositions {
            spawnTurtle(at: CGPoint(x: xPos, y: groundHeight + 18))
        }
        lastEnemySpawnX = 7800
    }

    private func spawnTurtle(at position: CGPoint) {
        let turtle = SKNode()
        turtle.name = "turtle"
        turtle.position = position
        turtle.zPosition = 8

        // Shell (main body - green dome)
        let shellPath = CGMutablePath()
        shellPath.move(to: CGPoint(x: -14, y: -4))
        shellPath.addQuadCurve(to: CGPoint(x: 14, y: -4), control: CGPoint(x: 0, y: 18))
        shellPath.addLine(to: CGPoint(x: -14, y: -4))
        shellPath.closeSubpath()

        let shell = SKShapeNode(path: shellPath)
        shell.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.15, alpha: 1.0)
        shell.strokeColor = SKColor(red: 0.05, green: 0.35, blue: 0.1, alpha: 1.0)
        shell.lineWidth = 2
        turtle.addChild(shell)

        // Shell pattern (hexagonal-ish lines)
        let patternPath = CGMutablePath()
        patternPath.move(to: CGPoint(x: -7, y: -2))
        patternPath.addLine(to: CGPoint(x: -4, y: 8))
        patternPath.addLine(to: CGPoint(x: 4, y: 8))
        patternPath.addLine(to: CGPoint(x: 7, y: -2))

        let pattern = SKShapeNode(path: patternPath)
        pattern.strokeColor = SKColor(red: 0.05, green: 0.3, blue: 0.08, alpha: 0.7)
        pattern.lineWidth = 1
        pattern.fillColor = .clear
        turtle.addChild(pattern)

        // Belly (lighter underside)
        let belly = SKShapeNode(rectOf: CGSize(width: 24, height: 6), cornerRadius: 2)
        belly.fillColor = SKColor(red: 0.6, green: 0.55, blue: 0.3, alpha: 1.0)
        belly.strokeColor = SKColor(red: 0.45, green: 0.4, blue: 0.2, alpha: 0.8)
        belly.position = CGPoint(x: 0, y: -6)
        turtle.addChild(belly)

        // Head
        let head = SKShapeNode(circleOfRadius: 5)
        head.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.25, alpha: 1.0)
        head.strokeColor = SKColor(red: 0.2, green: 0.45, blue: 0.15, alpha: 0.8)
        head.position = CGPoint(x: 16, y: 0)
        turtle.addChild(head)

        // Evil red eyes
        let eye = SKShapeNode(circleOfRadius: 2)
        eye.fillColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 1.0)
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 18, y: 2)
        eye.glowWidth = 1
        turtle.addChild(eye)

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -14, y: -2))
        tailPath.addLine(to: CGPoint(x: -20, y: 0))
        tailPath.addLine(to: CGPoint(x: -14, y: -5))

        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.25, alpha: 1.0)
        tail.strokeColor = .clear
        turtle.addChild(tail)

        // Legs
        for (lx, ly) in [(-8, -10), (-3, -10), (3, -10), (8, -10)] as [(CGFloat, CGFloat)] {
            let leg = SKShapeNode(rectOf: CGSize(width: 4, height: 5), cornerRadius: 1)
            leg.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.25, alpha: 1.0)
            leg.strokeColor = .clear
            leg.position = CGPoint(x: lx, y: CGFloat(ly))
            turtle.addChild(leg)
        }

        // Physics
        turtle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 28, height: 20), center: CGPoint(x: 0, y: -2))
        turtle.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        turtle.physicsBody?.contactTestBitMask = PhysicsCategory.hero | PhysicsCategory.projectile
        turtle.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform
        turtle.physicsBody?.allowsRotation = false
        turtle.physicsBody?.friction = 1.0
        turtle.physicsBody?.mass = 0.3

        // Patrol behavior: walk back and forth
        turtle.userData = NSMutableDictionary()
        turtle.userData?["direction"] = -1 // start moving left
        turtle.userData?["patrolStart"] = position.x - 60
        turtle.userData?["patrolEnd"] = position.x + 60

        // Waddle animation
        let waddle = SKAction.sequence([
            SKAction.rotate(toAngle: 0.05, duration: 0.3),
            SKAction.rotate(toAngle: -0.05, duration: 0.3)
        ])
        turtle.run(SKAction.repeatForever(waddle))

        worldNode.addChild(turtle)
    }

    // MARK: - Whip Attack
    private func performWhipAttack() {
        guard !isAttacking && !isGameOver else { return }
        isAttacking = true

        // Hide coiled whip
        hero.childNode(withName: "whipCoil")?.isHidden = true

        let direction: CGFloat = heroFacingRight ? 1 : -1

        // Create whip extending from hero
        let whip = SKNode()
        whip.name = "whip"
        whip.zPosition = 9

        // Whip segments (chain-like)
        let whipLength: CGFloat = 60
        let segments = 8
        for i in 0..<segments {
            let segX = direction * (CGFloat(i) * whipLength / CGFloat(segments) + 12)
            let segSize: CGFloat = i == segments - 1 ? 5 : 3
            let seg = SKShapeNode(circleOfRadius: segSize)
            seg.fillColor = i == segments - 1 ?
                SKColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0) : // tip is metallic
                SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0)  // leather
            seg.strokeColor = .clear
            seg.position = CGPoint(x: segX, y: CGFloat.random(in: -2...6))
            whip.addChild(seg)
        }

        // Whip physics (hitbox at the tip)
        let whipTipX = direction * (whipLength + 8)
        let hitbox = SKNode()
        hitbox.position = CGPoint(x: whipTipX, y: 2)
        hitbox.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 16))
        hitbox.physicsBody?.isDynamic = false
        hitbox.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        hitbox.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        hitbox.physicsBody?.collisionBitMask = PhysicsCategory.none
        hitbox.name = "whipHitbox"
        whip.addChild(hitbox)

        hero.addChild(whip)
        whipNode = whip

        // Whip swing animation
        let swingUp = SKAction.rotate(toAngle: direction * 0.3, duration: 0.08)
        let swingDown = SKAction.rotate(toAngle: direction * -0.15, duration: 0.12)
        let swingBack = SKAction.rotate(toAngle: 0, duration: 0.1)

        let removeWhip = SKAction.run { [weak self] in
            whip.removeFromParent()
            self?.whipNode = nil
            self?.isAttacking = false
            self?.hero.childNode(withName: "whipCoil")?.isHidden = false
        }

        whip.run(SKAction.sequence([swingUp, swingDown, swingBack, removeWhip]))
    }

    // MARK: - Projectile (Sub-weapon: Throwing Cross)
    private func throwCross() {
        guard !isGameOver else { return }

        let direction: CGFloat = heroFacingRight ? 1 : -1
        let cross = SKNode()
        cross.name = "cross"
        cross.position = CGPoint(x: hero.position.x + direction * 15, y: hero.position.y + 5)
        cross.zPosition = 9

        // Cross shape
        let vBar = SKSpriteNode(color: SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0), size: CGSize(width: 3, height: 14))
        cross.addChild(vBar)

        let hBar = SKSpriteNode(color: SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0), size: CGSize(width: 10, height: 3))
        hBar.position = CGPoint(x: 0, y: 2)
        cross.addChild(hBar)

        // Physics
        cross.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        cross.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        cross.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        cross.physicsBody?.collisionBitMask = PhysicsCategory.none
        cross.physicsBody?.affectedByGravity = false
        cross.physicsBody?.velocity = CGVector(dx: direction * 350, dy: 0)

        worldNode.addChild(cross)

        // Spinning animation
        let spin = SKAction.rotate(byAngle: direction * .pi * 2, duration: 0.3)
        cross.run(SKAction.repeatForever(spin))

        // Remove after 2 seconds
        cross.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else {
            restartGame()
            return
        }

        for touch in touches {
            let locationInCamera = touch.location(in: cameraNode)
            let nodesAtPoint = cameraNode.nodes(at: locationInCamera)

            for node in nodesAtPoint {
                switch node.name {
                case "leftBtn":
                    isMovingLeft = true
                    heroFacingRight = false
                    hero.xScale = -1
                case "rightBtn":
                    isMovingRight = true
                    heroFacingRight = true
                    hero.xScale = 1
                case "jumpBtn":
                    jump()
                case "attackBtn":
                    performWhipAttack()
                    // Also throw a cross as a ranged sub-weapon
                    throwCross()
                default:
                    break
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let locationInCamera = touch.location(in: cameraNode)
            let nodesAtPoint = cameraNode.nodes(at: locationInCamera)

            for node in nodesAtPoint {
                switch node.name {
                case "leftBtn":
                    isMovingLeft = false
                case "rightBtn":
                    isMovingRight = false
                default:
                    break
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMovingLeft = false
        isMovingRight = false
    }

    // MARK: - Jump
    private func jump() {
        guard isOnGround && !isGameOver else { return }
        isOnGround = false
        hero.physicsBody?.velocity.dy = 0
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse * 0.5))

        // Cape flutter on jump
        if let cape = hero.childNode(withName: "cape") as? SKShapeNode {
            let flutter = SKAction.sequence([
                SKAction.rotate(toAngle: 0.3, duration: 0.15),
                SKAction.rotate(toAngle: -0.1, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.2)
            ])
            cape.run(flutter)
        }
    }

    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        let collision = bodyA.categoryBitMask | bodyB.categoryBitMask

        // Hero lands on ground
        if collision == (PhysicsCategory.hero | PhysicsCategory.ground) ||
           collision == (PhysicsCategory.hero | PhysicsCategory.platform) {
            isOnGround = true
        }

        // Projectile/whip hits enemy
        if collision == (PhysicsCategory.projectile | PhysicsCategory.enemy) {
            let enemyNode = (bodyA.categoryBitMask == PhysicsCategory.enemy) ? bodyA.node : bodyB.node
            let projectileNode = (bodyA.categoryBitMask == PhysicsCategory.projectile) ? bodyA.node : bodyB.node

            if let enemy = enemyNode {
                killEnemy(enemy)
            }
            // Remove cross projectile (but not whip hitbox - it stays attached to hero)
            if projectileNode?.name == "cross" {
                projectileNode?.removeFromParent()
            }
        }

        // Hero touches enemy
        if collision == (PhysicsCategory.hero | PhysicsCategory.enemy) {
            let heroNode = (bodyA.categoryBitMask == PhysicsCategory.hero) ? bodyA.node : bodyB.node
            let enemyNode = (bodyA.categoryBitMask == PhysicsCategory.enemy) ? bodyA.node : bodyB.node

            // Check if hero is landing on top of the enemy (jumping on it)
            if let h = heroNode, let e = enemyNode {
                let heroBottom = h.position.y - 20
                let enemyTop = e.position.y + 10

                if heroBottom > enemyTop - 5 && (h.physicsBody?.velocity.dy ?? 0) < 0 {
                    // Stomped the turtle!
                    killEnemy(e)
                    // Bounce hero up
                    h.physicsBody?.velocity.dy = 0
                    h.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse * 0.3))
                } else {
                    heroHit()
                }
            }
        }
    }

    private func killEnemy(_ enemy: SKNode) {
        score += 100
        scoreLabel.text = "SCORE: \(score)"

        // Death effect - flip and fade
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.none
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.none
        enemy.physicsBody?.collisionBitMask = PhysicsCategory.none

        let deathSequence = SKAction.group([
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: 30, duration: 0.3),
                SKAction.moveBy(x: 0, y: -60, duration: 0.4)
            ]),
            SKAction.rotate(byAngle: .pi * 3, duration: 0.7),
            SKAction.fadeOut(withDuration: 0.7)
        ])

        enemy.run(SKAction.sequence([deathSequence, SKAction.removeFromParent()]))

        // Score popup
        let popup = SKLabelNode(fontNamed: "Courier-Bold")
        popup.fontSize = 14
        popup.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        popup.text = "+100"
        popup.position = enemy.position
        popup.zPosition = 50
        worldNode.addChild(popup)

        popup.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func heroHit() {
        guard !isGameOver else { return }

        lives -= 1
        livesLabel.text = "LIVES: \(lives)"

        // Flash red
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])

        // Apply flash to hero body
        if let body = hero.childNode(withName: "heroBody") as? SKShapeNode {
            let originalColor = body.fillColor
            body.fillColor = .red
            body.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.run { body.fillColor = originalColor }
            ]))
        }

        // Knockback
        let knockbackDir: CGFloat = heroFacingRight ? -1 : 1
        hero.physicsBody?.velocity = .zero
        hero.physicsBody?.applyImpulse(CGVector(dx: knockbackDir * 80, dy: 120))

        if lives <= 0 {
            gameOver()
        }
    }

    private func gameOver() {
        isGameOver = true

        gameOverLabel = SKLabelNode(fontNamed: "Courier-Bold")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.position = CGPoint(x: 0, y: 20)
        gameOverLabel.zPosition = 120
        hudNode.addChild(gameOverLabel)

        let subtitleLabel = SKLabelNode(fontNamed: "Courier")
        subtitleLabel.fontSize = 16
        subtitleLabel.fontColor = SKColor(red: 0.7, green: 0.6, blue: 0.8, alpha: 1.0)
        subtitleLabel.text = "Tap to restart"
        subtitleLabel.position = CGPoint(x: 0, y: -15)
        subtitleLabel.zPosition = 120
        subtitleLabel.name = "restartLabel"
        hudNode.addChild(subtitleLabel)

        let finalScore = SKLabelNode(fontNamed: "Courier-Bold")
        finalScore.fontSize = 20
        finalScore.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        finalScore.text = "FINAL SCORE: \(score)"
        finalScore.position = CGPoint(x: 0, y: 50)
        finalScore.zPosition = 120
        finalScore.name = "finalScoreLabel"
        hudNode.addChild(finalScore)

        // Pulse animation on game over text
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        gameOverLabel.run(SKAction.repeatForever(pulse))
    }

    private func restartGame() {
        // Remove game over labels
        gameOverLabel?.removeFromParent()
        hudNode.childNode(withName: "restartLabel")?.removeFromParent()
        hudNode.childNode(withName: "finalScoreLabel")?.removeFromParent()

        // Reset state
        score = 0
        lives = 3
        isGameOver = false
        isOnGround = true
        isMovingLeft = false
        isMovingRight = false
        scoreLabel.text = "SCORE: 0"
        livesLabel.text = "LIVES: 3"

        // Reset hero position
        hero.position = CGPoint(x: 150, y: groundHeight + 40)
        hero.physicsBody?.velocity = .zero
        hero.xScale = 1
        heroFacingRight = true

        // Remove old enemies and spawn new ones
        worldNode.enumerateChildNodes(withName: "turtle") { node, _ in
            node.removeFromParent()
        }
        worldNode.enumerateChildNodes(withName: "cross") { node, _ in
            node.removeFromParent()
        }
        spawnInitialEnemies()
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }

        let dt: CGFloat
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = CGFloat(currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime

        // Move hero
        if isMovingLeft {
            hero.physicsBody?.velocity.dx = -heroSpeed
        } else if isMovingRight {
            hero.physicsBody?.velocity.dx = heroSpeed
        } else {
            hero.physicsBody?.velocity.dx *= 0.85 // friction
        }

        // Clamp hero position
        let minX: CGFloat = 20
        let maxX: CGFloat = totalWorldWidth - 20
        hero.position.x = max(minX, min(maxX, hero.position.x))

        // Ground check (if hero is barely moving vertically, consider on ground)
        if let vy = hero.physicsBody?.velocity.dy, abs(vy) < 5 {
            isOnGround = true
        }

        // Update camera to follow hero
        let targetCameraX = hero.position.x
        let targetCameraY = size.height / 2
        let cameraX = max(size.width / 2, min(totalWorldWidth - size.width / 2, targetCameraX))
        cameraNode.position = CGPoint(x: cameraX, y: targetCameraY)

        // Parallax scrolling
        let cameraOffsetX = cameraNode.position.x - size.width / 2
        bgLayer1.position.x = -cameraOffsetX * 0.2
        bgLayer2.position.x = -cameraOffsetX * 0.4

        // Update turtle enemies (patrol AI)
        worldNode.enumerateChildNodes(withName: "turtle") { node, _ in
            guard let data = node.userData,
                  let dir = data["direction"] as? Int,
                  let patrolStart = data["patrolStart"] as? CGFloat,
                  let patrolEnd = data["patrolEnd"] as? CGFloat else { return }

            let speed: CGFloat = 40.0
            node.physicsBody?.velocity.dx = CGFloat(dir) * speed

            // Flip direction at patrol bounds
            if node.position.x <= patrolStart && dir == -1 {
                data["direction"] = 1
                node.xScale = -1
            } else if node.position.x >= patrolEnd && dir == 1 {
                data["direction"] = -1
                node.xScale = 1
            }
        }

        // Spawn more enemies as player progresses
        if hero.position.x > lastEnemySpawnX - 800 {
            let newX = lastEnemySpawnX + CGFloat.random(in: 400...700)
            if newX < totalWorldWidth - 100 {
                spawnTurtle(at: CGPoint(x: newX, y: groundHeight + 18))
                lastEnemySpawnX = newX
            }
        }

        // Fall death check
        if hero.position.y < -50 {
            heroHit()
            if !isGameOver {
                hero.position = CGPoint(x: hero.position.x, y: groundHeight + 60)
                hero.physicsBody?.velocity = .zero
            }
        }
    }
}
