//
//  GameScene.m
//  Dropping Cats
//
//  Created by Lionel Chen on 1/3/24.
//


#import "GameScene.h"
#import <Foundation/Foundation.h>


static const uint32_t PhysicsCategoryBallSize1 = 0x1 << 1;
static const uint32_t PhysicsCategoryBallSize2 = 0x1 << 2;
static const uint32_t PhysicsCategoryBallSize3 = 0x1 << 3;
static const uint32_t PhysicsCategoryBallSize4 = 0x1 << 4;
static const uint32_t PhysicsCategoryBallSize5 = 0x1 << 5;




@implementation GameScene {
    
    SKShapeNode *_spinnyNode;
    SKLabelNode *_label;
    BallSize largestUnlockedSize;

}


- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
    self.physicsWorld.contactDelegate = self;
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = 2; // Assuming category 2 for edges
    static const uint32_t PhysicsCategoryBall = 0x1 << 0;
    static const uint32_t PhysicsCategoryEdge = 0x1 << 1;



    
    // Initialization code moved here
    if (!self.unlockedBallSizes) {
        self.unlockedBallSizes = [NSMutableArray arrayWithObject:@(BallSize1)];
        NSLog(@"Unlocked ball sizes initialized as: %@", self.unlockedBallSizes);
    }

    if (!self.ballSpawnProbabilities) {
        self.ballSpawnProbabilities = @[@0.5, @0.3, @0.2]; // Example probabilities
        NSLog(@"Ball spawn probabilities initialized as: %@", self.ballSpawnProbabilities);
    }

    // ... other initialization code, such as setting up the scene ...

    NSLog(@"GameScene didMoveToView: method called");
    
    
    // Get label node from scene and store it for use later
    CGFloat w = (self.size.width + self.size.height) * 0.05;
    
    // Create shape node to use during mouse interaction
    _spinnyNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(w, w) cornerRadius:w * 0.3];
    _spinnyNode.lineWidth = 2.5;
    
    [_spinnyNode runAction:[SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:1]]];
    [_spinnyNode runAction:[SKAction sequence:@[
                                                [SKAction waitForDuration:0.5],
                                                [SKAction fadeOutWithDuration:0.5],
                                                [SKAction removeFromParent],
                                                ]]];
    
    
    // Create a simple slider
    SKShapeNode *slider = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(100, 20)];
    slider.fillColor = [SKColor grayColor];
    slider.name = @"slider"; // Important for identifying the node in touch events
    slider.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 450);
    [self addChild:slider];
    
    /// Calculate container dimensions and positions
    CGFloat edgeThickness = 4.0; // Adjust the thickness of the edge as needed
    CGFloat containerWidth = 450.0;
    CGFloat containerHeight = 950.0;
    CGPoint containerBottomLeft = CGPointMake(CGRectGetMidX(self.frame) - containerWidth / 2, CGRectGetMidY(self.frame) - containerHeight / 2);
    CGPoint containerBottomRight = CGPointMake(containerBottomLeft.x + containerWidth, containerBottomLeft.y);
    CGPoint containerTopLeft = CGPointMake(containerBottomLeft.x, containerBottomLeft.y + containerHeight);
    
    // Left Edge
    SKShapeNode *leftEdge = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, edgeThickness, containerHeight)];
    leftEdge.fillColor = [SKColor grayColor];
    leftEdge.position = containerBottomLeft;
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0, containerHeight)];
    leftEdge.physicsBody.dynamic = NO;
    leftEdge.name = @"leftEdge";
    [self addChild:leftEdge];

    // Right Edge
    SKShapeNode *rightEdge = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, edgeThickness, containerHeight)];
    rightEdge.fillColor = [SKColor grayColor];
    rightEdge.position = CGPointMake(containerBottomRight.x - edgeThickness, containerBottomRight.y);
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0, containerHeight)];
    rightEdge.physicsBody.dynamic = NO;
    rightEdge.name = @"rightEdge";
    [self addChild:rightEdge];

    // Bottom Edge
    SKShapeNode *bottomEdge = [SKShapeNode shapeNodeWithRect:CGRectMake(0, 0, containerWidth, edgeThickness)];
    bottomEdge.fillColor = [SKColor grayColor];
    bottomEdge.position = containerBottomLeft;
    bottomEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(containerWidth, 0)];
    bottomEdge.physicsBody.dynamic = NO;
    bottomEdge.physicsBody.contactTestBitMask = 0; // Set the property on the physics body
    bottomEdge.name = @"bottomEdge";

    [self addChild:bottomEdge];

    
    // Inside didMoveToView: method where you create edges
    leftEdge.physicsBody.categoryBitMask = PhysicsCategoryEdge;
    rightEdge.physicsBody.categoryBitMask = PhysicsCategoryEdge;
    bottomEdge.physicsBody.categoryBitMask = PhysicsCategoryEdge;
    bottomEdge.physicsBody.collisionBitMask = PhysicsCategoryBall; // Allow collisions with balls

}


