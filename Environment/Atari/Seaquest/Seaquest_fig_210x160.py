import pygame
import random
import sys
import json
# 初始化 pygame
pygame.init()

# 定义屏幕大小
SCREEN_WIDTH, SCREEN_HEIGHT = 210, 160
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("Seaquest")
# 定义颜色
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 255, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)
PLAYER_BULLET_COLOR = (0, 255, 255)  # 自己子弹的颜色
ENEMY_BULLET_COLOR = (255, 0, 0)     # 敌人子弹的颜色

# 定义玩家、敌人、潜水员的大小
PLAYER_SIZE = 10
ENEMY_SIZE = 10
DIVER_SIZE = 8
BULLET_SIZE = 2

# 定义速度
PLAYER_SPEED = 1
ENEMY_SPEED = 1
PSUB_SPEED = 1  # 巡逻潜艇的速度
DIVER_SPEED = 1
PLAYER_BULLET_SPEED = 1  # 自己子弹的速度
ENEMY_BULLET_SPEED = 1    # 敌人子弹的速度
# define the maximum number
MAX_ENEMY_BULLETS = 5  # 最大敌人子弹数目
MAX_PLAYER_BULLET = 5  # 最大玩家子弹数目
MAX_OXYGEN = 100  # 最大氧气量
MAX_ENEMIES = 5  # 设置最大敌人数目
MAX_DIVERS = 5  # 设置最大潜水员数目

# 水面的 y 坐标
SURFACE_Y = 10  # 定义水平面的位置，当玩家潜艇到达该 y 坐标时，补充氧气

# 定义帧率
FPS = 60

# 定义玩家类
class Player:
    def __init__(self):
        self.diver_reward = 0
        self.x = SCREEN_WIDTH // 4
        self.y = SCREEN_HEIGHT // 2
        self.width = PLAYER_SIZE
        self.height = PLAYER_SIZE
        self.speed = PLAYER_SPEED
        self.oxygen = MAX_OXYGEN

        self.current_divers_count = 0 # 船上目前的潜水员数量
        self.lives = 4  # 初始潜艇数量
        self.max_lives = 6  # 潜艇最大数量
        self.has_surface = False  # 标志玩家是否已在水面上处理过潜水员或潜艇损失
        self.succeed_surface = 0  # 标志玩家成功浮出水面,且未损失潜水员或潜艇的次数

    def move(self, keys):
        if keys[pygame.K_LEFT] and self.x > 0:
            self.x -= self.speed
        if keys[pygame.K_RIGHT] and self.x + self.width < SCREEN_WIDTH:
            self.x += self.speed
        if keys[pygame.K_UP] and self.y > 0:
            self.y -= self.speed
        if keys[pygame.K_DOWN] and self.y + self.height < SCREEN_HEIGHT:
            self.y += self.speed

    def draw(self):
        pygame.draw.rect(screen, YELLOW, (self.x, self.y, self.width, self.height))

    def lose_life(self):
        self.lives -= 1
        if self.lives <= 0:
            print("所有潜艇都被摧毁！游戏结束！")
            pygame.quit()
            sys.exit()

    def gain_life(self):
        if self.lives < self.max_lives:
            self.lives += 1

    def refill_oxygen(self):
        self.oxygen = MAX_OXYGEN

    def handle_surface_logic(self, score):

        if self.current_divers_count == 6:
            print("你已经救援了 6 名潜水员！获得奖励！")
            if (self.diver_reward <=1000):
                self.diver_reward = 50 + 50 * self.succeed_surface
            else:
                self.diver_reward = 1000
            score += self.diver_reward  # 获得50分奖励
            self.current_divers_count = 0  # 重置潜水员数量
            self.succeed_surface += 1  # 成功浮出水面次数加1
            self.refill_oxygen()  # 补满氧气
            self.has_surface = True  # 标志已处理过一次浮出水面
        elif self.current_divers_count < 6:
            # 只有在 self.has_surface 为 False 的情况下处理潜水员或潜艇损失
            if not self.has_surface:
                if self.current_divers_count == 0:
                    self.lose_life()  # 没有潜水员则失去一艘潜艇
                    print("没有潜水员，损失一艘潜艇！")
                else:
                    self.current_divers_count -= 1  # 有潜水员但不足6个，失去一个潜水员
                    print("救援的潜水员不足6个，损失一名潜水员！")
                self.has_surface = True  # 标志已经处理过一次潜水逻辑
        return score
