extends Resource
class_name OfflineWorldConfig

## Compatibility resource for the shared R.E.A.L. ActionExecutor.
## This project keeps its state in main.gd; the executor only needs a valid
## preload target so the shared debug bridge can be used unchanged.
const PROJECT_ID := "no_wifi_games"
static var game_speed: float = 1.0