- (void)spawnBallAtSliderPositionWithSize:(BallSize)size {
    SKNode *slider = [self childNodeWithName:@"slider"];
    if (!slider) return;

    // Update ballSpawnProbabilities dynamically based on unlocked sizes
    [self updateBallSpawnProbabilities];

    // Determine the size of the ball to spawn
    BallSize sizeToSpawn = [self determineBallSizeToSpawn];
    
    CGFloat radius = [self radiusForBallSize:sizeToSpawn];
    SKShapeNode *ball = [SKShapeNode shapeNodeWithCircleOfRadius:radius];
    ball.fillColor = [self colorForBallSize:sizeToSpawn];
    ball.strokeColor = [SKColor blackColor];
    ball.lineWidth = 1.5;
    ball.name = [NSString stringWithFormat:@"ball_%lu", (unsigned long)sizeToSpawn];

    // Set up the physics body for the ball
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius];
    switch (sizeToSpawn) {
        case BallSize1: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize1; break;
        case BallSize2: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize2; break;
        case BallSize3: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize3; break;
        case BallSize4: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize4; break;
        case BallSize5: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize5; break;
        // ... and so on for other sizes
    }
    ball.physicsBody.collisionBitMask = PhysicsCategoryBall | PhysicsCategoryEdge;
    ball.physicsBody.contactTestBitMask = PhysicsCategoryBall | PhysicsCategoryEdge;
    ball.physicsBody.dynamic = YES;
    ball.physicsBody.affectedByGravity = YES;
    ball.physicsBody.allowsRotation = YES;
    ball.physicsBody.friction = 0.1; // Adjust as needed
    ball.physicsBody.restitution = 0.5; // Adjust as needed
    ball.physicsBody.linearDamping = 0.5; // Adjust as needed
    ball.physicsBody.angularDamping = 0.5; // Adjust as needed

    // Position the ball above the slider
    ball.position = CGPointMake(slider.position.x, slider.position.y + radius + 50); // Adjust Y position as needed

    [self addChild:ball];
}



