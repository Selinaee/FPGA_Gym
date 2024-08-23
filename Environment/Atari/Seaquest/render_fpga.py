import pygame
import json
import sys

# 初始化 pygame
pygame.init()

# 定义屏幕大小
SCREEN_WIDTH, SCREEN_HEIGHT = 210, 160
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("Seaquest - Replay")

# 定义颜色
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 255, 0)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)
PLAYER_BULLET_COLOR = (0, 255, 255)
ENEMY_BULLET_COLOR = (255, 0, 0)

# 定义玩家、敌人、潜水员的大小
PLAYER_SIZE = 10
ENEMY_SIZE = 10
DIVER_SIZE = 8
BULLET_SIZE = 2

# 渲染游戏状态的函数
def render_state(state):
    # 清空屏幕
    screen.fill(BLACK)

    # 渲染玩家
    player_data = state['player']
    pygame.draw.rect(screen, YELLOW, (player_data['x'], player_data['y'], PLAYER_SIZE, PLAYER_SIZE))

    # 渲染子弹
    for bullet_data in state['bullets']:
        if bullet_data['active']:  # 只渲染活跃的子弹
            pygame.draw.rect(screen, PLAYER_BULLET_COLOR, (bullet_data['x'], bullet_data['y'], BULLET_SIZE, BULLET_SIZE))

    # 渲染敌人子弹
    for bullet_data in state['enemy_bullets']:
        if bullet_data['active']:  # 只渲染活跃的敌人子弹
            pygame.draw.rect(screen, ENEMY_BULLET_COLOR, (bullet_data['x'], bullet_data['y'], BULLET_SIZE, BULLET_SIZE))

    # 渲染敌人
    for enemy_data in state['enemies']:
        if enemy_data['active']:  # 只渲染活跃的敌人
            enemy_color = RED if enemy_data['type'] == 1 else BLUE
            pygame.draw.rect(screen, enemy_color, (enemy_data['x'], enemy_data['y'], ENEMY_SIZE, ENEMY_SIZE))

    # 渲染潜水员
    for diver_data in state['divers']:
        if diver_data['active']:  # 只渲染活跃的潜水员
            pygame.draw.rect(screen, GREEN, (diver_data['x'], diver_data['y'], DIVER_SIZE, DIVER_SIZE))

    # 渲染巡逻潜艇
    patrol_submarine_data = state['patrol_submarine']
    if patrol_submarine_data['active']:  # 只渲染活跃的巡逻潜艇
        pygame.draw.rect(screen, BLUE, (patrol_submarine_data['x'], patrol_submarine_data['y'], ENEMY_SIZE, ENEMY_SIZE))

    # 渲染得分、氧气和潜水员、潜艇信息
    font = pygame.font.Font(None, 18)
    text1 = f"得分: {state['score']}  氧气: {int(player_data['oxygen'])}%"
    text2 = f"生命: {player_data['lives']} 船上潜水员数目: {player_data['current_divers_count']}"
    text_surface1 = font.render(text1, True, WHITE)
    text_surface2 = font.render(text2, True, WHITE)
    screen.blit(text_surface1, (10, 10))
    screen.blit(text_surface2, (10, 30))

    # 刷新屏幕
    pygame.display.flip()

# 播放重放
def replay():
    # 打开并加载 JSON 文件
    with open("simulation_output.json", "r") as f:
        all_states = json.load(f)

    clock = pygame.time.Clock()

    # 循环遍历每个状态，进行渲染
    for state in all_states:
        render_state(state)
        clock.tick(1)  # 控制重放速度

        # 处理退出事件
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

if __name__ == "__main__":
    replay()