# 定义巡逻潜艇类

class PatrolSubmarine:
    def __init__(self):
        self.x = -ENEMY_SIZE  # 巡逻潜艇从屏幕左边外面开始
        self.y = SURFACE_Y  # 巡逻潜艇总是在水面上
        self.width = ENEMY_SIZE
        self.height = ENEMY_SIZE
        self.speed = PSUB_SPEED # 巡逻潜艇的速度
        self.direction = 1  # 1 表示向右

    def move(self):
        self.x += self.speed * self.direction
        # 当巡逻潜艇走出屏幕右边时，标记完成一圈
        if self.x > SCREEN_WIDTH:
            return False  # 表示巡逻潜艇完成了一圈并应被移除
        return True

    def draw(self):
        pygame.draw.rect(screen, BLUE, (self.x, self.y, self.width, self.height))

    def check_collision(self, player):
        if player.x < self.x + self.width and player.x + player.width > self.x and player.y < self.y + self.height and player.y + player.height > self.y:
            print("巡逻潜艇碰撞玩家！")
            player.lose_life()

# 定义敌人类
class Enemy:
    def __init__(self):
        self.x = SCREEN_WIDTH if random.random() > 0.5 else -ENEMY_SIZE
        self.y = random.randint(50, SCREEN_HEIGHT - ENEMY_SIZE)
        self.width = ENEMY_SIZE
        self.height = ENEMY_SIZE
        self.succeed_surface = 0  # 玩家成功浮出水面的次数
        self.speed = ENEMY_SPEED + self.succeed_surface  # 敌人速度随玩家成功浮出水面次数增加
        self.direction = 1 if self.x == -ENEMY_SIZE else -1
        self.color = RED if random.random() > 0.5 else BLUE
        self.last_shot_time = pygame.time.get_ticks()
        self.shoot_delay = random.randint(1000, 3000)  # 随机发射子弹的间隔时间

    def move(self):
        self.x += self.speed * self.direction

    def shoot(self):
        current_time = pygame.time.get_ticks()
        if current_time - self.last_shot_time > self.shoot_delay:
            if self.color == RED:
                self.last_shot_time = current_time
                return Bullet(self.x, self.y, -self.direction, ENEMY_BULLET_COLOR, ENEMY_BULLET_SPEED)  # 子弹的方向根据敌人的方向
        return None

    def draw(self):
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.width, self.height))

# 定义潜水员类
class Diver:
    def __init__(self):
        self.x = random.randint(0, SCREEN_WIDTH - DIVER_SIZE)
        self.y = random.randint(100, SCREEN_HEIGHT - DIVER_SIZE)
        self.width = DIVER_SIZE
        self.height = DIVER_SIZE
        self.speed_x = random.choice([-1, 1]) * DIVER_SPEED  # 随机水平速度
        self.speed_y = 0  # 随机垂直速度 

    def move(self):
        self.x += self.speed_x
        self.y += self.speed_y

        # 碰到屏幕边缘时反弹
        if self.x < 0 or self.x > SCREEN_WIDTH - self.width:
            self.speed_x = -self.speed_x
        if self.y < 0 or self.y > SCREEN_HEIGHT - self.height:
            self.speed_y = -self.speed_y

    def draw(self):
        self.move()  # 更新位置
        pygame.draw.rect(screen, GREEN, (self.x, self.y, self.width, self.height))
 
# 定义子弹类
class Bullet:
    def __init__(self, x, y, direction, color, speed):
        self.x = x
        self.y = y
        self.width = BULLET_SIZE
        self.height = BULLET_SIZE
        self.speed = speed * direction  # 子弹速度随方向变化
        self.color = color

    def move(self):
        self.x += self.speed

    def draw(self):
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.width, self.height))

# 绘制救援的潜水员图标
def draw_rescued_divers(player):
    for i in range(player.current_divers_count):
        # 在屏幕的左下角绘制小潜水员图标
        x = 10 + i * 10  # 间距设置为40
        y = SCREEN_HEIGHT - 10  # 距离底部50像素
        pygame.draw.rect(screen, GREEN, (x, y, DIVER_SIZE, DIVER_SIZE))  # 绘制一个代表潜水员的小矩形