- (BallSize)determineBallSizeToSpawn {
    double randomValue = ((double)arc4random() / UINT32_MAX); // Normalized random value [0, 1]

    double accumulatedProbability = 0.0;
    for (NSUInteger i = 0; i < self.ballSpawnProbabilities.count; i++) {
        NSNumber *probability = self.ballSpawnProbabilities[i];
        accumulatedProbability += probability.doubleValue;

        if (randomValue <= accumulatedProbability) {
            BallSize potentialSize = i + 1; // Assuming BallSize enum starts at 1
            if ([self.unlockedBallSizes containsObject:@(potentialSize)]) {
                return potentialSize;
            }
        }
    }

    return BallSize1; // Fallback to BallSize1
}
- (void)updateBallSpawnProbabilities {
    NSUInteger numUnlockedSizes = self.unlockedBallSizes.count;

    if (numUnlockedSizes == 0) {
        NSLog(@"(Initial state) No unlocked ball sizes yet, but updating probabilities for consistency.");
    } else {
        NSLog(@"Updating ball spawn probabilities based on %lu unlocked sizes: %@", (unsigned long)numUnlockedSizes, self.unlockedBallSizes);
    }

    NSMutableArray *updatedProbabilities = [NSMutableArray arrayWithCapacity:numUnlockedSizes];
    double totalProbability = 1.0;
    double decrementAmount = 0.1; // Adjust this value to control how much less likely larger sizes are

    // Track probabilities being generated
    for (NSUInteger i = 0; i < numUnlockedSizes; i++) {
        double probabilityForSize = totalProbability - (decrementAmount * i);
        [updatedProbabilities addObject:@(probabilityForSize)];
        NSLog(@"Generated probability for size %lu: %f", (unsigned long)i, probabilityForSize);
    }

    // Inspect updatedProbabilities before assignment
    NSLog(@"Probabilities before normalization: %@", updatedProbabilities);

    // Normalize probabilities to sum up to 1.0
    double sum = [[updatedProbabilities valueForKeyPath:@"@sum.self"] doubleValue];
    for (NSUInteger i = 0; i < updatedProbabilities.count; i++) {
        double normalizedProbability = [updatedProbabilities[i] doubleValue] / sum;
        updatedProbabilities[i] = @(normalizedProbability);
    }

    // Inspect normalized probabilities
    NSLog(@"Probabilities after normalization: %@", updatedProbabilities);

    NSLog(@"Updated ball spawn probabilities: %@", self.ballSpawnProbabilities);
    self.ballSpawnProbabilities = updatedProbabilities;
}




- (SKColor *)colorForBallSize:(BallSize)size {
    switch (size) {
        case BallSize1: return [SKColor yellowColor]; // Smallest ball is yellow
        case BallSize2: return [SKColor greenColor];
        case BallSize3: return [SKColor blueColor];
        case BallSize4: return [SKColor redColor];
        case BallSize5: return [SKColor purpleColor];
        // Add more cases as needed
        default: return [SKColor whiteColor]; // Default color
    }
}



- (SKShapeNode *)spawnBallAtPosition:(CGPoint)position withSize:(BallSize)size {
    CGFloat radius = [self radiusForBallSize:size];
    SKShapeNode *ball = [SKShapeNode shapeNodeWithCircleOfRadius:radius];
    NSLog(@"Spawning ball of size: %lu", (unsigned long)size);

    ball.fillColor = [self colorForBallSize:size]; // Use the method to determine color
    ball.strokeColor = [SKColor blackColor];
    ball.lineWidth = 1.5;
    ball.name = [NSString stringWithFormat:@"ball_%lu", (unsigned long)size];

    // Set up the physics body for the ball
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:radius];
    ball.physicsBody.dynamic = YES;
    ball.physicsBody.affectedByGravity = YES;
    ball.physicsBody.allowsRotation = YES;
    ball.physicsBody.friction = 0.1;
    ball.physicsBody.restitution = 0.5;
    ball.physicsBody.linearDamping = 0.5;
    ball.physicsBody.angularDamping = 0.5;
    ball.physicsBody.categoryBitMask = 1 << size;
    ball.physicsBody.contactTestBitMask = 0xFFFFFFFF;

    ball.position = position;
    
    switch (size) {
        case BallSize1: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize1; break;
        case BallSize2: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize2; break;
        case BallSize3: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize3; break;
        case BallSize4: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize4; break;
        case BallSize5: ball.physicsBody.categoryBitMask = PhysicsCategoryBallSize5; break;
        // ... and so on for other sizes
    }


    [self addChild:ball];
    return ball;
}


- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKNode *nodeA = contact.bodyA.node;
    SKNode *nodeB = contact.bodyB.node;

    //NSLog(@"%@: categoryBitMask = %lu, contactTestBitMask = %lu", nodeA.name, (unsigned long)nodeA.physicsBody.categoryBitMask, (unsigned long)nodeA.physicsBody.contactTestBitMask);
    //NSLog(@"%@: categoryBitMask = %lu, contactTestBitMask = %lu", nodeB.name, (unsigned long)nodeB.physicsBody.categoryBitMask, (unsigned long)nodeB.physicsBody.contactTestBitMask);

    if ([self isBall:nodeA] && [self isBall:nodeB] && nodeA.physicsBody.categoryBitMask == nodeB.physicsBody.categoryBitMask) {


        BallSize sizeA = [self sizeFromName:nodeA.name];
        BallSize sizeB = [self sizeFromName:nodeB.name];
        
        NSLog(@"Here comes %@ and %@ making contact", nodeA.name, nodeB.name);
        
        BallSize mergedSize = MAX(sizeA, sizeB) + 1;  // Assuming consecutive sizes

        // Merge BallSize1 balls
        if (sizeA == BallSize1 && sizeB == BallSize1) {
            [self mergeBalls:nodeA withBall:nodeB intoSize:mergedSize mergedSize:mergedSize];
            NSLog(@"balls merging into size 2. Nodes involved: %@ and %@", nodeA.name, nodeB.name);
        }

        // Merge BallSize2 balls
        else if (sizeA == BallSize2 && sizeB == BallSize2) {
            [self mergeBalls:nodeA withBall:nodeB intoSize:mergedSize mergedSize:mergedSize];
            NSLog(@"balls merging into size 3. Nodes involved: %@ and %@", nodeA.name, nodeB.name);
        }
        
        else if (sizeA == BallSize3 && sizeB == BallSize3) {
            [self mergeBalls:nodeA withBall:nodeB intoSize:mergedSize mergedSize:mergedSize];
            NSLog(@"balls merging into size 4. Nodes involved: %@ and %@", nodeA.name, nodeB.name);
        }
        
        else if (sizeA == BallSize4 && sizeB == BallSize4) {
            [self mergeBalls:nodeA withBall:nodeB intoSize:mergedSize mergedSize:mergedSize];
            NSLog(@"balls merging into size 5. Nodes involved: %@ and %@", nodeA.name, nodeB.name);
        }
        
        else {
            NSLog(@"Balls did not merge. Sizes: %lu and %lu", (unsigned long)sizeA, (unsigned long)sizeB);
        }
    } else if ([nodeA.name isEqualToString:@"bottomEdge"] || [nodeB.name isEqualToString:@"bottomEdge"]) {
        NSLog(@"Ball collided with edge.");
        return; // Skip further processing for edge collisions
    } else {
        // Log if the collision is not between two mergeable balls
        NSLog(@"Collision not between two mergeable balls. Nodes involved: %@ and %@", nodeA.name, nodeB.name);
    }
}

- (BOOL)isBall:(SKNode *)node {
    uint32_t bitmask = node.physicsBody.categoryBitMask;
    return (bitmask == PhysicsCategoryBallSize1 ||
            bitmask == PhysicsCategoryBallSize2 ||
            bitmask == PhysicsCategoryBallSize3 ||
            bitmask == PhysicsCategoryBallSize4 ||
            bitmask == PhysicsCategoryBallSize5) &&
           node.physicsBody.contactTestBitMask != 0;
}