# 定义游戏主函数
def game():
    clock = pygame.time.Clock()
    player = Player()
    enemies = []
    divers = [Diver() for _ in range(6)]
    bullets = []
    enemy_bullets = []
    shoot_reward = 0
    score = 0
    score_for_extra_life = 10000  # 每增加10000分增加一条潜艇
    patrol_submarine = None  # 初始状态下没有巡逻潜艇
    all_states = []  # 用于存储每一帧的状态数据

    # 游戏主循环
    while True:
        screen.fill(BLACK)
        keys = pygame.key.get_pressed()

        # 玩家动作
        player.move(keys)
        if keys[pygame.K_RETURN] and len(bullets) < MAX_PLAYER_BULLET:
            bullets.append(Bullet(player.x + player.width, player.y + player.height // 2, 1, PLAYER_BULLET_COLOR, PLAYER_BULLET_SPEED))  # 向右发射
        elif keys[pygame.K_SPACE] and len(bullets) < MAX_PLAYER_BULLET:
            bullets.append(Bullet(player.x - player.width, player.y + player.height // 2, -1, PLAYER_BULLET_COLOR, PLAYER_BULLET_SPEED))  # 向左发射
        pygame.draw.line(screen, WHITE, (0, SURFACE_Y), (SCREEN_WIDTH, SURFACE_Y), 1)  # 1 像素粗的白色线

        for bullet in bullets[:]:
            bullet.move()
            bullet.draw()
            if bullet.x < 0 or bullet.x > SCREEN_WIDTH:  # 移除超出屏幕的子弹
                bullets.remove(bullet)



        # 检查是否到达水面补充氧气并处理潜水员和潜艇损失逻辑
        if player.y <= SURFACE_Y:
            score = player.handle_surface_logic(score)
            if (player.succeed_surface % 2 == 0) and not patrol_submarine:  # 当成功送回两次6个潜水员时生成巡逻潜艇
                patrol_submarine = PatrolSubmarine()  # 生成巡逻潜艇
                # player.succeed_surface = 0  # 重置成功送回潜水员的计数
        else:
            player.has_surface = False  # 如果潜艇不在水面上，则重置该标志




        # 敌人生成与更新
        if random.random() < 0.02 and len(enemies) < MAX_ENEMIES:  # 检查当前敌人数目是否小于上限
            enemies.append(Enemy())


        for enemy in enemies[:]:
            enemy.move()
            enemy.draw()
            if enemy.x < -ENEMY_SIZE or enemy.x > SCREEN_WIDTH + ENEMY_SIZE:
                enemies.remove(enemy)

            # 敌人发射子弹
            if len(enemy_bullets) < MAX_ENEMY_BULLETS:
                enemy_bullet = enemy.shoot()
                if enemy_bullet:
                    enemy_bullets.append(enemy_bullet)

            # 检查子弹是否击中敌人
            for bullet in bullets[:]:
                if bullet.x < enemy.x + enemy.width and bullet.x + bullet.width > enemy.x and bullet.y < enemy.y + enemy.height and bullet.y + bullet.height > enemy.y:
                    enemies.remove(enemy)
                    bullets.remove(bullet)
                    if shoot_reward <= 90:
                        shoot_reward = 20 + 10 * player.succeed_surface
                    else: 
                        shoot_reward = 90
                    score += shoot_reward  # 击杀一个敌人获得100分
                    break

            # 检查敌人与玩家的碰撞
            if player.x < enemy.x + enemy.width and player.x + player.width > enemy.x and player.y < enemy.y + enemy.height and player.y + player.height > enemy.y:
                player.lose_life()
                enemies.remove(enemy)

        # 更新并绘制敌人子弹
        for enemy_bullet in enemy_bullets[:]:
            enemy_bullet.move()
            enemy_bullet.draw()

            # 检查敌人子弹与玩家的碰撞
            if player.x < enemy_bullet.x + enemy_bullet.width and player.x + player.width > enemy_bullet.x and player.y < enemy_bullet.y + enemy_bullet.height and player.y + player.height > enemy_bullet.y:
                player.lose_life()
                enemy_bullets.remove(enemy_bullet)

            # 移除超出屏幕的敌人子弹
            if enemy_bullet.x < 0 or enemy_bullet.x > SCREEN_WIDTH:
                enemy_bullets.remove(enemy_bullet)

        # 更新巡逻潜艇
        if patrol_submarine:
            if patrol_submarine.move():  # 如果巡逻潜艇还在屏幕内
                patrol_submarine.draw()
                patrol_submarine.check_collision(player)
            else:
                patrol_submarine = None  # 巡逻潜艇完成一圈后移除


        # 绘制潜水员并检查救援
        for diver in divers[:]:
            diver.draw()
            if player.x < diver.x + diver.width and player.x + player.width > diver.x and player.y < diver.y + diver.height and player.y + player.height > diver.y:
                if (player.current_divers_count < 6):  
                    divers.remove(diver)
                    player.current_divers_count += 1
                    score += 50
                else: 
                    print("船上潜水员已满，无法救援！")

            if len(divers) < MAX_DIVERS:  # 确保潜水员总数为6
                divers.append(Diver())

        # 画出玩家潜艇
        player.draw()

        # 绘制救援的潜水员数量
        draw_rescued_divers(player)

        # 更新氧气
        if player.y > SURFACE_Y:  # 只有在水下时氧气消耗
            player.oxygen -= 0.1  # 每帧消耗氧气

        if player.oxygen <= 0:
            player.lose_life()
            player.oxygen = MAX_OXYGEN  # 重置氧气

        # 增加生命值逻辑
        if score >= score_for_extra_life:
            player.gain_life()
            score_for_extra_life += 10000  # 下一个10000分点再次增加生命

        # # 绘制得分、氧气和生命状态
        # font = pygame.font.Font(None, 18)
        # text = font.render(f"得分: {score}  氧气: {int(player.oxygen)}%  生命: {player.lives} 船上潜水员数目: {player.current_divers_count}", True, WHITE)
        # screen.blit(text, (10, 10))

        # # 绘制得分、氧气和生命状态
        # font = pygame.font.Font(None, 18)
        # text = f"得分: {score}  氧气: {int(player.oxygen)}%  生命: {player.lives} 船上潜水员数目: {player.current_divers_count}"
        # pygame.display.set_caption(text)

        # 绘制得分、氧气和生命状态
        font = pygame.font.Font(None, 18)
        text1 = f"得分: {score}  氧气: {int(player.oxygen)}%"
        text2 = f"生命: {player.lives} 船上潜水员数目: {player.current_divers_count}"
        text_surface1 = font.render(text1, True, (255, 255, 255))
        text_surface2 = font.render(text2, True, (255, 255, 255))
        screen.blit(text_surface1, (10, 10))
        screen.blit(text_surface2, (10, 30))

        # 刷新屏幕
        pygame.display.flip()



        # # 保存状态数据
        state_data = {
            "player": {
                "x": player.x,
                "y": player.y,
                "oxygen": player.oxygen,
                "lives": player.lives,
                "current_divers_count": player.current_divers_count  # 添加船上现有的潜水员数量
            },
            "bullets": [{"x": bullet.x, "y": bullet.y, "speed": bullet.speed} for bullet in bullets],
            "enemy_bullets": [{"x": bullet.x, "y": bullet.y, "speed": bullet.speed} for bullet in enemy_bullets],
            "enemies": [{"x": enemy.x, "y": enemy.y, "speed": enemy.speed} for enemy in enemies],
            "divers": [{"x": diver.x, "y": diver.y} for diver in divers],
            "patrol_submarine": {
                "x": patrol_submarine.x,
                "y": patrol_submarine.y,
                "speed": patrol_submarine.speed
            } if patrol_submarine else None,  # 添加巡逻潜艇的状态
            "score": score  # 添加得分
        }

        # # 添加当前帧的状态数据到 all_states
        all_states.append(state_data)


        if len(all_states) >= 300:  # 比如存储 300 帧的数据
            with open("state_data.json", "w") as f:
                json.dump(all_states, f)
            print("State data saved to state_data.json")
            break  # 暂时停止游戏循环以保存数据

        # 事件处理（退出事件）
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        # 更新游戏速度
        clock.tick(FPS)

if __name__ == "__main__":
    game()