- (void)mergeBalls:(SKNode *)nodeA withBall:(SKNode *)nodeB intoSize:(BallSize)newSize mergedSize:(BallSize)mergedSize {
    CGPoint newPosition = CGPointMake((nodeA.position.x + nodeB.position.x) / 2,
                                           (nodeA.position.y + nodeB.position.y) / 2);
    [nodeA removeFromParent];
    [nodeB removeFromParent];

    BOOL isNewSizeUnlocked = NO;
    NSNumber *newSizeNumber = @(mergedSize);

    // Log current unlocked sizes before potential addition
    NSLog(@"Current unlocked sizes before merge: %@", self.unlockedBallSizes);

    if (![self.unlockedBallSizes containsObject:newSizeNumber]) {
        [self.unlockedBallSizes addObject:newSizeNumber];
        NSLog(@"Added new size %@ to unlocked ball sizes: %@", @(mergedSize), self.unlockedBallSizes);

        isNewSizeUnlocked = YES;
        NSLog(@"Unlocked new size: %@", newSizeNumber);
    } else {
        NSLog(@"Size %@ already unlocked.", newSizeNumber);
    }

    // **New logging for verification**
    NSLog(@"Unlocked ball sizes after adding new size: %@", self.unlockedBallSizes);

    // Create the new ball with the appropriate category bit mask
    SKShapeNode *newBall = [self spawnBallAtPosition:newPosition withSize:newSize];
    switch (newSize) {
        case BallSize1: newBall.physicsBody.categoryBitMask = PhysicsCategoryBallSize1; break;
        case BallSize2: newBall.physicsBody.categoryBitMask = PhysicsCategoryBallSize2; break;
        case BallSize3: newBall.physicsBody.categoryBitMask = PhysicsCategoryBallSize3; break;
        case BallSize4: newBall.physicsBody.categoryBitMask = PhysicsCategoryBallSize4; break;
        case BallSize5: newBall.physicsBody.categoryBitMask = PhysicsCategoryBallSize5; break;
        // ... and so on for other sizes
    }

    // Check if newBall already has a parent
    if (!newBall.parent) {
        [self addChild:newBall];
    }

    NSLog(@"hmmmm can the mergeball function get to the statement below??!?!");
    // Update probabilities if a new size was unlocked
    if (isNewSizeUnlocked) {
        NSLog(@"OH WOWOWWW YES IT CANNNN??!?!");
        [self updateBallSpawnProbabilities];
    }
}





- (CGFloat)radiusForBallSize:(BallSize)size {
    switch (size) {
        case BallSize1: return 15.0;
        case BallSize2: return 25.0;
        case BallSize3: return 40.0;
        case BallSize4: return 55.0;
        case BallSize5: return 70.0;

        // Add more sizes as needed
    }
}
- (BallSize)sizeFromName:(NSString *)name {
    NSUInteger sizeIndex = [[[name componentsSeparatedByString:@"_"] lastObject] integerValue];
    switch (sizeIndex) {
        case 1: return BallSize1;
        case 2: return BallSize2;
        case 3: return BallSize3;
        case 4: return BallSize4;
        case 5: return BallSize5;
        default: return BallSize1; // Default case
    }
}


- (void)touchDownAtPoint:(CGPoint)pos {
    SKShapeNode *n = [_spinnyNode copy];
    n.position = pos;
    n.strokeColor = [SKColor greenColor];
    [self addChild:n];
}


- (void)touchMovedToPoint:(CGPoint)pos {
    SKNode *slider = [self childNodeWithName:@"slider"];
    if (slider) {
        slider.position = CGPointMake(pos.x, slider.position.y);
    }
}

- (void)touchUpAtPoint:(CGPoint)pos {
    SKShapeNode *n = [_spinnyNode copy];
    n.position = pos;
    n.strokeColor = [SKColor redColor];
    [self addChild:n];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        CGPoint pos = [t locationInNode:self];

        SKNode *slider = [self childNodeWithName:@"slider"];
        if (slider) {
            slider.position = CGPointMake(pos.x, slider.position.y);
        }

    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        CGPoint pos = [t locationInNode:self];
        [self touchMovedToPoint:pos];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        [self spawnBallAtSliderPositionWithSize:BallSize1]; // Spawn ball when touch is released
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchUpAtPoint:[t locationInNode:self]];}
}


-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
}

@end
